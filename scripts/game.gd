extends Control

signal pause
signal victory

var moves_label: Label
var time_label: Label
var board_container: Control
var tiles: Array = []
var tile_size: Vector2
var cell_gap: float = 4.0
var animation_duration: float = 0.15
var move_sfx: AudioStream = preload("res://assets/sounds/move.ogg")
var is_animating: bool = false

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建顶部信息栏
	var top_bar = HBoxContainer.new()
	top_bar.anchor_left = 0.05
	top_bar.anchor_right = 0.95
	top_bar.offset_top = 15
	top_bar.offset_bottom = 75
	add_child(top_bar)
	
	# 步数标签
	moves_label = Label.new()
	moves_label.text = tr("moves") + ": " + str(GameManager.move_count)
	moves_label.add_theme_font_size_override("font_size", 24)
	moves_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	moves_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(moves_label)
	
	# 时间标签
	time_label = Label.new()
	time_label.text = tr("time") + ": " + GameManager.format_time(GameManager.game_time)
	time_label.add_theme_font_size_override("font_size", 24)
	time_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(time_label)
	
	# 暂停按钮
	var pause_button = GameManager.create_image_button("res://assets/images/btn_pause.png")
	pause_button.custom_minimum_size = Vector2(58, 58)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause_button.pressed.connect(_on_pause)
	top_bar.add_child(pause_button)
	
	# 创建棋盘容器
	board_container = Control.new()
	board_container.anchor_left = 0.5
	board_container.anchor_right = 0.5
	board_container.anchor_top = 0.5
	board_container.anchor_bottom = 0.5
	add_child(board_container)
	
	# 创建棋盘
	create_board()
	
	# 更新显示
	update_display()

func _process(_delta: float) -> void:
	if GameManager.is_timer_running:
		time_label.text = tr("time") + ": " + GameManager.format_time(GameManager.game_time)

func _input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if is_animating:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				move_empty(0, 1)
			KEY_DOWN, KEY_S:
				move_empty(0, -1)
			KEY_LEFT, KEY_A:
				move_empty(1, 0)
			KEY_RIGHT, KEY_D:
				move_empty(-1, 0)

func create_board() -> void:
	for child in board_container.get_children():
		child.queue_free()
	tiles.clear()
	
	var board_width = GameManager.current_grid_size.x
	var board_height = GameManager.current_grid_size.y
	
	var playable_cells: Array[Vector2i] = []
	for y in range(board_height):
		for x in range(board_width):
			var cell_value = GameManager.current_grid[y][x]
			if cell_value != 0:
				playable_cells.append(Vector2i(x, y))
	
	if playable_cells.size() == 0:
		return
	
	var playable_set: Dictionary = {}
	for cell in playable_cells:
		playable_set[cell] = true
	
	var min_x = board_width
	var max_x = 0
	var min_y = board_height
	var max_y = 0
	for cell in playable_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	var playable_width = max_x - min_x + 1
	var playable_height = max_y - min_y + 1
	
	var margin_x = 14
	var margin_top = 90
	var margin_bottom = 30
	var available_width = 540 - margin_x * 2
	var available_height = 960 - margin_top - margin_bottom
	var gap_total_w = cell_gap * (playable_width - 1)
	var gap_total_h = cell_gap * (playable_height - 1)
	var tile_w = (available_width - gap_total_w) / float(playable_width)
	var tile_h = (available_height - gap_total_h) / float(playable_height)
	tile_size = Vector2(min(tile_w, tile_h), min(tile_w, tile_h))
	
	var board_pixel_width = tile_size.x * playable_width + gap_total_w
	var board_pixel_height = tile_size.y * playable_height + gap_total_h
	
	var available_center_offset = (margin_top - margin_bottom) / 2.0
	board_container.size = Vector2(board_pixel_width, board_pixel_height)
	board_container.offset_left = -board_pixel_width / 2
	board_container.offset_right = board_pixel_width / 2
	board_container.offset_top = -board_pixel_height / 2 + available_center_offset
	board_container.offset_bottom = board_pixel_height / 2 + available_center_offset
	
	for cell in playable_cells:
		var cell_bg = create_cell_bg(cell.x, cell.y, playable_set, tile_size, cell_gap)
		board_container.add_child(cell_bg)
	
	var offset_x = -min_x * (tile_size.x + cell_gap)
	var offset_y = -min_y * (tile_size.y + cell_gap)
	
	for y in range(board_height):
		for x in range(board_width):
			var cell_value = GameManager.current_grid[y][x]
			if cell_value == 0 or cell_value == 1:
				continue
			var tile = create_tile(cell_value - 10, x, y)
			tile.position.x += offset_x
			tile.position.y += offset_y
			tiles.append(tile)
			board_container.add_child(tile)

func create_cell_bg(x: int, y: int, playable_set: Dictionary, t_size: Vector2, gap: float) -> Panel:
	var has_left = playable_set.has(Vector2i(x - 1, y))
	var has_right = playable_set.has(Vector2i(x + 1, y))
	var has_up = playable_set.has(Vector2i(x, y - 1))
	var has_down = playable_set.has(Vector2i(x, y + 1))
	
	var expand = gap / 2.0 + 4.0
	var bg_size = Vector2(t_size.x + expand * 2, t_size.y + expand * 2)
	var bg_pos = Vector2(
		x * (t_size.x + gap) - expand,
		y * (t_size.y + gap) - expand
	)
	
	var bg = Panel.new()
	bg.size = bg_size
	bg.position = bg_pos
	
	var style = StyleBoxFlat.new()
	style.bg_color = GameManager.get_theme_color("secondary")
	
	var corner_radius = 8.0
	style.corner_radius_top_left = corner_radius if (not has_left and not has_up) else 0.0
	style.corner_radius_top_right = corner_radius if (not has_right and not has_up) else 0.0
	style.corner_radius_bottom_left = corner_radius if (not has_left and not has_down) else 0.0
	style.corner_radius_bottom_right = corner_radius if (not has_right and not has_down) else 0.0
	
	bg.add_theme_stylebox_override("panel", style)
	
	return bg

func create_tile(number: int, x: int, y: int) -> Control:
	var tile = Panel.new()
	tile.size = tile_size
	tile.position = Vector2(x * (tile_size.x + cell_gap), y * (tile_size.y + cell_gap))
	
	# 设置棋子样式
	var style = StyleBoxFlat.new()
	style.bg_color = GameManager.get_theme_color("tile")
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = GameManager.get_theme_color("tile").darkened(0.2)
	
	tile.add_theme_stylebox_override("panel", style)
	
	# 添加数字标签
	var label = Label.new()
	label.text = str(number)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(tile_size.x * 0.5))
	label.add_theme_color_override("font_color", GameManager.get_theme_color("tile_text"))
	label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	tile.add_child(label)
	
	# 存储数字和位置信息
	tile.set_meta("number", number)
	tile.set_meta("grid_x", x)
	tile.set_meta("grid_y", y)
	
	# 连接点击信号
	tile.gui_input.connect(_on_tile_input.bind(tile))
	
	return tile

func _on_tile_input(event: InputEvent, tile: Control) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if is_animating:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tile_x = tile.get_meta("grid_x")
		var tile_y = tile.get_meta("grid_y")
		move_tile(tile_x, tile_y)

func move_tile(tile_x: int, tile_y: int) -> void:
	# 查找空白格位置
	var empty_pos = find_empty_position()
	if empty_pos == Vector2i(-1, -1):
		return
	
	# 检查是否在同一行或同一列
	if tile_x == empty_pos.x:
		# 同一列，垂直移动 - 先检查路径上是否有墙
		var start_y = min(tile_y, empty_pos.y)
		var end_y = max(tile_y, empty_pos.y)
		for y in range(start_y, end_y + 1):
			if GameManager.current_grid[y][tile_x] == 0:
				return  # 路径上有墙，阻止移动
		var direction = 1 if tile_y < empty_pos.y else -1
		animate_move_column(tile_x, tile_y, empty_pos.y, direction)
	elif tile_y == empty_pos.y:
		# 同一行，水平移动 - 先检查路径上是否有墙
		var start_x = min(tile_x, empty_pos.x)
		var end_x = max(tile_x, empty_pos.x)
		for x in range(start_x, end_x + 1):
			if GameManager.current_grid[tile_y][x] == 0:
				return  # 路径上有墙，阻止移动
		var direction = 1 if tile_x < empty_pos.x else -1
		animate_move_row(tile_y, tile_x, empty_pos.x, direction)

func find_empty_position() -> Vector2i:
	for y in range(GameManager.current_grid_size.y):
		for x in range(GameManager.current_grid_size.x):
			if GameManager.current_grid[y][x] == 1:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func animate_move_column(col: int, from_y: int, to_y: int, direction: int) -> void:
	var tiles_to_move = []
	var original_values = []
	
	# 收集需要移动的棋子和原始值
	var start_y = min(from_y, to_y)
	var end_y = max(from_y, to_y)
	
	for y in range(start_y, end_y + 1):
		var cell_value = GameManager.current_grid[y][col]
		original_values.append(cell_value)
		if cell_value > 10:
			var tile = find_tile_at(col, y)
			if tile:
				tiles_to_move.append(tile)
	
	# 如果没有需要移动的棋子，直接返回
	if tiles_to_move.size() == 0:
		return
	
	is_animating = true
	
	# 播放音效
	GameManager.play_sfx(move_sfx)
	
	# 执行动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	for tile in tiles_to_move:
		var new_y = tile.get_meta("grid_y") + direction
		tween.tween_property(tile, "position:y", new_y * (tile_size.y + cell_gap), animation_duration)
		tile.set_meta("grid_y", new_y)
	
	await tween.finished
	
	# 更新网格数据 - 先清空原位置
	for y in range(start_y, end_y + 1):
		GameManager.current_grid[y][col] = 1
	
	# 再设置新位置
	for i in range(original_values.size()):
		if original_values[i] > 10:
			GameManager.current_grid[start_y + i + direction][col] = original_values[i]
	
	is_animating = false
	
	# 更新步数
	GameManager.move_count += 1
	update_display()
	
	# 检查胜利
	check_victory()

func animate_move_row(row: int, from_x: int, to_x: int, direction: int) -> void:
	var tiles_to_move = []
	var original_values = []
	
	# 收集需要移动的棋子和原始值
	var start_x = min(from_x, to_x)
	var end_x = max(from_x, to_x)
	
	for x in range(start_x, end_x + 1):
		var cell_value = GameManager.current_grid[row][x]
		original_values.append(cell_value)
		if cell_value > 10:
			var tile = find_tile_at(x, row)
			if tile:
				tiles_to_move.append(tile)
	
	# 如果没有需要移动的棋子，直接返回
	if tiles_to_move.size() == 0:
		return
	
	is_animating = true
	
	# 播放音效
	GameManager.play_sfx(move_sfx)
	
	# 执行动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	for tile in tiles_to_move:
		var new_x = tile.get_meta("grid_x") + direction
		tween.tween_property(tile, "position:x", new_x * (tile_size.x + cell_gap), animation_duration)
		tile.set_meta("grid_x", new_x)
	
	await tween.finished
	
	# 更新网格数据 - 先清空原位置
	for x in range(start_x, end_x + 1):
		GameManager.current_grid[row][x] = 1
	
	# 再设置新位置
	for i in range(original_values.size()):
		if original_values[i] > 10:
			GameManager.current_grid[row][start_x + i + direction] = original_values[i]
	
	is_animating = false
	
	# 更新步数
	GameManager.move_count += 1
	update_display()
	
	# 检查胜利
	check_victory()

func find_tile_at(x: int, y: int) -> Control:
	for tile in tiles:
		if tile.get_meta("grid_x") == x and tile.get_meta("grid_y") == y:
			return tile
	return null

func move_empty(dx: int, dy: int) -> void:
	var empty_pos = find_empty_position()
	if empty_pos == Vector2i(-1, -1):
		return
	
	var target_x = empty_pos.x + dx
	var target_y = empty_pos.y + dy
	
	# 检查目标位置是否有效
	if target_x < 0 or target_x >= GameManager.current_grid_size.x:
		return
	if target_y < 0 or target_y >= GameManager.current_grid_size.y:
		return
	
	var target_value = GameManager.current_grid[target_y][target_x]
	if target_value <= 10:  # 不是棋子
		return
	
	move_tile(target_x, target_y)

func update_display() -> void:
	moves_label.text = tr("moves") + ": " + str(GameManager.move_count)
	time_label.text = tr("time") + ": " + GameManager.format_time(GameManager.game_time)

func check_victory() -> void:
	if GameManager.is_victory():
		GameManager.is_timer_running = false
		victory.emit()

func _on_pause() -> void:
	pause.emit()
