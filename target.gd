extends StaticBody3D

var hp := 100
var mat: StandardMaterial3D
var col: CollisionShape3D
const BASE := Color(0.8, 0.2, 0.2)

func _ready() -> void:
	col = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	mat = StandardMaterial3D.new()
	mat.albedo_color = BASE
	var m := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	m.mesh = cm
	m.position.y = 0.9
	m.material_override = mat
	add_child(m)

func take_damage(dmg: int, pos: Vector3) -> void:
	if hp <= 0:
		return
	if pos.y - global_position.y > 1.5:
		dmg *= 4
	hp -= dmg
	mat.albedo_color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	mat.albedo_color = BASE
	if hp <= 0:
		die()

func die() -> void:
	hide()
	col.set_deferred("disabled", true)
	await get_tree().create_timer(3.0).timeout
	hp = 100
	show()
	col.set_deferred("disabled", false)
