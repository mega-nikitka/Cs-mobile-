extends Node3D

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.7, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)

	box(Vector3(0, -0.5, 0), Vector3(60, 1, 60), Color(0.76, 0.68, 0.5))
	box(Vector3(0, 2, -30), Vector3(60, 4, 1), Color(0.6, 0.55, 0.45))
	box(Vector3(0, 2, 30), Vector3(60, 4, 1), Color(0.6, 0.55, 0.45))
	box(Vector3(-30, 2, 0), Vector3(1, 4, 60), Color(0.6, 0.55, 0.45))
	box(Vector3(30, 2, 0), Vector3(1, 4, 60), Color(0.6, 0.55, 0.45))
	box(Vector3(0, 1.5, 0), Vector3(8, 3, 1), Color(0.5, 0.5, 0.52))
	box(Vector3(-10, 0.75, 8), Vector3(1.5, 1.5, 1.5), Color(0.55, 0.38, 0.2))
	box(Vector3(10, 0.75, 6), Vector3(1.5, 1.5, 1.5), Color(0.55, 0.38, 0.2))
	box(Vector3(12, 1, -8), Vector3(2, 2, 2), Color(0.55, 0.38, 0.2))
	box(Vector3(-12, 1, -10), Vector3(2, 2, 2), Color(0.55, 0.38, 0.2))

	var target_script := load("res://target.gd")
	for p in [Vector3(-8, 0, -12), Vector3(0, 0, -18), Vector3(8, 0, -14), Vector3(-15, 0, -22), Vector3(14, 0, -24), Vector3(0, 0, -6)]:
		var t := StaticBody3D.new()
		t.set_script(target_script)
		t.position = p
		add_child(t)

	var layer := CanvasLayer.new()
	add_child(layer)
	var hud := Control.new()
	hud.set_script(load("res://touch_hud.gd"))
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hud)

	var player := CharacterBody3D.new()
	player.set_script(load("res://player.gd"))
	player.hud = hud
	player.position = Vector3(0, 0.1, 24)
	add_child(player)

func box(pos: Vector3, sz: Vector3, color: Color) -> void:
	var b := StaticBody3D.new()
	b.position = pos
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	b.add_child(m)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = sz
	c.shape = s
	b.add_child(c)
	add_child(b)
