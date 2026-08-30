extends Node

# ==========================================
# 阶梯任务系统管理器 - 全局单例
# 任务按顺序解锁，每完成一个任务解锁新物品
# ==========================================

# 任务状态枚举
enum TaskStatus {
	LOCKED,       # 未解锁
	IN_PROGRESS,  # 进行中
	COMPLETED,    # 已完成（待领取）
	CLAIMED       # 已领取奖励
}

# 信号定义
signal task_progress_changed(task_id: String, current: int, target: int)
signal task_completed(task_id: String)       # 任务达成可领取
signal task_claimed(task_id: String, reward: Dictionary)  # 奖励已领取
signal item_unlocked(item_id: String)        # 新物品解锁
signal new_task_unlocked(task_id: String)    # 新任务解锁

# ==========================================
# 阶梯任务定义（按顺序排列）
# ==========================================
const TASK_ORDER = [
	"unlock_feed_1",         # 1. 第一次喂食 → 解锁新鲜蔬菜
	"unlock_pet_5",          # 2. 抚摸5次 → 解锁苹果片
	"unlock_drink_3",        # 3. 喂水3次 → 解锁维生素片
	"unlock_shave_1",        # 4. 第一次剃毛 → 解锁高级兔粮
	"unlock_clean_poop_5",   # 5. 打扫5次便便 → 解锁草萝卜
	"unlock_coins_500",      # 6. 累计500金币 → 解锁小木屋
	"unlock_breed_2",        # 7. 拥有2只兔子 → 解锁草药膏
	"unlock_feed_15",        # 8. 累计喂食15次 → 解锁自动饮水器
	"unlock_place_house",    # 9. 放置1个设施 → 解锁青草垫
	"unlock_shave_5",        # 10. 累计剃毛5次 → 解锁胡萝卜蛋糕
	"unlock_breed_5",        # 11. 同时拥有5只兔子 → 解锁自动喂食器
	"unlock_coins_5000",     # 12. 累计5000金币 → 解锁自动马桶
]

# 初始解锁的物品（游戏一开始就可用）
const INITIAL_UNLOCKED_ITEMS = ["carrot", "water"]

# 任务详细定义
var task_definitions: Dictionary = {
	# ========== 第一阶段：基础操作教学 ==========
	"unlock_feed_1": {
		"id": "unlock_feed_1",
		"name": "喂兔兔吃胡萝卜",
		"description": "选中一只兔子，点「喂食」喂它胡萝卜～",
		"category": "feed",
		"target": 1,
		"reward": {
			"coins": 30,
			"unlock_item": "vegetable"
		},
		"icon": "🥕",
		"phase": 1
	},
	"unlock_pet_5": {
		"id": "unlock_pet_5",
		"name": "摸摸小脑袋",
		"description": "选中兔子后点「抚摸」，摸5次让它开心！",
		"category": "pet",
		"target": 5,
		"reward": {
			"coins": 50,
			"unlock_item": "apple"
		},
		"icon": "🤚",
		"phase": 1
	},
	"unlock_drink_3": {
		"id": "unlock_drink_3",
		"name": "喝水啦",
		"description": "给兔子喂3次水，别让它口渴哦～",
		"category": "drink",
		"target": 3,
		"reward": {
			"coins": 30,
			"unlock_item": "vitamin"
		},
		"icon": "💧",
		"phase": 1
	},
	"unlock_shave_1": {
		"id": "unlock_shave_1",
		"name": "剪毛毛",
		"description": "兔毛长长的啦，点「剃毛」剪掉还能赚金币！",
		"category": "shave",
		"target": 1,
		"reward": {
			"coins": 80,
			"unlock_item": "rabbit_food"
		},
		"icon": "✂️",
		"phase": 1
	},
	"unlock_clean_poop_5": {
		"id": "unlock_clean_poop_5",
		"name": "勤劳铲屎官",
		"description": "点击围栏里的便便，打扫5次吧～",
		"category": "clean_poop",
		"target": 5,
		"reward": {
			"coins": 50,
			"unlock_item": "grass_carrot"
		},
		"icon": "💩",
		"phase": 1
	},

	# ========== 第二阶段：基础建设 ==========
	"unlock_coins_500": {
		"id": "unlock_coins_500",
		"name": "小有积蓄",
		"description": "通过饲养兔子，累计获得500金币！",
		"category": "coins_earned",
		"target": 500,
		"reward": {
			"coins": 100,
			"unlock_item": "wooden_house"
		},
		"icon": "💰",
		"phase": 2
	},
	"unlock_breed_2": {
		"id": "unlock_breed_2",
		"name": "兔子伙伴",
		"description": "去商店买一只新兔子，让它们有个伴～",
		"category": "breed",
		"target": 2,
		"reward": {
			"coins": 150,
			"unlock_item": "herb_medicine"
		},
		"icon": "🐰",
		"phase": 2
	},
	"unlock_feed_15": {
		"id": "unlock_feed_15",
		"name": "熟练饲养员",
		"description": "累计喂食兔子15次，你已经很熟练啦！",
		"category": "feed",
		"target": 15,
		"reward": {
			"coins": 200,
			"unlock_item": "water_fountain"
		},
		"icon": "🥕",
		"phase": 2
	},
	"unlock_place_house": {
		"id": "unlock_place_house",
		"name": "安家落户",
		"description": "购买并放置一个设施，布置你的兔园吧！",
		"category": "place_furniture",
		"target": 1,
		"reward": {
			"coins": 250,
			"unlock_item": "grass_mat"
		},
		"icon": "🏠",
		"phase": 2
	},

	# ========== 第三阶段：进阶养成 ==========
	"unlock_shave_5": {
		"id": "unlock_shave_5",
		"name": "毛茸收藏家",
		"description": "累计给兔子剃毛5次，收集更多兔毛！",
		"category": "shave",
		"target": 5,
		"reward": {
			"coins": 300,
			"unlock_item": "carrot_cake"
		},
		"icon": "✂️",
		"phase": 3
	},
	"unlock_breed_5": {
		"id": "unlock_breed_5",
		"name": "兔子大家庭",
		"description": "同时养5只兔子，兔园里热闹非凡！",
		"category": "breed",
		"target": 5,
		"reward": {
			"coins": 600,
			"unlock_item": "auto_feeder"
		},
		"icon": "🏡",
		"phase": 3
	},

	# ========== 第四阶段：终极挑战 ==========
	"unlock_coins_5000": {
		"id": "unlock_coins_5000",
		"name": "兔园大亨",
		"description": "累计获得1000金币，你已经是兔园大亨啦！",
		"category": "coins_earned",
		"target": 1000,
		"reward": {
			"coins": 1000,
			"unlock_item": "auto_toilet"
		},
		"icon": "👑",
		"phase": 4
	},
}

# ==========================================
# 运行时数据
# ==========================================

# 任务进度 {任务ID: {current, status}}
var task_progress: Dictionary = {}

# 已解锁的物品ID集合
var unlocked_items: Array = []

# ==========================================
# 初始化
# ==========================================

func _init():
	_init_default_data()
	print("[UnlockTaskManager] _init() 完成，初始解锁物品: ", unlocked_items)

func _ready():
	print("[UnlockTaskManager] _ready() 被调用")
	# 调试：打印所有任务状态
	for task_id in TASK_ORDER:
		var p = task_progress.get(task_id, {})
		print("[UnlockTaskManager] 任务状态: ", task_id, " status=", p.get("status", "?"), " current=", p.get("current", "?"))

# 初始化默认数据
func _init_default_data() -> void:
	# 初始解锁物品
	if unlocked_items.is_empty():
		unlocked_items = INITIAL_UNLOCKED_ITEMS.duplicate()

	# 初始化任务进度
	for task_id in TASK_ORDER:
		if not task_progress.has(task_id):
			task_progress[task_id] = {
				"current": 0,
				"status": TaskStatus.LOCKED
			}

	# 第一个任务默认解锁
	if TASK_ORDER.size() > 0:
		var first_task = TASK_ORDER[0]
		if task_progress[first_task].status == TaskStatus.LOCKED:
			task_progress[first_task].status = TaskStatus.IN_PROGRESS

# ==========================================
# 进度更新方法
# ==========================================

# 按分类更新进度
func update_progress(category: String, amount: int = 1) -> void:
	print("[UnlockTaskManager] 更新进度: category=", category, " amount=", amount)
	for task_id in task_progress:
		var progress = task_progress[task_id]
		# 只更新进行中的任务
		if progress.status != TaskStatus.IN_PROGRESS:
			continue

		var task_def = get_task_def(task_id)
		if task_def.is_empty():
			continue

		# 检查分类是否匹配
		if task_def.category != category:
			continue

		print("[UnlockTaskManager] 匹配到任务: ", task_id, " 当前进度:", progress.current, " 目标:", task_def.target)

		# 更新进度
		progress.current = min(progress.current + amount, task_def.target)

		# 发送进度更新信号
		task_progress_changed.emit(task_id, progress.current, task_def.target)

		# 检查是否完成
		if progress.current >= task_def.target:
			progress.status = TaskStatus.COMPLETED
			task_completed.emit(task_id)
			print("[UnlockTaskManager] ✅ 任务完成: ", task_def.name, " (", task_id, ")")

# 喂食次数+1
func increment_feed_count() -> void:
	print("[UnlockTaskManager] increment_feed_count() 被调用")
	update_progress("feed", 1)

# 抚摸次数+1
func increment_pet_count() -> void:
	update_progress("pet", 1)

# 剃毛次数+1
func increment_shave_count() -> void:
	update_progress("shave", 1)

# 喂水次数+1
func increment_drink_count() -> void:
	update_progress("drink", 1)

# 更新当前兔子数量（用于 breed 类型任务，直接设置当前数量而非累加）
func update_rabbit_count(count: int) -> void:
	for task_id in task_progress:
		var progress = task_progress[task_id]
		if progress.status != TaskStatus.IN_PROGRESS:
			continue
		var task_def = get_task_def(task_id)
		if task_def.get("category", "") != "breed":
			continue
		progress.current = min(count, task_def.target)
		task_progress_changed.emit(task_id, progress.current, task_def.target)
		if progress.current >= task_def.target:
			progress.status = TaskStatus.COMPLETED
			task_completed.emit(task_id)
			print("[UnlockTaskManager] ✅ 任务完成: ", task_def.name, " (", task_id, ")")

# 累计获得金币
func update_coins_earned(amount: int) -> void:
	update_progress("coins_earned", amount)

# 放置设施
func increment_place_furniture() -> void:
	update_progress("place_furniture", 1)

# ==========================================
# 任务查询
# ==========================================

# 获取任务定义
func get_task_def(task_id: String) -> Dictionary:
	if task_definitions.has(task_id):
		return task_definitions[task_id]
	return {}

# 获取任务状态
func get_task_status(task_id: String) -> int:
	if not task_progress.has(task_id):
		return TaskStatus.LOCKED
	return task_progress[task_id].status

# 获取任务进度
func get_task_current(task_id: String) -> int:
	if not task_progress.has(task_id):
		return 0
	return task_progress[task_id].current

# 获取当前进行中的任务（第一个IN_PROGRESS的任务）
func get_current_task() -> String:
	for task_id in TASK_ORDER:
		if get_task_status(task_id) == TaskStatus.IN_PROGRESS:
			return task_id
	return ""

# 获取按顺序排列的所有任务ID
func get_all_tasks() -> Array:
	return TASK_ORDER.duplicate()

# 检查是否全部完成
func is_all_completed() -> bool:
	for task_id in TASK_ORDER:
		if get_task_status(task_id) != TaskStatus.CLAIMED:
			return false
	return true

# ==========================================
# 物品解锁查询
# ==========================================

# 检查物品是否已解锁
func is_item_unlocked(item_id: String) -> bool:
	return item_id in unlocked_items

# 获取所有已解锁物品
func get_unlocked_items() -> Array:
	return unlocked_items.duplicate()

# ==========================================
# 领取奖励
# ==========================================

func claim_reward(task_id: String) -> Dictionary:
	if not task_progress.has(task_id):
		return {"success": false, "message": "任务不存在"}

	var progress = task_progress[task_id]
	if progress.status != TaskStatus.COMPLETED:
		return {"success": false, "message": "任务未完成或已领取"}

	var task_def = get_task_def(task_id)
	if task_def.is_empty():
		return {"success": false, "message": "任务定义不存在"}

	# 标记为已领取
	progress.status = TaskStatus.CLAIMED

	# 发放奖励
	var reward = task_def.reward
	var coins = reward.get("coins", 0)
	var unlock_item = reward.get("unlock_item", "")
	var reward_items = reward.get("items", {})

	# 金币奖励
	if coins > 0:
		GameManager.add_coins(coins)

	# 物品奖励（直接放入背包）
	for item_id in reward_items:
		InventoryManager.add_item(item_id, reward_items[item_id])

	# 解锁新物品
	if unlock_item != "" and unlock_item not in unlocked_items:
		unlocked_items.append(unlock_item)
		item_unlocked.emit(unlock_item)
		print("[UnlockTaskManager] 🔓 解锁新物品: ", unlock_item, " 已解锁列表: ", unlocked_items)
	else:
		print("[UnlockTaskManager] ⚠️ 物品已解锁或为空: ", unlock_item)

	# 发送信号
	task_claimed.emit(task_id, reward)

	# 解锁下一个任务
	_unlock_next_task()

	print("[UnlockTaskManager] 🎁 领取奖励: ", task_def.name, " 金币:", coins, " 解锁:", unlock_item)
	return {
		"success": true,
		"coins": coins,
		"unlock_item": unlock_item,
		"items": reward_items,
		"task_name": task_def.name
	}

# 解锁下一个任务
func _unlock_next_task() -> void:
	var found_claimed = false
	for task_id in TASK_ORDER:
		var status = get_task_status(task_id)
		if status == TaskStatus.CLAIMED:
			found_claimed = true
			continue
		elif status == TaskStatus.LOCKED and found_claimed:
			# 解锁这个任务
			task_progress[task_id].status = TaskStatus.IN_PROGRESS
			new_task_unlocked.emit(task_id)
			print("[UnlockTaskManager] 🔓 解锁新任务: ", task_definitions[task_id].name, " (", task_id, ")")
			break

# ==========================================
# 存档接口
# ==========================================

# 获取待保存数据
func get_save_data() -> Dictionary:
	return {
		"task_progress": task_progress,
		"unlocked_items": unlocked_items
	}

# 加载存档数据
func load_data(data: Dictionary) -> void:
	if data.has("task_progress"):
		task_progress.merge(data.task_progress, true)
	if data.has("unlocked_items"):
		unlocked_items = data.unlocked_items.duplicate()

	# 确保默认数据存在
	_init_default_data()
