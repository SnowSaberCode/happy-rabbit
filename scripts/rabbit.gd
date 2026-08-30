extends CharacterBody2D

# 核心属性
var breed: String = "lop_gray"
var rabbit_name: String = ""  # 兔子名字
var fur_color: Color = Color(1, 1, 1)  # 毛发颜色
var hunger: float = 100.0
var thirst: float = 100.0
var happiness: float = 80.0
var fur_length: float = 20.0
var health: float = 100.0
var is_dead: bool = false  # 死亡状态

# 随机名字库（所有兔子第一个字都是"萝"）
const RABBIT_FIRST_NAMES = ["萝"]
const RABBIT_LAST_NAMES = ["小", "大", "胖", "壮", "软", "萌", "甜", "乖", "宝", "贝", "球", "朵", "菲", "莉", "娜", "咪", "妮", "塔", "拉", "西", "米", "卡", "布", "丁", "嘟", "噜"]

# 不同品种的毛发颜色预设（调得更白）
const COLORS_GRAY = [
	Color(0.95, 0.95, 0.97),  # 更浅的灰色
	Color(0.92, 0.92, 0.95),  # 中浅灰色
	Color(0.88, 0.88, 0.92),  # 标准灰色
	Color(0.94, 0.92, 0.97),  # 浅灰紫色
	Color(0.92, 0.94, 0.97),  # 浅灰蓝色
]

const COLORS_WHITE = [
	Color(1.00, 1.00, 1.00),  # 纯白色
	Color(0.99, 0.99, 1.00),  # 极浅的冷白
	Color(1.00, 1.00, 0.99),  # 极浅的暖白
	Color(0.98, 0.98, 1.00),  # 冷白色
	Color(0.98, 0.97, 0.96),  # 米白色
]

const COLORS_BROWN = [
	Color(0.95, 0.85, 0.70),  # 浅棕色
	Color(0.92, 0.80, 0.65),  # 暖棕色
	Color(0.85, 0.75, 0.65),  # 卡其色
	Color(0.90, 0.75, 0.60),  # 深棕色
	Color(0.95, 0.90, 0.75),  # 金黄色
]

# 所有颜色（用于随机分配）
const FUR_COLORS = COLORS_GRAY + COLORS_WHITE + COLORS_BROWN

# 属性衰减速度（每秒）
const HUNGER_DECAY: float = 0.3
const THIRST_DECAY: float = 0.4
const HAPPINESS_DECAY: float = 0.15
const FUR_GROWTH: float = 0.2

# AI状态
enum AIState {
	IDLE,
	WANDERING,
	SITTING,
	SLEEPING,
	HAPPY,
	DEAD
}

var current_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO
var move_speed: float = 30.0

# 选中状态
var is_selected: bool = false

# 动画相关
var happy_tween: Tween
var select_tween: Tween
var base_scale: Vector2 = Vector2(1, 1)
var is_bouncing: bool = false
var is_eating: bool = false

# 抚摸连击和冷却系统
var pet_combo_count: int = 0          # 当前连击次数
var pet_cooldown_timer: float = 0.0   # 冷却倒计时
var pet_cooldown_max: float = 10.0    # 最大冷却时间
var is_pet_cooldown: bool = false     # 是否在冷却中

# 冷却显示节点
var cooldown_label: Label

# 便便系统
var poop_timer: float = 0.0  # 便便生成计时器
var next_poop_time: float = 0.0  # 下次生成便便的时间
var my_poop_count: int = 0  # 这只兔子当前存在的便便数量
const MAX_POOP_PER_RABBIT: int = 3  # 单只兔子最多便便数
const POOP_MIN_INTERVAL: float = 10.0  # 最短间隔（秒）
const POOP_MAX_INTERVAL: float = 20.0  # 最长间隔（秒）
const GOLDEN_POOP_CHANCE: float = 0.005  # 金色便便概率 0.5%

# 信号
signal attribute_changed()
signal poop_created(position: Vector2, is_golden: bool)  # 生成便便时发出

func _ready():
	# 确保兔子可见
	visible = true

	# 初始化随机种子
	randomize()

	# 确保有颜色
	_assign_random_fur_color()

	# 应用毛发颜色
	modulate = fur_color

	print("Rabbit: 已初始化，名字=", rabbit_name, "，颜色=", fur_color, "，位置=", position)

	# 设置初始AI状态
	set_state(AIState.IDLE)

	# 创建冷却UI
	_create_cooldown_ui()

	# 创建鼠标悬停检测区域
	_create_hover_detector()

	# 初始化便便计时器
	_reset_poop_timer()

# 设置兔子名字，并根据名字分配颜色
func set_rabbit_name(rabbit_name_str: String) -> void:
	rabbit_name = rabbit_name_str
	_assign_random_fur_color()
	modulate = fur_color

# 分配随机毛发颜色（根据品种和名字）
func _assign_random_fur_color() -> void:
	# 根据品种选择对应的颜色数组
	var color_array = COLORS_GRAY  # 默认灰色
	match breed:
		"lop_white":
			color_array = COLORS_WHITE
		"lop_brown":
			color_array = COLORS_BROWN

	# 根据名字的哈希值确定颜色，保证同一只兔子颜色一致
	if rabbit_name.is_empty():
		# 如果名字为空，随机分配一个颜色
		fur_color = color_array[randi() % color_array.size()]
	else:
		# 根据名字的哈希值确定颜色
		var name_hash = 0
		for c in rabbit_name:
			name_hash += c.unicode_at(0)
		fur_color = color_array[name_hash % color_array.size()]

# 生成随机名字（确保第二个字和第三个字不重复）
func generate_random_name() -> String:
	var first = RABBIT_FIRST_NAMES[randi() % RABBIT_FIRST_NAMES.size()]
	var second_index = randi() % RABBIT_LAST_NAMES.size()
	var second = RABBIT_LAST_NAMES[second_index]

	# 确保第三个字和第二个字不一样
	var third_index = randi() % RABBIT_LAST_NAMES.size()
	while third_index == second_index:
		third_index = randi() % RABBIT_LAST_NAMES.size()
	var third = RABBIT_LAST_NAMES[third_index]

	return first + second + third

func _process(delta: float):
	if is_dead:
		return
	update_attributes(delta)
	update_ai(delta)

	# 更新冷却计时器
	if is_pet_cooldown:
		pet_cooldown_timer -= delta
		if pet_cooldown_timer <= 0:
			pet_cooldown_timer = 0
			is_pet_cooldown = false
			pet_combo_count = 0
			_hide_cooldown_ui()

		# 更新冷却UI
		_update_cooldown_ui()

	# 更新便便计时器
	_update_poop_timer(delta)

func _physics_process(delta: float):
	if is_dead:
		return
	if current_state == AIState.WANDERING:
		var direction = (wander_target - position).normalized()
		velocity = direction * move_speed
		move_and_slide()

		if position.distance_to(wander_target) < 5:
			set_state(AIState.IDLE)

# 更新属性
func update_attributes(delta: float) -> void:
	hunger = max(0, hunger - HUNGER_DECAY * delta)
	thirst = max(0, thirst - THIRST_DECAY * delta)
	happiness = max(0, happiness - HAPPINESS_DECAY * delta)
	fur_length = min(100, fur_length + FUR_GROWTH * delta)

	var min_need = min(hunger, thirst, happiness)
	if min_need < 30:
		health = max(0, health - 0.1 * delta)
	else:
		health = min(100, health + 0.05 * delta)

	# 健康值为0时死亡
	if health <= 0 and not is_dead:
		die()

	attribute_changed.emit()

# 更新AI
func update_ai(delta: float) -> void:
	if is_dead:
		return
	state_timer -= delta
	if state_timer <= 0:
		decide_next_action()

# 死亡
func die() -> void:
	is_dead = true
	current_state = AIState.DEAD
	modulate = Color(0.4, 0.4, 0.5)  # 变灰
	stop_bounce_animation()
	scale = Vector2(0.9, 0.9)  # 稍微变小
	print(rabbit_name, " 去了兔星... 😢")
	update_animation()

# 决定下一个动作
func decide_next_action() -> void:
	var rand = randf()

	if happiness < 30:
		if rand < 0.6:
			set_state(AIState.SITTING)
		else:
			set_state(AIState.IDLE)
	elif happiness > 70:
		if rand < 0.4:
			set_state(AIState.WANDERING)
		elif rand < 0.6:
			set_state(AIState.HAPPY)
		elif rand < 0.8:
			set_state(AIState.SITTING)
		else:
			set_state(AIState.IDLE)
	else:
		if rand < 0.3:
			set_state(AIState.WANDERING)
		elif rand < 0.5:
			set_state(AIState.SITTING)
		elif rand < 0.6:
			set_state(AIState.SLEEPING)
		else:
			set_state(AIState.IDLE)

# 设置AI状态
func set_state(new_state: AIState) -> void:
	current_state = new_state

	match new_state:
		AIState.IDLE:
			state_timer = randf_range(1.0, 3.0)
			velocity = Vector2.ZERO

		AIState.WANDERING:
			state_timer = randf_range(2.0, 5.0)
			wander_target = Vector2(
				randf_range(50, 710),
				randf_range(50, 350)
			)

		AIState.SITTING:
			state_timer = randf_range(2.0, 4.0)
			velocity = Vector2.ZERO

		AIState.SLEEPING:
			state_timer = randf_range(4.0, 8.0)
			velocity = Vector2.ZERO

		AIState.HAPPY:
			state_timer = randf_range(1.0, 2.0)
			velocity = Vector2.ZERO
			if not is_bouncing:
				start_bounce_animation()

# 更新动画
func update_animation() -> void:
	match current_state:
		AIState.IDLE:
			stop_bounce_animation()

		AIState.WANDERING:
			stop_bounce_animation()

		AIState.SITTING:
			stop_bounce_animation()

		AIState.SLEEPING:
			stop_bounce_animation()

# 开始弹跳动画
func start_bounce_animation() -> void:
	is_bouncing = true
	if happy_tween and happy_tween.is_valid():
		happy_tween.kill()

	happy_tween = create_tween()
	happy_tween.set_loops()
	happy_tween.tween_property(self, "scale", base_scale * 1.08, 0.2)
	happy_tween.tween_property(self, "scale", base_scale * 0.98, 0.2)
	happy_tween.tween_property(self, "scale", base_scale * 1.03, 0.15)
	# 确保弹跳时也保持毛发颜色
	modulate = fur_color

# 停止弹跳动画
func stop_bounce_animation() -> void:
	is_bouncing = false
	if happy_tween and happy_tween.is_valid():
		happy_tween.kill()
	scale = base_scale

# 喂食
func feed(food_type: String = "normal") -> void:
	if is_dead:
		return
	match food_type:
		"normal":
			hunger = min(100, hunger + 30)
		"vegetable":
			hunger = min(100, hunger + 50)
			happiness = min(100, happiness + 5)
		"carrot":
			hunger = min(100, hunger + 70)
			happiness = min(100, happiness + 15)
		"apple":
			hunger = min(100, hunger + 40)
			fur_length = min(100, fur_length + 5)

	start_eating_animation()
	set_state(AIState.HAPPY)
	attribute_changed.emit()

# 喝水
func drink() -> void:
	if is_dead:
		return
	thirst = min(100, thirst + 60)
	happiness = min(100, happiness + 3)

	var drink_tween = create_tween()
	drink_tween.tween_property(self, "scale", base_scale * 1.03, 0.1)
	drink_tween.tween_property(self, "scale", base_scale, 0.1)

	set_state(AIState.HAPPY)
	attribute_changed.emit()

# 抚摸 - 返回获得的金币数
func pet() -> int:
	if is_dead:
		return 0

	happiness = min(100, happiness + 20)

	# 计算连击奖励
	var coins = 0
	if not is_pet_cooldown:
		pet_combo_count += 1

		# 连击奖励：第1次5，第2次8，第3次12，然后立即开始冷却
		match pet_combo_count:
			1:
				coins = 5
			2:
				coins = 8
			3:
				coins = 12
				# 第3次后立即开始冷却
				is_pet_cooldown = true
				pet_cooldown_timer = pet_cooldown_max
				_show_cooldown_ui()

		# 显示连击提示
		if coins > 0:
			_show_combo_text(pet_combo_count, coins)
	else:
		# 冷却中只加快乐值不给金币
		coins = 0

	# 只使用缩放效果，不改变位置避免偏移
	var pet_tween = create_tween()
	pet_tween.tween_property(self, "scale", base_scale * 1.1, 0.1)
	pet_tween.tween_property(self, "scale", base_scale * 0.95, 0.1)
	pet_tween.tween_property(self, "scale", base_scale, 0.1)

	set_state(AIState.HAPPY)
	attribute_changed.emit()

	return coins

# 创建冷却UI
func _create_cooldown_ui() -> void:
	# 冷却时间文本（带背景色）
	cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.custom_minimum_size = Vector2(50, 20)
	cooldown_label.position = Vector2(-25, -55)  # 兔子头顶
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 12)
	cooldown_label.modulate = Color(1, 0.3, 0.3, 1)  # 红色表示冷却中
	cooldown_label.visible = false
	add_child(cooldown_label)

# 显示冷却UI
func _show_cooldown_ui() -> void:
	if cooldown_label:
		cooldown_label.visible = true

# 隐藏冷却UI
func _hide_cooldown_ui() -> void:
	if cooldown_label:
		cooldown_label.visible = false

# 更新冷却UI
func _update_cooldown_ui() -> void:
	if cooldown_label:
		var remaining = int(ceil(pet_cooldown_timer))
		# 根据剩余时间改变颜色
		if remaining > 7:
			cooldown_label.modulate = Color(1, 0.3, 0.3, 1)  # 红色
		elif remaining > 3:
			cooldown_label.modulate = Color(1, 0.8, 0.3, 1)  # 黄色
		else:
			cooldown_label.modulate = Color(0.3, 1, 0.3, 1)  # 绿色

		cooldown_label.text = "⏱️ " + str(remaining) + "s"

# 显示连击文本
func _show_combo_text(combo: int, coins: int) -> void:
	var combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.custom_minimum_size = Vector2(60, 20)
	combo_label.position = Vector2(-30, -70)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 14)

	if combo == 1:
		combo_label.text = "抚摸! +" + str(coins) + "💰"
		combo_label.modulate = Color(1, 1, 0.5)
	elif combo == 2:
		combo_label.text = "连击! +" + str(coins) + "💰"
		combo_label.modulate = Color(1, 0.8, 0.3)
	elif combo == 3:
		combo_label.text = "完美! +" + str(coins) + "💰"
		combo_label.modulate = Color(1, 0.5, 0.2)

	add_child(combo_label)

	# 动画：向上飘动然后消失
	var tween = create_tween()
	tween.tween_property(combo_label, "position:y", combo_label.position.y - 20, 0.5)
	tween.tween_property(combo_label, "modulate:a", 0, 0.3)
	tween.finished.connect(func(): combo_label.queue_free())

# 剃毛
func shave() -> Dictionary:
	if is_dead:
		return {"success": false, "message": "兔子已经去兔星了...", "coins": 0}
	if fur_length < 80:
		return {"success": false, "message": "毛还不够长！", "coins": 0}

	var breed_multiplier: float = 1.0
	match breed:
		"lop_white":
			breed_multiplier = 1.5
		"lop_brown":
			breed_multiplier = 1.2

	var quality: String = "normal"
	var base_value: int = int(15 * breed_multiplier)

	if happiness > 90:
		quality = "perfect"
		base_value = int(60 * breed_multiplier)
	elif happiness > 70:
		quality = "excellent"
		base_value = int(40 * breed_multiplier)
	elif happiness > 50:
		quality = "good"
		base_value = int(25 * breed_multiplier)

	fur_length = 0
	happiness = max(0, happiness - 10)

	# 只使用缩放，不改变位置
	var shave_tween = create_tween()
	shave_tween.tween_property(self, "scale", base_scale * Vector2(0.95, 1.05), 0.08)
	shave_tween.tween_property(self, "scale", base_scale * Vector2(1.05, 0.95), 0.08)
	shave_tween.tween_property(self, "scale", base_scale * Vector2(0.98, 1.02), 0.08)
	shave_tween.tween_property(self, "scale", base_scale, 0.08)

	modulate = fur_color * Color(0.9, 0.9, 1.0)
	var color_tween = create_tween()
	color_tween.tween_property(self, "modulate", fur_color, 0.3)

	attribute_changed.emit()

	var quality_text = ""
	match quality:
		"perfect":
			quality_text = "✨完美品质✨"
		"excellent":
			quality_text = "⭐优秀品质⭐"
		"good":
			quality_text = "👍良好品质👍"
		_:
			quality_text = "普通品质"

	return {
		"success": true,
		"quality": quality,
		"coins": base_value,
		"message": "剃毛成功！" + quality_text + " 获得 " + str(base_value) + " 金币！✂️"
	}

# 进食动画
func start_eating_animation() -> void:
	is_eating = true
	if happy_tween and happy_tween.is_valid():
		happy_tween.kill()

	var eat_tween = create_tween()
	eat_tween.set_loops()
	eat_tween.tween_property(self, "scale", base_scale * Vector2(0.95, 1.05), 0.15)
	eat_tween.tween_property(self, "scale", base_scale, 0.15)

	get_tree().create_timer(0.8).timeout.connect(func():
		is_eating = false
		if eat_tween and eat_tween.is_valid():
			eat_tween.kill()
		scale = base_scale
	)

# 选中
func select() -> void:
	if is_dead:
		return
	is_selected = true

	if select_tween and select_tween.is_valid():
		select_tween.kill()

	select_tween = create_tween()
	select_tween.set_loops()
	select_tween.tween_property(self, "scale", base_scale * 1.08, 0.2)
	select_tween.tween_property(self, "scale", base_scale * 0.98, 0.2)
	select_tween.tween_property(self, "scale", base_scale * 1.03, 0.15)

	# 在原有毛发颜色基础上添加蓝色高亮效果
	modulate = fur_color * Color(1.05, 1.05, 1.15)
	print("Rabbit: 已选中")
	set_state(AIState.HAPPY)

# 取消选中
func deselect() -> void:
	is_selected = false

	if select_tween and select_tween.is_valid():
		select_tween.kill()

	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", base_scale, 0.2)
	modulate = fur_color

	print("Rabbit: 已取消选中")
	if current_state == AIState.HAPPY:
		set_state(AIState.IDLE)

# 获取存档数据
func get_save_data() -> Dictionary:
	return {
		"rabbit_name": rabbit_name,  # 保存兔子名字
		"breed": breed,
		"hunger": hunger,
		"thirst": thirst,
		"happiness": happiness,
		"fur_length": fur_length,
		"health": health,
		"pos_x": position.x,
		"pos_y": position.y,
		"current_state": int(current_state),  # 保存AI状态
		"state_timer": state_timer,  # 保存状态计时器
		"fur_color_r": fur_color.r,  # 保存毛发颜色
		"fur_color_g": fur_color.g,
		"fur_color_b": fur_color.b
	}

# 从存档数据恢复
func load_from_data(data: Dictionary) -> void:
	rabbit_name = data.get("rabbit_name", "")
	breed = data.get("breed", "lop_gray")
	hunger = data.get("hunger", 100.0)
	thirst = data.get("thirst", 100.0)
	happiness = data.get("happiness", 80.0)
	fur_length = data.get("fur_length", 20.0)
	health = data.get("health", 100.0)

	# 恢复毛发颜色
	var r = data.get("fur_color_r", 1.0)
	var g = data.get("fur_color_g", 1.0)
	var b = data.get("fur_color_b", 1.0)
	fur_color = Color(r, g, b)
	modulate = fur_color
	fur_length = data.get("fur_length", 20.0)
	health = data.get("health", 100.0)
	position = Vector2(data.get("pos_x", 380), data.get("pos_y", 200))

	# 恢复AI状态
	var saved_state = data.get("current_state", int(AIState.IDLE))
	current_state = AIState.values()[saved_state]
	state_timer = data.get("state_timer", 1.0)

# ========== 鼠标悬停检测 ==========

# 创建悬停检测区域
func _create_hover_detector() -> void:
	# 创建一个用于检测鼠标的区域
	var hover_area = ColorRect.new()
	hover_area.name = "HoverDetector"
	hover_area.size = Vector2(50, 50)
	hover_area.position = Vector2(-25, -25)
	hover_area.mouse_filter = Control.MOUSE_FILTER_STOP
	hover_area.modulate = Color(0, 0, 0, 0)  # 完全透明
	hover_area.mouse_entered.connect(_on_mouse_entered)
	hover_area.mouse_exited.connect(_on_mouse_exited)
	add_child(hover_area)

# 鼠标进入
func _on_mouse_entered() -> void:
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_method("_show_hover_name"):
		main_node._show_hover_name(rabbit_name, get_global_position())

# 鼠标离开
func _on_mouse_exited() -> void:
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_method("_hide_hover_name"):
		main_node._hide_hover_name()

# ========== 便便系统 ==========

# 重置便便计时器（随机下一次时间）
func _reset_poop_timer() -> void:
	poop_timer = 0.0
	next_poop_time = randf_range(POOP_MIN_INTERVAL, POOP_MAX_INTERVAL)

# 更新便便计时器
func _update_poop_timer(delta: float) -> void:
	# 死亡的兔子不拉便便
	if is_dead:
		return
	# 饱食度太低不拉
	if hunger < 20:
		return
	# 达到上限不拉
	if my_poop_count >= MAX_POOP_PER_RABBIT:
		return

	poop_timer += delta
	if poop_timer >= next_poop_time:
		_create_poop()
		_reset_poop_timer()

# 生成便便
func _create_poop() -> void:
	# 随机位置（脚边附近）
	var offset = Vector2(randf_range(-15, 15), randf_range(10, 25))
	var poop_pos = position + offset

	# 限制在围栏范围内
	poop_pos.x = clamp(poop_pos.x, 20, 740)
	poop_pos.y = clamp(poop_pos.y, 20, 380)

	# 随机是否金色
	var is_golden = randf() < GOLDEN_POOP_CHANCE

	# 计数+1
	my_poop_count += 1

	# 发出信号，由主场景处理显示和交互
	poop_created.emit(poop_pos, is_golden)

	print("[Poop] ", rabbit_name, " 拉了一坨便便，位置:", poop_pos, " 金色:", is_golden)

# 便便被收集时调用（减少计数，允许继续拉）
func on_poop_collected() -> void:
	my_poop_count = max(0, my_poop_count - 1)
