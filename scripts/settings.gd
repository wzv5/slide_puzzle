extends Control

signal back
signal theme_updated

var music_slider: HSlider
var sfx_slider: HSlider
var music_value_label: Label
var sfx_value_label: Label
var theme_buttons: Array = []

func _ready() -> void:
	# 设置背景颜色
	var bg = ColorRect.new()
	bg.color = GameManager.get_theme_color("bg")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建标题
	var title = Label.new()
	title.text = tr("settings")
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
	settings_container.offset_top = 150
	settings_container.offset_bottom = 900
	settings_container.add_theme_constant_override("separation", 30)
	add_child(settings_container)
	
	# 创建主题选择部分
	create_theme_section(settings_container)
	
	# 创建音乐音量部分
	create_volume_section(settings_container, tr("music_volume"), GameManager.settings.music_volume, _on_music_volume_changed)
	
	# 创建音效音量部分
	create_volume_section(settings_container, tr("sfx_volume"), GameManager.settings.sfx_volume, _on_sfx_volume_changed)

func create_theme_section(parent: Node) -> void:
	var theme_container = VBoxContainer.new()
	theme_container.add_theme_constant_override("separation", 10)
	parent.add_child(theme_container)
	
	# 主题标签
	var theme_label = Label.new()
	theme_label.text = tr("theme")
	theme_label.add_theme_font_size_override("font_size", 24)
	theme_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	theme_container.add_child(theme_label)
	
	# 主题按钮网格（2行3列）
	var grid_container = VBoxContainer.new()
	grid_container.add_theme_constant_override("separation", 8)
	theme_container.add_child(grid_container)
	
	var light_themes = ["light", "nature", "sunset"]
	var dark_themes = ["dark", "ember", "midnight"]
	
	for row_themes in [light_themes, dark_themes]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid_container.add_child(row)
		
		for theme_name in row_themes:
			var button = Button.new()
			button.text = tr(theme_name)
			button.custom_minimum_size = Vector2(100, 50)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 18)
			button.add_theme_color_override("font_color", GameManager.get_theme_color("button_text"))
			button.add_theme_color_override("font_hover_color", GameManager.get_theme_color("button_text"))
			button.add_theme_color_override("font_pressed_color", GameManager.get_theme_color("button_text"))
			
			# 设置按钮样式
			var normal_style = StyleBoxFlat.new()
			if GameManager.settings.theme == theme_name:
				normal_style.bg_color = GameManager.get_theme_color("button_hover")
			else:
				normal_style.bg_color = GameManager.get_theme_color("button")
			normal_style.corner_radius_top_left = 8
			normal_style.corner_radius_top_right = 8
			normal_style.corner_radius_bottom_left = 8
			normal_style.corner_radius_bottom_right = 8
			
			var hover_style = normal_style.duplicate()
			hover_style.bg_color = GameManager.get_theme_color("button_hover")
			
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_stylebox_override("pressed", hover_style)
			
			button.pressed.connect(_on_theme_selected.bind(theme_name))
			theme_buttons.append(button)
			row.add_child(button)

func create_volume_section(parent: Node, label_text: String, initial_value: int, callback: Callable) -> void:
	var volume_container = VBoxContainer.new()
	volume_container.add_theme_constant_override("separation", 10)
	parent.add_child(volume_container)
	
	# 音量标签和数值容器
	var label_container = HBoxContainer.new()
	volume_container.add_child(label_container)
	
	# 音量标签
	var volume_label = Label.new()
	volume_label.text = label_text
	volume_label.add_theme_font_size_override("font_size", 24)
	volume_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	label_container.add_child(volume_label)
	
	# 音量数值标签
	var value_label = Label.new()
	value_label.text = str(initial_value) + "%"
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", GameManager.get_theme_color("text"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_container.add_child(value_label)
	
	# 音量滑块
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(0, 40)
	slider.value_changed.connect(callback)
	
	# 设置滑块样式
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = GameManager.get_theme_color("bg").lerp(GameManager.get_theme_color("primary"), 0.25)
	slider_style.corner_radius_top_left = 6
	slider_style.corner_radius_top_right = 6
	slider_style.corner_radius_bottom_left = 6
	slider_style.corner_radius_bottom_right = 6
	slider_style.content_margin_top = 8
	slider_style.content_margin_bottom = 8
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = GameManager.get_theme_color("primary")
	grabber_style.corner_radius_top_left = 12
	grabber_style.corner_radius_top_right = 12
	grabber_style.corner_radius_bottom_left = 12
	grabber_style.corner_radius_bottom_right = 12
	grabber_style.content_margin_left = 12
	grabber_style.content_margin_right = 12
	grabber_style.content_margin_top = 12
	grabber_style.content_margin_bottom = 12
	
	var grabber_hover_style = grabber_style.duplicate()
	grabber_hover_style.bg_color = GameManager.get_theme_color("button_hover")
	
	slider.add_theme_stylebox_override("slider", slider_style)
	slider.add_theme_stylebox_override("grabber", grabber_style)
	slider.add_theme_stylebox_override("grabber_highlight", grabber_hover_style)
	slider.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	slider.add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())
	
	volume_container.add_child(slider)
	
	# 保存引用以便更新
	if label_text == tr("music_volume"):
		music_slider = slider
		music_value_label = value_label
	else:
		sfx_slider = slider
		sfx_value_label = value_label

func _on_back() -> void:
	# 保存设置
	GameManager.save_settings()
	back.emit()

func _on_theme_selected(theme_name: String) -> void:
	GameManager.settings.theme = theme_name
	GameManager.apply_settings()
	
	# 发出主题已更改信号，让主场景重新显示设置界面
	theme_updated.emit()

func _on_music_volume_changed(value: float) -> void:
	GameManager.settings.music_volume = int(value)
	music_value_label.text = str(int(value)) + "%"
	GameManager.apply_settings()

func _on_sfx_volume_changed(value: float) -> void:
	GameManager.settings.sfx_volume = int(value)
	sfx_value_label.text = str(int(value)) + "%"
	GameManager.apply_settings()
