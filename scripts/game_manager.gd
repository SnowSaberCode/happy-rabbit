extends Node

# 游戏状态
var coins: int = 10000
var max_rabbits: int = 3
var selected_rabbit: Node2D = null

# 围栏边界
var fence_boundary: Rect2 = Rect2(100, 100, 760, 400)

# 点击兔子标志位，防止立即取消选中
var just_clicked_rabbit: bool = false

# 信号
signal coins_changed(new_amount: int)
signal rabbit_selected(rabbit: Node2D)
signal rabbit_deselected()

func _ready():
	pass

func _process(_delta: float):
	# 已禁用自动存档功能
	# if SaveManager and Time.get_ticks_msec() - SaveManager.last_save_time > 60000:
	# 	SaveManager.save_game()
	pass

# 添加金币
func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	# 通知任务系统获得金币
	TaskManager.update_coins_earned(amount)
	UnlockTaskManager.update_coins_earned(amount)

# 扣除金币
func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

# 生成新兔子
func spawn_rabbit(breed: String, position: Vector2) -> void:
	# 检查是否达到上限
	if get_tree().root.get_node_or_null("Main/FenceArea"):
		var rabbit_count = get_tree().root.get_node("Main/FenceArea").get_child_count()
		if rabbit_count >= max_rabbits:
			print("已达到兔子数量上限！")
			return

	var rabbit_scene = preload("res://scenes/rabbit.tscn")
	var rabbit = rabbit_scene.instantiate()
	rabbit.breed = breed
	# 将位置限制在围栏范围内（相对于FenceArea的本地坐标）
	rabbit.position = Vector2(
		clamp(position.x, 50, 710),
		clamp(position.y, 50, 350)
	)

	# 添加到围栏区域
	if get_tree().root.get_node_or_null("Main/FenceArea"):
		get_tree().root.get_node("Main/FenceArea").add_child(rabbit)
		print("生成兔子: ", breed)
		# 通知任务系统兔子数量+1
		TaskManager.increment_breed_count()
	else:
		print("警告: FenceArea节点未找到")

# 从存档数据生成兔子
func spawn_rabbit_from_data(data: Dictionary) -> Node2D:
	var rabbit_scene = preload("res://scenes/rabbit.tscn")
	var rabbit = rabbit_scene.instantiate()

	# 使用兔子的方法恢复完整数据
	rabbit.load_from_data(data)

	if get_tree().root.get_node_or_null("Main/FenceArea"):
		get_tree().root.get_node("Main/FenceArea").add_child(rabbit)
		print("从存档恢复兔子: ", rabbit.rabbit_name, " (", rabbit.breed, ") 颜色: ", rabbit.fur_color)
		# 通知任务系统兔子数量+1
		TaskManager.increment_breed_count()

	return rabbit

# 获取所有兔子实例
func get_all_rabbits() -> Array:
	var rabbits = []
	if get_tree().root.get_node_or_null("Main/FenceArea"):
		var fence = get_tree().root.get_node("Main/FenceArea")
		for child in fence.get_children():
			if child is CharacterBody2D:  # 只返回CharacterBody2D类型的兔子
				rabbits.append(child)
	return rabbits

# 获取指定索引的兔子
func get_rabbit_at(index: int) -> Node2D:
	var rabbits = get_all_rabbits()
	if index >= 0 and index < rabbits.size():
		return rabbits[index]
	return null

# 获取兔子数量
func get_rabbit_count() -> int:
	return get_all_rabbits().size()

# 选中兔子
func select_rabbit(rabbit: Node2D) -> void:
	just_clicked_rabbit = true

	# 如果点击的是已选中的兔子，重新触发选中
	if selected_rabbit == rabbit:
		rabbit_selected.emit(rabbit)
		return

	if selected_rabbit and selected_rabbit != rabbit:
		selected_rabbit.deselect()

	selected_rabbit = rabbit
	print("GameManager: 选中兔子，发出信号")
	rabbit_selected.emit(rabbit)

	# 通知任务系统选中了兔子（用于新手任务）
	TaskManager.increment_select_rabbit()

# 取消选中
func deselect_rabbit() -> void:
	if selected_rabbit:
		selected_rabbit.deselect()
	selected_rabbit = null
	rabbit_deselected.emit()

# 获取所有兔子数据（用于存档）
func get_all_rabbits_data() -> Array:
	var rabbit_data = []
	var rabbits = get_all_rabbits()
	for rabbit in rabbits:
		if rabbit.has_method("get_save_data"):
			rabbit_data.append(rabbit.get_save_data())
	print("保存兔子数据: ", rabbit_data.size(), " 只")
	return rabbit_data
