extends Control

signal back

var save_callback: Callable

var name_input: LineEdit
var width_label: Label
var height_label: Label
var board_container: Control
var cells: Array = []
var current_width: int = 4
var current_height: int = 4
var current_name: String = ""

var has_changes: bool = false
var original_data: Dictionary = {}

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建标题
	var title = Label.new()
	title.text = tr("new_level")
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
	
	# 创建设置容器
	var settings_container = VBoxContainer.new()
	settings_container.anchor_left = 0.1
	settings_container.anchor_right = 0.9
	settings_container.offset_top = 130
	settings_container.offset_bottom = 340
	settings_container.add_theme_constant_override("separation", 15)
	add_child(settings_container)
	
	# 关卡名称输入
	var name_container = HBoxContainer.new()
	settings_container.add_child(name_container)
	
	var name_label = Label.new()
	name_label.text = tr("level_name") + ":"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	name_label.custom_minimum_size = Vector2(120, 30)
	name_container.add_child(name_label)
	
	name_input = LineEdit.new()
	name_input.text = current_name
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.add_theme_font_size_override("font_size", 20)
	name_input.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	name_input.text_changed.connect(_on_name_changed)
	name_container.add_child(name_input)
	
	# 宽度设置
	var width_container = HBoxContainer.new()
	settings_container.add_child(width_container)
	
	var width_title = Label.new()
	width_title.text = tr("width") + ":"
	width_title.add_theme_font_size_override("font_size", 20)
	width_title.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	width_title.custom_minimum_size = Vector2(120, 30)
	width_container.add_child(width_title)
	
	var width_minus = GameManager.create_styled_button("-")
	width_minus.custom_minimum_size = Vector2(40, 40)
	width_minus.pressed.connect(_on_width_minus)
	width_container.add_child(width_minus)
	
	width_label = Label.new()
	width_label.text = str(current_width)
	width_label.add_theme_font_size_override("font_size", 24)
	width_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	width_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	width_label.custom_minimum_size = Vector2(50, 40)
	width_container.add_child(width_label)
	
	var width_plus = GameManager.create_styled_button("+")
	width_plus.custom_minimum_size = Vector2(40, 40)
	width_plus.pressed.connect(_on_width_plus)
	width_container.add_child(width_plus)
	
	# 高度设置
	var height_container = HBoxContainer.new()
	settings_container.add_child(height_container)
	
	var height_title = Label.new()
	height_title.text = tr("height") + ":"
	height_title.add_theme_font_size_override("font_size", 20)
	height_title.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	height_title.custom_minimum_size = Vector2(120, 30)
	height_container.add_child(height_title)
	
	var height_minus = GameManager.create_styled_button("-")
	height_minus.custom_minimum_size = Vector2(40, 40)
	height_minus.pressed.connect(_on_height_minus)
	height_container.add_child(height_minus)
	
	height_label = Label.new()
	height_label.text = str(current_height)
	height_label.add_theme_font_size_override("font_size", 24)
	height_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	height_label.custom_minimum_size = Vector2(50, 40)
	height_container.add_child(height_label)
	
	var height_plus = GameManager.create_styled_button("+")
	height_plus.custom_minimum_size = Vector2(40, 40)
	height_plus.pressed.connect(_on_height_plus)
	height_container.add_child(height_plus)
	
	# 创建棋盘容器
	board_container = Control.new()
	board_container.anchor_left = 0.5
	board_container.anchor_right = 0.5
	board_container.anchor_top = 0.5
	board_container.anchor_bottom = 0.5
	add_child(board_container)
	
	# 创建棋盘
	update_board()

func load_level(level_data: Dictionary) -> void:
	current_name = level_data.name
	current_width = level_data.width
	current_height = level_data.height
	
	if name_input:
		name_input.text = current_name
		width_label.text = str(current_width)
		height_label.text = str(current_height)
		update_board()
		
		# 加载网格数据
		if level_data.has("grid"):
			for y in range(min(current_height, level_data.grid.size())):
				for x in range(min(current_width, level_data.grid[y].size())):
					if y < cells.size() and x < cells[y].size():
						cells[y][x].set_meta("is_wall", level_data.grid[y][x] == 0)
						update_cell_style(cells[y][x])
	
	# 保存原始数据用于比较
	original_data = {
		"name": current_name,
		"width": current_width,
		"height": current_height,
		"grid": get_grid_data()
	}
	has_changes = false

func update_board() -> void:
	# 清空棋盘
	for child in board_container.get_children():
		child.queue_free()
	cells.clear()
	
	# 计算棋盘大小和位置
	var max_board_width = 513
	var max_board_height = 600
	var cell_size = Vector2(
		min(max_board_width / float(current_width), 60),
		min(max_board_height / float(current_height), 60)
	)
	
	var board_pixel_width = cell_size.x * current_width
	var board_pixel_height = cell_size.y * current_height
	
	board_container.offset_left = -board_pixel_width / 2
	board_container.offset_right = board_pixel_width / 2
	board_container.offset_top = -board_pixel_height / 2 + 150
	board_container.offset_bottom = board_pixel_height / 2 + 150
	
	# 创建格子
	for y in range(current_height):
		var row = []
		for x in range(current_width):
			var cell = create_cell(x, y, cell_size)
			row.append(cell)
			board_container.add_child(cell)
		cells.append(row)

func create_cell(x: int, y: int, cell_size: Vector2) -> Control:
	var cell = Panel.new()
	cell.size = cell_size
	cell.position = Vector2(x * cell_size.x, y * cell_size.y)
	
	# 默认不是墙壁
	cell.set_meta("is_wall", false)
	cell.set_meta("grid_x", x)
	cell.set_meta("grid_y", y)
	
	# 设置样式
	update_cell_style(cell)
	
	# 连接点击信号
	cell.gui_input.connect(_on_cell_input.bind(cell))
	
	return cell

func update_cell_style(cell: Control) -> void:
	var is_wall = cell.get_meta("is_wall")
	
	var style = StyleBoxFlat.new()
	if is_wall:
		style.bg_color = GameManager.get_theme_color("wall")
	else:
		style.bg_color = GameManager.get_theme_color("tile")
	
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = GameManager.get_theme_color("text").darkened(0.5)
	
	cell.add_theme_stylebox_override("panel", style)

func _on_cell_input(event: InputEvent, cell: Control) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var is_wall = cell.get_meta("is_wall")
		cell.set_meta("is_wall", not is_wall)
		update_cell_style(cell)
		has_changes = true

func _on_width_minus() -> void:
	if current_width > 2:
		current_width -= 1
		width_label.text = str(current_width)
		update_board()
		has_changes = true

func _on_width_plus() -> void:
	if current_width < 10:
		current_width += 1
		width_label.text = str(current_width)
		update_board()
		has_changes = true

func _on_height_minus() -> void:
	if current_height > 2:
		current_height -= 1
		height_label.text = str(current_height)
		update_board()
		has_changes = true

func _on_height_plus() -> void:
	if current_height < 10:
		current_height += 1
		height_label.text = str(current_height)
		update_board()
		has_changes = true

func get_grid_data() -> Array:
	var grid_data = []
	for y in range(current_height):
		var row = []
		for x in range(current_width):
			if cells.size() > y and cells[y].size() > x:
				if cells[y][x].get_meta("is_wall"):
					row.append(0)
				else:
					row.append(1)
			else:
				row.append(1)
		grid_data.append(row)
	return grid_data

func _on_save() -> bool:
	# 收集网格数据
	var grid_data = []
	for y in range(current_height):
		var row = []
		for x in range(current_width):
			if cells[y][x].get_meta("is_wall"):
				row.append(0)
			else:
				row.append(1)
		grid_data.append(row)
	
	var level_data = {
		"name": name_input.text,
		"width": current_width,
		"height": current_height,
		"grid": grid_data
	}
	
	if save_callback.is_valid():
		return save_callback.call(level_data)
	return false

func _on_back() -> void:
	# 检查是否有修改
	if not has_changes and name_input.text == original_data.get("name", ""):
		back.emit()
		return
	
	# 显示确认对话框
	GameManager.show_confirm(tr("save_level"), _on_save_and_back, _on_cancel_back)

func _on_save_and_back() -> void:
	if _on_save():
		back.emit()

func _on_cancel_back() -> void:
	back.emit()

func _on_name_changed(new_text: String) -> void:
	has_changes = true
