extends Node

# ==========================================
# 任务系统管理器 - 全局单例
# ==========================================

# 任务类型枚举
enum TaskType {
	NEWBIE,        # 新手引导任务（一次性，按顺序解锁）
	DAILY,         # 每日任务（每天重置）
	ACHIEVEMENT,   # 成就任务（一次性里程碑）
	PROGRESS       # 进度任务（累计完成）
}

# 新手任务解锁顺序（任务链）
const NEWBIE_TASK_ORDER = [
	"newbie_select_rabbit",      # 1. 选中兔子
	"newbie_feed_once",          # 2. 喂食1次
	"newbie_drink_once",         # 3. 喂水1次
	"newbie_pet_once",           # 4. 抚摸1次
	"newbie_shave_once",         # 5. 剃毛1次
	"newbie_buy_rabbit",         # 6. 购买第2只兔子
	"newbie_place_house",        # 7. 放置小木屋
	"newbie_earn_5000"           # 8. 累计获得5000金币
]

# 任务状态枚举
enum TaskStatus {
	LOCKED,        # 未解锁
	IN_PROGRESS,   # 进行中
	COMPLETED,     # 已完成（待领取）
	CLAIMED        # 已领取奖励
}

# 信号定义
signal task_progress_updated(task_id: String, current: int, target: int)
signal task_completed(task_id: String)
signal task_reward_claimed(task_id: String, reward: Dictionary)
signal daily_tasks_refreshed(tasks: Array)
signal new_task_unlocked(task_id: String)   # 新任务解锁信号
signal newbie_task_completed(task_id: String)  # 新手任务完成（用于引导）

# ==========================================
# 任务定义（静态数据）
# ==========================================
var task_definitions: Dictionary = {
	# ========== 新手引导任务 ==========
	"newbie_select_rabbit": {
		"id": "newbie_select_rabbit",
		"name": "第一步：认识新朋友",
		"description": "点击选中一只兔子，和它打个招呼吧！",
		"type": TaskType.NEWBIE,
		"category": "select_rabbit",
		"target": 1,
		"reward": {"coins": 100},
		"icon": "👋"
	},
	"newbie_feed_once": {
		"id": "newbie_feed_once",
		"name": "喂食时间",
		"description": "给小兔子喂一次胡萝卜，不要让它饿肚子哦！",
		"type": TaskType.NEWBIE,
		"category": "feed",
		"target": 1,
		"reward": {"coins": 200, "items": {"carrot": 5}},
		"icon": "🥕"
	},
	"newbie_drink_once": {
		"id": "newbie_drink_once",
		"name": "喝口水吧",
		"description": "小兔子口渴了，给它喂点水！",
		"type": TaskType.NEWBIE,
		"category": "drink",
		"target": 1,
		"reward": {"coins": 150, "items": {"water": 5}},
		"icon": "💧"
	},
	"newbie_pet_once": {
		"id": "newbie_pet_once",
		"name": "摸摸头",
		"description": "轻轻抚摸小兔子，让它感受到你的爱！",
		"type": TaskType.NEWBIE,
		"category": "pet",
		"target": 1,
		"reward": {"coins": 200},
		"icon": "❤️"
	},
	"newbie_shave_once": {
		"id": "newbie_shave_once",
		"name": "第一次剃毛",
		"description": "兔毛长长了，给它剃毛还能获得金币哦！",
		"type": TaskType.NEWBIE,
		"category": "shave",
		"target": 1,
		"reward": {"coins": 500},
		"icon": "✂️"
	},
	"newbie_buy_rabbit": {
		"id": "newbie_buy_rabbit",
		"name": "欢迎新成员",
		"description": "去商店购买第二只兔子，让兔园更热闹！",
		"type": TaskType.NEWBIE,
		"category": "breed",
		"target": 2,
		"reward": {"coins": 1000},
		"icon": "🐰"
	},
	"newbie_place_house": {
		"id": "newbie_place_house",
		"name": "第一个家",
		"description": "在商店购买小木屋并放置在兔园里！",
		"type": TaskType.NEWBIE,
		"category": "place_house",
		"target": 1,
		"reward": {"coins": 800, "items": {"grass_toy": 3}},
		"icon": "🏠"
	},
	"newbie_earn_5000": {
		"id": "newbie_earn_5000",
		"name": "小有积蓄",
		"description": "通过饲养兔子，累计获得5000金币！",
		"type": TaskType.NEWBIE,
		"category": "money_total",
		"target": 5000,
		"reward": {"coins": 1500, "items": {"carrot_cake": 2}},
		"icon": "💰"
	},

	# ========== 每日任务 ==========
	"daily_feed_5": {
		"id": "daily_feed_5",
		"name": "喂食小能手",
		"description": "今天喂食兔子5次",
		"type": TaskType.DAILY,
		"category": "feed",
		"target": 5,
		"reward": {"coins": 50},
		"icon": "🥕"
	},
	"daily_pet_10": {
		"id": "daily_pet_10",
		"name": "亲密互动",
		"description": "今天抚摸兔子10次",
		"type": TaskType.DAILY,
		"category": "pet",
		"target": 10,
		"reward": {"coins": 80},
		"icon": "❤️"
	},
	"daily_shave_3": {
		"id": "daily_shave_3",
		"name": "剃毛达人",
		"description": "今天给兔子剃毛3次",
		"type": TaskType.DAILY,
		"category": "shave",
		"target": 3,
		"reward": {"coins": 100},
		"icon": "✂️"
	},
	"daily_earn_500": {
		"id": "daily_earn_500",
		"name": "今日小赚",
		"description": "今天累计获得500金币",
		"type": TaskType.DAILY,
		"category": "money",
		"target": 500,
		"reward": {"coins": 100},
		"icon": "💰"
	},
	"daily_drink_3": {
		"id": "daily_drink_3",
		"name": "及时补水",
		"description": "今天喂水3次",
		"type": TaskType.DAILY,
		"category": "drink",
		"target": 3,
		"reward": {"coins": 30},
		"icon": "💧"
	},

	# ========== 成就任务 ==========
	"ach_first_rabbit": {
		"id": "ach_first_rabbit",
		"name": "初来乍到",
		"description": "拥有第一只兔子",
		"type": TaskType.ACHIEVEMENT,
		"category": "breed",
		"target": 1,
		"reward": {"coins": 100},
		"icon": "🐰"
	},
	"ach_coins_1000": {
		"id": "ach_coins_1000",
		"name": "小有积蓄",
		"description": "累计获得1000金币",
		"type": TaskType.ACHIEVEMENT,
		"category": "money_total",
		"target": 1000,
		"reward": {"coins": 200},
		"icon": "💰"
	},
	"ach_coins_10000": {
		"id": "ach_coins_10000",
		"name": "小富翁",
		"description": "累计获得10000金币",
		"type": TaskType.ACHIEVEMENT,
		"category": "money_total",
		"target": 10000,
		"reward": {"coins": 2000, "items": {"carrot_cake": 3}},
		"icon": "👑"
	},
	"ach_rabbits_5": {
		"id": "ach_rabbits_5",
		"name": "兔子大家庭",
		"description": "同时养5只兔子",
		"type": TaskType.ACHIEVEMENT,
		"category": "breed",
		"target": 5,
		"reward": {"coins": 500},
		"icon": "🏠"
	},
	"ach_shave_10": {
		"id": "ach_shave_10",
		"name": "熟练理发师",
		"description": "累计剃毛10次",
		"type": TaskType.ACHIEVEMENT,
		"category": "shave_total",
		"target": 10,
		"reward": {"coins": 300},
		"icon": "✂️"
	},

	# ========== 进度任务 ==========
	"prog_feed_100": {
		"id": "prog_feed_100",
		"name": "资深饲养员",
		"description": "累计喂食100次",
		"type": TaskType.PROGRESS,
		"category": "feed_total",
		"target": 100,
		"reward": {"coins": 500},
		"icon": "🥕"
	},
	"prog_pet_200": {
		"id": "prog_pet_200",
		"name": "最受欢迎铲屎官",
		"description": "累计抚摸200次",
		"type": TaskType.PROGRESS,
		"category": "pet_total",
		"target": 200,
		"reward": {"coins": 800},
		"icon": "❤️"
	},
	"prog_shave_50": {
		"id": "prog_shave_50",
		"name": "剃毛大师",
		"description": "累计剃毛50次",
		"type": TaskType.PROGRESS,
		"category": "shave_total",
		"target": 50,
		"reward": {"coins": 1000},
		"icon": "✂️"
	},
	"prog_earn_50000": {
		"id": "prog_earn_50000",
		"name": "大富翁",
		"description": "累计获得50000金币",
		"type": TaskType.PROGRESS,
		"category": "money_total",
		"target": 50000,
		"reward": {"coins": 5000},
		"icon": "💎"
	}
}

# ==========================================
# 运行时数据
# ==========================================

# 任务进度 {任务ID: {current, status, completed_at}}
var task_progress: Dictionary = {}

# 每日任务状态
var daily_state: Dictionary = {
	"last_reset_date": "",
	"selected_tasks": []
}

# 累计统计（用于进度任务）
var total_stats: Dictionary = {
	"feed": 0,
	"pet": 0,
	"shave": 0,
	"breed": 0,
	"money": 0,
	"drink": 0,
	"select_rabbit": 0,    # 选中兔子
	"place_house": 0,      # 放置小木屋
	"feed_total": 0,       # 累计喂食
	"pet_total": 0,        # 累计抚摸
	"shave_total": 0,      # 累计剃毛
	"money_total": 0       # 累计获得金币
}

# ==========================================
# 初始化
# ==========================================
func _init():
	# 立即初始化数据（Autoload 时调用）
	_init_default_progress()
	print("TaskManager 已初始化")

func _ready():
	print("TaskManager 已加载")

# 初始化默认进度
func _init_default_progress() -> void:
	for task_id in task_definitions:
		if not task_progress.has(task_id):
			var task_def = task_definitions[task_id]
			# 进度任务默认进行中
			var default_status = TaskStatus.LOCKED
			if task_def.type == TaskType.PROGRESS:
				default_status = TaskStatus.IN_PROGRESS
			# 新手任务：第一个默认解锁，其他锁定
			elif task_def.type == TaskType.NEWBIE:
				if NEWBIE_TASK_ORDER.size() > 0 and NEWBIE_TASK_ORDER[0] == task_id:
					default_status = TaskStatus.IN_PROGRESS

			task_progress[task_id] = {
				"current": 0,
				"status": default_status,
				"completed_at": ""
			}

# ==========================================
# 进度更新方法
# ==========================================

# 按分类更新进度
func update_task_progress(category: String, amount: int = 1) -> void:
	# 更新累计统计
	if total_stats.has(category):
		total_stats[category] += amount

	# 遍历所有任务，更新匹配分类的进度
	for task_id in task_progress:
		var task_def = get_task_definition(task_id)
		if task_def.size() == 0:
			continue

		# 只更新进行中的任务
		var progress = task_progress[task_id]
		if progress.status != TaskStatus.IN_PROGRESS:
			continue

		# 检查分类是否匹配
		if task_def.category == category:
			# 每日任务只在被选中为当日任务时才更新
			if task_def.type == TaskType.DAILY:
				if not task_id in daily_state.selected_tasks:
					continue

			# 更新进度
			progress.current = min(progress.current + amount, task_def.target)

			# 发送进度更新信号
			task_progress_updated.emit(task_id, progress.current, task_def.target)

			# 检查是否完成
			if progress.current >= task_def.target:
				progress.status = TaskStatus.COMPLETED
				progress.completed_at = Time.get_datetime_string_from_system()
				task_completed.emit(task_id)
				print("✅ 任务完成: ", task_def.name)

				# 如果是新手任务，发送特殊信号并解锁下一个
				if task_def.type == TaskType.NEWBIE:
					newbie_task_completed.emit(task_id)
					# 延迟一帧后解锁下一个新手任务
					call_deferred("unlock_next_newbie_task")

# 喂食次数+1
func increment_feed_count() -> void:
	update_task_progress("feed", 1)
	update_task_progress("feed_total", 1)

# 抚摸次数+1
func increment_pet_count() -> void:
	update_task_progress("pet", 1)
	update_task_progress("pet_total", 1)

# 剃毛次数+1
func increment_shave_count() -> void:
	update_task_progress("shave", 1)
	update_task_progress("shave_total", 1)

# 养兔子+1
func increment_breed_count() -> void:
	update_task_progress("breed", 1)

# 累计获得金币
func update_coins_earned(amount: int) -> void:
	update_task_progress("money", amount)
	update_task_progress("money_total", amount)

# 喂水次数+1
func increment_drink_count() -> void:
	update_task_progress("drink", 1)

# 选中兔子（新手任务用）
func increment_select_rabbit() -> void:
	update_task_progress("select_rabbit", 1)

# 放置小木屋（新手任务用）
func increment_place_house() -> void:
	update_task_progress("place_house", 1)

# ==========================================
# 任务状态管理
# ==========================================

# 获取任务定义
func get_task_definition(task_id: String) -> Dictionary:
	if task_definitions.has(task_id):
		return task_definitions[task_id]
	return {}

# 获取任务状态
func get_task_status(task_id: String) -> int:
	if not task_progress.has(task_id):
		return TaskStatus.LOCKED
	return task_progress[task_id].status

# 获取任务进度
func get_task_progress(task_id: String) -> int:
	if not task_progress.has(task_id):
		return 0
	return task_progress[task_id].current

# 检查任务是否完成
func is_task_completed(task_id: String) -> bool:
	return get_task_status(task_id) == TaskStatus.COMPLETED

# 检查任务是否已领取
func is_task_claimed(task_id: String) -> bool:
	return get_task_status(task_id) == TaskStatus.CLAIMED

# 领取奖励
func claim_reward(task_id: String) -> Dictionary:
	if not task_progress.has(task_id):
		return {"success": false, "message": "任务不存在"}

	var progress = task_progress[task_id]
	if progress.status != TaskStatus.COMPLETED:
		return {"success": false, "message": "任务未完成或已领取"}

	var task_def = get_task_definition(task_id)
	if task_def.size() == 0:
		return {"success": false, "message": "任务定义不存在"}

	# 标记为已领取
	progress.status = TaskStatus.CLAIMED

	# 发放奖励
	var reward = task_def.reward
	var coins = reward.get("coins", 0)
	var items = reward.get("items", {})

	if coins > 0:
		GameManager.add_coins(coins)

	for item_id in items:
		InventoryManager.add_item(item_id, items[item_id])

	# 发送信号
	task_reward_claimed.emit(task_id, reward)

	print("领取奖励: ", task_def.name, " 金币: ", coins, " 物品: ", items)
	return {
		"success": true,
		"coins": coins,
		"items": items,
		"task_name": task_def.name
	}

# ==========================================
# 每日任务管理
# ==========================================

# 检查是否需要重置每日任务
func check_daily_reset() -> void:
	var current_date = Time.get_date_string_from_system()

	# 如果日期变更或首次运行
	if daily_state.last_reset_date != current_date:
		_reset_daily_tasks()
		daily_state.last_reset_date = current_date
		print("每日任务已重置: ", current_date)

# 重置每日任务
func _reset_daily_tasks() -> void:
	# 重置所有每日任务进度
	for task_id in task_definitions:
		var task_def = task_definitions[task_id]
		if task_def.type == TaskType.DAILY:
			if task_progress.has(task_id):
				task_progress[task_id].current = 0
				task_progress[task_id].status = TaskStatus.LOCKED
				task_progress[task_id].completed_at = ""

	# 随机选择3-5个每日任务
	daily_state.selected_tasks = generate_daily_tasks()

	# 激活选中的每日任务
	for task_id in daily_state.selected_tasks:
		if task_progress.has(task_id):
			task_progress[task_id].status = TaskStatus.IN_PROGRESS

	# 发送刷新信号
	daily_tasks_refreshed.emit(daily_state.selected_tasks)

# 随机选择每日任务
func generate_daily_tasks() -> Array:
	var all_daily_tasks = []
	for task_id in task_definitions:
		var task_def = task_definitions[task_id]
		if task_def.type == TaskType.DAILY:
			all_daily_tasks.append(task_id)

	# 随机打乱
	all_daily_tasks.shuffle()

	# 选择3-5个任务
	var count = randi_range(3, min(5, all_daily_tasks.size()))
	return all_daily_tasks.slice(0, count)

# 获取当日任务列表
func get_daily_tasks() -> Array:
	return daily_state.selected_tasks

# 获取成就任务列表
func get_achievement_tasks() -> Array:
	var result = []
	for task_id in task_definitions:
		var task_def = task_definitions[task_id]
		if task_def.type == TaskType.ACHIEVEMENT:
			# 成就任务默认激活
			if task_progress.has(task_id) and task_progress[task_id].status == TaskStatus.LOCKED:
				task_progress[task_id].status = TaskStatus.IN_PROGRESS
			result.append(task_id)
	return result

# 获取进度任务列表
func get_progress_tasks() -> Array:
	var result = []
	for task_id in task_definitions:
		var task_def = task_definitions[task_id]
		if task_def.type == TaskType.PROGRESS:
			result.append(task_id)
	return result

# ==========================================
# 新手任务管理
# ==========================================

# 获取新手任务列表（按顺序）
func get_newbie_tasks() -> Array:
	var result = []
	for task_id in NEWBIE_TASK_ORDER:
		result.append(task_id)
	return result

# 获取当前应该进行的新手任务
func get_current_newbie_task() -> String:
	for task_id in NEWBIE_TASK_ORDER:
		var status = get_task_status(task_id)
		if status == TaskStatus.IN_PROGRESS:
			return task_id
		elif status == TaskStatus.LOCKED:
			# 解锁这个任务
			if task_progress.has(task_id):
				task_progress[task_id].status = TaskStatus.IN_PROGRESS
				new_task_unlocked.emit(task_id)
			return task_id
	return ""  # 所有新手任务已完成

# 检查并解锁下一个新手任务
func unlock_next_newbie_task() -> void:
	# 找到第一个未完成的任务并解锁
	var found_in_progress = false
	for task_id in NEWBIE_TASK_ORDER:
		var status = get_task_status(task_id)
		if status == TaskStatus.IN_PROGRESS:
			found_in_progress = true
			break
		elif status == TaskStatus.LOCKED and not found_in_progress:
			# 解锁这个任务
			if task_progress.has(task_id):
				task_progress[task_id].status = TaskStatus.IN_PROGRESS
				new_task_unlocked.emit(task_id)
				print("🔓 解锁新的新手任务: ", task_definitions[task_id].name)
			break

# 检查新手任务是否全部完成
func is_all_newbie_completed() -> bool:
	for task_id in NEWBIE_TASK_ORDER:
		var status = get_task_status(task_id)
		if status != TaskStatus.CLAIMED:
			return false
	return true

# ==========================================
# 存档接口
# ==========================================

# 获取待保存数据
func get_save_data() -> Dictionary:
	return {
		"task_progress": task_progress,
		"daily_state": daily_state,
		"total_stats": total_stats
	}

# 加载存档数据
func load_data(data: Dictionary) -> void:
	if data.has("task_progress"):
		task_progress.merge(data.task_progress, true)
	if data.has("daily_state"):
		daily_state.merge(data.daily_state, true)
	if data.has("total_stats"):
		total_stats.merge(data.total_stats, true)

	# 确保所有任务都有默认进度
	_init_default_progress()

	# 检查是否需要重置每日任务
	check_daily_reset()
