extends Node
# 背包和已放置物品管理器

# 背包物品 {物品ID: 数量}
var inventory: Dictionary = {}

signal item_used(item_id: String)
signal item_added(item_id: String, count: int)
signal storage_updated()  # 存放物品更新时发送

# 已放置在笼子里的物品列表 [{id, position, food_storage: [], ...}]
var placed_items: Array = []

# 当前选中的喂食器（用于存放界面）
var selected_feeder_index: int = -1

# 跟踪喂食器已喂了几只兔子（一个食物可以喂3只）
var feeder_feed_count: Dictionary = {}  # {feeder_index: count}
var fountain_feed_count: Dictionary = {}  # {fountain_index: count}
var house_feed_count: Dictionary = {}  # {house_index: count} 小木屋玩具计数

# 喂食计时器（每3秒喂一次）
var feed_timer: float = 0.0

# 青草垫相关
var grass_mat_duration: float = 60.0  # 青草垫持续时间（60秒）
var grass_mat_active: Array = []  # 活跃的青草垫 [{index, remaining_time}, ...]

# 放置的物品效果累加
var total_happiness_bonus: float = 0.0
var total_hunger_bonus: float = 0.0
var total_thirst_bonus: float = 0.0
var total_fur_bonus: float = 0.0

signal item_purchased(item_id: String)
signal item_placed(item_id: String, position: Vector2)

func _ready():
	print("✅✅✅ InventoryManager._ready() 被调用了！")
	# 启动时计算效果
	calculate_bonuses()
	# 启动效果应用循环 - 使用正确的循环方式
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_apply_bonuses_every_minute)
	add_child(timer)
	print("✅ 循环计时器已创建！")

# 每秒应用一次设施效果
func _apply_bonuses_every_minute():
	# 如果有兔子的话才应用效果
	var fence = get_tree().root.get_node_or_null("Main/FenceArea")
	if not fence:
		print("DEBUG: 没有找到围栏 Main/FenceArea")
		return

	# 统计所有兔子（先统计，方便调试）
	var rabbits = []
	for child in fence.get_children():
		if child is CharacterBody2D:
			rabbits.append(child)

	# 检查喂食器和饮水器是否有存储的物资
	var has_stored_food = false
	var has_stored_water = false

	print("DEBUG: placed_items.size()=", placed_items.size())
	for placed in placed_items:
		print("DEBUG: 检查物品 id=", placed.id)
		# 检查喂食器是否有食物
		if placed.id == "auto_feeder" or placed.id == "golden_bowl":
			var food_count = 0
			var food_storage = placed.get("food_storage", [])
			print("DEBUG: food_storage =", food_storage)
			for stored in food_storage:
				food_count += stored.count
			if food_count > 0:
				has_stored_food = true
				print("DEBUG: ", placed.id, " 有食物 ", food_count, " 个")
		# 检查饮水器是否有水
		if placed.id == "water_fountain":
			var water_count = 0
			for stored in placed.get("water_storage", []):
				water_count += stored.count
			if water_count > 0:
				has_stored_water = true
				print("DEBUG: ", placed.id, " 有水 ", water_count, " 个")

	print("DEBUG: 兔子数量=", rabbits.size(), ", 有食物=", has_stored_food, ", 有水=", has_stored_water, ", 饥饿加成=", total_hunger_bonus)

	# 更新青草垫倒计时
	_update_grass_mat_timer(rabbits)

	# 应用效果（缓慢的，每分钟的效果）
	for child in rabbits:
		# 饥饿需要有食物在喂食器里
		if total_hunger_bonus > 0 and has_stored_food:
			child.hunger = min(100, child.hunger + total_hunger_bonus / 60)
		# 口渴需要有水在饮水器里
		if total_thirst_bonus > 0 and has_stored_water:
			child.thirst = min(100, child.thirst + total_thirst_bonus / 60)
		if total_happiness_bonus > 0:
			child.happiness = min(100, child.happiness + total_happiness_bonus / 60)
		if total_fur_bonus > 0:
			child.fur_length = min(100, child.fur_length + total_fur_bonus / 60)

	# 累计计时器，每3秒喂一次（快速的，消耗食物的喂食）
	feed_timer += 1.0  # 每秒+1
	print("DEBUG: feed_timer=", feed_timer)

	if feed_timer < 3.0:
		return  # 还没到3秒，返回
	feed_timer = 0.0  # 重置计时器
	print("DEBUG: 达到3秒，开始喂食！")

	if rabbits.size() == 0:
		print("DEBUG: 没有兔子，跳过喂食")
		return

	var has_update = false

	# 给每个喂食器的兔子喂食物
	for i in range(placed_items.size()):
		var placed = placed_items[i]
		if placed.id == "auto_feeder" or placed.id == "golden_bowl":
			# 检查是否有食物
			var has_food = false
			for stored in placed.get("food_storage", []):
				if stored.count > 0:
					has_food = true
					break

			if has_food:
				var count = feeder_feed_count.get(i, 0)
				print("DEBUG: ", placed.id, " feed_count=", count)

				if count >= 3:
					# 已经喂了3次，消耗一个食物
					if _consume_food_from_feeder(i):
						feeder_feed_count[i] = 0
						has_update = true
						print("✅ ", placed.id, " 消耗了一个食物，重置计数器")
				else:
					# 给所有兔子加饱食度
					for rabbit in rabbits:
						var old_hunger = rabbit.hunger
						rabbit.hunger = min(100, rabbit.hunger + 2.0)  # 增加到 2.0，效果更明显
						print("🐰 ", rabbit.rabbit_name, " 饱食: ", old_hunger, " -> ", rabbit.hunger)
					feeder_feed_count[i] = count + 1
					print("✅ ", placed.id, " 喂食成功，第", feeder_feed_count[i], "次")

		if placed.id == "water_fountain":
			# 检查是否有水
			var has_water = false
			for stored in placed.get("water_storage", []):
				if stored.count > 0:
					has_water = true
					break

			if has_water:
				var count = fountain_feed_count.get(i, 0)
				print("DEBUG: ", placed.id, " feed_count=", count)

				if count >= 3:
					# 已经喂了3次，消耗一瓶水
					if _consume_water_from_fountain(i):
						fountain_feed_count[i] = 0
						has_update = true
						print("✅ 饮水器消耗了一瓶水，重置计数器")
				else:
					# 给所有兔子加口渴度
					for rabbit in rabbits:
						var old_thirst = rabbit.thirst
						rabbit.thirst = min(100, rabbit.thirst + 2.0)  # 增加到 2.0，效果更明显
						print("🐰 ", rabbit.rabbit_name, " 口渴: ", old_thirst, " -> ", rabbit.thirst)
					fountain_feed_count[i] = count + 1
					print("✅ 饮水器喂水成功，第", fountain_feed_count[i], "次")

			if placed.id == "wooden_house":
				# 检查是否有玩具
				var has_toy = false
				for stored in placed.get("toy_storage", []):
					if stored.count > 0:
						has_toy = true
						break

				if has_toy:
					var count = house_feed_count.get(i, 0)
					print("DEBUG: ", placed.id, " feed_count=", count)

					if count >= 5:
						# 已经用了5次，消耗一个玩具
						if _consume_toy_from_house(i):
							house_feed_count[i] = 0
							has_update = true
							print("✅ 小木屋消耗了一个玩具，重置计数器")
					else:
						# 给所有兔子加快乐值
						for rabbit in rabbits:
							var old_happiness = rabbit.happiness
							rabbit.happiness = min(100, rabbit.happiness + 1.5)
							print("🐰 ", rabbit.rabbit_name, " 快乐: ", old_happiness, " -> ", rabbit.happiness)
						house_feed_count[i] = count + 1
						print("✅ 小木屋玩具效果，第", house_feed_count[i], "次")

	if has_update:
		storage_updated.emit()

# 从喂食器消耗一个食物
func _consume_food_from_feeder(feeder_index: int) -> bool:
	if feeder_index < 0 or feeder_index >= placed_items.size():
		return false

	var feeder = placed_items[feeder_index]
	for stored in feeder.get("food_storage", []):
		if stored.count > 0:
			stored.count -= 1
			print(feeder.id, " 消耗了一个食物:", stored.id)
			if stored.count <= 0:
				feeder.food_storage.erase(stored)
			return true
	return false

# 从饮水器消耗一瓶水
func _consume_water_from_fountain(fountain_index: int) -> bool:
	if fountain_index < 0 or fountain_index >= placed_items.size():
		return false

	var fountain = placed_items[fountain_index]
	for stored in fountain.get("water_storage", []):
		if stored.count > 0:
			stored.count -= 1
			print("自动饮水器消耗了一瓶清水")
			if stored.count <= 0:
				fountain.water_storage.erase(stored)
			return true
	return false

# 购买物品
func purchase_item(item_id: String) -> bool:
	var item = ItemData.get_item(item_id)
	if not item:
		return false

	# 检查金币
	if GameManager.coins < item.price:
		return false

	# 扣除金币
	GameManager.coins -= item.price
	GameManager.coins_changed.emit(GameManager.coins)

	# 设施类直接放置，其他放入背包
	if item.get("placeable", false):
		place_item(item_id)
	else:
		add_item(item_id, 1)

	item_purchased.emit(item_id)
	return true

# 添加物品到背包
func add_item(item_id: String, count: int = 1) -> void:
	if item_id in inventory:
		inventory[item_id] += count
	else:
		inventory[item_id] = count
	item_added.emit(item_id, count)

# 使用物品（消耗物品）
func use_item(item_id: String, count: int = 1) -> bool:
	if not has_item(item_id):
		return false
	if inventory[item_id] < count:
		return false

	inventory[item_id] -= count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)

	item_used.emit(item_id)
	return true

# 放置物品到笼子
func place_item(item_id: String) -> void:
	var item = ItemData.get_item(item_id)
	if not item or not item.get("placeable", false):
		return

	# 随机位置放置（避免重叠）
	var placed_item = {
		"id": item_id,
		"x": randf_range(50, 710),
		"y": randf_range(250, 380),
		"type": item.type
	}

	# 如果是喂食器或饮水器，添加食物存储
	if item_id == "auto_feeder" or item_id == "golden_bowl":
		placed_item["food_storage"] = []  # 存放的食物 [{id, count}]
		placed_item["max_storage"] = 10  # 最大容量
	if item_id == "water_fountain":
		placed_item["water_storage"] = []  # 存放的清水
		placed_item["max_storage"] = 10
	if item_id == "wooden_house":
		placed_item["toy_storage"] = []  # 存放的玩具 [{id, count}]
		placed_item["max_storage"] = 20  # 最大容量
		# 通知任务系统放置了小木屋（用于新手任务）
		TaskManager.increment_place_house()

	placed_items.append(placed_item)

	# 如果是青草垫，添加到活跃列表并开始计时
	if item_id == "grass_mat":
		var item_index = placed_items.size() - 1
		grass_mat_active.append({"index": item_index, "remaining_time": grass_mat_duration})
		print("✅ 青草垫已放置，开始倒计时 60 秒")

	item_placed.emit(item_id, Vector2(placed_item.x, placed_item.y))

	# 重新计算效果
	calculate_bonuses()

# 给喂食器添加食物
func add_food_to_feeder(feeder_index: int, food_id: String, count: int = 1) -> bool:
	print("DEBUG: add_food_to_feeder 被调用！index=", feeder_index, ", food_id=", food_id)

	if feeder_index < 0 or feeder_index >= placed_items.size():
		print("❌ index 超出范围")
		return false

	var feeder = placed_items[feeder_index]
	print("DEBUG: feeder=", feeder)

	var item = ItemData.get_item(food_id)
	if not item or not item.type == ItemData.ItemType.FOOD:
		print("❌ 物品类型错误")
		return false

	# 检查当前容量
	var current_count = 0
	for stored in feeder.get("food_storage", []):
		current_count += stored.count

	print("DEBUG: 当前容量=", current_count)

	if current_count >= feeder.max_storage:
		print("❌ 已满")
		return false  # 已满

	# 检查背包是否有足够的物品
	if not has_item(food_id) or get_item_count(food_id) < count:
		print("❌ 背包物品不足")
		return false

	# 消耗背包物品
	use_item(food_id, count)

	# 添加到喂食器存储
	var found = false
	for stored in feeder.food_storage:
		if stored.id == food_id:
			stored.count += count
			found = true
			break

	if not found:
		feeder.food_storage.append({"id": food_id, "count": count})

	print("✅ 已将 ", item.name, " x", count, " 放入喂食器")
	print("DEBUG: 喂食器现在的 food_storage =", feeder.food_storage)
	print("DEBUG: 发送 storage_updated 信号！")
	storage_updated.emit()  # 刷新显示
	return true

# 给饮水器添加清水
func add_water_to_fountain(fountain_index: int, count: int = 1) -> bool:
	if fountain_index < 0 or fountain_index >= placed_items.size():
		return false

	var fountain = placed_items[fountain_index]
	if fountain.id != "water_fountain":
		return false

	# 检查当前容量
	var current_count = 0
	for stored in fountain.get("water_storage", []):
		current_count += stored.count

	if current_count >= fountain.max_storage:
		return false  # 已满

	# 检查背包是否有足够的清水
	if not has_item("water") or get_item_count("water") < count:
		return false

	# 消耗背包物品
	use_item("water", count)

	# 添加到饮水器存储
	var found = false
	for stored in fountain.water_storage:
		if stored.id == "water":
			stored.count += count
			found = true
			break

	if not found:
		fountain.water_storage.append({"id": "water", "count": count})

	print("已将清水 x", count, " 放入饮水器")
	storage_updated.emit()  # 刷新显示
	return true

# 给小木屋添加草萝卜
func add_toy_to_house(house_index: int, toy_id: String, count: int = 1) -> bool:
	print("DEBUG: add_toy_to_house 被调用！index=", house_index, ", toy_id=", toy_id)

	if house_index < 0 or house_index >= placed_items.size():
		print("❌ index 超出范围")
		return false

	var house = placed_items[house_index]
	print("DEBUG: house=", house)

	if house.id != "wooden_house":
		print("❌ 不是小木屋")
		return false

	var item = ItemData.get_item(toy_id)
	if not item or not item.get("storable", false):
		print("❌ 物品类型错误或不可存储")
		return false

	# 检查当前容量
	var current_count = 0
	for stored in house.get("toy_storage", []):
		current_count += stored.count

	print("DEBUG: 当前容量=", current_count)

	if current_count >= house.max_storage:
		print("❌ 已满")
		return false

	# 检查背包是否有足够的物品
	if not has_item(toy_id) or get_item_count(toy_id) < count:
		print("❌ 背包物品不足")
		return false

	# 消耗背包物品
	use_item(toy_id, count)

	# 添加到小木屋存储
	var found = false
	for stored in house.toy_storage:
		if stored.id == toy_id:
			stored.count += count
			found = true
			break

	if not found:
		house.toy_storage.append({"id": toy_id, "count": count})

	print("✅ 已将 ", item.name, " x", count, " 放入小木屋")
	print("DEBUG: 小木屋现在的 toy_storage =", house.toy_storage)
	print("DEBUG: 发送 storage_updated 信号！")
	storage_updated.emit()  # 刷新显示
	return true

# 检查饮水器是否有水
func _has_water_in_fountain(fountain_index: int) -> bool:
	return get_fountain_water_count(fountain_index) > 0

# 获取喂食器剩余食物数量
func get_feeder_food_count(feeder_index: int) -> int:
	if feeder_index < 0 or feeder_index >= placed_items.size():
		return 0

	var feeder = placed_items[feeder_index]
	var total = 0
	for stored in feeder.get("food_storage", []):
		total += stored.count
	return total

# 获取饮水器剩余清水数量
func get_fountain_water_count(fountain_index: int) -> int:
	if fountain_index < 0 or fountain_index >= placed_items.size():
		return 0

	var fountain = placed_items[fountain_index]
	var total = 0
	for stored in fountain.get("water_storage", []):
		total += stored.count
	return total

# 获取小木屋剩余玩具数量
func get_house_toy_count(house_index: int) -> int:
	if house_index < 0 or house_index >= placed_items.size():
		return 0

	var house = placed_items[house_index]
	var total = 0
	for stored in house.get("toy_storage", []):
		total += stored.count
	return total

# 从小木屋消耗一个玩具
func _consume_toy_from_house(house_index: int) -> bool:
	if house_index < 0 or house_index >= placed_items.size():
		return false

	var house = placed_items[house_index]
	for stored in house.get("toy_storage", []):
		if stored.count > 0:
			stored.count -= 1
			print(house.id, " 消耗了一个玩具:", stored.id)
			if stored.count <= 0:
				house.toy_storage.erase(stored)
			return true
	return false

# 更新青草垫倒计时和效果
func _update_grass_mat_timer(rabbits: Array) -> void:
	# 倒序遍历，安全移除
	for i in range(grass_mat_active.size() - 1, -1, -1):
		var grass_mat = grass_mat_active[i]
		grass_mat.remaining_time -= 1.0

		# 青草垫效果：每秒给所有兔子加速毛生长（效果翻倍）
		if grass_mat.remaining_time > 0:
			for rabbit in rabbits:
				rabbit.fur_length = min(100, rabbit.fur_length + 1.0)  # 每秒+1.0，60秒总共+60

			# 更新显示倒计时
			var item_index = grass_mat.index
			if item_index < placed_items.size() and get_tree().root.get_node_or_null("Main"):
				var main_node = get_tree().root.get_node("Main")
				if main_node.has_method("_update_grass_mat_countdown"):
					main_node._update_grass_mat_countdown(item_index, int(grass_mat.remaining_time))

		# 时间到，移除青草垫
		if grass_mat.remaining_time <= 0:
			print("⏱️ 青草垫时间到，已移除")
			# 从placed_items中移除（需要修正后面的索引）
			if grass_mat.index < placed_items.size():
				placed_items.remove_at(grass_mat.index)
			# 从活跃列表移除
			grass_mat_active.remove_at(i)
			# 更新其他青草垫的索引（因为移除了一个，后面的索引都-1）
			for gm in grass_mat_active:
				if gm.index > grass_mat.index:
					gm.index -= 1
			# 重新计算效果
			calculate_bonuses()
			# 刷新显示
			storage_updated.emit()

# 计算所有放置物品的总效果
func calculate_bonuses() -> void:
	total_happiness_bonus = 0.0
	total_hunger_bonus = 0.0
	total_thirst_bonus = 0.0
	total_fur_bonus = 0.0

	for placed in placed_items:
		var item = ItemData.get_item(placed.id)
		if item:
			if "happiness_bonus" in item:
				total_happiness_bonus += item.happiness_bonus
			if "hunger_bonus" in item:
				total_hunger_bonus += item.hunger_bonus
			if "thirst_bonus" in item:
				total_thirst_bonus += item.thirst_bonus
			if "fur_bonus" in item:
				total_fur_bonus += item.fur_bonus

	print("设施效果已更新 - 快乐:", total_happiness_bonus, "/min, 饱食:", total_hunger_bonus, "/min, 口渴:", total_thirst_bonus, "/min, 毛:", total_fur_bonus, "/min")

# 获取总效果文本描述
func get_total_effects_text() -> String:
	var effects = []
	if total_happiness_bonus > 0:
		effects.append("快乐+" + str(total_happiness_bonus) + "/分钟")
	if total_hunger_bonus > 0:
		effects.append("饱食+" + str(total_hunger_bonus) + "/分钟")
	if total_thirst_bonus > 0:
		effects.append("口渴+" + str(total_thirst_bonus) + "/分钟")
	if total_fur_bonus > 0:
		effects.append("毛+" + str(total_fur_bonus) + "/分钟")
	return ", ".join(effects)

# 检查是否有物品
func has_item(item_id: String) -> bool:
	return item_id in inventory and inventory[item_id] > 0

# 获取物品数量
func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

# 获取已放置物品
func get_placed_items() -> Array:
	return placed_items

# 保存数据
func get_save_data() -> Dictionary:
	return {
		"inventory": inventory,
		"placed_items": placed_items
	}

# 加载数据
func load_data(data: Dictionary) -> void:
	inventory = data.get("inventory", {})
	placed_items = data.get("placed_items", [])
	calculate_bonuses()
