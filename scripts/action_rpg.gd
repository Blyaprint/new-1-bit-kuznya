extends Node3D

const WORLD_SIZE := 24.0
const PLAYER_SPEED := 5.2
const PLAYER_MAX_HP := 100
const ENEMY_COUNT := 6

var player: CharacterBody3D
var camera: Camera3D
var enemies: Array[Dictionary] = []
var loot: Array[Dictionary] = []
var player_hp := PLAYER_MAX_HP
var attack_cooldown := 0.0
var dash_cooldown := 0.0
var dash_time := 0.0
var invulnerability := 0.0
var skill_cooldown := 0.0
var move_target := Vector3.ZERO
var has_move_target := false
var attack_target: Node3D = null
var click_marker: MeshInstance3D
var gold := 0
var defeated := 0
var game_over := false
var paused := false
var status_label: Label
var hp_label: Label
var hp_fill: ColorRect
var gold_label: Label
var objective_label: Label
var overlay: ColorRect
var result_label: Label
var weapon_pivot: Node3D
var attack_anim_time := 0.0
var combat_effects: Array[Dictionary] = []

var mat_floor: StandardMaterial3D
var mat_tile_a: StandardMaterial3D
var mat_tile_b: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_player: StandardMaterial3D
var mat_enemy: StandardMaterial3D
var mat_bone: StandardMaterial3D
var mat_gold: StandardMaterial3D
var mat_torch: StandardMaterial3D
var mat_sword: StandardMaterial3D
var mat_bronze: StandardMaterial3D
var mat_accent: StandardMaterial3D
var mat_shadow: StandardMaterial3D

func _ready() -> void:
	_build_materials()
	_build_world()
	_build_player()
	_build_enemies()
	_build_camera()
	_build_hud()
	_update_hud()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_materials() -> void:
	mat_floor = _mat(Color("#242b35"))
	mat_tile_a = _mat(Color("#303a46"))
	mat_tile_b = _mat(Color("#28323d"))
	mat_wall = _mat(Color("#48515b"))
	mat_player = _mat(Color("#d5d0bd"))
	mat_enemy = _mat(Color("#343a45"))
	mat_bone = _mat(Color("#d8d0b8"))
	mat_gold = _mat(Color("#e5b95c"), true)
	mat_torch = _mat(Color("#ffad58"), true)
	mat_sword = _mat(Color("#9fb8c8"), true)
	mat_bronze = _mat(Color("#8c7150"))
	mat_accent = _mat(Color("#6f9b9b"), true)
	mat_shadow = _mat(Color("#101820"))

func _mat(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	if glow:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.65
	return material

func _build_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#111821")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#788392")
	environment.ambient_light_energy = 0.38
	environment.ambient_light_color = Color("#65717f")
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_color = Color("#9eafc0")
	sun.light_energy = 0.52
	sun.shadow_enabled = true
	add_child(sun)

	var floor_body := StaticBody3D.new()
	floor_body.name = "DungeonFloor"
	add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
	floor_mesh.mesh = plane
	floor_mesh.material_override = mat_floor
	floor_body.add_child(floor_mesh)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(WORLD_SIZE, 0.3, WORLD_SIZE)
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.18
	floor_body.add_child(floor_collision)

	for x in range(-6, 6):
		for z in range(-6, 6):
			var tile := MeshInstance3D.new()
			var tile_mesh := BoxMesh.new()
			tile_mesh.size = Vector3(1.94, 0.045, 1.94)
			tile.mesh = tile_mesh
			tile.material_override = mat_tile_a if (x + z) % 2 == 0 else mat_tile_b
			tile.position = Vector3(float(x) * 2.0, 0.015, float(z) * 2.0)
			add_child(tile)

	_add_wall(Vector3(0, 1.1, -12), Vector3(24, 2.2, 0.7))
	_add_wall(Vector3(0, 1.1, 12), Vector3(24, 2.2, 0.7))
	_add_wall(Vector3(-12, 1.1, 0), Vector3(0.7, 2.2, 24))
	_add_wall(Vector3(12, 1.1, 0), Vector3(0.7, 2.2, 24))
	_add_dungeon_sigil()
	_build_click_marker()

	for p in [Vector3(-8, 0, -8), Vector3(8, 0, -8), Vector3(-8, 0, 8), Vector3(8, 0, 8)]:
		_add_pillar(p)
	for p in [Vector3(-10.5, 0, -4), Vector3(10.5, 0, 4), Vector3(-4, 0, -10.5), Vector3(4, 0, 10.5)]:
		_add_torch(p)

func _build_click_marker() -> void:
	click_marker = MeshInstance3D.new()
	var marker_mesh := TorusMesh.new()
	marker_mesh.inner_radius = 0.24
	marker_mesh.outer_radius = 0.31
	click_marker.mesh = marker_mesh
	click_marker.material_override = mat_accent
	click_marker.visible = false
	click_marker.position.y = 0.075
	add_child(click_marker)

func _add_dungeon_sigil() -> void:
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.65
	ring_mesh.outer_radius = 2.78
	ring.mesh = ring_mesh
	ring.material_override = mat_bronze
	ring.position.y = 0.055
	add_child(ring)
	for angle in range(0, 360, 45):
		var rune := MeshInstance3D.new()
		var rune_mesh := BoxMesh.new()
		rune_mesh.size = Vector3(0.16, 0.035, 0.48)
		rune.mesh = rune_mesh
		rune.material_override = mat_accent
		var radians := deg_to_rad(float(angle))
		rune.position = Vector3(cos(radians) * 2.42, 0.06, sin(radians) * 2.42)
		rune.rotation.y = -radians
		add_child(rune)
	var center := MeshInstance3D.new()
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.62
	center_mesh.bottom_radius = 0.62
	center_mesh.height = 0.035
	center.mesh = center_mesh
	center.material_override = mat_shadow
	center.position.y = 0.06
	add_child(center)

func _add_wall(pos: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = mat_wall
	body.add_child(mesh)
	var trim := MeshInstance3D.new()
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(dimensions.x + 0.08, 0.12, dimensions.z + 0.08)
	trim.mesh = trim_mesh
	trim.material_override = mat_bronze
	trim.position.y = dimensions.y * 0.5 - 0.08
	body.add_child(trim)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)

func _add_pillar(pos: Vector3) -> void:
	var pillar_body := StaticBody3D.new()
	pillar_body.position = pos + Vector3(0, 1.4, 0)
	add_child(pillar_body)
	var pillar := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 2.8, 1.0)
	pillar.mesh = mesh
	pillar.material_override = mat_wall
	pillar_body.add_child(pillar)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.28, 0.22, 1.28)
	base.mesh = base_mesh
	base.material_override = mat_bronze
	base.position.y = -1.28
	pillar_body.add_child(base)
	var capital := MeshInstance3D.new()
	var capital_mesh := BoxMesh.new()
	capital_mesh.size = Vector3(1.24, 0.2, 1.24)
	capital.mesh = capital_mesh
	capital.material_override = mat_bronze
	capital.position.y = 1.28
	pillar_body.add_child(capital)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	pillar_body.add_child(collision)

func _add_torch(pos: Vector3) -> void:
	var stand := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.09
	mesh.bottom_radius = 0.15
	mesh.height = 1.2
	stand.mesh = mesh
	stand.material_override = mat_wall
	stand.position = pos + Vector3(0, 0.6, 0)
	add_child(stand)
	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.14
	flame_mesh.height = 0.34
	flame.mesh = flame_mesh
	flame.material_override = mat_torch
	flame.position = pos + Vector3(0, 1.35, 0)
	add_child(flame)
	var crown := MeshInstance3D.new()
	var crown_mesh := BoxMesh.new()
	crown_mesh.size = Vector3(0.34, 0.08, 0.34)
	crown.mesh = crown_mesh
	crown.material_override = mat_bronze
	crown.position = pos + Vector3(0, 1.18, 0)
	add_child(crown)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 1.45, 0)
	light.light_color = Color("#ffad66")
	light.light_energy = 1.5
	light.omni_range = 5.0
	add_child(light)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.9, 4.0)
	player.floor_snap_length = 0.25
	player.set_meta("facing", Vector3.FORWARD)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.35
	collision.shape = capsule
	collision.position.y = 0.0
	player.add_child(collision)

	var torso := MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.58, 0.76, 0.38)
	torso.mesh = torso_mesh
	torso.material_override = mat_player
	torso.position.y = -0.04
	player.add_child(torso)
	var chest_plate := MeshInstance3D.new()
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.48, 0.44, 0.08)
	chest_plate.mesh = chest_mesh
	chest_plate.material_override = mat_bronze
	chest_plate.position = Vector3(0, 0.02, -0.22)
	player.add_child(chest_plate)
	for shoulder_x in [-0.36, 0.36]:
		var shoulder := MeshInstance3D.new()
		var shoulder_mesh := SphereMesh.new()
		shoulder_mesh.radius = 0.18
		shoulder_mesh.height = 0.28
		shoulder.mesh = shoulder_mesh
		shoulder.material_override = mat_bronze
		shoulder.position = Vector3(shoulder_x, 0.2, 0)
		player.add_child(shoulder)
	var belt := MeshInstance3D.new()
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(0.62, 0.12, 0.42)
	belt.mesh = belt_mesh
	belt.material_override = mat_bronze
	belt.position.y = -0.32
	player.add_child(belt)

	var cloak := MeshInstance3D.new()
	var cloak_mesh := BoxMesh.new()
	cloak_mesh.size = Vector3(0.58, 0.68, 0.18)
	cloak.mesh = cloak_mesh
	cloak.material_override = _mat(Color("#536b78"))
	cloak.position = Vector3(0, -0.05, 0.22)
	player.add_child(cloak)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head.mesh = head_mesh
	head.material_override = mat_bone
	head.position.y = 0.63
	player.add_child(head)

	var helmet := MeshInstance3D.new()
	var helmet_mesh := BoxMesh.new()
	helmet_mesh.size = Vector3(0.52, 0.16, 0.48)
	helmet.mesh = helmet_mesh
	helmet.material_override = mat_wall
	helmet.position.y = 0.83
	player.add_child(helmet)

	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector3(0.43, 0.02, -0.08)
	player.add_child(weapon_pivot)
	var sword := MeshInstance3D.new()
	var sword_mesh := BoxMesh.new()
	sword_mesh.size = Vector3(0.11, 0.78, 0.055)
	sword.mesh = sword_mesh
	sword.material_override = mat_sword
	sword.rotation.z = -0.22
	weapon_pivot.add_child(sword)
	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.32, 0.07, 0.11)
	guard.mesh = guard_mesh
	guard.material_override = mat_bronze
	guard.position = Vector3(0, -0.18, 0)
	guard.rotation.z = -0.22
	weapon_pivot.add_child(guard)
	var foot_shadow := MeshInstance3D.new()
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.48
	shadow_mesh.bottom_radius = 0.48
	shadow_mesh.height = 0.018
	foot_shadow.mesh = shadow_mesh
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0.015, 0.025, 0.035, 0.48)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foot_shadow.material_override = shadow_mat
	foot_shadow.position.y = -0.62
	player.add_child(foot_shadow)

func _build_enemies() -> void:
	var spawn_points := [
		Vector3(-5, 0, -5), Vector3(0, 0, -7), Vector3(5, 0, -5),
		Vector3(-6, 0, 1), Vector3(6, 0, 1), Vector3(0, 0, -1)
	]
	for point in spawn_points:
		var enemy := Node3D.new()
		enemy.name = "BoneWarden"
		enemy.position = point + Vector3(0, 0.48, 0)
		add_child(enemy)
		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.32
		body_mesh.height = 0.95
		body.mesh = body_mesh
		body.material_override = mat_enemy
		enemy.add_child(body)
		for rib_index in range(3):
			var rib := MeshInstance3D.new()
			var rib_mesh := BoxMesh.new()
			rib_mesh.size = Vector3(0.46 - float(rib_index) * 0.06, 0.07, 0.12)
			rib.mesh = rib_mesh
			rib.material_override = mat_bone
			rib.position = Vector3(0, 0.12 - float(rib_index) * 0.16, -0.25)
			enemy.add_child(rib)
		for shoulder_x in [-0.3, 0.3]:
			var shoulder_bone := MeshInstance3D.new()
			var bone_mesh := BoxMesh.new()
			bone_mesh.size = Vector3(0.18, 0.16, 0.18)
			shoulder_bone.mesh = bone_mesh
			shoulder_bone.material_override = mat_bone
			shoulder_bone.position = Vector3(shoulder_x, 0.34, 0)
			enemy.add_child(shoulder_bone)
		var skull := MeshInstance3D.new()
		var skull_mesh := SphereMesh.new()
		skull_mesh.radius = 0.23
		skull_mesh.height = 0.46
		skull.mesh = skull_mesh
		skull.material_override = mat_bone
		skull.position.y = 0.62
		enemy.add_child(skull)
		var eye_mat := _mat(Color("#e6a66d"), true)
		for eye_x in [-0.09, 0.09]:
			var eye := MeshInstance3D.new()
			var eye_mesh := SphereMesh.new()
			eye_mesh.radius = 0.035
			eye_mesh.height = 0.07
			eye.mesh = eye_mesh
			eye.material_override = eye_mat
			eye.position = Vector3(eye_x, 0.65, -0.19)
			enemy.add_child(eye)
		var selection_ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.43
		ring_mesh.outer_radius = 0.49
		selection_ring.mesh = ring_mesh
		selection_ring.material_override = mat_accent
		selection_ring.position.y = -0.43
		selection_ring.visible = false
		enemy.add_child(selection_ring)
		enemies.append({"node": enemy, "hp": 3, "attack_timer": 0.6, "flash": 0.0, "selection_ring": selection_ring})

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16.5
	camera.position = player.global_position + Vector3(10, 12, 10)
	camera.look_at(player.global_position, Vector3.UP)
	add_child(camera)
	camera.current = true

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(178, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101820", 0.96)
	style.border_color = Color("#9a805d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	hp_label = Label.new()
	hp_label.text = "ЗДОРОВЬЕ  100 / 100"
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color("#e9e4d5"))
	column.add_child(hp_label)
	var hp_back := ColorRect.new()
	hp_back.color = Color("#3b2830")
	hp_back.custom_minimum_size = Vector2(158, 6)
	column.add_child(hp_back)
	hp_fill = ColorRect.new()
	hp_fill.color = Color("#bd6260")
	hp_fill.size = Vector2(158, 6)
	hp_back.add_child(hp_fill)

	gold_label = _hud_label("ЗОЛОТО  0", 10, Color("#e5bd72"))
	gold_label.position = Vector2(10, 67)
	layer.add_child(gold_label)
	objective_label = _hud_label("ЗАЧИСТИ ПОДЗЕМЕЛЬЕ", 10, Color("#e9e4d5"))
	objective_label.anchor_left = 1.0
	objective_label.anchor_right = 1.0
	objective_label.offset_left = -190
	objective_label.offset_right = -10
	objective_label.offset_top = 14
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(objective_label)
	status_label = _hud_label("ЛКМ — ДВИЖЕНИЕ / АТАКА   ПКМ — ВИХРЬ   Q — РЫВОК", 9, Color("#b9c3cc"))
	status_label.anchor_top = 1.0
	status_label.anchor_bottom = 1.0
	status_label.offset_left = 10
	status_label.offset_top = -22
	status_label.offset_bottom = -8
	layer.add_child(status_label)

	overlay = ColorRect.new()
	overlay.color = Color(0.03, 0.05, 0.08, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	layer.add_child(overlay)
	result_label = _hud_label("", 18, Color("#f1e7d0"))
	result_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_label.position = Vector2(-115, -28)
	result_label.size = Vector2(230, 56)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(result_label)

func _hud_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("#080c12"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _process(delta: float) -> void:
	if paused or game_over:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_time = maxf(0.0, dash_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	_update_camera()
	_update_weapon_animation(delta)
	_update_combat_effects(delta)
	_update_enemies(delta)
	_update_loot()
	_update_hud()

func _physics_process(delta: float) -> void:
	if paused or game_over or player == null:
		return
	var move_dir := Vector3.ZERO
	if attack_target != null and is_instance_valid(attack_target):
		var to_enemy := attack_target.global_position - player.global_position
		to_enemy.y = 0.0
		if to_enemy.length() > 1.7:
			move_dir = to_enemy.normalized()
		else:
			player.look_at(player.global_position + to_enemy.normalized(), Vector3.UP)
			if attack_cooldown <= 0.0:
				_attack_target()
	else:
		attack_target = null
		if has_move_target:
			var to_point := move_target - player.global_position
			to_point.y = 0.0
			if to_point.length() > 0.18:
				move_dir = to_point.normalized()
			else:
				has_move_target = false
				if click_marker != null:
					click_marker.visible = false
		# WASD remains as an optional alternative to mouse movement.
		var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if keyboard.length() > 0.1:
			var camera_right := camera.global_transform.basis.x
			var camera_forward := -camera.global_transform.basis.z
			camera_right.y = 0.0
			camera_forward.y = 0.0
			move_dir = (camera_right.normalized() * keyboard.x) + (camera_forward.normalized() * -keyboard.y)
			move_dir = move_dir.normalized()
			has_move_target = false
	if attack_target == null:
		for enemy_data in enemies:
			var ring: MeshInstance3D = enemy_data["selection_ring"]
			ring.visible = false
	if move_dir.length() > 0.05:
		move_dir = move_dir.normalized()
		player.look_at(player.global_position + move_dir, Vector3.UP)
	var speed := PLAYER_SPEED * (2.5 if dash_time > 0.0 else 1.0)
	player.velocity.x = move_dir.x * speed
	player.velocity.z = move_dir.z * speed
	player.velocity.y -= 22.0 * delta
	player.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			paused = not paused
			status_label.text = "ПАУЗА — ESC ДЛЯ ПРОДОЛЖЕНИЯ" if paused else "ЛКМ — ДВИЖЕНИЕ / АТАКА   ПКМ — ВИХРЬ   Q — РЫВОК"
		elif event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
		elif (event.keycode == KEY_Q or event.keycode == KEY_SPACE) and dash_cooldown <= 0.0:
			_dash()
		elif event.keycode == KEY_E and skill_cooldown <= 0.0:
			_spin_attack()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_spin_attack()

func _face_toward_mouse() -> void:
	if camera == null or player == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse)
	var ray_direction := camera.project_ray_normal(mouse)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
	if hit != null:
		var direction: Vector3 = hit - player.global_position
		direction.y = 0.0
		if direction.length() > 0.05:
			player.look_at(player.global_position + direction.normalized(), Vector3.UP)

func _dash() -> void:
	var direction := Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	if direction.length() < 0.1 and attack_target != null and is_instance_valid(attack_target):
		direction = attack_target.global_position - player.global_position
		direction.y = 0.0
		direction = direction.normalized()
	if direction.length() < 0.1 and has_move_target:
		direction = move_target - player.global_position
		direction.y = 0.0
		direction = direction.normalized()
	if direction.length() < 0.1:
		direction = -player.global_transform.basis.z
	dash_time = 0.22
	dash_cooldown = 1.3
	player.velocity.x = direction.x * 13.0
	player.velocity.z = direction.z * 13.0
	invulnerability = 0.28

func _handle_left_click() -> void:
	if game_over or paused:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var selected_enemy: Node3D = null
	var nearest_screen_distance := 42.0
	for enemy_data in enemies:
		var enemy_node: Node3D = enemy_data["node"]
		var enemy_screen_pos := camera.unproject_position(enemy_node.global_position + Vector3.UP * 0.45)
		var screen_distance := enemy_screen_pos.distance_to(mouse_pos)
		if screen_distance < nearest_screen_distance:
			nearest_screen_distance = screen_distance
			selected_enemy = enemy_node
	if selected_enemy != null:
		attack_target = selected_enemy
		has_move_target = false
		if click_marker != null:
			click_marker.visible = false
		for enemy_data in enemies:
			var ring: MeshInstance3D = enemy_data["selection_ring"]
			ring.visible = enemy_data["node"] == selected_enemy
		status_label.text = "ЦЕЛЬ ВЫБРАНА"
		return
	attack_target = null
	for enemy_data in enemies:
		var ring: MeshInstance3D = enemy_data["selection_ring"]
		ring.visible = false
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)
	var ground_hit = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
	if ground_hit != null:
		move_target = ground_hit
		move_target.x = clampf(move_target.x, -10.7, 10.7)
		move_target.z = clampf(move_target.z, -10.7, 10.7)
		has_move_target = true
		if click_marker != null:
			click_marker.global_position = Vector3(move_target.x, 0.075, move_target.z)
			click_marker.visible = true
		status_label.text = "ДВИЖЕНИЕ"


func _update_weapon_animation(delta: float) -> void:
	if weapon_pivot == null:
		return
	if attack_anim_time > 0.0:
		attack_anim_time = maxf(0.0, attack_anim_time - delta)
		var progress := 1.0 - attack_anim_time / 0.24
		var swing := sin(progress * PI)
		weapon_pivot.rotation.z = lerpf(-0.22, -1.35, swing)
	else:
		weapon_pivot.rotation.z = lerpf(weapon_pivot.rotation.z, -0.22, minf(1.0, delta * 18.0))

func _spawn_combat_burst(world_position: Vector3, radius: float, effect_material: Material) -> void:
	var effect := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 0.78
	ring.outer_radius = radius
	effect.mesh = ring
	effect.material_override = effect_material
	effect.global_position = world_position
	effect.rotation_degrees.x = 90.0
	effect.scale = Vector3.ONE * 0.25
	add_child(effect)
	combat_effects.append({"node": effect, "life": 0.22, "duration": 0.22})

func _update_combat_effects(delta: float) -> void:
	for i in range(combat_effects.size() - 1, -1, -1):
		var effect: Dictionary = combat_effects[i]
		var node: MeshInstance3D = effect["node"]
		if not is_instance_valid(node):
			combat_effects.remove_at(i)
			continue
		effect["life"] = maxf(0.0, float(effect["life"]) - delta)
		var progress := 1.0 - float(effect["life"]) / float(effect["duration"])
		node.scale = Vector3.ONE * lerpf(0.25, 1.0, progress)
		node.transparency = progress
		if float(effect["life"]) <= 0.0:
			node.queue_free()
			combat_effects.remove_at(i)
		else:
			combat_effects[i] = effect

func _attack_target() -> void:
	if attack_cooldown > 0.0 or attack_target == null or not is_instance_valid(attack_target):
		return
	attack_cooldown = 0.42
	attack_anim_time = 0.24
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i]["node"] == attack_target:
			_damage_enemy(i, 1)
			_spawn_combat_burst(attack_target.global_position + Vector3.UP * 0.12, 0.72, mat_sword)
			status_label.text = "ПОПАДАНИЕ!"
			if attack_target == null or not is_instance_valid(attack_target):
				attack_target = null
			return
	attack_target = null

func _spin_attack() -> void:
	if game_over or paused:
		return
	skill_cooldown = 4.0
	_spawn_combat_burst(player.global_position + Vector3.UP * 0.08, 3.0, mat_accent)
	var hit_any := false
	for i in range(enemies.size() - 1, -1, -1):
		var enemy_node: Node3D = enemies[i]["node"]
		var offset: Vector3 = enemy_node.global_position - player.global_position
		if Vector2(offset.x, offset.z).length() <= 3.0:
			_damage_enemy(i, 2)
			_spawn_combat_burst(enemy_node.global_position + Vector3.UP * 0.12, 0.9, mat_accent)
			hit_any = true
	status_label.text = "ВИХРЬ!" if hit_any else "ВИХРЬ — НИКОГО НЕ ЗАДЕЛ"

func _damage_enemy(index: int, amount: int) -> void:
	var enemy: Dictionary = enemies[index]
	enemy["hp"] = int(enemy["hp"]) - amount
	var node: Node3D = enemy["node"]
	node.scale = Vector3(1.12, 0.88, 1.12)
	enemy["flash"] = 0.12
	if int(enemy["hp"]) <= 0:
		var drop := Node3D.new()
		drop.position = node.position + Vector3(0, 0.3, 0)
		var orb := MeshInstance3D.new()
		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.16
		orb_mesh.height = 0.32
		orb.mesh = orb_mesh
		orb.material_override = mat_gold
		drop.add_child(orb)
		add_child(drop)
		loot.append({"node": drop, "value": 5})
		node.queue_free()
		enemies.remove_at(index)
		defeated += 1
		if enemies.is_empty():
			_finish_game(true)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var node: Node3D = enemy["node"]
		if not is_instance_valid(node):
			enemies.remove_at(i)
			continue
		var to_player := player.global_position - node.global_position
		to_player.y = 0.0
		var distance := to_player.length()
		if distance > 1.05:
			var direction := to_player.normalized()
			node.position += direction * 1.55 * delta
			node.look_at(node.global_position + direction, Vector3.UP)
		else:
			enemy["attack_timer"] = float(enemy["attack_timer"]) - delta
			if float(enemy["attack_timer"]) <= 0.0:
				enemy["attack_timer"] = 1.15
				if invulnerability <= 0.0:
					player_hp = maxi(0, player_hp - 9)
					invulnerability = 0.5
					status_label.text = "ТЫ ПОЛУЧИЛ УРОН"
					if player_hp <= 0:
						_finish_game(false)
		if float(enemy["flash"]) > 0.0:
			enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
			if float(enemy["flash"]) == 0.0:
				node.scale = Vector3.ONE
		enemies[i] = enemy

func _update_loot() -> void:
	for i in range(loot.size() - 1, -1, -1):
		var drop: Node3D = loot[i]["node"]
		if not is_instance_valid(drop):
			loot.remove_at(i)
			continue
		drop.rotate_y(0.035)
		drop.position.y = 0.3 + sin(Time.get_ticks_msec() * 0.004 + i) * 0.08
		if drop.global_position.distance_to(player.global_position) < 0.9:
			gold += int(loot[i]["value"])
			drop.queue_free()
			loot.remove_at(i)
			status_label.text = "ПОДОБРАНО: 5 ЗОЛОТА"

func _update_camera() -> void:
	if camera == null or player == null:
		return
	# Diablo-style camera: fixed orthographic angle, distance and zoom.
	# It follows the hero instantly without rotation, zoom or interpolation.
	camera.global_position = player.global_position + Vector3(9.5, 11.5, 9.5)
	camera.look_at(player.global_position + Vector3(0, 0.25, 0), Vector3.UP)

func _update_hud() -> void:
	if hp_label == null:
		return
	hp_label.text = "ЗДОРОВЬЕ  %d / %d" % [player_hp, PLAYER_MAX_HP]
	hp_fill.size.x = 158.0 * float(player_hp) / float(PLAYER_MAX_HP)
	gold_label.text = "ЗОЛОТО  %d" % gold
	objective_label.text = "ПОДЗЕМЕЛЬЕ  %d / %d" % [defeated, ENEMY_COUNT]

func _finish_game(victory: bool) -> void:
	game_over = true
	overlay.visible = true
	result_label.text = "ПОДЗЕМЕЛЬЕ ЗАЧИЩЕНО\nЗОЛОТО: %d\n\nR — ЗАНОВО" % gold if victory else "ТЫ ПОГИБ\nУБИЙСТВ: %d\n\nR — ПОВТОРИТЬ" % defeated

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
