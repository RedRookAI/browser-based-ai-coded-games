extends SceneTree
func _initialize():call_deferred("run_checks")
func run_checks():
	var game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	for i in 5:await physics_frame
	game.creatures.restart_lineup(["sushi"])
	game.actor.position=Vector2(966,522.5);game.actor.velocity=Vector2(480,0);game.grounded=false;game.recovery_grace=0
	for i in 4:await physics_frame
	var triggered=game.ragdoll_active
	for i in 90:await physics_frame
	var finite=true
	for n in game.loose_nodes.values():finite=finite&&n.p.is_finite()
	var event=InputEventKey.new();event.physical_keycode=KEY_A;event.keycode=KEY_A;event.pressed=true
	Input.parse_input_event(event)
	for i in 4:await physics_frame
	event.pressed=false;Input.parse_input_event(event)
	print("IMPACT_RECOVERY ",JSON.stringify({"actual_wall_collision_triggered_ragdoll":triggered,"articulated_nodes":game.robot.joints.size(),"nodes_finite":finite,"recovered":!game.ragdoll_active,"collision_enabled":!game.actor.get_child(0).disabled,"feet":game.feet()}))
	quit(0)
