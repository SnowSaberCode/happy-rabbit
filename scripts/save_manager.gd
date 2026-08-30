extends Node

# 存档基础路径
const SAVE_FILE_BASE: String = "user://game_save_"
# 最大存档数
const MAX_SAVE_SLOTS: int = 5

# 当前激活的存档槽 (0-4，-1表示未选择)
var current_save_slot: int = -1

# 缓存的存档列表信息
var save_list_cache: Array = []

# 存档数据
var loaded_data: Dictionary = {}
var last_save_time: int = 0

func _ready():
	last_save_time = Time.get_ticks_msec()
	# 默认加载第一个存档（如果存在）
	if save_exists(0):
		load_game(0)
		print("SaveManager: 默认加载存档 1")
	else:
		# 没有存档时自动创建第一个存档
		create_new_save(0)
		print("SaveManager: 自动创建新存档 1")

# 检查存档是否存在
func save_exists(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	var save_path = SAVE_FILE_BASE + str(slot + 1) + ".json"
	return FileAccess.file_exists(save_path)

# 获取存档文件路径
func get_save_path(slot: int) -> String:
	return SAVE_FILE_BASE + str(slot + 1) + ".json"

# 获取所有存档的预览信息
func get_all_save_info() -> Array:
	var save_list = []
	for i in range(MAX_SAVE_SLOTS):
		var save_path = get_save_path(i)
		var info = {
			"slot": i,
			"exists": false,
			"saved_at": "",
			"coins": 0,
			"rabbit_count": 0
		}

		if FileAccess.file_exists(save_path):
			var file = FileAccess.open(save_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()

				var json = JSON.new()
				if json.parse(json_string) == OK:
					var save_data = json.data
					info["exists"] = true
					info["saved_at"] = save_data.get("saved_at", "")
					info["coins"] = save_data.get("coins", 0)
					info["rabbit_count"] = save_data.get("rabbits", []).size()

		save_list.append(info)

	save_list_cache = save_list
	return save_list

# 创建新存档（在空存档槽中创建新游戏）
func create_new_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	# 重置为新游戏状态
	GameManager.coins = 10000
	GameManager.max_rabbits = 3

	# 清空背包和设施
	InventoryManager.inventory = {}
	InventoryManager.placed_items = []
	InventoryManager.calculate_bonuses()

	# 重置任务系统
	TaskManager.task_progress = {}
	TaskManager.daily_state = {"last_reset_date": "", "selected_tasks": []}
	TaskManager.total_stats = {"feed": 0, "pet": 0, "shave": 0, "breed": 0, "money": 0, "drink": 0}
	TaskManager.check_daily_reset()

	# 重置阶梯任务系统
	UnlockTaskManager.task_progress = {}
	UnlockTaskManager.unlocked_items = []
	UnlockTaskManager._init_default_data()

	# 设置为当前存档
	current_save_slot = slot
	loaded_data = {}

	# 保存新存档
	save_game()

	print("创建新存档: 存档 ", slot + 1)
	return true

# 保存游戏到当前存档槽
func save_game() -> void:
	if current_save_slot < 0:
		push_error("没有选择存档槽！")
		return

	# 获取Main节点中的兔子创建计数
	var main_node = get_tree().root.get_node_or_null("Main")
	var total_created = 0
	if main_node and "total_rabbits_created" in main_node:
		total_created = main_node.total_rabbits_created

	var inv_data = InventoryManager.get_save_data()
	var task_data = TaskManager.get_save_data()
	var unlock_task_data = UnlockTaskManager.get_save_data()
	var save_data = {
		"version": 1,
		"slot": current_save_slot,
		"coins": GameManager.coins,
		"max_rabbits": GameManager.max_rabbits,
		"total_rabbits_created": total_created,  # 保存兔子创建计数
		"rabbits": GameManager.get_all_rabbits_data(),
		"inventory": inv_data.get("inventory", {}),
		"placed_items": inv_data.get("placed_items", []),
		"tasks": task_data,
		"unlock_tasks": unlock_task_data,
		"saved_at": Time.get_datetime_string_from_system()
	}

	var save_path = get_save_path(current_save_slot)
	var json_string = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	if file:
		file.store_string(json_string)
		file.close()
		last_save_time = Time.get_ticks_msec()
		print("游戏已保存到存档 ", current_save_slot + 1, ": ", save_data["saved_at"])
	else:
		push_error("无法创建存档文件！")

# 加载指定存档槽的游戏
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	var save_path = get_save_path(slot)
	if not FileAccess.file_exists(save_path):
		print("存档 ", slot + 1, " 不存在")
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("无法读取存档文件！")
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("存档文件解析错误！")
		return false

	var save_data = json.data
	var _version = save_data.get("version", 1)

	# 保存加载的数据供其他管理器使用
	loaded_data = save_data
	current_save_slot = slot

	# 应用到GameManager
	GameManager.coins = save_data.get("coins", 10000)
	GameManager.max_rabbits = save_data.get("max_rabbits", 3)

	# 加载任务数据
	if save_data.has("tasks"):
		TaskManager.load_data(save_data.tasks)

	# 加载阶梯任务数据
	if save_data.has("unlock_tasks"):
		UnlockTaskManager.load_data(save_data.unlock_tasks)

	print("存档 ", slot + 1, " 已加载: 金币=", GameManager.coins, ", 兔子数量=", save_data.get("rabbits", []).size())
	return true

# 删除指定存档
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	var save_path = get_save_path(slot)
	if FileAccess.file_exists(save_path):
		var error = DirAccess.remove_absolute(save_path)
		if error == OK:
			print("存档 ", slot + 1, " 已删除")
			# 如果删除的是当前存档，重置
			if current_save_slot == slot:
				current_save_slot = -1
				loaded_data = {}
			return true
		else:
			push_error("删除存档失败，错误码: " + str(error))
			return false
	return false

# 获取已加载的兔子数据
func get_saved_rabbits() -> Array:
	return loaded_data.get("rabbits", [])

# 获取已保存的兔子创建总数
func get_saved_total_rabbits_created() -> int:
	return loaded_data.get("total_rabbits_created", 0)

# 检查是否有存档数据
func has_saved_rabbits() -> bool:
	return get_saved_rabbits().size() > 0

# 获取当前存档号（显示用，1-5）
func get_current_save_number() -> int:
	return current_save_slot + 1 if current_save_slot >= 0 else 0

# 检查是否有当前存档
func has_current_save() -> bool:
	return current_save_slot >= 0

# 切换到下一个存档
func switch_to_next_save() -> int:
	var next_slot = (current_save_slot + 1) % MAX_SAVE_SLOTS
	if save_exists(next_slot):
		load_game(next_slot)
	else:
		create_new_save(next_slot)
	return get_current_save_number()
