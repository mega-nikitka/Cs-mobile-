extends Control

var move := Vector2.ZERO
var look_delta := Vector2.ZERO
var fire_held := false
var jump_pressed := false
var reload_pressed := false
var info := ""

const STICK_R := 110.0
var _move_id := -1
var _look_id := -1
var _fire_id := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO

func _fire_c() -> Vector2: return get_viewport_rect().size - Vector2(200, 180)
func _jump_c() -> Vector2: return get_viewport_rect().size - Vector2(80, 330)
func _reload_c() -> Vector2: return get_viewport_rect().size - Vector2(350, 100)

func _process(_d: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	var half := get_viewport_rect().size.x * 0.5
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		var i: int = event.index
		if event.pressed:
			if p.distance_to(_fire_c()) < 105:
				_fire_id = i
				fire_held = true
			elif p.distance_to(_jump_c()) < 75:
				jump_pressed = true
			elif p.distance_to(_reload_c()) < 70:
				reload_pressed = true
			elif p.x < half and _move_id == -1:
				_move_id = i
				_origin = p
				_knob = p
			elif p.x >= half and _look_id == -1:
				_look_id = i
		else:
			if i == _fire_id:
				_fire_id = -1
				fire_held = false
			elif i == _move_id:
				_move_id = -1
				move = Vector2.ZERO
			elif i == _look_id:
				_look_id = -1
	elif event is InputEventScreenDrag:
		var i: int = event.index
		if i == _move_id:
			var d: Vector2 = event.position - _origin
			move = (d / STICK_R).limit_length(1.0)
			_knob = _origin + d.limit_length(STICK_R)
		elif i == _look_id or i == _fire_id:
			look_delta += event.relative

func _draw() -> void:
	var s := get_viewport_rect().size
	var white := Color(1, 1, 1, 0.35)
	var c := s * 0.5
	for off in [Vector2(-14, 0), Vector2(6, 0), Vector2(0, -14), Vector2(0, 6)]:
		var horiz: bool = off.y == 0
		draw_rect(Rect2(c + off - (Vector2(0, 1) if horiz else Vector2(1, 0)), Vector2(8, 2) if horiz else Vector2(2, 8)), Color(0.2, 1, 0.3, 0.9))
	var base := _origin if _move_id != -1 else Vector2(180, s.y - 180)
	var knob := _knob if _move_id != -1 else base
	draw_arc(base, STICK_R, 0, TAU, 48, white, 4)
	draw_circle(knob, 45, Color(1, 1, 1, 0.3))
	_btn(_fire_c(), 85, "FIRE", fire_held)
	_btn(_jump_c(), 60, "JUMP", false)
	_btn(_reload_c(), 55, "R", false)
	draw_string(ThemeDB.fallback_font, Vector2(s.x - 260, 50), info, HORIZONTAL_ALIGNMENT_RIGHT, 240, 36, Color.WHITE)

func _btn(pos: Vector2, r: float, label: String, active: bool) -> void:
	draw_circle(pos, r, Color(1, 1, 1, 0.3 if active else 0.15))
	draw_arc(pos, r, 0, TAU, 40, Color(1, 1, 1, 0.45), 3)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-r, 8), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2, 22, Color.WHITE)
