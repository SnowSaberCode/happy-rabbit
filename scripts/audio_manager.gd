extends Node
# 音效管理器 - 全局单例

# 音效播放器
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

# 音效资源缓存
var sound_cache: Dictionary = {}

func _ready():
	# 创建音效播放器
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)

	# 创建音乐播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.volume_db = -10.0  # 音乐稍小一点
	add_child(bgm_player)

	# 生成所有需要的音效
	generate_all_sounds()

	print("AudioManager: 音效系统初始化完成")

	# 开始播放背景音乐
	play_bgm()

# 生成所有音效
func generate_all_sounds() -> void:
	sound_cache["click"] = SoundGenerator.generate_click()
	sound_cache["eat1"] = SoundGenerator.generate_eat()
	sound_cache["eat2"] = SoundGenerator.generate_beep(650.0, 0.12, 0.2)
	sound_cache["drink"] = SoundGenerator.generate_drink()
	sound_cache["pet1"] = SoundGenerator.generate_pet()
	sound_cache["pet2"] = SoundGenerator.generate_beep(550.0, 0.12, 0.25)
	sound_cache["pet3"] = SoundGenerator.generate_beep(450.0, 0.18, 0.2)
	sound_cache["shave"] = SoundGenerator.generate_shave()
	sound_cache["coin1"] = SoundGenerator.generate_coin()
	sound_cache["coin2"] = SoundGenerator.generate_beep(1200.0, 0.08, 0.2)
	sound_cache["happy1"] = SoundGenerator.generate_happy()
	sound_cache["happy2"] = SoundGenerator.generate_beep(1800.0, 0.15, 0.2)
	sound_cache["buy"] = SoundGenerator.generate_buy()
	sound_cache["notice"] = SoundGenerator.generate_beep(880.0, 0.1, 0.25)
	sound_cache["cooldown"] = SoundGenerator.generate_beep(200.0, 0.15, 0.1)  # 低频冷却提示音
	sound_cache["bgm"] = SoundGenerator.generate_bgm()

	print("AudioManager: ", sound_cache.size(), " 个音效已生成")

# 播放音效
func play_sfx(sound_name: String) -> void:
	var stream = sound_cache.get(sound_name, null)
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
	else:
		print("AudioManager: 找不到音效 ", sound_name)

# 播放随机音效（多个变体）
func play_sfx_random(sound_names: Array) -> void:
	if sound_names.size() > 0:
		var choice = randi() % sound_names.size()
		play_sfx(sound_names[choice])

# 播放背景音乐
func play_bgm() -> void:
	var stream = sound_cache.get("bgm", null)
	if stream:
		bgm_player.stream = stream
		bgm_player.finished.connect(_on_bgm_finished)
		bgm_player.play()
		print("AudioManager: 背景音乐开始播放")

# 背景音乐循环
func _on_bgm_finished() -> void:
	bgm_player.play()

# 播放点击UI音效
func play_click() -> void:
	play_sfx("click")

# 播放喂食音效
func play_feed() -> void:
	play_sfx_random(["eat1", "eat2"])

# 播放喝水音效
func play_drink() -> void:
	play_sfx("drink")

# 播放抚摸音效
func play_pet() -> void:
	play_sfx_random(["pet1", "pet2", "pet3"])

# 播放剃毛音效
func play_shave() -> void:
	play_sfx("shave")

# 播放金币音效
func play_coin() -> void:
	play_sfx_random(["coin1", "coin2"])

# 播放兔子开心叫声
func play_happy() -> void:
	play_sfx_random(["happy1", "happy2"])

# 播放购买成功音效
func play_buy() -> void:
	play_sfx("buy")

# 播放提示音效
func play_notice() -> void:
	play_sfx("notice")

# 播放冷却提示音效
func play_cooldown() -> void:
	play_sfx("cooldown")
