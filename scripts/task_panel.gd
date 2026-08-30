extends Panel

# 任务面板UI控制器（成就 / 进度）

# 节点引用
var achievement_tab: Button
var progress_tab: Button

var achievement_section: ScrollContainer
var progress_section: ScrollContainer

var achievement_task_list: VBoxContainer
var progress_task_list: VBoxContainer

var close_button: Button

# 任务项场景预加载
var task_item_scene: PackedScene = preload("res://scenes/task_item.tscn")

# 信号
signal close_requested()

func _ready():
	call_deferred("_initialize_nodes")

# 初始化节点和连接信号
func _initialize_nodes():
	print("🎨 TaskPanel: 开始初始化节点")

	close_button = $TitleHBox/CloseButton
	achievement_tab = $TabBar/AchievementTab
	progress_tab = $TabBar/ProgressTab
	achievement_section = $AchievementSection
	progress_section = $ProgressSection
	achievement_task_list = $AchievementSection/AchievementTaskList
	progress_task_list = $ProgressSection/ProgressTaskList

	print("  按钮节点:")
	print("    - CloseButton: ", close_button != null)
	print("    - AchievementTab: ", achievement_tab != null)
	print("    - ProgressTab: ", progress_tab != null)
	print("  列表节点:")
	print("    - AchievementTaskList: ", achievement_task_list != null)
	print("    - ProgressTaskList: ", progress_task_list != null)

	# 连接关闭按钮
	if close_button:
		close_button.pressed.connect(_on_close_clicked)
	# 连接标签按钮
	if achievement_tab:
		achievement_tab.pressed.connect(_on_achievement_tab_clicked)
	if progress_tab:
		progress_tab.pressed.connect(_on_progress_tab_clicked)

	# 连接任务管理器信号
	TaskManager.task_progress_updated.connect(_on_task_progress_updated)
	TaskManager.task_completed.connect(_on_task_completed)
	TaskManager.task_reward_claimed.connect(_on_task_reward_claimed)

	# 默认显示成就
	_switch_tab("achievement")
	_refresh_all_tasks()

	print("✅ TaskPanel: 初始化完成")

# 刷新所有任务（供外部调用）
func _refresh_all_tasks() -> void:
	_refresh_achievement_tasks()
	_refresh_progress_tasks()

# 刷新成就任务
func _refresh_achievement_tasks() -> void:
	if not achievement_task_list:
		return
	for child in achievement_task_list.get_children():
		child.queue_free()

	var achievement_tasks = TaskManager.get_achievement_tasks()
	for task_id in achievement_tasks:
		var task_def = TaskManager.get_task_definition(task_id)
		var progress = TaskManager.task_progress.get(task_id, {})
		if task_def.size() > 0:
			_add_task_item(achievement_task_list, task_id, task_def, progress)

# 刷新进度任务
func _refresh_progress_tasks() -> void:
	if not progress_task_list:
		return
	for child in progress_task_list.get_children():
		child.queue_free()

	var progress_tasks = TaskManager.get_progress_tasks()
	for task_id in progress_tasks:
		var task_def = TaskManager.get_task_definition(task_id)
		var progress = TaskManager.task_progress.get(task_id, {})
		if task_def.size() > 0:
			_add_task_item(progress_task_list, task_id, task_def, progress)

# 添加任务项
func _add_task_item(container: VBoxContainer, task_id: String, task_def: Dictionary, progress: Dictionary) -> void:
	if not container:
		return
	var task_item = task_item_scene.instantiate()
	if not task_item:
		return
	task_item.set_task_data(task_id, task_def, progress)
	task_item.claim_clicked.connect(_on_claim_clicked)
	container.add_child(task_item)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer)

# 领取奖励
func _on_claim_clicked(task_id: String) -> void:
	var result = TaskManager.claim_reward(task_id)
	if result.success:
		var message = "领取成功！"
		if result.coins > 0:
			message += " 获得 " + str(result.coins) + " 金币"
		if result.has("items") and result.items.size() > 0:
			message += " 和物品奖励"
		if get_parent().has_method("_show_message"):
			get_parent()._show_message(message, "success")
		_refresh_all_tasks()
	else:
		var error_msg = result.get("message", "未知错误")
		if get_parent().has_method("_show_message"):
			get_parent()._show_message(error_msg, "warning")

# 标签切换
func _switch_tab(tab_name: String) -> void:
	if achievement_tab:
		achievement_tab.modulate = Color(0.8, 0.8, 0.8)
	if progress_tab:
		progress_tab.modulate = Color(0.8, 0.8, 0.8)

	if achievement_section:
		achievement_section.visible = false
	if progress_section:
		progress_section.visible = false

	match tab_name:
		"achievement":
			if achievement_section and achievement_tab:
				achievement_section.visible = true
				achievement_tab.modulate = Color(1, 1, 1)
		"progress":
			if progress_section and progress_tab:
				progress_section.visible = true
				progress_tab.modulate = Color(1, 1, 1)

func _on_achievement_tab_clicked() -> void:
	AudioManager.play_click()
	_switch_tab("achievement")

func _on_progress_tab_clicked() -> void:
	AudioManager.play_click()
	_switch_tab("progress")

# 关闭
func _on_close_clicked() -> void:
	AudioManager.play_click()
	close_requested.emit()

# 信号响应
func _on_task_progress_updated(task_id: String, current: int, target: int) -> void:
	pass

func _on_task_completed(task_id: String) -> void:
	_refresh_achievement_tasks()
	_refresh_progress_tasks()

func _on_task_reward_claimed(task_id: String, reward: Dictionary) -> void:
	_refresh_achievement_tasks()
	_refresh_progress_tasks()
