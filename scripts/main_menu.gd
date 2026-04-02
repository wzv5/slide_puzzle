extends Control

signal start_game
signal custom_levels
signal settings
signal about
signal exit_game
signal language_changed

# 支持的语言列表
const LANGUAGES = [
	{"code": "en", "name": "English", "button": "EN"},
	{"code": "zh_CN", "name": "简体中文", "button": "中"},
	{"code": "zh_TW", "name": "繁體中文", "button": "繁"},
	{"code": "ja", "name": "日本語", "button": "日"},
	{"code": "ko", "name": "한국어", "button": "한"}
]

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建标题
	var title = Label.new()
	title.text = "Slide Puzzle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", GameManager.get_theme_color("primary"))
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -270
	title.offset_right = 270
	title.offset_top = 120
	title.offset_bottom = 225
	add_child(title)
	
	# 创建按钮
	var button_container = VBoxContainer.new()
	button_container.anchor_left = 0.5
	button_container.anchor_right = 0.5
	button_container.offset_left = -203
	button_container.offset_right = 203
	button_container.offset_top = 300
	button_container.offset_bottom = 825
	button_container.add_theme_constant_override("separation", 20)
	add_child(button_container)
	
	# 创建按钮
	for data in [
		[tr("start_game"), _on_start_game],
		[tr("custom_level"), _on_custom_levels],
		[tr("settings"), _on_settings],
		[tr("about"), _on_about],
		[tr("exit"), _on_exit_game]
	]:
		var button = GameManager.create_styled_button(data[0], 24, 8, 20)
		button.pressed.connect(data[1])
		button_container.add_child(button)
	
	# 创建语言切换按钮
	var language_button = GameManager.create_image_button("res://assets/images/btn_language.png")
	language_button.anchor_top = 1.0
	language_button.anchor_bottom = 1.0
	language_button.offset_left = 20
	language_button.offset_right = 78
	language_button.offset_top = -78
	language_button.offset_bottom = -20
	language_button.pressed.connect(_on_language_toggle)
	add_child(language_button)

func get_current_language_index() -> int:
	var current_locale = TranslationServer.get_locale()
	for i in range(LANGUAGES.size()):
		if LANGUAGES[i].code == current_locale:
			return i
	# 如果没有完全匹配，尝试前缀匹配
	for i in range(LANGUAGES.size()):
		if current_locale.begins_with(LANGUAGES[i].code):
			return i
	return 0

func get_next_language_button_text() -> String:
	var current_index = get_current_language_index()
	var next_index = (current_index + 1) % LANGUAGES.size()
	return LANGUAGES[next_index].button

func _on_start_game() -> void:
	start_game.emit()

func _on_custom_levels() -> void:
	custom_levels.emit()

func _on_settings() -> void:
	settings.emit()

func _on_about() -> void:
	about.emit()

func _on_exit_game() -> void:
	# 显示确认对话框
	GameManager.show_confirm(tr("exit_confirm"), _confirm_exit)

func _confirm_exit() -> void:
	exit_game.emit()

func _on_language_toggle() -> void:
	var current_index = get_current_language_index()
	var next_index = (current_index + 1) % LANGUAGES.size()
	TranslationServer.set_locale(LANGUAGES[next_index].code)
	
	# 发出信号让主场景重新显示主菜单（不重新播放音乐）
	language_changed.emit()
