extends CharacterBody3D

var hud
const SPEED := 6.0
const JUMP_V := 5.5
const GRAVITY := 16.0
const SENS := 0.004
const MAG_SIZE := 30
const GUN_BASE := Vector3(0.22, -0.22, -0.45)

var pitch := 0.0
var hp := 100
var mag := MAG_SIZE
var reserve := 90
var cooldown := 0.0
var reloading := false
var head: Node3D
var cam: Camera3D
var gun: Node3D
var flash: MeshInstance3D

func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 75
	head.add_child(cam)
	cam.current = true

	gun = Node3D.new()
	gun.position = GUN_BASE
	cam.add_child(gun)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.1, 0.5)
	body.mesh = bm
	body.material_override = _mat(Color(0.15, 0.15, 0.17))
	gun.add_child(body)
	flash = MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.06
	fm.height = 0.12
	flash.mesh = fm
	flash.material_override = _mat(Color(1, 0.8, 0.2), true)
	flash.position = Vector3(0, 0, -0.32)
	flash.visible = false
	gun.add_child(flash)

func _physics_process(delta: float) -> void:
	var look: Vector2 = hud.look_delta
	hud.look_delta = Vector2.ZERO
	rotate_y(-look.x * SENS)
	pitch = clamp(pitch - look.y * SENS, -1.4, 1.4)
	head.rotation.x = pitch

	var dir: Vector3 = transform.basis * Vector3(hud.move.x, 0, hud.move.y)
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		if hud.jump_pressed:
			velocity.y = JUMP_V
	else:
		velocity.y -= GRAVITY * delta
	hud.jump_pressed = false
	move_and_slide()

	cooldown -= delta
	if hud.reload_pressed:
		hud.reload_pressed = false
		reload()
	if hud.fire_held and cooldown <= 0.0 and not reloading:
		if mag > 0:
			shoot()
		else:
			reload()
	gun.position = gun.position.lerp(GUN_BASE, 12.0 * delta)
	hud.info = "RELOAD..." if reloading else "%d / %d" % [mag, reserve]

func shoot() -> void:
	mag -= 1
	cooldown = 0.1
	gun.position.z += 0.05
	pitch = clamp(pitch + 0.004, -1.4, 1.4)
	flash.visible = true
	get_tree().create_timer(0.04).timeout.connect(func(): flash.visible = false)

	var spread: float = 0.01 + hud.move.length() * 0.03
    var b := cam.global_transform.basis
	var dir := -b.z + b.x * randf_range(-spread, spread) + b.y * randf_range(-spread, spread)
	var from := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + dir.normalized() * 100.0)
	q.exclude = [get_rid()]
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r:
		var c = r.collider
		if c.has_method("take_damage"):
			c.take_damage(25, r.position)
		else:
			spawn_hole(r.position, r.normal)

func spawn_hole(pos: Vector3, normal: Vector3) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	m.mesh = s
	m.material_override = _mat(Color(0.1, 0.1, 0.1))
	get_parent().add_child(m)
	m.global_position = pos + normal * 0.02
	get_tree().create_timer(6.0).timeout.connect(m.queue_free)

func reload() -> void:
	if reloading or mag == MAG_SIZE or reserve <= 0:
		return
	reloading = true
	await get_tree().create_timer(1.8).timeout
	var take: int = min(MAG_SIZE - mag, reserve)
	mag += take
	reserve -= take
	reloading = false
