extends Node3D

var m_sand: StandardMaterial3D
var m_wall: StandardMaterial3D
var m_house: StandardMaterial3D
var m_crate: StandardMaterial3D
var m_concrete: StandardMaterial3D
var m_path: StandardMaterial3D
var m_barrel_a: StandardMaterial3D
var m_barrel_b: StandardMaterial3D
var m_site: StandardMaterial3D

func _ready() -> void:
	setup_environment()
	build_materials()
	build_map()
	spawn_targets()
	spawn_player()

func setup_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.45, 0.8)
	sky_mat.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky_mat.ground_horizon_color = Color(0.7, 0.7, 0.65)
	sky_mat.ground_bottom_color = Color(0.4, 0.38, 0.33)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.8, 0.85)
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 50.0
	add_child(sun)

func make_tex(base: Color, v: float, pattern: int) -> ImageTexture:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var k: float = 1.0 + randf_range(-v, v)
			var c: Color = base * k
			if pattern == 1:
				if y % 32 < 2 or (x + (y >> 5) * 16) % 32 < 2:
					c = base * 0.7
			elif pattern == 2:
				if y % 32 < 2:
					c = base * 0.6
			c.a = 1.0
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func make_mat(tex: Texture2D, tint: Color, sc: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(sc, sc, sc)
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

func plain(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.3
	m.roughness = 0.6
	return m

func build_materials() -> void:
	m_sand = make_mat(make_tex(Color(0.76, 0.68, 0.5), 0.08, 0), Color.WHITE, 0.25)
	m_wall = make_mat(make_tex(Color(0.72, 0.5, 0.38), 0.07, 1), Color.WHITE, 0.5)
	m_house = make_mat(make_tex(Color(0.85, 0.8, 0.7), 0.05, 1), Color.WHITE, 0.5)
	m_crate = make_mat(make_tex(Color(0.62, 0.43, 0.22), 0.1, 2), Color.WHITE, 1.0)
	m_concrete = make_mat(make_tex(Color(0.55, 0.55, 0.57), 0.1, 0), Color.WHITE, 0.5)
	m_path = make_mat(make_tex(Color(0.5, 0.45, 0.38), 0.1, 0), Color.WHITE, 0.3)
	m_barrel_a = plain(Color(0.6, 0.15, 0.1))
	m_barrel_b = plain(Color(0.2, 0.3, 0.4))
	m_site = StandardMaterial3D.new()
	m_site.albedo_color = Color(0.9, 0.65, 0.1, 0.6)
	m_site.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func box(pos: Vector3, sz: Vector3, material: Material, collide := true) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.position = pos
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	m.mesh = bm
	m.material_override = material
	b.add_child(m)
	if collide:
		var c := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = sz
		c.shape = s
		b.add_child(c)
	add_child(b)
	return b

func barrel(pos: Vector3, material: Material) -> void:
	var b := StaticBody3D.new()
	b.position = pos
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.4
	cm.bottom_radius = 0.4
	cm.height = 1.0
	m.mesh = cm
	m.material_override = material
	b.add_child(m)
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 0.4
	s.height = 1.0
	c.shape = s
	b.add_child(c)
	add_child(b)

func crate(pos: Vector3, size: float) -> void:
	box(pos, Vector3(size, size, size), m_crate)

func room(pos: Vector3, w: float, d: float, h: float) -> void:
	var door := 2.4
	var seg := (w - door) / 2.0
	box(Vector3(pos.x, h / 2, pos.z + d / 2), Vector3(w, h, 0.4), m_house)
	box(Vector3(pos.x - w / 2, h / 2, pos.z), Vector3(0.4, h, d), m_house)
	box(Vector3(pos.x + w / 2, h / 2, pos.z), Vector3(0.4, h, d), m_house)
	box(Vector3(pos.x - (door / 2 + seg / 2), h / 2, pos.z - d / 2), Vector3(seg, h, 0.4), m_house)
	box(Vector3(pos.x + (door / 2 + seg / 2), h / 2, pos.z - d / 2), Vector3(seg, h, 0.4), m_house)
	box(Vector3(pos.x, 2.5 + (h - 2.5) / 2, pos.z - d / 2), Vector3(door, h - 2.5, 0.4), m_house)
	box(Vector3(pos.x, h + 0.1, pos.z), Vector3(w + 0.6, 0.2, d + 0.6), m_concrete)

func site(pos: Vector3, letter: String) -> void:
	box(Vector3(pos.x, 0.03, pos.z), Vector3(8, 0.04, 8), m_site, false)
	var l := Label3D.new()
	l.text = letter
	l.font_size = 400
	l.pixel_size = 0.01
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.position = Vector3(pos.x, 0.07, pos.z)
	l.modulate = Color(1, 0.85, 0.2)
	add_child(l)

func build_map() -> void:
	box(Vector3(0, -0.5, 0), Vector3(60, 1, 60), m_sand)
	box(Vector3(0, 0.01, 0), Vector3(6, 0.02, 56), m_path, false)

	# внешние стены с карнизом
	box(Vector3(0, 2.5, -30), Vector3(60, 5, 1), m_wall)
	box(Vector3(0, 2.5, 30), Vector3(60, 5, 1), m_wall)
	box(Vector3(-30, 2.5, 0), Vector3(1, 5, 60), m_wall)
	box(Vector3(30, 2.5, 0), Vector3(1, 5, 60), m_wall)
	box(Vector3(0, 5.1, -30), Vector3(61, 0.2, 1.4), m_concrete, false)
	box(Vector3(0, 5.1, 30), Vector3(61, 0.2, 1.4), m_concrete, false)
	box(Vector3(-30, 5.1, 0), Vector3(1.4, 0.2, 61), m_concrete, false)
	box(Vector3(30, 5.1, 0), Vector3(1.4, 0.2, 61), m_concrete, false)

	# центральная стена
	box(Vector3(0, 1.5, 0), Vector3(8, 3, 1), m_wall)
	box(Vector3(0, 3.05, 0), Vector3(8.4, 0.1, 1.4), m_concrete, false)

	# дома
	room(Vector3(20, 0, 10), 10, 8, 3.5)
	room(Vector3(-21, 0, 14), 8, 6, 3.5)
	crate(Vector3(22, 0.6, 12), 1.2)
	crate(Vector3(-22, 0.6, 16), 1.2)

	# ящики
	crate(Vector3(-10, 0.75, 8), 1.5)
	crate(Vector3(-8.6, 0.75, 8.3), 1.5)
	crate(Vector3(-9.3, 2.25, 8.1), 1.5)
	crate(Vector3(10, 0.75, 6), 1.5)
	crate(Vector3(12, 1, -8), 2.0)
	crate(Vector3(-12, 1, -10), 2.0)
	crate(Vector3(-12, 2.6, -10), 1.2)

	# бочки
	barrel(Vector3(6, 0.5, -4), m_barrel_a)
	barrel(Vector3(6.9, 0.5, -4.3), m_barrel_a)
	barrel(Vector3(-5, 0.5, -14), m_barrel_b)
	barrel(Vector3(15, 0.5, -14), m_barrel_b)
	barrel(Vector3(-16, 0.5, 4), m_barrel_a)

	# бетонные блоки
	box(Vector3(-4, 0.5, 14), Vector3(3, 1, 0.6), m_concrete)
	box(Vector3(4, 0.5, 17), Vector3(3, 1, 0.6), m_concrete)
	box(Vector3(-6, 0.5, -20), Vector3(0.6, 1, 3), m_concrete)

	# площадки закладки
	site(Vector3(-20, 0, -6), "A")
	site(Vector3(18, 0, -18), "B")

func spawn_targets() -> void:
	var target_script := load("res://target.gd")
	for p in [Vector3(-8, 0, -12), Vector3(0, 0, -18), Vector3(8, 0, -14), Vector3(-15, 0, -22), Vector3(14, 0, -24), Vector3(0, 0, -6)]:
		var t := StaticBody3D.new()
		t.set_script(target_script)
		t.position = p
		add_child(t)

func spawn_player() -> void:
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
