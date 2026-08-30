extends PanelContainer

# 成长任务项UI组件

# 节点引用
var task_num_label: Label
var icon_label: Label
var name_label: Label
var status_label: Label
var desc_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var reward_label: Label
var unlock_label: Label
var claim_button: Button

# 当前任务ID
var task_id: String = ""
var task_index: int = 0

# 信号
signal claim_clicked(task_id: String)

func _ready():
	# 延迟查找节点，确保场景加载完成
	call_deferred("_initialize_nodes")

# 初始化节点引用和信号连接
func _initialize_nodes():
	print("🌟 UnlockTaskItem: 初始化节点")

	# 使用路径查找
	task_num_label = $VBox/HeaderHBox/TaskNumLabel
	icon_label = $VBox/HeaderHBox/IconLabel
	name_label = $VBox/HeaderHBox/NameLabel
	status_label = $VBox/HeaderHBox/StatusLabel
	desc_label = $VBox/DescLabel
	progress_bar = $VBox/ProgressBar
	progress_label = $VBox/FooterHBox/ProgressLabel
	reward_label = $VBox/FooterHBox/RewardLabel
	unlock_label = $VBox/FooterHBox/UnlockLabel
	claim_button = $VBox/FooterHBox/ClaimButton

	print("  - TaskNumLabel: ", task_num_label != null)
	print("  - IconLabel: ", icon_label != null)
	print("  - NameLabel: ", name_label != null)
	print("  - StatusLabel: ", status_label != null)
	print("  - DescLabel: ", desc_label != null)
	print("  - ProgressBar: ", progress_bar != null)
	print("  - ProgressLabel: ", progress_label != null)
	print("  - RewardLabel: ", reward_label != null)
	print("  - UnlockLabel: ", unlock_label != null)
	print("  - ClaimButton: ", claim_button != null)

	# 连接按钮信号
	if claim_button:
		claim_button.pressed.connect(_on_claim_clicked)

# 设置任务数据
func set_task_data(index: int, t_id: String, task_def: Dictionary, progress: Dictionary) -> void:
	task_id = t_id
	task_index = index
	print("🌟 设置成长任务数据: #", index + 1, " ", t_id, " 名称: ", task_def.get("name", "未知"))

	# 确保节点已初始化
	if not icon_label:
		_initialize_nodes()

	# 获取任务状态
	var task_status = progress.get("status", 0)
	var is_locked = task_status == 0  # LOCKED = 0

	# 任务序号
	if task_num_label:
		task_num_label.text = "#" + str(index + 1)

	# 设置图标和名称
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
	var coins = reward.get("coins", 0)
	if reward_label:
		reward_label.text = "💰 " + str(coins) + "金币" if coins > 0 else ""

	# 设置解锁物品
	var unlock_item_id = reward.get("unlock_item", "")
	if unlock_label:
		if unlock_item_id != "":
			var item_data = ItemData.get_item(unlock_item_id)
			if item_data.size() > 0:
				var item_icon = item_data.get("icon", "📦")
				var item_name = item_data.get("name", "未知物品")
				unlock_label.text = "🔓 " + item_icon + item_name
			else:
				unlock_label.text = "🔓 新物品"
		else:
			unlock_label.text = ""

	# 设置状态
	_update_status(task_status)

# 更新状态显示
func _update_status(status: int) -> void:
	if not status_label or not claim_button:
		return

	match status:
		0:  # LOCKED
			status_label.text = "未解锁"
			status_label.modulate = Color(0.55, 0.55, 0.55)
			claim_button.disabled = true
			claim_button.visible = false
			modulate = Color(0.92, 0.92, 0.92)
			if task_num_label:
				task_num_label.modulate = Color(0.6, 0.6, 0.6)
			if unlock_label:
				unlock_label.modulate = Color(0.6, 0.6, 0.6)

		1:  # IN_PROGRESS
			status_label.text = "进行中"
			status_label.modulate = Color(0.35, 0.55, 0.95)
			claim_button.disabled = true
			claim_button.visible = false
			modulate = Color(1, 1, 1)
			if task_num_label:
				task_num_label.modulate = Color(0.7, 0.5, 0.95, 1)
			if unlock_label:
				unlock_label.modulate = Color(0.35, 0.55, 0.85, 1)

		2:  # COMPLETED
			status_label.text = "可领取"
			status_label.modulate = Color(0.2, 0.7, 0.3)
			claim_button.disabled = false
			claim_button.visible = true
			modulate = Color(1, 1, 0.98)
			if task_num_label:
				task_num_label.modulate = Color(0.3, 0.8, 0.4, 1)
			if unlock_label:
				unlock_label.modulate = Color(0.2, 0.8, 0.45, 1)

		3:  # CLAIMED
			status_label.text = "✓ 已完成"
			status_label.modulate = Color(0.4, 0.65, 0.4)
			claim_button.disabled = true
			claim_button.visible = false
			modulate = Color(0.98, 1, 0.97)
			if task_num_label:
				task_num_label.modulate = Color(0.4, 0.65, 0.4, 1)
			if unlock_label:
				unlock_label.modulate = Color(0.4, 0.75, 0.55, 1)

# 点击领取按钮
func _on_claim_clicked() -> void:
	AudioManager.play_click()
	claim_clicked.emit(task_id)
