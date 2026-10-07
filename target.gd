extends StaticBody3D

var hp := 100
var col: CollisionShape3D
var mats: Array = []
var colors: Array = []

func _part(mesh: Mesh, pos: Vector3, color: Color, flash := true) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	m.material_override = mat
	add_child(m)
	if flash:
		mats.append(mat)
		colors.append(color)

func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	return b

func _ball(r: float, h: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h
	return s

func _ready() -> void:
	col = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

	var pants := Color(0.2, 0.22, 0.3)
	var shirt := Color(0.7, 0.2, 0.15)
	var skin := Color(0.85, 0.65, 0.5)
	_part(_box(0.18, 0.8, 0.22), Vector3(-0.12, 0.4, 0), pants)
	_part(_box(0.18, 0.8, 0.22), Vector3(0.12, 0.4, 0), pants)
	_part(_box(0.5, 0.6, 0.28), Vector3(0, 1.1, 0), shirt)
	_part(_box(0.12, 0.55, 0.14), Vector3(-0.32, 1.1, 0), shirt)
	_part(_box(0.12, 0.55, 0.14), Vector3(0.32, 1.1, 0), shirt)
	_part(_ball(0.13, 0.26), Vector3(0, 1.6, 0), skin)
	_part(_ball(0.15, 0.16), Vector3(0, 1.7, 0), Color(0.15, 0.17, 0.15))

func take_damage(dmg: int, pos: Vector3) -> void:
	if hp <= 0:
		return
	if pos.y - global_position.y > 1.5:
		dmg *= 4
	hp -= dmg
	for m in mats:
		m.albedo_color = Color.WHITE
	if hp <= 0:
		die()
	await get_tree().create_timer(0.08).timeout
	for i in mats.size():
		mats[i].albedo_color = colors[i]

func die() -> void:
	col.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(self, "rotation_degrees:x", -90.0, 0.3)
	await tw.finished
	hide()
	await get_tree().create_timer(3.0).timeout
	hp = 100
	rotation_degrees.x = 0
	show()
	col.set_deferred("disabled", false)
