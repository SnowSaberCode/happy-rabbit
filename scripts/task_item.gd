extends PanelContainer

# 任务项UI组件

# 节点引用
var icon_label: Label
var name_label: Label
var status_label: Label
var desc_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var reward_label: Label
var claim_button: Button

# 当前任务ID
var task_id: String = ""

# 信号
signal claim_clicked(task_id: String)

func _ready():
	# 延迟查找节点，确保场景加载完成
	call_deferred("_initialize_nodes")

# 初始化节点引用和信号连接
func _initialize_nodes():
	print("📦 TaskItem: 初始化节点")

	# 使用路径查找
	icon_label = $VBox/HeaderHBox/IconLabel
	name_label = $VBox/HeaderHBox/NameLabel
	status_label = $VBox/HeaderHBox/StatusLabel
	desc_label = $VBox/DescLabel
	progress_bar = $VBox/ProgressBar
	progress_label = $VBox/FooterHBox/ProgressLabel
	reward_label = $VBox/FooterHBox/RewardLabel
	claim_button = $VBox/FooterHBox/ClaimButton

	print("  - IconLabel: ", icon_label != null)
	print("  - NameLabel: ", name_label != null)
	print("  - StatusLabel: ", status_label != null)
	print("  - DescLabel: ", desc_label != null)
	print("  - ProgressBar: ", progress_bar != null)
	print("  - ProgressLabel: ", progress_label != null)
	print("  - RewardLabel: ", reward_label != null)
	print("  - ClaimButton: ", claim_button != null)

	# 连接按钮信号
	if claim_button:
		claim_button.pressed.connect(_on_claim_clicked)

# 设置任务数据
func set_task_data(t_id: String, task_def: Dictionary, progress: Dictionary) -> void:
	task_id = t_id
	print("📋 设置任务数据: ", t_id, " 任务名称: ", task_def.get("name", "未知"))

	# 确保节点已初始化
	if not icon_label:
		_initialize_nodes()

	# 获取任务状态
	var task_status = progress.get("status", TaskManager.TaskStatus.LOCKED)
	var is_locked = task_status == TaskManager.TaskStatus.LOCKED

	# 设置图标和名称（锁定状态显示锁图标）
	if icon_label:
		if is_locked:
			icon_label.text = "🔒"
		else:
			icon_label.text = task_def.get("icon", "📋")
	if name_label:
		name_label.text = task_def.get("name", "未知任务")
	if desc_label:
		desc_label.text = task_def.get("description", "")

	# 设置进度
	var current = progress.get("current", 0)
	var target = task_def.get("target", 1)
	if progress_bar:
		progress_bar.max_value = target
		progress_bar.value = current
	if progress_label:
		progress_label.text = str(current) + "/" + str(target)

	# 设置奖励文本
	var reward = task_def.get("reward", {})
	var reward_text = ""
	var coins = reward.get("coins", 0)
	var items = reward.get("items", {})

	if coins > 0:
		reward_text += "💰 " + str(coins) + "金币"
	if items.size() > 0:
		if reward_text:
			reward_text += " "
		for item_id in items:
			var item_data = ItemData.get_item(item_id)
			if item_data.size() > 0:  # 检查是否非空字典
				reward_text += item_data.get("icon", "📦") + "x" + str(items[item_id])

	if reward_label:
		reward_label.text = reward_text if reward_text else "无奖励"

	# 设置状态
	_update_status(task_status)

# 更新状态显示
func _update_status(status: int) -> void:
	if not status_label or not claim_button:
		return

	match status:
		TaskManager.TaskStatus.LOCKED:
			status_label.text = "未解锁"
			status_label.modulate = Color(0.6, 0.6, 0.6)  # 灰色
			claim_button.disabled = true
			claim_button.visible = false
			modulate = Color(0.85, 0.85, 0.85)  # 整体灰化
			if name_label:
				name_label.modulate = Color(0.6, 0.6, 0.6)
			if desc_label:
				desc_label.modulate = Color(0.6, 0.6, 0.6)

		TaskManager.TaskStatus.IN_PROGRESS:
			status_label.text = "进行中"
			status_label.modulate = Color(0.5, 0.7, 1.0)  # 蓝色
			claim_button.disabled = true
			claim_button.visible = false
			modulate = Color(1, 1, 1)
			if name_label:
				name_label.modulate = Color(1, 1, 1)
			if desc_label:
				desc_label.modulate = Color(1, 1, 1)

		TaskManager.TaskStatus.COMPLETED:
			status_label.text = "已完成"
			status_label.modulate = Color(0.3, 0.9, 0.3)  # 绿色
			claim_button.disabled = false
			claim_button.visible = true
			modulate = Color(0.95, 1.0, 0.95)  # 浅绿色背景
			if name_label:
				name_label.modulate = Color(1, 1, 1)
			if desc_label:
				desc_label.modulate = Color(1, 1, 1)

		TaskManager.TaskStatus.CLAIMED:
			status_label.text = "✓ 已领取"
			status_label.modulate = Color(0.4, 0.7, 0.4)  # 深绿色
			claim_button.disabled = true
			claim_button.visible = false
			modulate = Color(0.9, 0.95, 0.9)  # 淡绿色背景
			if name_label:
				name_label.modulate = Color(0.8, 0.9, 0.8)
			if desc_label:
				desc_label.modulate = Color(0.7, 0.8, 0.7)

# 点击领取按钮
func _on_claim_clicked() -> void:
	AudioManager.play_click()
	claim_clicked.emit(task_id)
