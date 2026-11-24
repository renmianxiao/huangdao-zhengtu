extends Node
## Global shortcuts route popup cancellation before page navigation or combat.
var window_size := Vector2i.ZERO
var window_position := Vector2i.ZERO
var window_screen := 0
var window_borderless := false
var window_mode := Window.MODE_WINDOWED

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	if DisplayServer.get_name() != "headless" and get_window().mode == Window.MODE_WINDOWED:
		var window := get_window()
		var screen_size := DisplayServer.screen_get_size(window.current_screen)
		window.size = default_window_size(screen_size)
		var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
		window.position = usable.position + (usable.size-window.size)/2

func default_window_size(screen_size: Vector2i) -> Vector2i:
	if screen_size.x <= 0 or screen_size.y <= 0: return Vector2i(1280,720)
	var ratio := float(screen_size.x)/screen_size.y
	var height := maxi(650,mini(720,roundi(1280.0/ratio)))
	return Vector2i(maxi(900,roundi(height*ratio)),height)

func _on_node_added(node: Node) -> void:
	# Native popup windows have their own input stream when they take focus.
	if node is Window and node != get_window():
		var handler := _on_window_input.bind(node)
		if not node.window_input.is_connected(handler):
			node.window_input.connect(handler)

func _on_window_input(event: InputEvent, window: Window) -> void:
	if _is_right_press(event):
		window.set_input_as_handled()
		get_viewport().set_input_as_handled()
		_handle_right_click(window)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_input(event)
		window.set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		for view: Node in get_tree().get_nodes_in_group("encyclopedia_overlay"):
			if view is Control and view.is_visible_in_tree():
				get_viewport().set_input_as_handled()
				view.handle_back()
				return
	if _is_right_press(event):
		get_viewport().set_input_as_handled()
		_handle_right_click()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func _is_right_press(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed

func _handle_right_click(source_window: Window = null) -> void:
	if get_viewport().gui_is_dragging():
		get_viewport().gui_cancel_drag()
		return
	# Consume the input before hiding a popup so it cannot reach the page beneath.
	var popup: Window = source_window if source_window != get_window() and source_window != null and source_window.visible else null
	if popup == null:
		var windows := get_tree().root.find_children("*", "Window", true, false)
		for index in range(windows.size()-1,-1,-1):
			var candidate: Window = windows[index]
			if not candidate.visible: continue
			if popup == null: popup = candidate
			if candidate.has_focus():
				popup = candidate
				break
	if popup != null:
		popup.hide()
		if popup is AcceptDialog: popup.canceled.emit()
		return
	for screen: Node in get_tree().get_nodes_in_group("right_click_navigation"):
		if screen is Control and screen.is_visible_in_tree():
			screen.handle_right_click()
			return
	for battle: Node in get_tree().get_nodes_in_group("right_click_battle"):
		if battle is Control and battle.is_visible_in_tree():
			battle.handle_right_click()
			return

func toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
		window.borderless = window_borderless
		if window_size != Vector2i.ZERO:
			window.current_screen = window_screen
			window.size = window_size
			window.position = window_position
		if window_mode == Window.MODE_MAXIMIZED:
			window.mode = Window.MODE_MAXIMIZED
	else:
		window_size = window.size
		window_position = window.position
		window_screen = window.current_screen
		window_borderless = window.borderless
		window_mode = window.mode
		# MODE_FULLSCREEN is Godot's borderless fullscreen; exclusive is separate.
		window.mode = Window.MODE_FULLSCREEN

