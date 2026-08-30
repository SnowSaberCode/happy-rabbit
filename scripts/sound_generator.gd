extends Node
# 简单的音效生成器

# 生成简单的哔哔声
static func generate_beep(freq: float = 440.0, duration: float = 0.1, volume: float = 0.3) -> AudioStreamWAV:
	var rate = 44100
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var sample = sin(t * freq * PI * 2) * 32767.0 * volume
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成点击音效 - 清脆的点击
static func generate_click() -> AudioStreamWAV:
	return generate_beep(1000.0, 0.06, 0.2)

# 生成喂食音效 - 清脆的吃东西声
static func generate_eat() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.15
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		# 高频的咔嚓声
		var freq = 800.0 + t * 600.0
		var envelope = 1.0
		if t < 0.02:
			envelope = t / 0.02
		elif t > 0.1:
			envelope = (duration - t) / 0.05

		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.2 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成喝水音效 - 清脆的水滴声
static func generate_drink() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.12
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		# 上升的水滴音调
		var freq = 1500.0 + t * 1000.0
		var envelope = exp(-t * 15.0)
		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.18 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成抚摸音效 - 柔和的啾啾声
static func generate_pet() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.18
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var freq = 600.0 + sin(t * 15.0) * 200.0
		var envelope = 1.0
		if t < 0.03:
			envelope = t / 0.03
		elif t > duration - 0.03:
			envelope = (duration - t) / 0.03

		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.18 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成剃毛音效 - 清脆的咔嚓
static func generate_shave() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.15
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var freq = 2000.0
		var envelope = 1.0
		if t < 0.02:
			envelope = t / 0.02
		elif t > 0.08:
			envelope = exp(-(t - 0.08) * 20.0)

		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.15 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成金币音效 - 清脆的叮
static func generate_coin() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.2
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var freq = 1800.0
		var envelope = exp(-t * 8.0)
		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.2 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成开心叫声 - 可爱的啾啾
static func generate_happy() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.2
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var freq = 1200.0 + sin(t * 12.0) * 300.0
		var envelope = 1.0
		if t < 0.03:
			envelope = t / 0.03
		elif t > duration - 0.05:
			envelope = (duration - t) / 0.05

		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.18 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成购买成功音效 - 愉悦的双音
static func generate_buy() -> AudioStreamWAV:
	var rate = 44100
	var duration = 0.18
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var freq = 784.0  # G5
		if t > 0.09:
			freq = 1046.5  # C6

		var envelope = exp(-max(0, t - 0.02) * 8.0)
		var sample = sin(t * freq * PI * 2) * 32767.0 * 0.2 * envelope
		var sample_int = int(clamp(sample, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav

# 生成背景音乐 - 轻快的C大调旋律
static func generate_bgm() -> AudioStreamWAV:
	var rate = 44100
	var duration = 6.0
	var sample_count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	# 简单可爱的旋律
	var melody = [
		523.25, 659.25, 783.99, 659.25,  # C5 E5 G5 E5
		523.25, 587.33, 659.25, 523.25,  # C5 D5 E5 C5
		392.00, 523.25, 587.33, 523.25,  # G4 C5 D5 C5
		349.23, 440.00, 523.25, 440.00,  # F4 A4 C5 A4
		523.25, 659.25, 783.99, 880.00,  # C5 E5 G5 A5
		783.99, 659.25, 523.25, 587.33,  # G5 E5 C5 D5
		392.00, 523.25, 587.33, 523.25,  # G4 C5 D5 C5
		349.23, 392.00, 261.63, 392.00   # F4 G4 C4 G4
	]

	var bass = [
		261.63, 261.63, 196.00, 196.00,
		220.00, 220.00, 174.61, 174.61,
		196.00, 196.00, 174.61, 174.61,
		130.81, 130.81, 196.00, 196.00,
		261.63, 261.63, 196.00, 196.00,
		220.00, 220.00, 261.63, 261.63,
		196.00, 196.00, 174.61, 174.61,
		130.81, 130.81, 196.00, 196.00
	]

	for i in range(sample_count):
		var t = float(i) / float(rate)
		var beat_duration = 0.25
		var beat = int(t / beat_duration)
		var note_t = fmod(t, beat_duration)

		# 主旋律
		var melody_freq = melody[beat % melody.size()]
		var melody_sample = sin(t * melody_freq * PI * 2)

		# 低音
		var bass_freq = bass[beat % bass.size()]
		var bass_sample = sin(t * bass_freq * PI * 2) * 0.35

		# 包络
		var envelope = 1.0
		if note_t < 0.05:
			envelope = note_t / 0.05
		elif note_t > beat_duration - 0.1:
			envelope = (beat_duration - note_t) / 0.1

		var total_sample = (melody_sample * 0.4 + bass_sample) * envelope
		var final_sample = total_sample * 32767.0 * 0.2
		var sample_int = int(clamp(final_sample, -32768, 32767))

		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav
