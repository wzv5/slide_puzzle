extends Control

signal back_to_menu

func _ready() -> void:
	# 设置半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建胜利面板
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -203
	panel.offset_right = 203
	panel.offset_top = -225
	panel.offset_bottom = 225
	
	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = GameManager.get_theme_color("bg")
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# 创建内容容器
	var content = VBoxContainer.new()
	content.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	content.offset_left = 20
	content.offset_right = -20
	content.offset_top = 20
	content.offset_bottom = -20
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	
	# 胜利标题
	var victory_label = Label.new()
	victory_label.text = tr("victory")
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 36)
	victory_label.add_theme_color_override("font_color", GameManager.get_theme_color("primary"))
	content.add_child(victory_label)
	
	# 步数显示
	var moves_label = Label.new()
	moves_label.text = tr("moves") + ": " + str(GameManager.move_count)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.add_theme_font_size_override("font_size", 24)
	moves_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	content.add_child(moves_label)
	
	# 时间显示
	var time_label = Label.new()
	time_label.text = tr("time") + ": " + GameManager.format_time(GameManager.game_time)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 24)
	time_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	content.add_child(time_label)
	
	# 返回主菜单按钮
	var menu_button = GameManager.create_styled_button(tr("menu"), 24, 8, 20)
	menu_button.pressed.connect(_on_back_to_menu)
	content.add_child(menu_button)

func _on_back_to_menu() -> void:
	back_to_menu.emit()
	queue_free()
