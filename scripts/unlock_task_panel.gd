extends Panel

# 成长任务面板UI控制器

# 节点引用
var close_button: Button
var task_list: VBoxContainer

# 任务项场景预加载
var task_item_scene: PackedScene = preload("res://scenes/unlock_task_item.tscn")

# 信号
signal close_requested()

func _ready():
	close_button = get_node("CloseButton")
	task_list = $TaskSection/TaskList

	if close_button:
		close_button.pressed.connect(_on_close_clicked)

	# 连接任务管理器信号
	UnlockTaskManager.task_progress_changed.connect(_on_task_progress_changed)
	UnlockTaskManager.task_completed.connect(_on_task_completed)
	UnlockTaskManager.task_claimed.connect(_on_task_claimed)

	# 刷新任务列表
	_refresh_task_list()

# 刷新所有任务（供外部调用）
func _refresh_all_tasks() -> void:
	_refresh_task_list()

# 刷新任务列表
func _refresh_task_list() -> void:
	if not task_list:
		return

	# 清空列表
	for child in task_list.get_children():
		child.queue_free()

	# 按顺序添加任务项
	var all_tasks = UnlockTaskManager.get_all_tasks()
	for i in range(all_tasks.size()):
		var task_id = all_tasks[i]
		var task_def = UnlockTaskManager.get_task_def(task_id)
		if task_def.is_empty():
			continue
		var progress = UnlockTaskManager.task_progress.get(task_id, {})
		_add_task_item(i, task_id, task_def, progress)

# 添加任务项到列表
func _add_task_item(index: int, task_id: String, task_def: Dictionary, progress: Dictionary) -> void:
	if not task_list:
		return

	var task_item = task_item_scene.instantiate()
	if not task_item:
		return

	task_item.set_task_data(index, task_id, task_def, progress)
	task_item.claim_clicked.connect(_on_claim_clicked)
	task_list.add_child(task_item)

	# 添加间距
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	task_list.add_child(spacer)

# 点击领取奖励
func _on_claim_clicked(task_id: String) -> void:
	var result = UnlockTaskManager.claim_reward(task_id)
	if result.get("success", false):
		var message = "🎉 领取成功！获得 " + str(result.get("coins", 0)) + " 金币"
		var unlock_item = result.get("unlock_item", "")
		if unlock_item != "":
			var item_data = ItemData.get_item(unlock_item)
			if item_data.size() > 0:
				message += "\n🔓 解锁新物品：" + item_data.get("icon", "") + item_data.get("name", "")
		if get_parent().has_method("_show_message"):
			get_parent()._show_message(message, "success")
		_refresh_task_list()
	else:
		var error_msg = result.get("message", "未知错误")
		if get_parent().has_method("_show_message"):
			get_parent()._show_message(error_msg, "warning")

# 关闭面板
func _on_close_clicked() -> void:
	AudioManager.play_click()
	close_requested.emit()

# ======== 信号响应 ========

func _on_task_progress_changed(task_id: String, current: int, target: int) -> void:
	_refresh_task_list()

func _on_task_completed(task_id: String) -> void:
	_refresh_task_list()

func _on_task_claimed(task_id: String, reward: Dictionary) -> void:
	_refresh_task_list()
