extends Control

signal back
signal new_level
signal edit_level(level_data: Dictionary)
signal play_level(level_data: Dictionary)
signal import_level(level_data: Dictionary)

var level_list: VBoxContainer
var scroll_container: ScrollContainer
var overlay: Control
var play_mode: bool = false  # true表示游玩模式，false表示编辑模式

var is_dragging: bool = false
var drag_start_position: Vector2
var drag_start_scroll: int
const DRAG_THRESHOLD: float = 10.0

var hovered_button: Button = null

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建标题
	var title = Label.new()
	if play_mode:
		title.text = tr("custom")
	else:
		title.text = tr("custom_level")
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
	
	# 创建关卡列表容器
	scroll_container = ScrollContainer.new()
	scroll_container.anchor_left = 0.1
	scroll_container.anchor_right = 0.9
	scroll_container.anchor_bottom = 1.0
	scroll_container.offset_top = 150
	scroll_container.offset_bottom = -100
	add_child(scroll_container)
	
	level_list = VBoxContainer.new()
	level_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_list.add_theme_constant_override("separation", 10)
	scroll_container.add_child(level_list)
	
	# 创建透明遮罩层覆盖在列表上
	overlay = Control.new()
	overlay.anchor_left = 0.1
	overlay.anchor_right = 0.9
	overlay.anchor_bottom = 1.0
	overlay.offset_top = 150
	overlay.offset_bottom = -100
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_gui_input)
	add_child(overlay)
	
	# 编辑模式下显示导入和新建关卡按钮
	if not play_mode:
		var import_button = GameManager.create_image_button("res://assets/images/btn_import.png")
		import_button.anchor_left = 1.0
		import_button.anchor_right = 1.0
		import_button.anchor_top = 1.0
		import_button.anchor_bottom = 1.0
		import_button.offset_left = -158
		import_button.offset_right = -100
		import_button.offset_top = -82
		import_button.offset_bottom = -24
		import_button.pressed.connect(_on_import_level)
		add_child(import_button)
		
		var new_button = GameManager.create_image_button("res://assets/images/btn_add.png")
		new_button.anchor_left = 1.0
		new_button.anchor_right = 1.0
		new_button.anchor_top = 1.0
		new_button.anchor_bottom = 1.0
		new_button.offset_left = -82
		new_button.offset_right = -24
		new_button.offset_top = -82
		new_button.offset_bottom = -24
		new_button.pressed.connect(_on_new_level)
		add_child(new_button)
	
	# 加载关卡列表
	load_level_list()

func load_level_list() -> void:
	# 清空列表
	for child in level_list.get_children():
		child.queue_free()
	
	# 加载自定义关卡
	GameManager.load_custom_levels()
	
	if GameManager.custom_levels.size() == 0:
		# 显示空列表提示
		var empty_label = Label.new()
		empty_label.text = tr("no_levels")
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_list.add_child(empty_label)
		
		if not play_mode:
			var hint_label = Label.new()
			hint_label.text = tr("no_levels_hint")
			hint_label.add_theme_font_size_override("font_size", 16)
			hint_label.add_theme_color_override("font_color", GameManager.get_theme_color("text").lightened(0.3))
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			level_list.add_child(hint_label)
	else:
		# 显示关卡列表
		for i in range(GameManager.custom_levels.size()):
			var level = GameManager.custom_levels[i]
			create_level_item(level, i)

func create_level_item(level_data: Dictionary, index: int) -> void:
	var item_container = HBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_list.add_child(item_container)
	
	# 关卡名称按钮
	var name_button = Button.new()
	name_button.text = level_data.name
	name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_button.add_theme_font_size_override("font_size", 24)
	name_button.add_theme_color_override("font_color", GameManager.get_theme_color("button_text"))
	name_button.add_theme_color_override("font_hover_color", GameManager.get_theme_color("button_text"))
	name_button.add_theme_color_override("font_pressed_color", GameManager.get_theme_color("button_text"))
	
	# 设置按钮样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = GameManager.get_theme_color("button")
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 12
	normal_style.content_margin_bottom = 12
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = GameManager.get_theme_color("button_hover")
	
	name_button.add_theme_stylebox_override("normal", normal_style)
	name_button.add_theme_stylebox_override("hover", hover_style)
	name_button.add_theme_stylebox_override("pressed", hover_style)
	name_button.set_meta("original_normal_color", normal_style.bg_color)
	name_button.set_meta("hover_color", hover_style.bg_color)
	
	# 根据模式连接不同的回调
	if play_mode:
		name_button.pressed.connect(_on_play_level.bind(level_data))
	else:
		name_button.pressed.connect(_on_edit_level.bind(level_data))
	item_container.add_child(name_button)
	
	# 编辑模式下显示导出和删除按钮
	if not play_mode:
		# 导出按钮
		var export_button = GameManager.create_image_button("res://assets/images/btn_share.png", Vector2(48, 48))
		export_button.set_meta("original_normal_color", Color(0.2, 0.7, 0.3))
		export_button.set_meta("hover_color", Color(0.3, 0.8, 0.4))
		
		# 设置导出按钮样式
		var export_style = normal_style.duplicate()
		export_style.bg_color = Color(0.2, 0.7, 0.3)
		export_style.content_margin_left = 6
		export_style.content_margin_right = 6
		export_style.content_margin_top = 6
		export_style.content_margin_bottom = 6
		
		var export_hover_style = export_style.duplicate()
		export_hover_style.bg_color = Color(0.3, 0.8, 0.4)
		
		export_button.add_theme_stylebox_override("normal", export_style)
		export_button.add_theme_stylebox_override("hover", export_hover_style)
		export_button.add_theme_stylebox_override("pressed", export_hover_style)
		
		export_button.pressed.connect(_on_export_level.bind(level_data))
		item_container.add_child(export_button)
		
		# 删除按钮
		var delete_button = GameManager.create_image_button("res://assets/images/btn_delete.png", Vector2(48, 48))
		delete_button.set_meta("original_normal_color", Color(0.8, 0.2, 0.2))
		delete_button.set_meta("hover_color", Color(0.9, 0.3, 0.3))
		
		# 设置删除按钮样式
		var delete_style = normal_style.duplicate()
		delete_style.bg_color = Color(0.8, 0.2, 0.2)
		delete_style.content_margin_left = 6
		delete_style.content_margin_right = 6
		delete_style.content_margin_top = 6
		delete_style.content_margin_bottom = 6
		
		var delete_hover_style = delete_style.duplicate()
		delete_hover_style.bg_color = Color(0.9, 0.3, 0.3)
		
		delete_button.add_theme_stylebox_override("normal", delete_style)
		delete_button.add_theme_stylebox_override("hover", delete_hover_style)
		delete_button.add_theme_stylebox_override("pressed", delete_hover_style)
		
		delete_button.pressed.connect(_on_delete_level.bind(index))
		item_container.add_child(delete_button)

func _on_back() -> void:
	back.emit()

func _on_new_level() -> void:
	new_level.emit()

func _on_edit_level(level_data: Dictionary) -> void:
	edit_level.emit(level_data)

func _on_play_level(level_data: Dictionary) -> void:
	play_level.emit(level_data)

func _on_delete_level(index: int) -> void:
	# 显示确认对话框
	GameManager.show_confirm(tr("delete_confirm"), _on_delete_confirmed.bind(index))

func _on_delete_confirmed(index: int) -> void:
	GameManager.delete_custom_level(index)
	load_level_list()

func _on_export_level(level_data: Dictionary) -> void:
	# 序列化关卡数据为 JSON 字符串
	var json_string = JSON.stringify(level_data)
	# 编码为 base64
	var base64_string = Marshalls.utf8_to_base64(json_string)
	# 写入剪切板
	DisplayServer.clipboard_set(base64_string)
	# 显示消息对话框
	GameManager.show_message(tr("export_success"), self)

func _on_import_level() -> void:
	# 读取剪切板
	var clipboard_content = DisplayServer.clipboard_get()
	
	# 尝试解码 base64
	var json_string = Marshalls.base64_to_utf8(clipboard_content)
	if json_string == "":
		GameManager.show_message(tr("import_failed"), self)
		return
	
	# 解析 JSON
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		GameManager.show_message(tr("import_failed"), self)
		return
	
	var level_data = json.data
	
	# 验证数据格式
	if not level_data is Dictionary:
		GameManager.show_message(tr("import_failed"), self)
		return
	if not level_data.has("name") or not level_data.has("width") or not level_data.has("height") or not level_data.has("grid"):
		GameManager.show_message(tr("import_failed"), self)
		return
	
	# 确保关卡名称不重复
	var original_name = level_data.name
	var counter = 1
	while true:
		var name_exists = false
		for level in GameManager.custom_levels:
			if level.name == level_data.name:
				name_exists = true
				break
		if not name_exists:
			break
		counter += 1
		level_data.name = original_name + " (" + str(counter) + ")"
	
	# 添加关卡
	GameManager.add_custom_level(level_data)
	
	# 刷新列表
	load_level_list()
	
	# 进入编辑模式
	import_level.emit(level_data)

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = false
				drag_start_position = event.position
				drag_start_scroll = scroll_container.scroll_vertical
			else:
				if is_dragging:
					accept_event()
				else:
					accept_event()
					_handle_click()
				is_dragging = false
	elif event is InputEventMouseMotion:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_update_hover_state()
		elif event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var distance = drag_start_position.distance_to(event.position)
			if distance > DRAG_THRESHOLD:
				is_dragging = true
				var new_scroll = drag_start_scroll - int(event.position.y - drag_start_position.y)
				scroll_container.scroll_vertical = max(0, new_scroll)
				accept_event()

func _update_hover_state() -> void:
	var mouse_pos = get_global_mouse_position()
	var new_hovered: Button = null
	
	for item_container in level_list.get_children():
		if item_container is HBoxContainer:
			for button in item_container.get_children():
				if button is Button:
					var button_rect = button.get_global_rect()
					if button_rect.has_point(mouse_pos):
						new_hovered = button
						break
			if new_hovered:
				break
	
	if new_hovered != hovered_button:
		if hovered_button:
			var normal_style = hovered_button.get_theme_stylebox("normal").duplicate()
			if normal_style is StyleBoxFlat:
				normal_style.bg_color = hovered_button.get_meta("original_normal_color")
				hovered_button.add_theme_stylebox_override("normal", normal_style)
		if new_hovered:
			var normal_style = new_hovered.get_theme_stylebox("normal").duplicate()
			if normal_style is StyleBoxFlat:
				normal_style.bg_color = new_hovered.get_meta("hover_color")
				new_hovered.add_theme_stylebox_override("normal", normal_style)
		hovered_button = new_hovered

func _handle_click() -> void:
	var mouse_pos = get_global_mouse_position()
	
	# 遍历所有列表项，找到鼠标位置下的按钮并触发点击
	for item_container in level_list.get_children():
		if item_container is HBoxContainer:
			for button in item_container.get_children():
				if button is Button:
					var button_rect = button.get_global_rect()
					if button_rect.has_point(mouse_pos):
						button.pressed.emit()
						return
