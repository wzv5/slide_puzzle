extends Control

var confirm_callback: Callable
var cancel_callback: Callable

func _ready() -> void:
	GameManager.current_dialog = self
	GameManager.current_dialog_type = GameManager.DialogType.CONFIRM

func on_ui_cancel() -> void:
	_on_cancel()

func on_ui_accept() -> void:
	_on_confirm()

func show_dialog(message: String, on_confirm: Callable, on_cancel: Callable) -> void:
	confirm_callback = on_confirm
	cancel_callback = on_cancel
	
	# 设置半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建对话框面板
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -203
	panel.offset_right = 203
	panel.offset_top = -150
	panel.offset_bottom = 150
	
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
	
	# 消息标签
	var message_label = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(message_label)
	
	# 按钮容器
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 50)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(button_container)
	
	# 确认按钮
	var confirm_button = GameManager.create_image_button("res://assets/images/btn_ok.png", Vector2(120, 50))
	confirm_button.pressed.connect(_on_confirm)
	button_container.add_child(confirm_button)
	
	# 取消按钮
	var cancel_button = GameManager.create_image_button("res://assets/images/btn_cancel.png", Vector2(120, 50))
	cancel_button.pressed.connect(_on_cancel)
	button_container.add_child(cancel_button)

	cancel_button.grab_focus(true)

func _on_confirm() -> void:
	var callback = confirm_callback
	GameManager.current_dialog = null
	GameManager.current_dialog_type = GameManager.DialogType.NONE
	queue_free()
	if callback:
		callback.call()

func _on_cancel() -> void:
	var callback = cancel_callback
	GameManager.current_dialog = null
	GameManager.current_dialog_type = GameManager.DialogType.NONE
	queue_free()
	if callback:
		callback.call()
