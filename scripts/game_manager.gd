extends Node

# 游戏状态
enum GameState { MENU, PLAYING, PAUSED, VICTORY }
var current_state: GameState = GameState.MENU

# 对话框状态
enum DialogType { NONE, CONFIRM, MESSAGE }
var current_dialog: Control = null
var current_dialog_type: DialogType = DialogType.NONE

# 设置
var settings: Dictionary = {
	"theme": "light",
	"music_volume": 40,
	"sfx_volume": 60
}

# 自定义关卡
var custom_levels: Array = []

# 当前游戏数据
var current_grid: Array = []  # 0=墙壁, 1=可移动, 2=棋子
var current_grid_size: Vector2i = Vector2i(3, 3)
var current_level_name: String = ""
var move_count: int = 0
var game_time: float = 0.0
var is_timer_running: bool = false

# 主题颜色
var themes: Dictionary = {
	"light": {
		"bg": Color(0.95, 0.95, 0.95),
		"primary": Color(0.2, 0.6, 0.9),
		"secondary": Color(0.63, 0.63, 0.63),
		"text": Color(0.1, 0.1, 0.1),
		"wall": Color(0.3, 0.3, 0.3),
		"tile": Color(0.3, 0.7, 1.0),
		"tile_text": Color(1, 1, 1),
		"button": Color(0.2, 0.6, 0.9),
		"button_hover": Color(0.3, 0.7, 1.0),
		"button_text": Color(1, 1, 1)
	},
	"dark": {
		"bg": Color(0.15, 0.15, 0.15),
		"primary": Color(0.4, 0.7, 1.0),
		"secondary": Color(0.425, 0.425, 0.425),
		"text": Color(0.9, 0.9, 0.9),
		"wall": Color(0.1, 0.1, 0.1),
		"tile": Color(0.3, 0.5, 0.8),
		"tile_text": Color(1, 1, 1),
		"button": Color(0.3, 0.5, 0.8),
		"button_hover": Color(0.4, 0.6, 0.9),
		"button_text": Color(1, 1, 1)
	},
	"nature": {
		"bg": Color(0.9, 0.95, 0.9),
		"primary": Color(0.2, 0.7, 0.3),
		"secondary": Color(0.595, 0.63, 0.595),
		"text": Color(0.1, 0.2, 0.1),
		"wall": Color(0.4, 0.5, 0.4),
		"tile": Color(0.3, 0.8, 0.4),
		"tile_text": Color(1, 1, 1),
		"button": Color(0.2, 0.7, 0.3),
		"button_hover": Color(0.3, 0.8, 0.4),
		"button_text": Color(1, 1, 1)
	},
	"sunset": {
		"bg": Color(0.95, 0.9, 0.85),
		"primary": Color(0.9, 0.5, 0.2),
		"secondary": Color(0.665, 0.644, 0.63),
		"text": Color(0.2, 0.1, 0.05),
		"wall": Color(0.5, 0.4, 0.3),
		"tile": Color(1.0, 0.6, 0.3),
		"tile_text": Color(1, 1, 1),
		"button": Color(0.9, 0.5, 0.2),
		"button_hover": Color(1.0, 0.6, 0.3),
		"button_text": Color(1, 1, 1)
	},
	"ember": {
		"bg": Color(0.18, 0.12, 0.08),
		"primary": Color(0.95, 0.55, 0.2),
		"secondary": Color(0.386, 0.295, 0.23),
		"text": Color(0.95, 0.88, 0.8),
		"wall": Color(0.15, 0.1, 0.07),
		"tile": Color(0.85, 0.45, 0.15),
		"tile_text": Color(1, 1, 1),
		"button": Color(0.85, 0.45, 0.15),
		"button_hover": Color(0.95, 0.55, 0.25),
		"button_text": Color(1, 1, 1)
	},
	"midnight": {
		"bg": Color(0.12, 0.1, 0.18),
		"primary": Color(0.6, 0.4, 0.9),
		"secondary": Color(0.334, 0.305, 0.425),
		"text": Color(0.9, 0.85, 0.95),
		"wall": Color(0.1, 0.08, 0.15),
		"tile": Color(0.5, 0.3, 0.8),
		"tile_text": Color(1, 1, 1),
		"button": Color(0.5, 0.3, 0.8),
		"button_hover": Color(0.6, 0.4, 0.9),
		"button_text": Color(1, 1, 1)
	}
}

# 音频播放器
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	# 初始化音频播放器
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	# 加载设置
	load_settings()
	
	# 应用设置
	apply_settings()

func _process(delta: float) -> void:
	if is_timer_running and current_state == GameState.PLAYING:
		game_time += delta

func get_theme_color(color_key: String) -> Color:
	if themes.has(settings.theme) and themes[settings.theme].has(color_key):
		return themes[settings.theme][color_key]
	return Color.WHITE

func apply_settings() -> void:
	# 设置音乐音量
	music_player.volume_db = linear_to_db(settings.music_volume / 100.0)
	sfx_player.volume_db = linear_to_db(settings.sfx_volume / 100.0)

func save_settings() -> void:
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func load_settings() -> void:
	if FileAccess.file_exists("user://settings.save"):
		var file = FileAccess.open("user://settings.save", FileAccess.READ)
		if file:
			settings = file.get_var()
			file.close()

func save_custom_levels() -> void:
	var file = FileAccess.open("user://custom_levels.save", FileAccess.WRITE)
	if file:
		file.store_var(custom_levels)
		file.close()

func load_custom_levels() -> void:
	if FileAccess.file_exists("user://custom_levels.save"):
		var file = FileAccess.open("user://custom_levels.save", FileAccess.READ)
		if file:
			custom_levels = file.get_var()
			file.close()

func play_music(stream: AudioStream) -> void:
	music_player.stream = stream
	stream.loop = true
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()

func start_game(grid_size: Vector2i, level_name: String = "") -> void:
	current_grid_size = grid_size
	current_level_name = level_name
	move_count = 0
	game_time = 0.0
	is_timer_running = true
	current_state = GameState.PLAYING
	
	# 创建网格
	create_grid(grid_size)
	
	# 打乱网格
	shuffle_grid()

func create_grid(grid_size: Vector2i) -> void:
	current_grid = []
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			row.append(1)  # 1表示可移动位置
		current_grid.append(row)
	
	# 放置棋子（编号从1开始）
	var tile_num = 1
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			if current_grid[y][x] == 1:
				if tile_num < grid_size.x * grid_size.y:
					current_grid[y][x] = tile_num + 10  # 用10+编号表示棋子
					tile_num += 1
	
	# 最后一个位置设为空白格
	current_grid[grid_size.y - 1][grid_size.x - 1] = 1

func shuffle_grid() -> void:
	# 随机移动多次来打乱
	var moves = current_grid_size.x * current_grid_size.y * 100
	for i in range(moves):
		var empty_pos = find_empty_position()
		var possible_moves = []
		
		# 检查四个方向，考虑墙壁
		# 左边
		if empty_pos.x > 0:
			var left_cell = current_grid[empty_pos.y][empty_pos.x - 1]
			if left_cell > 10:  # 是棋子
				possible_moves.append(Vector2i(-1, 0))
		# 右边
		if empty_pos.x < current_grid_size.x - 1:
			var right_cell = current_grid[empty_pos.y][empty_pos.x + 1]
			if right_cell > 10:
				possible_moves.append(Vector2i(1, 0))
		# 上边
		if empty_pos.y > 0:
			var up_cell = current_grid[empty_pos.y - 1][empty_pos.x]
			if up_cell > 10:
				possible_moves.append(Vector2i(0, -1))
		# 下边
		if empty_pos.y < current_grid_size.y - 1:
			var down_cell = current_grid[empty_pos.y + 1][empty_pos.x]
			if down_cell > 10:
				possible_moves.append(Vector2i(0, 1))
		
		if possible_moves.size() > 0:
			var move = possible_moves[randi() % possible_moves.size()]
			move_tile(empty_pos + move, empty_pos)

func find_empty_position() -> Vector2i:
	for y in range(current_grid_size.y):
		for x in range(current_grid_size.x):
			if current_grid[y][x] == 1:
				return Vector2i(x, y)
	return Vector2i(0, 0)

func move_tile(from: Vector2i, to: Vector2i) -> void:
	var tile = current_grid[from.y][from.x]
	current_grid[to.y][to.x] = tile
	current_grid[from.y][from.x] = 1

func is_victory() -> bool:
	# 按从左到右、从上到下的顺序检查
	var expected = 1
	var last_playable_is_empty = false
	
	for y in range(current_grid_size.y):
		for x in range(current_grid_size.x):
			var cell = current_grid[y][x]
			if cell == 0:
				# 墙壁，跳过
				continue
			elif cell == 1:
				# 空白格，应该是最后一个可玩位置
				last_playable_is_empty = true
			elif cell > 10:
				# 棋子
				if not last_playable_is_empty:
					# 在空白格之前，检查编号是否正确
					if cell != expected + 10:
						return false
					expected += 1
				else:
					# 在空白格之后，不应该有棋子
					return false
	
	# 检查最后一个可玩位置是否是空白格
	return last_playable_is_empty

func get_next_custom_level_name() -> String:
	var base_name = tr("new_level")
	var max_num = 0
	
	for level in custom_levels:
		if level.name.begins_with(base_name):
			var num_str = level.name.substr(base_name.length()).strip_edges()
			if num_str.is_valid_int():
				max_num = max(max_num, num_str.to_int())
	
	# 检查已删除的数字
	for n in range(1, max_num + 2):
		var test_name = base_name + " " + str(n)
		var exists = false
		for level in custom_levels:
			if level.name == test_name:
				exists = true
				break
		if not exists:
			return test_name
	
	return base_name + " 1"

func add_custom_level(level_data: Dictionary) -> void:
	custom_levels.append(level_data)
	save_custom_levels()

func delete_custom_level(index: int) -> void:
	if index >= 0 and index < custom_levels.size():
		custom_levels.remove_at(index)
		save_custom_levels()

# 创建带主题样式的按钮
func create_styled_button(text: String, font_size: int = 20, corner_radius: int = 6, margin: int = 15) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", get_theme_color("button_text"))
	button.add_theme_color_override("font_hover_color", get_theme_color("button_text"))
	button.add_theme_color_override("font_pressed_color", get_theme_color("button_text"))
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = get_theme_color("button")
	normal_style.corner_radius_top_left = corner_radius
	normal_style.corner_radius_top_right = corner_radius
	normal_style.corner_radius_bottom_left = corner_radius
	normal_style.corner_radius_bottom_right = corner_radius
	normal_style.content_margin_left = margin
	normal_style.content_margin_right = margin
	normal_style.content_margin_top = margin / 2
	normal_style.content_margin_bottom = margin / 2
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = get_theme_color("button_hover")
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	
	return button

func create_image_button(texture_path: String, size: Vector2 = Vector2(48, 48), corner_radius: int = 8, margin: int = 8) -> Button:
	var button = Button.new()
	button.custom_minimum_size = size
	button.icon = load(texture_path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = get_theme_color("button")
	normal_style.corner_radius_top_left = corner_radius
	normal_style.corner_radius_top_right = corner_radius
	normal_style.corner_radius_bottom_left = corner_radius
	normal_style.corner_radius_bottom_right = corner_radius
	normal_style.content_margin_left = margin
	normal_style.content_margin_right = margin
	normal_style.content_margin_top = margin
	normal_style.content_margin_bottom = margin
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = get_theme_color("button_hover")
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	
	return button

# 格式化时间显示
func format_time(seconds: float) -> String:
	var total_seconds := floori(seconds)
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	var secs := total_seconds % 60
	return "%02d:%02d" % [minutes, secs]

# 未完成游戏存档
const UNFINISHED_SAVE_PATH = "user://unfinished_game.save"

func has_unfinished_game() -> bool:
	return FileAccess.file_exists(UNFINISHED_SAVE_PATH)

func save_unfinished_game() -> void:
	if current_state != GameState.PLAYING:
		return
	var data = {
		"grid": current_grid,
		"grid_size": [current_grid_size.x, current_grid_size.y],
		"level_name": current_level_name,
		"move_count": move_count,
		"game_time": game_time
	}
	var file = FileAccess.open(UNFINISHED_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_unfinished_game() -> Dictionary:
	if not has_unfinished_game():
		return {}
	var file = FileAccess.open(UNFINISHED_SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		return data
	return {}

func delete_unfinished_game() -> void:
	if FileAccess.file_exists(UNFINISHED_SAVE_PATH):
		DirAccess.remove_absolute(UNFINISHED_SAVE_PATH)

func show_message(message: String, parent: Node = null) -> void:
	if parent == null:
		parent = get_tree().current_scene
	var dialog = preload("res://scenes/message_dialog.tscn").instantiate()
	parent.add_child(dialog)
	dialog.show_message(message)

func show_confirm(message: String, on_confirm: Callable, on_cancel: Callable = func(): pass, parent: Node = null) -> void:
	if parent == null:
		parent = get_tree().current_scene
	var dialog = preload("res://scenes/confirm_dialog.tscn").instantiate()
	parent.add_child(dialog)
	dialog.show_dialog(message, on_confirm, on_cancel)
