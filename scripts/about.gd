extends Control

signal back

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建标题
	var title = Label.new()
	title.text = tr("about")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GameManager.get_theme_color("primary"))
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -270
	title.offset_right = 270
	title.offset_top = 45
	title.offset_bottom = 120
	add_child(title)
	
	# 创建返回按钮
	var back_button = GameManager.create_image_button("res://assets/images/btn_back.png")
	back_button.anchor_left = 1.0
	back_button.anchor_right = 1.0
	back_button.anchor_top = 0.0
	back_button.anchor_bottom = 0.0
	back_button.offset_left = -68
	back_button.offset_right = -10
	back_button.offset_top = 10
	back_button.offset_bottom = 68
	back_button.pressed.connect(_on_back)
	add_child(back_button)
	
	# 创建关于文本
	var about_text = Label.new()
	about_text.text = tr("about_text")
	about_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	about_text.add_theme_font_size_override("font_size", 20)
	about_text.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	about_text.anchor_left = 0.1
	about_text.anchor_right = 0.9
	about_text.offset_top = 225
	about_text.offset_bottom = 750
	about_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(about_text)

func _on_back() -> void:
	back.emit()
