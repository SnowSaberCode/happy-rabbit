extends Node2D

# 节点引用
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var rabbit_count_label: Label = $TopBar/RabbitCountLabel
@onready var rabbit_info_panel: Panel = $RabbitInfoPanel
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/ContentArea/ItemGrid
@onready var inventory_empty_label: Label = $InventoryPanel/EmptyLabel
@onready var breed_label: Label = $RabbitInfoPanel/BreedLabel
@onready var hunger_bar: ProgressBar = $RabbitInfoPanel/HungerBar
@onready var thirst_bar: ProgressBar = $RabbitInfoPanel/ThirstBar
@onready var happiness_bar: ProgressBar = $RabbitInfoPanel/HappinessBar
@onready var health_bar: ProgressBar = $RabbitInfoPanel/HealthBar
@onready var fur_bar: ProgressBar = $RabbitInfoPanel/FurBar
@onready var message_label: Label = $MessageLabel
@onready var message_timer: Timer = $MessageTimer
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_coins_label: Label = $ShopPanel/ShopCoinsLabel
@onready var task_panel: Panel = $TaskPanel
@onready var unlock_task_panel: Panel = $UnlockTaskPanel

# 动画相关
var message_tween: Tween
var current_message_label: Label

# 自动马桶计时器
var auto_toilet_timer: float = 0.0
const AUTO_TOILET_INTERVAL: float = 30.0  # 每30秒自动收集一次

# 已拥有的兔子品种
var owned_breeds: Array = ["lop_gray"]

# 兔子名字和计数（第二个字和第三个字都不一样）
var total_rabbits_created: int = 0
const RABBIT_NAMES = ["萝小草", "萝大壮", "萝二白", "萝雪球", "萝花菲", "萝绵软", "萝乖宝", "萝甜朵"]

func _ready():
	print("✅ main.gd _ready() 被调用！")

	# 测试 InventoryManager 是否存在
	if InventoryManager:
		print("✅ InventoryManager 存在！placed_items 数量=", InventoryManager.placed_items.size())
	else:
		print("❌ InventoryManager 不存在！")

	# 连接GameManager信号
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.rabbit_selected.connect(_on_rabbit_selected)
	GameManager.rabbit_deselected.connect(_on_rabbit_deselected)

	# 确保背景不拦截鼠标
	$FenceArea/FenceBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$FenceArea/FenceBorder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$FenceArea/FenceBorder2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$FenceArea/FenceBorder3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$FenceArea/FenceBorder4.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 确保所有弹窗面板在最上层（覆盖兔子）
	shop_panel.z_index = 100
	rabbit_info_panel.z_index = 100
	inventory_panel.z_index = 100
	$StoragePanel.z_index = 100
	if task_panel:
		task_panel.z_index = 100
	if unlock_task_panel:
		unlock_task_panel.z_index = 100

	# 初始化金币显示
	_on_coins_changed(GameManager.coins)

	# 当存放更新时刷新显示
	InventoryManager.storage_updated.connect(_refresh_placed_items)

	# 从存档加载背包和设施数据
	if "inventory" in SaveManager.loaded_data:
		InventoryManager.load_data(SaveManager.loaded_data)
		print("Main: 已从存档加载背包和设施数据")

	# 连接商店标签页按钮信号（如果节点存在的话）
	if $ShopPanel.get_node_or_null("TabBar/TabFood"):
		$ShopPanel/TabBar/TabFood.pressed.connect(_on_tab_food_pressed)
	if $ShopPanel.get_node_or_null("TabBar/TabToy"):
		$ShopPanel/TabBar/TabToy.pressed.connect(_on_tab_toy_pressed)
	if $ShopPanel.get_node_or_null("TabBar/TabMedicine"):
		$ShopPanel/TabBar/TabMedicine.pressed.connect(_on_tab_medicine_pressed)
	if $ShopPanel.get_node_or_null("TabBar/TabFurniture"):
		$ShopPanel/TabBar/TabFurniture.pressed.connect(_on_tab_furniture_pressed)
	if $ShopPanel.get_node_or_null("TabBar/TabRabbit"):
		$ShopPanel/TabBar/TabRabbit.pressed.connect(_on_tab_rabbit_pressed)

	# 延迟检查并生成初始兔子和刷新已放置物品
	call_deferred("_check_and_spawn_rabbit")
	call_deferred("_refresh_placed_items")
	call_deferred("_update_rabbit_count_display")

	# 检查每日任务重置
	TaskManager.check_daily_reset()

	# 连接任务面板关闭信号
	if task_panel:
		task_panel.close_requested.connect(_on_task_panel_close)

	# 连接成长面板关闭信号
	if unlock_task_panel:
		unlock_task_panel.close_requested.connect(_on_growth_panel_close)

	# 物品解锁时刷新商店状态
	UnlockTaskManager.item_unlocked.connect(_on_item_unlocked)

	# 创建悬停显示名字标签
	_create_hover_label()

# 当前正在拖拽的设施物品
var dragging_item: Control = null
var is_refreshing_placed_items: bool = false  # 防止刷新期间进行拖拽

# 悬停显示名字标签
var hover_label: Label
var hovered_item: Node = null
var save_panel_visible: bool = false  # 存档面板是否显示

# 便便系统
var total_poop_count: int = 0
const MAX_TOTAL_POOP: int = 15  # 全场最多便便数
var poop_list: Array = []  # 便便数据列表，每项 {node, world_pos, is_golden}

# 简单的悬停检测（只检测兔子，不检测道具）
func _process(delta: float) -> void:
	# 自动马桶：定时收集所有便便
	_auto_toilet_update(delta)

	# 获取围栏内的鼠标位置
	var mouse_pos = get_global_mouse_position()
	var fence_pos = $FenceArea.get_global_position()
	var local_mouse_pos = mouse_pos - fence_pos

	# 检测鼠标是否在围栏范围内
	if local_mouse_pos.x < -10 or local_mouse_pos.x > 760 or local_mouse_pos.y < -10 or local_mouse_pos.y > 400:
		_hide_hover_name()
		return

	# 检测是否在某只兔子上
	for child in $FenceArea.get_children():
		if child is CharacterBody2D:
			var rabbit_rect = Rect2(child.position - Vector2(25, 25), Vector2(50, 50))
			if rabbit_rect.has_point(local_mouse_pos):
				_show_hover_name(child.rabbit_name, child.get_global_position())
				return

	# 没在任何兔子上，隐藏标签
	_hide_hover_name()

# 处理全局输入，用于取消选中、选中兔子、拖拽设施和存档快捷键
func _input(event: InputEvent) -> void:
	# 刷新期间禁止操作
	if is_refreshing_placed_items and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return

	# 按 R 键重置所有存档（调试用）
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reset_all_saves()
		return

	# ========== 存档面板快捷键 ==========
	if save_panel_visible:
		# ESC 关闭面板
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_hide_save_panel()

	if event is InputEventMouseButton:
		var mouse_pos = get_global_mouse_position()

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 检查是否点击在商店面板上
			if shop_panel.visible:
				var shop_rect = Rect2(shop_panel.position, shop_panel.size)
				if shop_rect.has_point(mouse_pos):
					return

			# 检查是否点击在背包面板上
			if inventory_panel.visible:
				var inventory_rect = Rect2(inventory_panel.position, inventory_panel.size)
				if inventory_rect.has_point(mouse_pos):
					return

			# 检查是否点击在任务面板上
			if task_panel and task_panel.visible:
				var task_rect = Rect2(task_panel.position, task_panel.size)
				if task_rect.has_point(mouse_pos):
					return

			# 检查是否点击在成长面板上
			if unlock_task_panel and unlock_task_panel.visible:
				var growth_rect = Rect2(unlock_task_panel.position, unlock_task_panel.size)
				if growth_rect.has_point(mouse_pos):
					return

			# 顶部栏在 y<60 范围
			if mouse_pos.y < 60 and mouse_pos.x > 100 and mouse_pos.x < 550:
				GameManager.deselect_rabbit()

			# 围栏内区域点击时检查
			if mouse_pos.y > 100 and mouse_pos.y < 500 and mouse_pos.x > 100 and mouse_pos.x < 860:
				var local_pos = Vector2(mouse_pos.x - 100, mouse_pos.y - 100)
				var fence = $FenceArea

				# 先检查是否点击到了便便（无需选中兔子，直接收集）
				for poop_data in poop_list:
					if local_pos.distance_to(poop_data.world_pos) <= 25.0:
						_collect_poop(poop_data.node)
						get_viewport().set_input_as_handled()
						return

				# 优先检查是否点击了设施物品
				for i in range(fence.get_child_count()):
					var child = fence.get_child(i)
					if child.name.begins_with("PlacedItem"):
						var item_rect = Rect2(child.position, Vector2(70, 55))
						if item_rect.has_point(local_pos):
							var item_index = child.name.substr(10).to_int()
							var placed_item = InventoryManager.placed_items[item_index]

							# 如果是喂食器/饮水器/小木屋，检查双击
							if placed_item.id in ["auto_feeder", "water_fountain", "golden_bowl", "wooden_house"]:
								if event.double_click:
									# 双击打开存放界面
									_show_storage_panel(placed_item.id, item_index)
								else:
									# 单击开始拖拽
									dragging_item = child
									dragging_item.modulate = Color(1.3, 1.3, 1.3)
									dragging_item.set_meta("drag_offset", local_pos - child.position)
							else:
								# 其他设施直接拖拽
								dragging_item = child
								dragging_item.modulate = Color(1.3, 1.3, 1.3)
								dragging_item.set_meta("drag_offset", local_pos - child.position)
								print("DEBUG: 开始拖拽，index = ", item_index, ", 初始位置 = ", child.position)

							get_viewport().set_input_as_handled()
							return

				# 检查是否点击到了某只兔子
				var found_rabbit = null
				for child in fence.get_children():
					if child is CharacterBody2D:
						var rabbit_rect = Rect2(child.position - Vector2(25, 25), Vector2(50, 50))
						if rabbit_rect.has_point(local_pos):
							found_rabbit = child
							break

				if found_rabbit:
					GameManager.just_clicked_rabbit = true
					GameManager.select_rabbit(found_rabbit)
					found_rabbit.select()
				else:
					# 点击了围栏空白区域，取消选中
					# 但如果是刚刚点击了兔子（just_clicked_rabbit为true），则跳过这次取消
					# 防止点击兔子的同时又立即取消选中
					if GameManager.just_clicked_rabbit:
						GameManager.just_clicked_rabbit = false
					else:
						GameManager.deselect_rabbit()

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and dragging_item:
			# 左键释放，结束拖拽并保存位置
			var item_index = dragging_item.get_meta("item_index")
			var items = InventoryManager.get_placed_items()
			if item_index < items.size():
				items[item_index].x = dragging_item.position.x
				items[item_index].y = dragging_item.position.y
				print("DEBUG: 结束拖拽，保存位置，index = ", item_index, ", 新位置 = ", dragging_item.position)
				AudioManager.play_click()

			dragging_item.modulate = Color(1, 1, 1)
			dragging_item = null

	# 鼠标移动时处理拖拽
	if event is InputEventMouseMotion and dragging_item and is_instance_valid(dragging_item):
		var mouse_pos = get_global_mouse_position()
		var local_pos = Vector2(mouse_pos.x - 100, mouse_pos.y - 100)
		var drag_offset = dragging_item.get_meta("drag_offset")
		var new_pos = local_pos - drag_offset

		# 限制在围栏范围内 (x: 10-710, y: 10-360)
		new_pos.x = clamp(new_pos.x, 10, 710)
		new_pos.y = clamp(new_pos.y, 10, 360)

		dragging_item.position = new_pos
func _check_and_spawn_rabbit():
	# 确保围栏区域存在
	if $FenceArea:
		# 统计真正的兔子数量（排除背景、边框和已放置物品标签）
		var rabbit_count = 0
		for child in $FenceArea.get_children():
			if child.name != "FenceBackground" and not child.name.begins_with("Fence") and not child.name.begins_with("PlacedItem"):
				rabbit_count += 1

		# 从存档恢复兔子总数
		if SaveManager.get_saved_total_rabbits_created() > 0:
			total_rabbits_created = SaveManager.get_saved_total_rabbits_created()
			print("从存档恢复兔子总数: ", total_rabbits_created)

		# 如果有存档兔子，从存档恢复
		if SaveManager.has_saved_rabbits():
			var saved_rabbits = SaveManager.get_saved_rabbits()
			var rabbit_scene = preload("res://scenes/rabbit.tscn")

			for rabbit_data in saved_rabbits:
				var rabbit = rabbit_scene.instantiate()
				rabbit.load_from_data(rabbit_data)
				$FenceArea.add_child(rabbit)
				_setup_rabbit(rabbit)
				print("从存档恢复兔子：", rabbit.rabbit_name, "，位置：", rabbit.position)

			# 刷新设施
			_refresh_placed_items()
		elif rabbit_count == 0:
			# 如果还没有兔子且没有存档，生成3只初始兔子
			var rabbit_scene = preload("res://scenes/rabbit.tscn")
			var start_positions = [Vector2(250, 200), Vector2(380, 200), Vector2(510, 200)]

			for i in range(3):
				var rabbit = rabbit_scene.instantiate()
				# 给兔子分配名字和颜色（使用预设的3个名字）
				var r_name = ""
				if total_rabbits_created < RABBIT_NAMES.size():
					r_name = RABBIT_NAMES[total_rabbits_created]
				else:
					r_name = rabbit.generate_random_name()
				rabbit.set_rabbit_name(r_name)
				total_rabbits_created += 1
				rabbit.position = start_positions[i]
				$FenceArea.add_child(rabbit)
				_setup_rabbit(rabbit)
				print("初始兔子已生成，名字：", rabbit.rabbit_name, "，颜色：", rabbit.fur_color)

			# 同步兔子数量到任务系统（初始生成或存档恢复后）
			var final_count = GameManager.get_rabbit_count()
			TaskManager.total_stats["breed"] = final_count
			TaskManager.update_task_progress("breed", 0)
			UnlockTaskManager.update_rabbit_count(final_count)
			print("[Main] 兔子数量同步到任务系统: ", final_count)
# 更新金币显示
func _on_coins_changed(new_amount: int) -> void:
	coins_label.text = "💰 " + str(new_amount)
	shop_coins_label.text = "当前金币: " + str(new_amount) + " 💰"

# 更新兔子数量显示
func _update_rabbit_count_display() -> void:
	# 统计当前兔子数量（只统计活着的兔子）
	var rabbit_count = 0
	for child in $FenceArea.get_children():
		if child is CharacterBody2D and not child.is_dead:
			rabbit_count += 1
	rabbit_count_label.text = "🐇 " + str(rabbit_count) + "/" + str(GameManager.max_rabbits)

# 打开商店
func _on_shop_button_pressed() -> void:
	# 停止任何正在进行的拖拽
	dragging_item = null
	AudioManager.play_click()

	# 关闭背包（互斥）
	if inventory_panel.visible:
		_on_inventory_close_pressed()

	shop_panel.visible = true
	shop_panel.position = Vector2(-760, 80)
	var tween = create_tween()
	tween.tween_property(shop_panel, "position:x", 100, 0.3)
	# 刷新商店物品锁定状态
	_refresh_shop_lock_status()

# 关闭商店
func _on_shop_close_pressed() -> void:
	AudioManager.play_click()
	var tween = create_tween()
	tween.tween_property(shop_panel, "position:x", -760, 0.3)
	tween.finished.connect(func(): shop_panel.visible = false)

# 选中兔子
func _on_rabbit_selected(rabbit: Node2D) -> void:
	print("Main: 收到选中兔子信号")
	AudioManager.play_click()
	rabbit_info_panel.visible = true

	# 面板滑入动画
	rabbit_info_panel.position = Vector2(960, 80)
	var tween = create_tween()
	tween.tween_property(rabbit_info_panel, "position:x", 680, 0.3)

	# 获取品种名称
	var breed_name = ""
	match rabbit.breed:
		"lop_gray":
			breed_name = "灰色垂耳兔"
		"lop_white":
			breed_name = "白色垂耳兔"
		"lop_brown":
			breed_name = "棕色垂耳兔"
		_:
			breed_name = rabbit.breed

	# 显示选中消息
	if rabbit.is_dead:
		_show_message(rabbit.rabbit_name + " 已经去兔星了... 😢", "normal")
	else:
		_show_message("选中了 " + rabbit.rabbit_name + "！🐇", "success")

	# 显示兔子名字和品种
	if rabbit.is_dead:
		breed_label.text = "名字：" + rabbit.rabbit_name + " (已故)\n品种：" + breed_name
	else:
		breed_label.text = "名字：" + rabbit.rabbit_name + "\n品种：" + breed_name

	# 连接属性更新信号（只在选中时实时更新）
	rabbit.attribute_changed.connect(_update_rabbit_info.bind(rabbit))

	# 立即更新一次
	_update_rabbit_info(rabbit)

# 取消选中兔子
func _on_rabbit_deselected() -> void:
	# 面板滑出动画
	var tween = create_tween()
	tween.tween_property(rabbit_info_panel, "position:x", 960, 0.2)
	tween.finished.connect(func(): rabbit_info_panel.visible = false)


# 更新兔子信息面板
func _update_rabbit_info(rabbit: Node2D) -> void:
	# 只更新当前选中兔子的信息（防止其他兔子的信号干扰）
	if GameManager.selected_rabbit != rabbit:
		return

	# 动画更新进度条
	var hunger_tween = create_tween()
	hunger_tween.tween_property(hunger_bar, "value", rabbit.hunger, 0.3)

	var thirst_tween = create_tween()
	thirst_tween.tween_property(thirst_bar, "value", rabbit.thirst, 0.3)

	var happiness_tween = create_tween()
	happiness_tween.tween_property(happiness_bar, "value", rabbit.happiness, 0.3)

	var health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", rabbit.health, 0.3)

	var fur_tween = create_tween()
	fur_tween.tween_property(fur_bar, "value", rabbit.fur_length, 0.3)

	# 根据属性值改变进度条颜色
	if rabbit.hunger < 30:
		hunger_bar.modulate = Color(0.9, 0.3, 0.3)
	elif rabbit.hunger < 60:
		hunger_bar.modulate = Color(0.9, 0.7, 0.2)
	else:
		hunger_bar.modulate = Color(0.3, 0.8, 0.3)

	if rabbit.thirst < 30:
		thirst_bar.modulate = Color(0.9, 0.3, 0.3)
	elif rabbit.thirst < 60:
		thirst_bar.modulate = Color(0.9, 0.7, 0.2)
	else:
		thirst_bar.modulate = Color(0.3, 0.7, 0.9)

	if rabbit.happiness < 30:
		happiness_bar.modulate = Color(0.9, 0.3, 0.3)
	elif rabbit.happiness < 60:
		happiness_bar.modulate = Color(0.9, 0.7, 0.2)
	else:
		happiness_bar.modulate = Color(0.9, 0.4, 0.8)

	# 根据健康值改变颜色
	if rabbit.health < 30:
		health_bar.modulate = Color(0.9, 0.2, 0.2)
	elif rabbit.health < 60:
		health_bar.modulate = Color(0.9, 0.5, 0.2)
	else:
		health_bar.modulate = Color(0.3, 0.9, 0.4)

	# 根据毛长度改变颜色
	if rabbit.fur_length >= 80:
		fur_bar.modulate = Color(0.3, 0.8, 0.3)
	elif rabbit.fur_length >= 50:
		fur_bar.modulate = Color(0.9, 0.7, 0.2)
	else:
		fur_bar.modulate = Color(0.7, 0.6, 0.5)

# 喂食按钮（使用背包中的胡萝卜）
func _on_feed_button_pressed() -> void:
	print("[Main] _on_feed_button_pressed() 被调用")
	AudioManager.play_click()
	if not GameManager.selected_rabbit:
		_show_message("请先点击选中一只兔子！", "warning")
		return

	if GameManager.selected_rabbit.is_dead:
		_show_message("兔子已经去兔星了...", "warning")
		return

	if not InventoryManager.has_item("carrot"):
		_show_message("背包中没有食物了！去商店购买吧 🛒", "warning")
		return

	_use_item("carrot")
	# 通知任务系统喂食次数+1
	TaskManager.increment_feed_count()
	# 通知阶梯任务系统
	UnlockTaskManager.increment_feed_count()

# 喂水按钮（使用背包中的清水）
func _on_drink_button_pressed() -> void:
	AudioManager.play_click()
	if not GameManager.selected_rabbit:
		_show_message("请先点击选中一只兔子！", "warning")
		return

	if GameManager.selected_rabbit.is_dead:
		_show_message("兔子已经去兔星了...", "warning")
		return

	if not InventoryManager.has_item("water"):
		_show_message("背包中没有水了！去商店购买吧 🛒", "warning")
		return

	_use_item("water")
	# 通知任务系统喂水次数+1
	TaskManager.increment_drink_count()
	# 通知阶梯任务系统
	UnlockTaskManager.increment_drink_count()

# 抚摸按钮
func _on_pet_button_pressed() -> void:
	AudioManager.play_click()
	if GameManager.selected_rabbit:
		var rabbit = GameManager.selected_rabbit  # 保存引用，防止 await 期间被置空

		if rabbit.is_dead:
			_show_message("兔子已经去兔星了...", "warning")
			return

		var coins = rabbit.pet()
		# 通知任务系统抚摸次数+1（只要不是冷却中就计数）
		if not rabbit.is_pet_cooldown:
			TaskManager.increment_pet_count()
			# 通知阶梯任务系统
			UnlockTaskManager.increment_pet_count()

		if coins > 0:
			GameManager.add_coins(coins)
			_coins_animate(coins)
		elif rabbit.is_pet_cooldown:
			AudioManager.play_cooldown()
			_show_message("冷却中... " + str(int(ceil(rabbit.pet_cooldown_timer))) + "秒后可抚摸获得金币", "warning")

		# 生成多个爱心
		for i in range(3):
			await get_tree().create_timer(i * 0.15).timeout
			_spawn_heart_effect(rabbit)
			AudioManager.play_pet()
		_show_message("兔子很开心！💕 +10 金币", "success")
	else:
		_show_message("请先点击选中一只兔子！", "warning")

# 剃毛按钮
func _on_shave_button_pressed() -> void:
	AudioManager.play_click()
	if GameManager.selected_rabbit:
		if GameManager.selected_rabbit.is_dead:
			_show_message("兔子已经去兔星了...", "warning")
			return
		var result = GameManager.selected_rabbit.shave()
		if result["success"]:
			GameManager.add_coins(result["coins"])
			_coins_animate(result["coins"])
			AudioManager.play_shave()
			AudioManager.play_coin()
			_show_message(result["message"], "success")
			# 通知任务系统剃毛次数+1
			TaskManager.increment_shave_count()
			# 通知阶梯任务系统
			UnlockTaskManager.increment_shave_count()
		else:
			_show_message(result["message"], "warning")
	else:
		_show_message("请先点击选中一只兔子！", "warning")

# 保存按钮
func _on_save_button_pressed() -> void:
	AudioManager.play_click()

	# 切换存档面板显示
	if save_panel_visible:
		_hide_save_panel()
	else:
		_show_save_panel()

# 存档面板相关变量
var save_panel: Panel
var save_panel_container: VBoxContainer
var save_panel_current_tab: String = "save"

# 确认对话框相关
var confirm_dialog: Panel
var pending_save_slot: int = -1
var pending_load_slot: int = -1
var pending_delete_slot: int = -1

# 显示存档管理面板 - 和商店风格一致
func _show_save_panel() -> void:
	print("DEBUG: 显示存档面板")
	save_panel_visible = true

	# 如果面板已存在，直接显示
	if save_panel and is_instance_valid(save_panel):
		save_panel.visible = true
		return

	# 创建新的存档面板（和商店风格一致）
	save_panel = Panel.new()
	save_panel.name = "SavePanel"
	save_panel.custom_minimum_size = Vector2(600, 450)
	save_panel.position = Vector2(180, 80)
	save_panel.z_index = 999  # 确保在最顶层
	save_panel.process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时仍可交互
	add_child(save_panel)

	# 暂停游戏
	get_tree().paused = true

	# 标题
	var title_label = Label.new()
	title_label.name = "Title"
	title_label.text = "📂 存档管理"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.custom_minimum_size = Vector2(600, 50)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_panel.add_child(title_label)

	# 关闭按钮
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(50, 40)
	close_btn.position = Vector2(540, 5)
	close_btn.pressed.connect(_hide_save_panel)
	save_panel.add_child(close_btn)

	# 当前存档显示
	var current_label = Label.new()
	current_label.name = "CurrentLabel"
	current_label.text = "当前: 存档 " + str(SaveManager.get_current_save_number())
	current_label.add_theme_font_size_override("font_size", 16)
	current_label.custom_minimum_size = Vector2(600, 30)
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_label.position = Vector2(0, 55)
	save_panel.add_child(current_label)

	# 标签栏
	var tab_bar = HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.custom_minimum_size = Vector2(560, 40)
	tab_bar.position = Vector2(20, 90)
	save_panel.add_child(tab_bar)

	# 保存标签
	var save_tab = Button.new()
	save_tab.name = "SaveTab"
	save_tab.text = "💾 保存游戏"
	save_tab.custom_minimum_size = Vector2(280, 40)
	save_tab.pressed.connect(_on_save_tab_pressed)
	tab_bar.add_child(save_tab)

	# 加载标签
	var load_tab = Button.new()
	load_tab.name = "LoadTab"
	load_tab.text = "📂 加载存档"
	load_tab.custom_minimum_size = Vector2(280, 40)
	load_tab.pressed.connect(_on_load_tab_pressed)
	tab_bar.add_child(load_tab)

	# 存档卡片容器
	save_panel_container = VBoxContainer.new()
	save_panel_container.name = "SaveContainer"
	save_panel_container.custom_minimum_size = Vector2(560, 300)
	save_panel_container.position = Vector2(20, 140)
	save_panel.add_child(save_panel_container)

	# 刷新存档列表
	_refresh_save_panel_list()

	print("DEBUG: 存档面板已创建并显示")

# 刷新存档列表
func _refresh_save_panel_list() -> void:
	if not save_panel_container or not is_instance_valid(save_panel_container):
		return

	# 清除旧内容
	for child in save_panel_container.get_children():
		child.queue_free()

	# 获取所有存档信息
	var save_list = SaveManager.get_all_save_info()

	# 创建5个存档卡片
	for i in range(save_list.size()):
		var save = save_list[i]

		# 创建存档卡片容器
		var card = Panel.new()
		card.name = "SaveCard_" + str(i)
		card.custom_minimum_size = Vector2(560, 55)
		card.modulate = Color(0.9, 0.95, 1.0, 0.8) if save.exists else Color(0.7, 0.7, 0.7, 0.5)
		save_panel_container.add_child(card)

		# 存档信息容器
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(400, 55)
		hbox.position = Vector2(10, 0)
		card.add_child(hbox)

		# 存档编号
		var slot_label = Label.new()
		slot_label.custom_minimum_size = Vector2(80, 55)
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if save.slot == SaveManager.current_save_slot:
			slot_label.text = "👉 存档 " + str(i + 1)
			slot_label.modulate = Color(0.3, 0.8, 1.0)
		else:
			slot_label.text = "存档 " + str(i + 1)
		hbox.add_child(slot_label)

		if save.exists:
			# 时间
			var time_str = save.saved_at.right(8) if save.saved_at.length() > 8 else save.saved_at
			var time_label = Label.new()
			time_label.text = "🕐 " + time_str
			time_label.custom_minimum_size = Vector2(120, 55)
			time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hbox.add_child(time_label)

			# 金币
			var coin_label = Label.new()
			coin_label.text = "💰 " + str(save.coins)
			coin_label.custom_minimum_size = Vector2(100, 55)
			coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hbox.add_child(coin_label)

			# 兔子数量
			var rabbit_label = Label.new()
			rabbit_label.text = "🐇 " + str(save.rabbit_count) + "只"
			rabbit_label.custom_minimum_size = Vector2(80, 55)
			rabbit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hbox.add_child(rabbit_label)

			# 按钮容器
			var btn_hbox = HBoxContainer.new()
			btn_hbox.custom_minimum_size = Vector2(150, 55)
			btn_hbox.position = Vector2(400, 0)
			card.add_child(btn_hbox)

			if save_panel_current_tab == "save":
				# 保存按钮
				var save_btn = Button.new()
				save_btn.text = "保存"
				save_btn.custom_minimum_size = Vector2(70, 40)
				save_btn.position = Vector2(0, 7)
				save_btn.pressed.connect(_on_save_slot.bind(i))
				btn_hbox.add_child(save_btn)

				# 删除按钮
				var delete_btn = Button.new()
				delete_btn.text = "删除"
				delete_btn.custom_minimum_size = Vector2(70, 40)
				delete_btn.position = Vector2(80, 7)
				delete_btn.modulate = Color(1, 0.5, 0.5)
				delete_btn.pressed.connect(_on_delete_slot.bind(i))
				btn_hbox.add_child(delete_btn)
			else:
				# 加载按钮
				var load_btn = Button.new()
				load_btn.text = "加载"
				load_btn.custom_minimum_size = Vector2(150, 40)
				load_btn.position = Vector2(0, 7)
				load_btn.modulate = Color(0.5, 1.0, 0.5)
				load_btn.pressed.connect(_on_load_slot.bind(i))
				btn_hbox.add_child(load_btn)
		else:
			# 空存档 - 显示新建或空
			var empty_label = Label.new()
			empty_label.text = "[空槽 - 点击保存创建新存档]"
			empty_label.custom_minimum_size = Vector2(300, 55)
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.modulate = Color(0.8, 0.8, 0.8)
			hbox.add_child(empty_label)

			if save_panel_current_tab == "save":
				# 创建按钮
				var create_btn = Button.new()
				create_btn.text = "创建"
				create_btn.custom_minimum_size = Vector2(150, 40)
				create_btn.position = Vector2(400, 7)
				create_btn.pressed.connect(_on_save_slot.bind(i))
				card.add_child(create_btn)

# 保存标签页
func _on_save_tab_pressed() -> void:
	AudioManager.play_click()
	save_panel_current_tab = "save"
	_refresh_save_panel_list()

# 加载标签页
func _on_load_tab_pressed() -> void:
	AudioManager.play_click()
	save_panel_current_tab = "load"
	_refresh_save_panel_list()

# 显示确认对话框
func _show_confirm_dialog(title: String, message: String, confirm_text: String, cancel_text: String = "取消") -> void:
	# 如果已有对话框，先关闭
	if confirm_dialog and is_instance_valid(confirm_dialog):
		confirm_dialog.queue_free()

	# 创建确认对话框
	confirm_dialog = Panel.new()
	confirm_dialog.name = "ConfirmDialog"
	confirm_dialog.custom_minimum_size = Vector2(400, 180)
	confirm_dialog.position = Vector2(280, 200)
	confirm_dialog.z_index = 1000  # 确保在最顶层
	confirm_dialog.modulate = Color(0.95, 0.95, 1.0, 1.0)
	confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时仍可交互
	add_child(confirm_dialog)

	# 标题
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.custom_minimum_size = Vector2(400, 50)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_dialog.add_child(title_label)

	# 消息
	var msg_label = Label.new()
	msg_label.name = "MsgLabel"
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.custom_minimum_size = Vector2(400, 60)
	msg_label.position = Vector2(0, 50)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.modulate = Color(0.9, 0.9, 0.9)
	confirm_dialog.add_child(msg_label)

	# 按钮容器
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "BtnHBox"
	btn_hbox.custom_minimum_size = Vector2(300, 50)
	btn_hbox.position = Vector2(50, 120)
	confirm_dialog.add_child(btn_hbox)

	# 确认按钮
	var confirm_btn = Button.new()
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.text = confirm_text
	confirm_btn.custom_minimum_size = Vector2(140, 45)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.modulate = Color(0.5, 1.0, 0.6)  # 绿色
	btn_hbox.add_child(confirm_btn)

	# 取消按钮
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelBtn"
	cancel_btn.text = cancel_text
	cancel_btn.custom_minimum_size = Vector2(140, 45)
	cancel_btn.position = Vector2(160, 0)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	btn_hbox.add_child(cancel_btn)

	# 连接信号
	confirm_btn.pressed.connect(_on_confirm_dialog_yes)
	cancel_btn.pressed.connect(_on_confirm_dialog_no)

# 确认按钮点击
func _on_confirm_dialog_yes() -> void:
	AudioManager.play_click()

	# 关闭对话框
	if confirm_dialog and is_instance_valid(confirm_dialog):
		confirm_dialog.queue_free()
		confirm_dialog = null

	# 执行待处理的操作
	if pending_save_slot >= 0:
		_execute_save(pending_save_slot)
		pending_save_slot = -1
	elif pending_load_slot >= 0:
		_execute_load(pending_load_slot)
		pending_load_slot = -1
	elif pending_delete_slot >= 0:
		_execute_delete(pending_delete_slot)
		pending_delete_slot = -1

# 取消按钮点击
func _on_confirm_dialog_no() -> void:
	AudioManager.play_click()

	# 关闭对话框
	if confirm_dialog and is_instance_valid(confirm_dialog):
		confirm_dialog.queue_free()
		confirm_dialog = null

	# 清空待处理操作
	pending_save_slot = -1
	pending_load_slot = -1
	pending_delete_slot = -1

# 保存到指定存档槽 - 弹出确认
func _on_save_slot(slot: int) -> void:
	AudioManager.play_click()
	pending_save_slot = slot

	if SaveManager.save_exists(slot):
		_show_confirm_dialog(
			"💾 确认保存",
			"确定要覆盖存档 " + str(slot + 1) + " 吗？\n原有数据将被替换！",
			"确定覆盖",
			"取消"
		)
	else:
		_show_confirm_dialog(
			"💾 创建新存档",
			"确定要在存档 " + str(slot + 1) + " 创建新存档吗？",
			"确定创建",
			"取消"
		)

# 执行实际保存
func _execute_save(slot: int) -> void:
	# 如果当前不是这个存档，先切换存档槽
	if SaveManager.current_save_slot != slot:
		SaveManager.current_save_slot = slot

	# 执行保存
	SaveManager.save_game()

	AudioManager.play_buy()
	_show_message("已保存到存档 " + str(slot + 1) + "！ 💾", "success")

	# 刷新列表
	_refresh_save_panel_list()

	# 更新当前存档显示
	if save_panel and is_instance_valid(save_panel):
		var current_label = save_panel.get_node_or_null("CurrentLabel")
		if current_label:
			current_label.text = "当前: 存档 " + str(SaveManager.get_current_save_number())

# 加载指定存档 - 弹出确认
func _on_load_slot(slot: int) -> void:
	AudioManager.play_click()

	if not SaveManager.save_exists(slot):
		_show_message("存档 " + str(slot + 1) + " 不存在！", "warning")
		return

	pending_load_slot = slot
	_show_confirm_dialog(
		"📂 确认加载",
		"确定要加载存档 " + str(slot + 1) + " 吗？\n当前游戏进度将被替换！",
		"确定加载",
		"取消"
	)

# 执行实际加载
func _execute_load(slot: int) -> void:
	# 加载存档
	SaveManager.load_game(slot)

	# 重置游戏状态 - 清除现有兔子
	for child in $FenceArea.get_children():
		if child is CharacterBody2D:
			child.queue_free()

	# 加载背包和设施
	if "inventory" in SaveManager.loaded_data:
		InventoryManager.load_data(SaveManager.loaded_data)

	# 重新生成兔子
	_check_and_spawn_rabbit()

	# 刷新设施显示
	_refresh_placed_items()

	# 更新金币显示
	_on_coins_changed(GameManager.coins)

	# 更新兔子数量显示
	_update_rabbit_count_display()

	AudioManager.play_buy()
	_show_message("已加载存档 " + str(slot + 1) + "！ 📂", "success")

	# 刷新列表
	_refresh_save_panel_list()

	# 更新当前存档显示
	if save_panel and is_instance_valid(save_panel):
		var current_label = save_panel.get_node_or_null("CurrentLabel")
		if current_label:
			current_label.text = "当前: 存档 " + str(SaveManager.get_current_save_number())

# 删除指定存档 - 弹出确认
func _on_delete_slot(slot: int) -> void:
	AudioManager.play_click()

	if not SaveManager.save_exists(slot):
		_show_message("存档 " + str(slot + 1) + " 不存在！", "warning")
		return

	pending_delete_slot = slot
	_show_confirm_dialog(
		"🗑️ 确认删除",
		"确定要删除存档 " + str(slot + 1) + " 吗？\n删除后无法恢复！",
		"确定删除",
		"取消"
	)

# 执行实际删除
func _execute_delete(slot: int) -> void:
	if SaveManager.delete_save(slot):
		_show_message("存档 " + str(slot + 1) + " 已删除！ 🗑️", "success")
		_refresh_save_panel_list()
	else:
		_show_message("删除存档 " + str(slot + 1) + " 失败！", "warning")

# 恢复消息标签的默认大小
func _restore_message_label() -> void:
	$MessageLabel.offset_left = 300.0
	$MessageLabel.offset_top = 70.0
	$MessageLabel.offset_right = 660.0
	$MessageLabel.offset_bottom = 100.0

# 隐藏存档面板
func _hide_save_panel() -> void:
	save_panel_visible = false

	# 关闭确认对话框（如果打开）
	if confirm_dialog and is_instance_valid(confirm_dialog):
		confirm_dialog.queue_free()
		confirm_dialog = null

	# 清空待处理操作
	pending_save_slot = -1
	pending_load_slot = -1
	pending_delete_slot = -1

	# 移除动态创建的面板
	if save_panel and is_instance_valid(save_panel):
		save_panel.queue_free()
		save_panel = null

	# 恢复消息标签默认大小
	if $MessageLabel and is_instance_valid($MessageLabel):
		_restore_message_label()
		$MessageLabel.visible = false

	# 恢复游戏
	get_tree().paused = false

	print("DEBUG: 存档面板已隐藏")

# 显示消息（浮层式，不会被任何面板遮挡）
func _show_message(message: String, message_type: String = "normal") -> void:
	print(message)

	# 清除之前的消息，防止重叠
	if current_message_label and is_instance_valid(current_message_label):
		current_message_label.queue_free()
		current_message_label = null
	if message_tween and message_tween.is_valid():
		message_tween.kill()

	# 创建消息浮层（每次新建，确保在最上层）
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(420, 30)
	label.position = Vector2(270, 58)
	label.z_index = 200

	# 设置文字颜色
	match message_type:
		"success":
			label.modulate = Color(0.4, 1, 0.4)
		"warning":
			label.modulate = Color(1, 0.85, 0.3)
		"error":
			label.modulate = Color(1, 0.4, 0.4)
		_:
			label.modulate = Color(1, 1, 1)

	add_child(label)
	current_message_label = label

	# 淡入 + 淡出动画
	label.modulate.a = 0
	message_tween = create_tween()
	message_tween.tween_property(label, "modulate:a", 1, 0.2)
	message_tween.tween_interval(1.8)
	message_tween.tween_property(label, "modulate:a", 0, 0.3)
	message_tween.finished.connect(func ():
		if label and is_instance_valid(label):
			label.queue_free()
		current_message_label = null
	)

# 显示爱心效果（在兔子位置）
func _spawn_heart_effect(rabbit: Node2D) -> void:
	if not rabbit or not is_instance_valid(rabbit):
		return
	var heart = Label.new()
	heart.text = "💕"
	heart.add_theme_font_size_override("font_size", 24)
	heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heart.custom_minimum_size = Vector2(40, 40)
	heart.position = rabbit.position + Vector2(-20, -50)
	heart.z_index = 100

	$FenceArea.add_child(heart)

	# 爱心飘动动画
	var tween = create_tween()
	tween.tween_property(heart, "position:y", heart.position.y - 40, 1.0)
	tween.tween_property(heart, "modulate:a", 0, 0.8)
	tween.finished.connect(func(): heart.queue_free())

# 金币增加动画
func _coins_animate(amount: int) -> void:
	var coin_label = Label.new()
	coin_label.text = "+" + str(amount) + " 💰"
	coin_label.add_theme_font_size_override("font_size", 20)
	coin_label.modulate = Color(1, 0.95, 0.3)
	coin_label.position = Vector2(70, 40)
	coin_label.z_index = 100

	add_child(coin_label)

	var tween = create_tween()
	tween.tween_property(coin_label, "position:y", 10, 0.8)
	tween.tween_property(coin_label, "modulate:a", 0, 0.6)
	tween.finished.connect(func(): coin_label.queue_free())

# ============ 商店购买功能 ============

# 购买白色垂耳兔
func _on_buy_white_rabbit_pressed() -> void:
	_buy_rabbit("lop_white", "白色垂耳兔", 200)

# 购买棕色垂耳兔
func _on_buy_brown_rabbit_pressed() -> void:
	_buy_rabbit("lop_brown", "棕色垂耳兔", 150)

# 通用购买兔子函数
func _buy_rabbit(breed_id: String, breed_name: String, cost: int) -> void:
	AudioManager.play_click()
	print("尝试购买兔子:", breed_name, ", 金币:", GameManager.coins, ", 上限:", GameManager.max_rabbits)

	if GameManager.coins < cost:
		_show_message("金币不足！需要 %d 金币（当前 %d）" % [cost, GameManager.coins], "warning")
		return

	if breed_id not in owned_breeds:
		owned_breeds.append(breed_id)

	# 检查兔子数量上限（只统计活着的）
	var rabbit_count = 0
	for child in $FenceArea.get_children():
		if child is CharacterBody2D and not child.is_dead:
			rabbit_count += 1

	print("当前兔子数量:", rabbit_count, ", 上限:", GameManager.max_rabbits)

	if rabbit_count >= GameManager.max_rabbits:
		_show_message("围栏已满（%d/%d）！去商店「兔子」页扩建围栏吧" % [rabbit_count, GameManager.max_rabbits], "warning")
		return

	if GameManager.spend_coins(cost):
		var rabbit_scene = preload("res://scenes/rabbit.tscn")
		var rabbit = rabbit_scene.instantiate()
		rabbit.breed = breed_id
		# 给兔子分配名字和颜色
		var r_name = ""
		if total_rabbits_created < RABBIT_NAMES.size():
			r_name = RABBIT_NAMES[total_rabbits_created]
		else:
			r_name = rabbit.generate_random_name()
		rabbit.set_rabbit_name(r_name)
		total_rabbits_created += 1
		rabbit.position = Vector2(randf_range(100, 650), randf_range(100, 350))
		$FenceArea.add_child(rabbit)
		_setup_rabbit(rabbit)
		AudioManager.play_buy()
		_show_message("购买成功！" + breed_name + " " + rabbit.rabbit_name + " 🐇", "success")
		print("购买成功！新兔子名字：", rabbit.rabbit_name, "，颜色：", rabbit.fur_color)
		# 更新兔子数量显示
		_update_rabbit_count_display()
		# 通知任务系统（养兔子任务用当前总数量）
		var new_count = GameManager.get_rabbit_count()
		TaskManager.total_stats["breed"] = new_count
		TaskManager.update_task_progress("breed", 0)  # 触发检查
		UnlockTaskManager.update_rabbit_count(new_count)

# 购买高级胡萝卜
func _on_buy_carrot_pressed() -> void:
	_purchase_item("carrot", "高级胡萝卜", 30)

# 购买清水
func _on_buy_water_pressed() -> void:
	_purchase_item("water", "清水", 10)

# 购买新鲜蔬菜
func _on_buy_vegetable_pressed() -> void:
	_purchase_item("vegetable", "新鲜蔬菜", 15)

# 购买苹果片
func _on_buy_apple_pressed() -> void:
	_purchase_item("apple", "苹果片", 25)

# 扩建围栏
func _on_expand_fence_pressed() -> void:
	AudioManager.play_click()
	var cost = 1000
	if GameManager.coins < cost:
		_show_message("金币不足！需要 %d 金币（当前 %d）" % [cost, GameManager.coins], "warning")
		return

	if GameManager.spend_coins(cost):
		GameManager.max_rabbits += 1
		AudioManager.play_buy()
		_show_message("围栏扩建成功！可养 " + str(GameManager.max_rabbits) + " 只兔子 🏠", "success")
		# 更新兔子数量显示
		_update_rabbit_count_display()

# ========== 商店标签页切换 ==========
func _on_tab_food_pressed() -> void:
	AudioManager.play_click()
	_switch_tab("Food")

func _on_tab_toy_pressed() -> void:
	AudioManager.play_click()
	_switch_tab("Toy")

func _on_tab_medicine_pressed() -> void:
	AudioManager.play_click()
	_switch_tab("Medicine")

func _on_tab_furniture_pressed() -> void:
	AudioManager.play_click()
	_switch_tab("Furniture")

func _on_tab_rabbit_pressed() -> void:
	AudioManager.play_click()
	_switch_tab("Rabbit")

func _switch_tab(tab_name: String) -> void:
	# 隐藏所有标签页
	$ShopPanel/FoodSection.visible = (tab_name == "Food")
	$ShopPanel/ToySection.visible = (tab_name == "Toy")
	$ShopPanel/MedicineSection.visible = (tab_name == "Medicine")
	$ShopPanel/FurnitureSection.visible = (tab_name == "Furniture")
	$ShopPanel/RabbitSection.visible = (tab_name == "Rabbit")

# ========== 购买新食物 ==========
func _on_buy_rabbit_food_pressed() -> void:
	_purchase_item("rabbit_food", "高级兔粮", 50)

func _on_buy_cake_pressed() -> void:
	_purchase_item("carrot_cake", "胡萝卜蛋糕", 100)

# 刷新商店物品锁定状态（未解锁的物品显示锁定）
func _refresh_shop_lock_status() -> void:
	print("[Main] 刷新商店物品锁定状态")
	# 食物类
	_set_item_lock_status("BuyVegetable", "vegetable", "新鲜蔬菜", 15)
	_set_item_lock_status("BuyApple", "apple", "苹果片", 25)
	_set_item_lock_status("BuyRabbitFood", "rabbit_food", "高级兔粮", 50)
	_set_item_lock_status("BuyCake", "carrot_cake", "胡萝卜蛋糕", 100)
	# 玩具类
	_set_item_lock_status("BuyGrassCarrot", "grass_carrot", "草萝卜", 25)
	# 药品类
	_set_item_lock_status("BuyVitamin", "vitamin", "维生素片", 80)
	_set_item_lock_status("BuyHerb", "herb_medicine", "草药膏", 150)
	_set_item_lock_status("BuyMagicWater", "magic_water", "神奇泉水", 300)
	# 设施类
	_set_item_lock_status("BuyHouse", "wooden_house", "小木屋", 200)
	_set_item_lock_status("BuyAutoFeeder", "auto_feeder", "自动喂食器", 500)
	_set_item_lock_status("BuyWaterFountain", "water_fountain", "自动饮水器", 400)
	_set_item_lock_status("BuyGrassMat", "grass_mat", "青草垫", 150)
	_set_item_lock_status("BuyGoldBowl", "golden_bowl", "黄金食盆", 800)
	_set_item_lock_status("BuyAutoToilet", "auto_toilet", "自动马桶", 1000)

# 物品解锁时刷新商店
func _on_item_unlocked(item_id: String) -> void:
	print("[Main] 收到物品解锁信号: ", item_id)
	if shop_panel.visible:
		print("[Main] 商店已打开，刷新锁定状态")
		_refresh_shop_lock_status()
	else:
		print("[Main] 商店未打开，下次打开时会刷新")

# 设置单个物品按钮的锁定状态
func _set_item_lock_status(button_node_name: String, item_id: String, item_name: String, cost: int) -> void:
	# 尝试在商店面板中查找按钮
	var btn = shop_panel.find_child(button_node_name, true)
	if btn and btn is Button:
		if not UnlockTaskManager.is_item_unlocked(item_id):
			# 锁定状态：灰化按钮，文字加上🔒
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)
			btn.text = "🔒 " + item_name + "\n完成任务解锁"
			print("[Main] 🔒 物品锁定: ", item_id, " (", item_name, ")")
		else:
			# 已解锁：恢复正常文字和价格
			var item_data = ItemData.get_item(item_id)
			var price = item_data.get("price", cost)
			var icon = item_data.get("icon", "📦")
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)
			btn.text = icon + " " + item_name + "\n" + str(price) + " 💰"
			print("[Main] ✅ 物品已解锁: ", item_id, " (", item_name, ")")
	else:
		print("[Main] ⚠️ 找不到商店按钮: ", button_node_name)

# 通用购买物品函数（放入背包）
func _purchase_item(item_id: String, item_name: String, cost: int) -> void:
	print("[Main] 点击购买物品: ", item_id, " (", item_name, ")")
	AudioManager.play_click()

	# 检查物品是否已解锁
	if not UnlockTaskManager.is_item_unlocked(item_id):
		print("[Main] ❌ 物品未解锁: ", item_id)
		_show_message("🔒 " + item_name + " 尚未解锁！完成成长任务解锁吧 🌟", "warning")
		return

	if GameManager.coins < cost:
		_show_message("金币不足！需要 %d 金币（当前 %d）" % [cost, GameManager.coins], "warning")
		return

	if GameManager.spend_coins(cost):
		InventoryManager.add_item(item_id, 1)
		AudioManager.play_buy()
		_show_message("购买成功！" + item_name + "已放入背包 🎒", "success")

# ========== 购买玩具 ==========
# func _on_buy_ball_pressed() -> void:
# 	_purchase_item("ball", "小皮球", 40)

# func _on_buy_yarn_pressed() -> void:
# 	_purchase_item("yarn", "毛线球", 35)

# func _on_buy_carrot_toy_pressed() -> void:
# 	_purchase_item("carrot_toy", "胡萝卜玩具", 60)

# func _on_buy_tunnel_pressed() -> void:
# 	_purchase_item("tunnel", "兔子隧道", 120)

func _on_buy_grass_carrot_pressed() -> void:
	_purchase_item("grass_carrot", "草萝卜", 25)

# ========== 购买药品 ==========
func _on_buy_vitamin_pressed() -> void:
	_purchase_item("vitamin", "维生素片", 80)

func _on_buy_herb_pressed() -> void:
	_purchase_item("herb_medicine", "草药膏", 150)

func _on_buy_magic_water_pressed() -> void:
	_purchase_item("magic_water", "神奇泉水", 300)

# ========== 购买设施 ==========
func _on_buy_house_pressed() -> void:
	_purchase_furniture("wooden_house", "小木屋", 200, "持续增加快乐值")

func _on_buy_auto_feeder_pressed() -> void:
	_purchase_furniture("auto_feeder", "自动喂食器", 500, "自动恢复饱食")

func _on_buy_water_fountain_pressed() -> void:
	_purchase_furniture("water_fountain", "自动饮水器", 400, "自动恢复口渴")

func _on_buy_grass_mat_pressed() -> void:
	_purchase_furniture("grass_mat", "青草垫", 150, "加速毛生长")

func _on_buy_gold_bowl_pressed() -> void:
	_purchase_furniture("golden_bowl", "黄金食盆", 800, "快乐+饱食双加成")

func _on_buy_auto_toilet_pressed() -> void:
	_purchase_furniture("auto_toilet", "自动马桶", 1000, "自动收集便便")

func _purchase_furniture(item_id: String, name: String, cost: int, effect_desc: String) -> void:
	print("[Main] 点击购买设施: ", item_id, " (", name, ")")
	AudioManager.play_click()

	# 检查物品是否已解锁
	if not UnlockTaskManager.is_item_unlocked(item_id):
		print("[Main] ❌ 设施未解锁: ", item_id)
		_show_message("🔒 " + name + " 尚未解锁！完成成长任务解锁吧 🌟", "warning")
		return

	# 检查是否为唯一设施（只能买一个）
	var unique_items = ["auto_feeder", "water_fountain", "auto_toilet"]
	if item_id in unique_items:
		for placed in InventoryManager.placed_items:
			if placed.id == item_id:
				_show_message(name + " 已经放置过了，只能拥有一个！", "warning")
				return

	if InventoryManager.purchase_item(item_id):
		AudioManager.play_buy()
		_show_message("购买成功！" + name + "已放置到笼子里 🏠", "success")
		# 刷新显示
		_refresh_placed_items()
		# 通知阶梯任务系统（放置设施任务）
		UnlockTaskManager.increment_place_furniture()
	else:
		_show_message("金币不足！需要 " + str(cost) + " 金币", "warning")

# 重置所有存档并重新开始（调试用）
func _reset_all_saves() -> void:
	print("[Main] 🔄 重置所有存档...")

	# 删除所有5个存档
	for i in range(SaveManager.MAX_SAVE_SLOTS):
		SaveManager.delete_save(i)

	# 清除当前兔子
	for child in $FenceArea.get_children():
		if child is CharacterBody2D:
			child.queue_free()

	# 重置游戏状态
	GameManager.coins = 10000
	GameManager.max_rabbits = 3
	GameManager.deselect_rabbit()
	InventoryManager.inventory = {}
	InventoryManager.placed_items = []
	InventoryManager.calculate_bonuses()
	TaskManager.task_progress = {}
	TaskManager.daily_state = {"last_reset_date": "", "selected_tasks": []}
	TaskManager.total_stats = {"feed": 0, "pet": 0, "shave": 0, "breed": 0, "money": 0, "drink": 0}
	TaskManager.check_daily_reset()
	UnlockTaskManager.task_progress = {}
	UnlockTaskManager.unlocked_items = []
	UnlockTaskManager._init_default_data()

	# 创建新存档
	SaveManager.create_new_save(0)
	total_rabbits_created = 0

	# 重新生成初始兔子
	_check_and_spawn_rabbit()
	_refresh_placed_items()
	_update_rabbit_count_display()
	_on_coins_changed(GameManager.coins)

	_show_message("所有存档已重置！ 🔄", "success")
	print("[Main] ✅ 存档重置完成")

# 刷新显示已放置的物品
func _refresh_placed_items() -> void:
	print("DEBUG: _refresh_placed_items() 被调用！dragging_item = ", dragging_item)

	# 防止重入
	if is_refreshing_placed_items:
		print("DEBUG: 正在刷新中，跳过...")
		return
	is_refreshing_placed_items = true

	# 如果正在拖拽中，先保存位置再刷新
	if dragging_item and is_instance_valid(dragging_item):
		var item_index = dragging_item.get_meta("item_index")
		var items = InventoryManager.get_placed_items()
		if item_index < items.size():
			items[item_index].x = dragging_item.position.x
			items[item_index].y = dragging_item.position.y
			print("DEBUG: 刷新前保存位置，index = ", item_index, ", pos = ", dragging_item.position)

	# 刷新前停止任何正在进行的拖拽
	dragging_item = null

	# 先清除旧的物品节点（使用安全的方式）
	var items_to_remove = []
	for child in $FenceArea.get_children():
		if child.name.begins_with("PlacedItem"):
			items_to_remove.append(child)

	print("DEBUG: 要移除的物品数量 = ", items_to_remove.size())

	# 安全移除所有物品节点
	for item in items_to_remove:
		if is_instance_valid(item):
			item.queue_free()

	# 等待一帧确保节点都已删除
	await get_tree().process_frame

	is_refreshing_placed_items = false
	print("DEBUG: 刷新完成！")

	# 创建新的物品显示（支持拖拽移动）
	var items = InventoryManager.get_placed_items()
	for i in range(items.size()):
		var item_data = items[i]
		var item_info = ItemData.get_item(item_data.id)
		if item_info:
			# 创建父容器来放图标和数字
			var item_container = Control.new()
			item_container.name = "PlacedItem" + str(i)
			item_container.position = Vector2(item_data.x, item_data.y)

			# 青草垫用更大的容器
			if item_data.id == "grass_mat":
				item_container.custom_minimum_size = Vector2(85, 60)
			else:
				item_container.custom_minimum_size = Vector2(70, 55)

			item_container.set_meta("item_index", i)

			# 设施图标 - 直接在标签上检测鼠标
			var item_label = Label.new()
			var display_icon = item_info.get("big_icon", item_info.icon)
			item_label.text = display_icon
			item_label.add_theme_font_size_override("font_size", 48)
			item_label.modulate = Color(1, 1, 1, 0.9)
			item_label.mouse_filter = Control.MOUSE_FILTER_STOP  # 直接在标签上检测鼠标
			item_label.custom_minimum_size = item_container.custom_minimum_size
			item_container.add_child(item_label)

			# 道具不需要悬停显示名字，只需要兔子显示

			# 如果是喂食器/饮水器/小木屋，添加右下角数字显示
			if item_data.id in ["auto_feeder", "water_fountain", "golden_bowl", "wooden_house"]:
				var remaining = 0
				if item_data.id in ["auto_feeder", "golden_bowl"]:
					remaining = InventoryManager.get_feeder_food_count(i)
				elif item_data.id == "water_fountain":
					remaining = InventoryManager.get_fountain_water_count(i)
				elif item_data.id == "wooden_house":
					remaining = InventoryManager.get_house_toy_count(i)

				# 数字背景框
				var count_bg = ColorRect.new()
				count_bg.name = "CountBg"
				count_bg.position = Vector2(40, 35)
				count_bg.size = Vector2(28, 20)
				if remaining > 0:
					count_bg.color = Color(0.2, 0.7, 0.3, 0.9)
				else:
					count_bg.color = Color(0.5, 0.5, 0.5, 0.9)
				item_container.add_child(count_bg)

				# 数字标签
				var count_label = Label.new()
				count_label.name = "CountLabel"
				count_label.position = Vector2(40, 35)
				count_label.custom_minimum_size = Vector2(28, 20)
				count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				count_label.add_theme_font_size_override("font_size", 14)
				count_label.modulate = Color(1, 1, 1)
				if remaining > 0:
					count_label.text = str(remaining)
				else:
					count_label.text = "空"
				item_container.add_child(count_label)

			# 如果是青草垫，添加倒计时显示
			if item_data.id == "grass_mat":
				# 倒计时背景框
				var count_bg = ColorRect.new()
				count_bg.name = "TimerBg"
				count_bg.position = Vector2(35, 35)
				count_bg.size = Vector2(35, 20)
				count_bg.color = Color(0.3, 0.7, 0.4, 0.9)
				item_container.add_child(count_bg)

				# 倒计时标签
				var timer_label = Label.new()
				timer_label.name = "TimerLabel"
				timer_label.position = Vector2(35, 35)
				timer_label.custom_minimum_size = Vector2(35, 20)
				timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				timer_label.add_theme_font_size_override("font_size", 13)
				timer_label.modulate = Color(1, 1, 1)
				timer_label.text = "60s"
				item_container.add_child(timer_label)

			$FenceArea.add_child(item_container)

	# 如果有设施，显示效果提示
	if items.size() > 0:
		var total_effects = InventoryManager.get_total_effects_text()
		if total_effects:
			print("设施效果: ", total_effects)

# ========== 背包功能 ==========
var current_inventory_tab = "Food"

# 打开背包
func _on_inventory_button_pressed() -> void:
	# 停止任何正在进行的拖拽
	dragging_item = null
	AudioManager.play_click()

	# 关闭商店（互斥）
	if shop_panel.visible:
		_on_shop_close_pressed()

	inventory_panel.visible = true
	inventory_panel.position = Vector2(-900, 80)
	var tween = create_tween()
	tween.tween_property(inventory_panel, "position:x", 50, 0.3)
	_refresh_inventory("Food")

# 关闭背包
func _on_inventory_close_pressed() -> void:
	AudioManager.play_click()
	var tween = create_tween()
	tween.tween_property(inventory_panel, "position:x", -900, 0.3)
	tween.finished.connect(func(): inventory_panel.visible = false)

# 打开任务面板
func _on_task_button_pressed() -> void:
	# 停止任何正在进行的拖拽
	dragging_item = null
	AudioManager.play_click()

	# 关闭商店和背包（互斥）
	if shop_panel.visible:
		_on_shop_close_pressed()
	if inventory_panel.visible:
		_on_inventory_close_pressed()

	# 确保任务面板节点存在
	if task_panel:
		task_panel.visible = true
		task_panel.position = Vector2(-600, 80)
		var tween = create_tween()
		tween.tween_property(task_panel, "position:x", 180, 0.3)
		# 延迟刷新任务列表，确保节点初始化完成
		task_panel.call_deferred("_refresh_all_tasks")
	else:
		_show_message("任务面板加载中...", "warning")

# 关闭任务面板（从任务面板调用）
func _on_task_panel_close() -> void:
	AudioManager.play_click()
	if task_panel:
		var tween = create_tween()
		tween.tween_property(task_panel, "position:x", -600, 0.3)
		tween.finished.connect(func(): task_panel.visible = false)

# 打开成长面板
func _on_growth_button_pressed() -> void:
	dragging_item = null
	AudioManager.play_click()

	# 关闭其他面板（互斥）
	if shop_panel.visible:
		_on_shop_close_pressed()
	if inventory_panel.visible:
		_on_inventory_close_pressed()
	if task_panel and task_panel.visible:
		_on_task_panel_close()

	if unlock_task_panel:
		unlock_task_panel.visible = true
		unlock_task_panel.position = Vector2(-600, 60)
		var tween = create_tween()
		tween.tween_property(unlock_task_panel, "position:x", 180, 0.3)
		unlock_task_panel.call_deferred("_refresh_all_tasks")

# 关闭成长面板
func _on_growth_panel_close() -> void:
	AudioManager.play_click()
	if unlock_task_panel:
		var tween = create_tween()
		tween.tween_property(unlock_task_panel, "position:x", -600, 0.3)
		tween.finished.connect(func(): unlock_task_panel.visible = false)

# 背包标签页切换
func _on_inventory_tab_food_pressed() -> void:
	AudioManager.play_click()
	_refresh_inventory("Food")

func _on_inventory_tab_toy_pressed() -> void:
	AudioManager.play_click()
	_refresh_inventory("Toy")

func _on_inventory_tab_medicine_pressed() -> void:
	AudioManager.play_click()
	_refresh_inventory("Medicine")

# 刷新背包显示
func _refresh_inventory(tab_name: String) -> void:
	current_inventory_tab = tab_name

	# 清除旧的物品
	for child in inventory_grid.get_children():
		child.queue_free()

	# 根据类型获取物品ID列表
	var type_filter = -1
	match tab_name:
		"Food":
			type_filter = ItemData.ItemType.FOOD
		"Toy":
			type_filter = ItemData.ItemType.TOY
		"Medicine":
			type_filter = ItemData.ItemType.MEDICINE

	# 获取该类型所有物品ID
	var item_ids = []
	for item_id in ItemData.all_items:
		var item = ItemData.get_item(item_id)
		if item and item.type == type_filter and not item.get("placeable", false):
			item_ids.append(item_id)

	# 显示有数量的物品
	var has_items = false
	for item_id in item_ids:
		var count = InventoryManager.get_item_count(item_id)
		if count > 0:
			has_items = true
			var item_info = ItemData.get_item(item_id)
			_create_item_button(item_id, item_info, count)

	inventory_empty_label.visible = not has_items

# 创建物品按钮
func _create_item_button(item_id: String, item_info: Dictionary, count: int) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 80)
	btn.text = "%s %s\n%s\n数量: %d" % [item_info.icon, item_info.name, item_info.description, count]
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_use_item.bind(item_id))
	inventory_grid.add_child(btn)

# 使用物品
func _use_item(item_id: String) -> void:
	AudioManager.play_click()

	if not GameManager.selected_rabbit:
		_show_message("请先选中一只兔子！", "warning")
		return

	var rabbit = GameManager.selected_rabbit
	if rabbit.is_dead:
		_show_message("兔子已经去兔星了...", "warning")
		return

	var item_info = ItemData.get_item(item_id)
	if not item_info:
		return

	if not InventoryManager.has_item(item_id):
		_show_message("物品数量不足！", "warning")
		return

	# 消耗物品
	InventoryManager.use_item(item_id, 1)

	# 应用物品效果
	match item_info.type:
		ItemData.ItemType.FOOD:
			if "hunger_add" in item_info:
				rabbit.hunger = min(100, rabbit.hunger + item_info.hunger_add)
			if "thirst_add" in item_info:
				rabbit.thirst = min(100, rabbit.thirst + item_info.thirst_add)
			if "happiness_add" in item_info:
				rabbit.happiness = min(100, rabbit.happiness + item_info.happiness_add)
			if "fur_boost" in item_info and item_info.fur_boost:
				rabbit.fur_length = min(100, rabbit.fur_length + 20)
			_spawn_heart_effect(rabbit)
			AudioManager.play_feed()
			if "thirst_add" in item_info and "hunger_add" not in item_info:
				_show_message("喂水" + item_info.name + "！", "success")
			else:
				_show_message("喂食" + item_info.name + "！", "success")

		ItemData.ItemType.TOY:
			if "happiness_add" in item_info:
				rabbit.happiness = min(100, rabbit.happiness + item_info.happiness_add)
			rabbit.set_state(0)
			for i in range(3):
				_spawn_heart_effect(rabbit)
				await get_tree().create_timer(0.2).timeout
			AudioManager.play_happy()
			_show_message("和兔子玩" + item_info.name + "！", "success")

		ItemData.ItemType.MEDICINE:
			if "health_add" in item_info:
				rabbit.health = min(100, rabbit.health + item_info.health_add)
			if "hunger_add" in item_info:
				rabbit.hunger = min(100, rabbit.hunger + item_info.hunger_add)
			if "happiness_add" in item_info:
				rabbit.happiness = min(100, rabbit.happiness + item_info.happiness_add)
			rabbit.set_state(0)
			_spawn_heart_effect(rabbit)
			AudioManager.play_coin()
			_show_message("使用" + item_info.name + "！健康恢复中 ❤️", "success")
			# 手动触发属性更新信号，立即刷新UI
			rabbit.attribute_changed.emit()

	# 刷新背包显示
	_refresh_inventory(current_inventory_tab)

# 当前打开的设施索引
var current_storage_index: int = -1
var current_storage_type: String = ""

# 显示存放物资界面
func _show_storage_panel(item_id: String, item_index: int) -> void:
	current_storage_index = item_index
	current_storage_type = item_id

	# 设置标题
	var panel = $StoragePanel
	var title_label = panel.get_node("Title")
	if item_id == "auto_feeder":
		title_label.text = "🍽️ 自动喂食器"
	elif item_id == "water_fountain":
		title_label.text = "💧 自动饮水器"
	elif item_id == "golden_bowl":
		title_label.text = "👑🥣 黄金食盆"
	elif item_id == "wooden_house":
		title_label.text = "🏠 小木屋"

	# 显示容量
	var capacity_label = panel.get_node("CapacityLabel")
	var current_count = 0
	var max_capacity = 10

	if item_id in ["auto_feeder", "golden_bowl"]:
		current_count = InventoryManager.get_feeder_food_count(item_index)
	elif item_id == "water_fountain":
		current_count = InventoryManager.get_fountain_water_count(item_index)
	elif item_id == "wooden_house":
		current_count = InventoryManager.get_house_toy_count(item_index)
		max_capacity = 20

	capacity_label.text = "剩余容量: " + str(current_count) + "/" + str(max_capacity)

	# 清空物品列表
	var item_list = panel.get_node("ItemList")
	for child in item_list.get_children():
		child.queue_free()

	# 显示可用的物资
	var has_items = false
	if item_id in ["auto_feeder", "golden_bowl"]:
		# 显示所有食物
		for food_id in InventoryManager.inventory:
			var item = ItemData.get_item(food_id)
			if item and item.type == ItemData.ItemType.FOOD and food_id != "water":
				var count = InventoryManager.get_item_count(food_id)
				if count > 0:
					has_items = true
					_add_storage_item(item_list, food_id, item.icon, item.name, count)
	elif item_id == "water_fountain":
		# 只显示清水
		var water_count = InventoryManager.get_item_count("water")
		if water_count > 0:
			has_items = true
			var item = ItemData.get_item("water")
			_add_storage_item(item_list, "water", item.icon, item.name, water_count)
	elif item_id == "wooden_house":
		# 显示所有可存储的玩具
		for toy_id in InventoryManager.inventory:
			var item = ItemData.get_item(toy_id)
			if item and item.type == ItemData.ItemType.TOY and item.get("storable", false):
				var count = InventoryManager.get_item_count(toy_id)
				if count > 0:
					has_items = true
					_add_storage_item(item_list, toy_id, item.icon, item.name, count)

	# 显示/隐藏空标签
	var empty_label = panel.get_node("EmptyLabel")
	empty_label.visible = not has_items

	# 显示面板
	panel.visible = true

# 添加一个可存放的物品按钮
func _add_storage_item(container: VBoxContainer, item_id: String, icon: String, name: String, count: int) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 60)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = name + " x" + str(count)
	name_label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(name_label)

	var put_btn = Button.new()
	put_btn.text = "放入"
	put_btn.custom_minimum_size = Vector2(100, 0)
	put_btn.pressed.connect(_put_item_to_storage.bind(item_id))
	hbox.add_child(put_btn)

	container.add_child(hbox)

# 把物品放入设施
func _put_item_to_storage(item_id: String) -> void:
	var success = false
	if current_storage_type in ["auto_feeder", "golden_bowl"]:
		success = InventoryManager.add_food_to_feeder(current_storage_index, item_id, 1)
	elif current_storage_type == "water_fountain":
		success = InventoryManager.add_water_to_fountain(current_storage_index, 1)
	elif current_storage_type == "wooden_house":
		success = InventoryManager.add_toy_to_house(current_storage_index, item_id, 1)

	if success:
		_show_message("放入成功！", "success")
		AudioManager.play_click()
		# 刷新界面
		_show_storage_panel(current_storage_type, current_storage_index)
		# 刷新围栏里的余量显示
		_refresh_placed_items()
	else:
		_show_message("放入失败！可能已满或物品不足", "warning")

# 关闭存放界面
func _on_storage_close_pressed() -> void:
	$StoragePanel.visible = false
	current_storage_index = -1
	current_storage_type = ""
	AudioManager.play_click()

# 更新青草垫倒计时显示
func _update_grass_mat_countdown(item_index: int, remaining_time: int) -> void:
	# 找到对应的青草垫节点
	var fence = $FenceArea
	if not fence:
		return

	var item_container = fence.get_node_or_null("PlacedItem" + str(item_index))
	if not item_container:
		return

	# 更新倒计时标签
	var timer_label = item_container.get_node_or_null("TimerLabel")
	if timer_label:
		timer_label.text = str(remaining_time) + "s"

	# 根据剩余时间改变颜色
	var timer_bg = item_container.get_node_or_null("TimerBg")
	if timer_bg:
		if remaining_time > 40:
			timer_bg.color = Color(0.2, 0.8, 0.3, 0.9)  # 绿色
		elif remaining_time > 20:
			timer_bg.color = Color(0.9, 0.8, 0.2, 0.9)  # 黄色
		else:
			timer_bg.color = Color(0.9, 0.3, 0.3, 0.9)  # 红色

# ========== 鼠标悬停显示名字 ==========

# 创建悬停标签
func _create_hover_label() -> void:
	hover_label = Label.new()
	hover_label.name = "HoverLabel"
	hover_label.custom_minimum_size = Vector2(120, 30)
	hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_label.add_theme_font_size_override("font_size", 16)
	hover_label.modulate = Color(1, 1, 0.8, 1)  # 浅黄色文字
	hover_label.z_index = 1000  # 确保在最上层
	hover_label.visible = false
	add_child(hover_label)


# 显示悬停名字
func _show_hover_name(name: String, position: Vector2) -> void:
	if not hover_label:
		return

	hover_label.text = name
	hover_label.position = position + Vector2(15, -35)  # 鼠标右上方
	hover_label.visible = true

# 隐藏悬停名字
func _hide_hover_name() -> void:
	if hover_label:
		hover_label.visible = false
	hovered_item = null


# 设施悬停回调（已禁用，只保留兔子悬停显示）
# func _on_item_hovered(item_name: String, item_node: Control) -> void:
# 	_show_hover_name(item_name, item_node.get_global_position())

# ========== 便便系统 ==========

# 初始化兔子（连接便便信号等）
func _setup_rabbit(rabbit: Node) -> void:
	if rabbit and rabbit.has_signal("poop_created"):
		rabbit.poop_created.connect(_on_rabbit_poop_created)

# 兔子拉便便时调用
func _on_rabbit_poop_created(rabbit, pos: Vector2, is_golden: bool) -> void:
	# 全场上限检查
	if total_poop_count >= MAX_TOTAL_POOP:
		return

	# 创建便便节点
	var poop_label = Label.new()
	poop_label.name = "Poop_" + str(Time.get_ticks_msec())
	poop_label.text = "💩"
	poop_label.add_theme_font_size_override("font_size", 24)
	poop_label.custom_minimum_size = Vector2(30, 30)
	poop_label.position = pos - Vector2(15, 15)
	poop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poop_label.set_meta("is_golden", is_golden)
	poop_label.set_meta("world_pos", pos)  # 便便中心在围栏内的坐标

	# 金色便便发光效果
	if is_golden:
		poop_label.modulate = Color(1, 0.95, 0.3, 1)
		# 简单的闪烁动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(poop_label, "modulate", Color(1, 0.9, 0.2, 1), 0.5)
		tween.tween_property(poop_label, "modulate", Color(1, 1, 0.5, 1), 0.5)

	# 注意：点击收集统一由 _on_fence_area_input 处理
	# 便便节点设置为 MOUSE_FILTER_IGNORE，确保事件穿透到 FenceArea

	$FenceArea.add_child(poop_label)
	total_poop_count += 1
	# 加入便便列表（用于点击检测，不依赖节点坐标）
	poop_list.append({
		"node": poop_label,
		"world_pos": pos,
		"is_golden": is_golden,
		"rabbit": rabbit
	})

# 收集便便
func _collect_poop(poop_node: Label) -> void:
	if not is_instance_valid(poop_node):
		return

	var is_golden = poop_node.get_meta("is_golden", false)
	var item_id = "golden_poop" if is_golden else "rabbit_poop"
	var item_data = ItemData.get_item(item_id)
	var price = item_data.get("price", 2)

	# 放入背包
	InventoryManager.add_item(item_id, 1)

	# 给金币
	GameManager.add_coins(price)

	# 通知任务系统
	UnlockTaskManager.update_progress("clean_poop", 1)

	# 减少计数
	total_poop_count = max(0, total_poop_count - 1)

	# 从便便列表中移除，并通知对应的兔子继续拉便便
	for i in range(poop_list.size()):
		if i < poop_list.size() and poop_list[i].node == poop_node:
			var poop_rabbit = poop_list[i].rabbit
			poop_list.remove_at(i)
			# 通知兔子，减少它的便便计数，让它可以继续拉
			if poop_rabbit and is_instance_valid(poop_rabbit):
				poop_rabbit.on_poop_collected()
			break

	# 通知兔子（让它可以继续拉）
	# 这里简单处理：找到最近的兔子并通知
	# （因为便便不记录是哪只兔子的，用全局计数控制就行）

	# 收集动画：向上飘然后消失
	var tween = create_tween()
	tween.tween_property(poop_node, "position:y", poop_node.position.y - 20, 0.3)
	tween.tween_property(poop_node, "modulate:a", 0, 0.2)
	tween.finished.connect(func():
		if is_instance_valid(poop_node):
			poop_node.queue_free()
	)

	# 显示提示
	if is_golden:
		_show_message("✨ 捡到金色便便！+" + str(price) + " 💰", "success")
		AudioManager.play_coin()
	else:
		AudioManager.play_click()

	print("[Poop] 收集便便，金色:", is_golden, "，金币+", price)

# 检查是否有自动马桶设施
func _has_auto_toilet() -> bool:
	for placed in InventoryManager.placed_items:
		if placed.id == "auto_toilet":
			return true
	return false

# 自动马桶更新（每帧调用）
func _auto_toilet_update(delta: float) -> void:
	if not _has_auto_toilet():
		auto_toilet_timer = 0.0
		return

	auto_toilet_timer += delta
	if auto_toilet_timer >= AUTO_TOILET_INTERVAL:
		auto_toilet_timer = 0.0
		_auto_collect_all_poop()

# 自动收集所有便便
func _auto_collect_all_poop() -> void:
	if poop_list.is_empty():
		return

	var total_coins = 0
	var golden_count = 0
	var normal_count = 0

	# 倒序遍历，边收集边移除
	for i in range(poop_list.size() - 1, -1, -1):
		var poop_data = poop_list[i]
		var poop_node = poop_data.node
		if not is_instance_valid(poop_node):
			poop_list.remove_at(i)
			continue

		var is_golden = poop_data.is_golden
		var item_id = "golden_poop" if is_golden else "rabbit_poop"
		var item_info = ItemData.get_item(item_id)
		var price = item_info.get("price", 2)

		# 放入背包
		InventoryManager.add_item(item_id, 1)
		total_coins += price

		# 通知兔子减少便便计数
		var poop_rabbit = poop_data.rabbit
		if poop_rabbit and is_instance_valid(poop_rabbit):
			poop_rabbit.on_poop_collected()

		# 收集动画
		var tween = create_tween()
		tween.tween_property(poop_node, "position:y", poop_node.position.y - 30, 0.4)
		tween.tween_property(poop_node, "modulate:a", 0, 0.3)
		tween.finished.connect(func ():
			if is_instance_valid(poop_node):
				poop_node.queue_free()
		)

		if is_golden:
			golden_count += 1
		else:
			normal_count += 1

		poop_list.remove_at(i)

	# 给金币
	if total_coins > 0:
		GameManager.add_coins(total_coins)
		# 通知任务系统
		UnlockTaskManager.update_progress("clean_poop", normal_count + golden_count)
		total_poop_count = max(0, total_poop_count - normal_count - golden_count)
		AudioManager.play_coin()

		print("[AutoToilet] 🚽 自动收集便便: 普通", normal_count, " 金色", golden_count, " 金币+", total_coins)
