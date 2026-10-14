extends SceneTree
# Independent input checks; run with the audited project as --path.
var game: Node
var passed: Array[String] = []
func _initialize() -> void:
	call_deferred("run_checks")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
func action(name: String, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = {"move_right":KEY_D,"move_left":KEY_A,"jump":KEY_SPACE}[name]
	event.keycode = event.physical_keycode
	event.pressed = down
	Input.parse_input_event(event)
func check_result(name: String, condition: bool) -> bool:
	if not condition:
		push_error("INDEPENDENT FAIL: " + name)
		quit(1)
		return false
	passed.append(name)
	return true
func run_checks() -> void:
	var scene_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var scene = load(scene_path)
	if not check_result("main scene exists", scene is PackedScene): return
	game = scene.instantiate()
	root.add_child(game)
	await frames(5)
	if not check_result("read-only state available", game.has_method("debug_state")): return
	var initial: Dictionary = game.debug_state()
	if not check_result("player feet observable", initial.get("player_feet") is Vector2): return
	action("move_right", true)
	await frames(30)
	action("move_right", false)
	var moved: Dictionary = game.debug_state()
	if not check_result("right input moves player", moved.player_feet.x > initial.player_feet.x + 20): return
	await frames(20)
	action("jump", true)
	await frames(1)
	action("jump", false)
	await frames(8)
	var jumped: Dictionary = game.debug_state()
	if not check_result("jump rises", jumped.player_feet.y < moved.player_feet.y - 20): return
	await frames(80)
	if not check_result("jump lands", bool(game.debug_state().get("grounded", false))): return
	print("INDEPENDENT_CHECKS ", JSON.stringify({"status":"passed","checks":passed,"scope":"native player input; not complete parity or Web verification"}))
	quit(0)
