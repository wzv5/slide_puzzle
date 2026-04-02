extends Control

# 场景引用
var current_scene: Node = null

# 当前编辑的关卡名称（用于判断是新建还是编辑）
var current_editing_level_name: String = ""

# 音频流 - 使用preload加载以确保导出时包含资源
var menu_music: AudioStream = preload("res://assets/sounds/menu.mp3")
var playing_music: AudioStream = preload("res://assets/sounds/playing.mp3")
var victory_sfx: AudioStream = preload("res://assets/sounds/victory.ogg")

func _ready() -> void:
	# 播放菜单音乐
	GameManager.play_music(menu_music)
	
	# 显示主菜单
	show_main_menu()
	
	# 禁止Android/iOS返回键自动退出
	get_tree().set_quit_on_go_back(false)
	
	# 禁止窗口关闭时自动退出，由通知处理
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_ui_cancel()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# 应用切入后台或窗口最小化，保存当前游戏状态
		GameManager.save_unfinished_game()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		# 窗口关闭请求（Windows关闭按钮等）
		GameManager.save_unfinished_game()
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_ui_cancel()
	elif event.is_action_pressed("ui_accept"):
		handle_ui_accept()

func handle_ui_cancel() -> void:
	# 检查是否有对话框打开
	if GameManager.current_dialog != null and is_instance_valid(GameManager.current_dialog):
		GameManager.current_dialog.on_ui_cancel()
		return
	
	# 根据当前场景类型决定行为
	if current_scene == null:
		get_tree().quit()
		return
	
	var script_path = current_scene.get_script().resource_path if current_scene.get_script() else ""
	
	if script_path == "res://scripts/game.gd":
		# 在游戏中按暂停
		show_pause_dialog()
	elif script_path in ["res://scripts/settings.gd", "res://scripts/about.gd", 
						  "res://scripts/difficulty_select.gd", "res://scripts/custom_levels.gd",
						  "res://scripts/level_editor.gd"]:
		# 在子界面中调用返回功能
		current_scene._on_back()
	elif script_path == "res://scripts/main_menu.gd":
		# 在主菜单中调用退出游戏方法（会显示确认对话框）
		current_scene._on_exit_game()
	else:
		# 默认退出
		get_tree().quit()

func handle_ui_accept() -> void:
	# 检查是否有对话框打开
	if GameManager.current_dialog != null and is_instance_valid(GameManager.current_dialog):
		GameManager.current_dialog.on_ui_accept()

func show_main_menu() -> void:
	GameManager.current_state = GameManager.GameState.MENU
	clear_current_scene()
	
	# 创建主菜单场景
	var menu_scene = preload("res://scenes/main_menu.tscn").instantiate()
	add_child(menu_scene)
	current_scene = menu_scene
	
	# 连接信号
	menu_scene.start_game.connect(_on_start_game)
	menu_scene.custom_levels.connect(_on_custom_levels)
	menu_scene.settings.connect(_on_settings)
	menu_scene.about.connect(_on_about)
	menu_scene.exit_game.connect(_on_exit_game)
	menu_scene.language_changed.connect(_on_language_changed)

func show_difficulty_select() -> void:
	clear_current_scene()
	
	var difficulty_scene = preload("res://scenes/difficulty_select.tscn").instantiate()
	add_child(difficulty_scene)
	current_scene = difficulty_scene
	
	difficulty_scene.back.connect(_on_back_to_menu)
	difficulty_scene.select_difficulty.connect(_on_select_difficulty)
	difficulty_scene.custom_levels.connect(_on_custom_levels_for_play)

func show_custom_levels() -> void:
	clear_current_scene()
	
	var custom_scene = preload("res://scenes/custom_levels.tscn").instantiate()
	add_child(custom_scene)
	current_scene = custom_scene
	
	custom_scene.back.connect(_on_back_to_menu)
	custom_scene.new_level.connect(_on_new_level)
	custom_scene.edit_level.connect(_on_edit_level)
	custom_scene.import_level.connect(_on_import_level)

func show_custom_levels_for_play() -> void:
	clear_current_scene()
	
	var custom_scene = preload("res://scenes/custom_levels.tscn").instantiate()
	custom_scene.play_mode = true
	add_child(custom_scene)
	current_scene = custom_scene
	
	custom_scene.back.connect(_on_back_to_difficulty)
	custom_scene.play_level.connect(_on_play_custom_level)

func show_level_editor(level_data: Dictionary = {}) -> void:
	clear_current_scene()
	
	var editor_scene = preload("res://scenes/level_editor.tscn").instantiate()
	add_child(editor_scene)
	current_scene = editor_scene
	
	editor_scene.back.connect(_on_back_to_custom_levels)
	editor_scene.save_callback = _on_save_level
	
	if level_data.size() > 0:
		editor_scene.load_level(level_data)

func show_game() -> void:
	clear_current_scene()
	
	var game_scene = preload("res://scenes/game.tscn").instantiate()
	add_child(game_scene)
	current_scene = game_scene
	
	game_scene.pause.connect(_on_pause)
	game_scene.victory.connect(_on_victory)

func show_settings() -> void:
	clear_current_scene()
	
	var settings_scene = preload("res://scenes/settings.tscn").instantiate()
	add_child(settings_scene)
	current_scene = settings_scene
	
	settings_scene.back.connect(_on_back_to_menu)
	settings_scene.theme_updated.connect(_on_theme_updated)

func show_about() -> void:
	clear_current_scene()
	
	var about_scene = preload("res://scenes/about.tscn").instantiate()
	add_child(about_scene)
	current_scene = about_scene
	
	about_scene.back.connect(_on_back_to_menu)

func show_pause_dialog() -> void:
	GameManager.save_unfinished_game()
	GameManager.current_state = GameManager.GameState.PAUSED
	GameManager.is_timer_running = false
	
	GameManager.show_confirm(tr("back_to_menu"), _on_pause_confirm, _on_pause_cancel)

func resume_game() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.is_timer_running = true

func show_victory() -> void:
	GameManager.current_state = GameManager.GameState.VICTORY
	GameManager.is_timer_running = false
	GameManager.play_sfx(victory_sfx)
	
	var victory_scene = preload("res://scenes/victory.tscn").instantiate()
	add_child(victory_scene)
	victory_scene.back_to_menu.connect(_on_back_to_menu)

func clear_current_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null

# 信号处理函数
func _on_start_game() -> void:
	if GameManager.has_unfinished_game():
		# 询问是否继续上一局
		GameManager.show_confirm(tr("continue_game"), _resume_unfinished, _start_new_game)
	else:
		show_difficulty_select()

func _resume_unfinished() -> void:
	var data = GameManager.load_unfinished_game()
	if data.is_empty():
		show_difficulty_select()
		return
	GameManager.current_grid = data["grid"].duplicate(true)
	GameManager.current_grid_size = Vector2i(data["grid_size"][0], data["grid_size"][1])
	GameManager.current_level_name = data["level_name"]
	GameManager.move_count = data["move_count"]
	GameManager.game_time = data["game_time"]
	GameManager.is_timer_running = true
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.play_music(playing_music)
	show_game()

func _start_new_game() -> void:
	GameManager.delete_unfinished_game()
	show_difficulty_select()

func _on_custom_levels() -> void:
	show_custom_levels()

func _on_custom_levels_for_play() -> void:
	show_custom_levels_for_play()

func _on_settings() -> void:
	show_settings()

func _on_about() -> void:
	show_about()

func _on_exit_game() -> void:
	get_tree().quit()

func _on_language_changed() -> void:
	# 重新显示主菜单以更新文本（不重新播放音乐）
	show_main_menu()

func _on_theme_updated() -> void:
	# 重新显示设置界面以应用新主题（不重新播放音乐）
	show_settings()

func _on_back_to_menu() -> void:
	# 只有当前音乐不是菜单音乐时才切换
	if GameManager.music_player.stream != menu_music:
		GameManager.play_music(menu_music)
	show_main_menu()

func _on_back_to_difficulty() -> void:
	show_difficulty_select()

func _on_select_difficulty(grid_size: Vector2i) -> void:
	GameManager.start_game(grid_size)
	GameManager.play_music(playing_music)
	show_game()

func _on_play_custom_level(level_data: Dictionary) -> void:
	# 使用自定义关卡的网格数据开始游戏
	GameManager.current_grid_size = Vector2i(level_data.width, level_data.height)
	GameManager.current_grid = level_data.grid.duplicate(true)
	
	# 给棋子编号
	var tile_num = 1
	var total_playable = count_playable_cells()
	for y in range(GameManager.current_grid_size.y):
		for x in range(GameManager.current_grid_size.x):
			if GameManager.current_grid[y][x] == 1:
				if tile_num < total_playable:
					GameManager.current_grid[y][x] = tile_num + 10
					tile_num += 1
	
	# 打乱棋子
	GameManager.shuffle_grid()
	
	GameManager.move_count = 0
	GameManager.game_time = 0.0
	GameManager.is_timer_running = true
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.play_music(playing_music)
	show_game()

func count_playable_cells() -> int:
	var count = 0
	for y in range(GameManager.current_grid_size.y):
		for x in range(GameManager.current_grid_size.x):
			if GameManager.current_grid[y][x] > 0:
				count += 1
	return count

func _on_back_to_custom_levels() -> void:
	show_custom_levels()

func _on_new_level() -> void:
	var level_data = {
		"name": GameManager.get_next_custom_level_name(),
		"width": 4,
		"height": 4,
		"grid": []
	}
	current_editing_level_name = ""  # 新建关卡时清空
	show_level_editor(level_data)

func _on_edit_level(level_data: Dictionary) -> void:
	current_editing_level_name = level_data.name  # 记录正在编辑的关卡名称
	show_level_editor(level_data)

func _on_import_level(level_data: Dictionary) -> void:
	current_editing_level_name = level_data.name  # 记录导入的关卡名称
	show_level_editor(level_data)

func _on_save_level(level_data: Dictionary) -> bool:
	# 检查名称是否重复（排除自身）
	var name_exists = false
	for level in GameManager.custom_levels:
		if level.name == level_data.name:
			# 如果是编辑现有关卡，通过名称匹配找到它
			if current_editing_level_name == level_data.name:
				continue  # 这是要编辑的关卡本身，不算重复
			name_exists = true
			break
	
	if name_exists:
		# 显示错误对话框
		GameManager.show_message(tr("name_exists"))
		return false
	
	# 保存关卡 - 通过名称查找是否是编辑现有关卡
	var found_index = -1
	for i in range(GameManager.custom_levels.size()):
		if GameManager.custom_levels[i].name == current_editing_level_name:
			found_index = i
			break
	
	if found_index >= 0:
		# 更新现有关卡
		GameManager.custom_levels[found_index] = level_data
	else:
		# 添加新关卡
		GameManager.custom_levels.append(level_data)
	
	# 更新当前编辑的关卡名称
	current_editing_level_name = level_data.name
	
	GameManager.save_custom_levels()
	return true

func _on_pause() -> void:
	show_pause_dialog()

func _on_victory() -> void:
	GameManager.delete_unfinished_game()
	show_victory()

func _on_pause_confirm() -> void:
	GameManager.play_music(menu_music)
	show_main_menu()

func _on_pause_cancel() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.is_timer_running = true
