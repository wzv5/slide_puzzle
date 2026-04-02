extends Control

signal back
signal select_difficulty(grid_size: Vector2i)
signal custom_levels

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建标题
	var title = Label.new()
	title.text = tr("difficulty")
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
	
	# 创建按钮容器
	var button_container = VBoxContainer.new()
	button_container.anchor_left = 0.5
	button_container.anchor_right = 0.5
	button_container.offset_left = -203
	button_container.offset_right = 203
	button_container.offset_top = 225
	button_container.offset_bottom = 750
	button_container.add_theme_constant_override("separation", 20)
	add_child(button_container)
	
	# 创建难度按钮
	for data in [
		[tr("3x3"), _on_3x3],
		[tr("4x4"), _on_4x4],
		[tr("5x5"), _on_5x5],
		[tr("custom"), _on_custom]
	]:
		var button = GameManager.create_styled_button(data[0], 24, 8, 20)
		button.pressed.connect(data[1])
		button_container.add_child(button)

func _on_back() -> void:
	back.emit()

func _on_3x3() -> void:
	select_difficulty.emit(Vector2i(3, 3))

func _on_4x4() -> void:
	select_difficulty.emit(Vector2i(4, 4))

func _on_5x5() -> void:
	select_difficulty.emit(Vector2i(5, 5))

func _on_custom() -> void:
	# 跳转到自定义关卡选择界面
	custom_levels.emit()
