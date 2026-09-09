extends Node2D

const ZombieScript = preload("res://scripts/game/zombie.gd")
const TurretScript = preload("res://scripts/game/turret.gd")
const TowerScript = preload("res://scripts/game/tower.gd")
const MineScript = preload("res://scripts/game/mine.gd")

const VIEW_W := 1920.0
const VIEW_H := 1080.0
const GROUND_Y := 880.0
const TOWER_POS := Vector2(900, GROUND_Y - 12)
const MINE_POS := Vector2(300, GROUND_Y - 12)
const SPAWN_X := 1980.0

var tower
var mine
var gold: int = 300
var wave: int = 0
var kills: int = 0
var gold_earned: int = 0
var gold_spent: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var tower_damage_taken: float = 0.0
var playtime: float = 0.0

var wave_state: String = "prep"
var prep_timer: float = 8.0
var spawn_timer: float = 0.0
var spawn_queue: Array[String] = []
var enemies_remaining: int = 0
var game_over: bool = false
var paused_game: bool = false

var ammo: int = 30
var magazine: int = 30
var weapon_damage: float = 30.0
var weapon_fire_rate: float = 8.0
var weapon_reload: float = 2.0
var weapon_spread: float = 0.035
var fire_cooldown: float = 0.0
var reloading: bool = false
var reload_timer: float = 0.0
var infinite_ammo: bool = false
var weapon_upgrade_levels := {"damage": 0, "magazine": 0, "reload": 0, "rate": 0, "accuracy": 0}

var turrets: Array = []
var occupied_hardpoints := {}
var selected_hardpoint: int = -1
var selected_turret = null
var build_panel: Panel
var detail_panel: Panel
var mine_panel: Panel
var tower_panel: Panel
var weapon_panel: Panel
var pause_panel: Panel
var game_over_panel: Panel
var debug_panel: Panel
var debug_overlay: Label

var gold_label: Label
var mine_rate_label: Label
var wave_label: Label
var enemy_label: Label
var timer_label: Label
var hp_label: Label
var ammo_label: Label
var reload_bar: ProgressBar
var message_label: Label
var crosshair: Label

var effects: Array[Dictionary] = []
var shake_time: float = 0.0
var shake_strength: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	setup_world()
	setup_ui()
	queue_redraw()

func setup_world() -> void:
	tower = TowerScript.new()
	tower.position = TOWER_POS
	tower.destroyed.connect(_on_tower_destroyed)
	tower.health_changed.connect(_on_tower_health_changed)
	tower.floor_added.connect(_on_floor_added)
	add_child(tower)
	mine = MineScript.new()
	mine.position = MINE_POS
	mine.gold_generated.connect(_on_mine_gold)
	add_child(mine)

func setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	gold_label = make_label(canvas, Vector2(32, 24), Vector2(300, 44), 28)
	mine_rate_label = make_label(canvas, Vector2(32, 67), Vector2(300, 34), 18)
	wave_label = make_label(canvas, Vector2(780, 20), Vector2(360, 44), 30, HORIZONTAL_ALIGNMENT_CENTER)
	enemy_label = make_label(canvas, Vector2(780, 62), Vector2(360, 30), 18, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label = make_label(canvas, Vector2(780, 92), Vector2(360, 30), 18, HORIZONTAL_ALIGNMENT_CENTER)
	hp_label = make_label(canvas, Vector2(1540, 24), Vector2(340, 44), 24, HORIZONTAL_ALIGNMENT_RIGHT)
	ammo_label = make_label(canvas, Vector2(1510, 976), Vector2(370, 50), 30, HORIZONTAL_ALIGNMENT_RIGHT)
	reload_bar = ProgressBar.new()
	reload_bar.position = Vector2(1510, 1030)
	reload_bar.size = Vector2(370, 14)
	reload_bar.max_value = 1.0
	reload_bar.show_percentage = false
	canvas.add_child(reload_bar)
	message_label = make_label(canvas, Vector2(610, 150), Vector2(700, 60), 26, HORIZONTAL_ALIGNMENT_CENTER)
	crosshair = make_label(canvas, Vector2.ZERO, Vector2(34, 34), 28, HORIZONTAL_ALIGNMENT_CENTER)
	crosshair.text = "+"
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mine_btn := make_button(canvas, "MINE", Vector2(28, 995), Vector2(150, 50))
	mine_btn.pressed.connect(func(): toggle_panel(mine_panel))
	var tower_btn := make_button(canvas, "TOWER", Vector2(190, 995), Vector2(150, 50))
	tower_btn.pressed.connect(func(): toggle_panel(tower_panel))
	var weapon_btn := make_button(canvas, "WEAPON", Vector2(352, 995), Vector2(170, 50))
	weapon_btn.pressed.connect(func(): toggle_panel(weapon_panel))
	var early_btn := make_button(canvas, "START WAVE", Vector2(800, 1000), Vector2(320, 48))
	early_btn.pressed.connect(start_wave_early)

	build_panel = create_build_panel(canvas)
	detail_panel = create_turret_panel(canvas)
	mine_panel = create_mine_panel(canvas)
	tower_panel = create_tower_panel(canvas)
	weapon_panel = create_weapon_panel(canvas)
	pause_panel = create_pause_panel(canvas)
	game_over_panel = create_game_over_panel(canvas)
	debug_panel = create_debug_panel(canvas)
	debug_overlay = make_label(canvas, Vector2(14, 180), Vector2(420, 240), 16)
	debug_overlay.visible = false
	refresh_ui()

func make_label(parent: Node, pos: Vector2, size_: Vector2, font_size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size_
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func make_button(parent: Node, text_: String, pos: Vector2, size_: Vector2) -> Button:
	var b := Button.new()
	b.text = text_
	b.position = pos
	b.size = size_
	b.add_theme_font_size_override("font_size", 17)
	parent.add_child(b)
	return b

func make_panel(parent: Node, title: String, pos: Vector2, size_: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size_
	p.visible = false
	parent.add_child(p)
	var title_label := make_label(p, Vector2(18, 10), Vector2(size_.x - 36, 42), 24)
	title_label.text = title
	return p

func create_build_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "BUILD TURRET", Vector2(590, 670), Vector2(740, 280))
	var defs := [
		["MG", "mg", 120], ["HEAVY MG", "hmg", 300], ["SHOTGUN", "shotgun", 350], ["SNIPER", "sniper", 450], ["ROCKET", "rocket", 750]
	]
	for i in range(defs.size()):
		var d = defs[i]
		var b := make_button(p, "%s\n%dG" % [d[0], d[2]], Vector2(20 + i * 142, 76), Vector2(128, 96))
		b.pressed.connect(func(): build_turret(d[1], d[2]))
	var close := make_button(p, "CLOSE", Vector2(550, 204), Vector2(160, 48))
	close.pressed.connect(func(): p.visible = false)
	return p

func create_turret_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "TURRET", Vector2(1450, 600), Vector2(420, 350))
	var stats := make_label(p, Vector2(20, 62), Vector2(380, 150), 18)
	stats.name = "Stats"
	var up := make_button(p, "UPGRADE", Vector2(20, 235), Vector2(180, 50))
	up.pressed.connect(upgrade_selected_turret)
	var sell := make_button(p, "SELL", Vector2(220, 235), Vector2(180, 50))
	sell.pressed.connect(sell_selected_turret)
	var close := make_button(p, "CLOSE", Vector2(120, 296), Vector2(180, 40))
	close.pressed.connect(func(): p.visible = false)
	return p

func create_mine_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "GOLD MINE", Vector2(80, 610), Vector2(390, 310))
	var stats := make_label(p, Vector2(20, 65), Vector2(350, 100), 20)
	stats.name = "Stats"
	var up := make_button(p, "UPGRADE MINE", Vector2(40, 190), Vector2(310, 58))
	up.pressed.connect(upgrade_mine)
	return p

func create_tower_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "TOWER", Vector2(510, 570), Vector2(410, 340))
	var stats := make_label(p, Vector2(20, 65), Vector2(370, 105), 19)
	stats.name = "Stats"
	var floor_btn := make_button(p, "ADD FLOOR", Vector2(35, 190), Vector2(340, 52))
	floor_btn.pressed.connect(add_tower_floor)
	var repair := make_button(p, "REPAIR 100 HP - 75G", Vector2(35, 255), Vector2(340, 52))
	repair.pressed.connect(repair_tower)
	return p

func create_weapon_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "ASSAULT RIFLE UPGRADES", Vector2(1080, 535), Vector2(470, 410))
	var names := [["DAMAGE", "damage"], ["MAGAZINE", "magazine"], ["RELOAD", "reload"], ["FIRE RATE", "rate"], ["ACCURACY", "accuracy"]]
	for i in range(names.size()):
		var item = names[i]
		var b := make_button(p, item[0], Vector2(30, 70 + i * 62), Vector2(410, 50))
		b.pressed.connect(func(): upgrade_weapon(item[1]))
	return p

func create_pause_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "PAUSED", Vector2(710, 340), Vector2(500, 400))
	var resume := make_button(p, "RESUME", Vector2(80, 90), Vector2(340, 58))
	resume.pressed.connect(toggle_pause)
	var restart := make_button(p, "RESTART", Vector2(80, 170), Vector2(340, 58))
	restart.pressed.connect(restart_game)
	var quit := make_button(p, "QUIT", Vector2(80, 250), Vector2(340, 58))
	quit.pressed.connect(func(): get_tree().quit())
	return p

func create_game_over_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "GAME OVER", Vector2(620, 270), Vector2(680, 520))
	var stats := make_label(p, Vector2(40, 85), Vector2(600, 260), 22, HORIZONTAL_ALIGNMENT_CENTER)
	stats.name = "Stats"
	var restart := make_button(p, "RETRY", Vector2(170, 390), Vector2(340, 65))
	restart.pressed.connect(restart_game)
	return p

func create_debug_panel(parent: Node) -> Panel:
	var p := make_panel(parent, "DEBUG F1", Vector2(18, 210), Vector2(430, 600))
	var actions := [
		["+100 GOLD", func(): add_gold(100)], ["+1000 GOLD", func(): add_gold(1000)],
		["SPAWN BASIC", func(): spawn_zombie("basic")], ["SPAWN RUNNER", func(): spawn_zombie("runner")],
		["SPAWN TANK", func(): spawn_zombie("tank")], ["SPAWN ARMORED", func(): spawn_zombie("armored")],
		["SPAWN EXPLODER", func(): spawn_zombie("exploder")], ["DAMAGE TOWER", func(): tower.take_damage(100)],
		["HEAL TOWER", func(): tower.repair(250)], ["KILL ALL", kill_all_enemies],
		["SKIP WAVE", skip_wave], ["INVINCIBLE", func(): tower.invincible = not tower.invincible],
		["INFINITE AMMO", func(): infinite_ammo = not infinite_ammo]
	]
	for i in range(actions.size()):
		var a = actions[i]
		var col := i % 2
		var row := i / 2
		var b := make_button(p, a[0], Vector2(18 + col * 198, 66 + row * 68), Vector2(188, 54))
		b.pressed.connect(a[1])
	return p

func _process(delta: float) -> void:
	if game_over or paused_game:
		return
	playtime += delta
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			reloading = false
			ammo = magazine
	update_wave(delta)
	update_effects(delta)
	update_crosshair()
	refresh_ui()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
		elif event.keycode == KEY_R:
			begin_reload()
		elif event.keycode == KEY_F1:
			debug_panel.visible = not debug_panel.visible
		elif event.keycode == KEY_F2:
			debug_overlay.visible = not debug_overlay.visible
	if game_over or paused_game:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if get_viewport().gui_get_hovered_control() != null:
			return
		var mouse := get_global_mouse_position()
		if try_select_hardpoint(mouse): return
		if try_select_turret(mouse): return
		fire_weapon(mouse)

func fire_weapon(target_pos: Vector2) -> void:
	if fire_cooldown > 0.0 or reloading: return
	if ammo <= 0 and not infinite_ammo:
		begin_reload()
		return
	fire_cooldown = 1.0 / weapon_fire_rate
	shots_fired += 1
	if not infinite_ammo: ammo -= 1
	var origin := Vector2(930, 760)
	var direction := origin.direction_to(target_pos).rotated(rng.randf_range(-weapon_spread, weapon_spread))
	var hit = ray_pick_enemy(origin, direction, 1200.0)
	var end := origin + direction * 1200.0
	if hit != null:
		end = hit.global_position
		var critical := rng.randf() <= 0.05
		var dmg := weapon_damage * (2.0 if critical else 1.0)
		hit.take_damage(dmg, 7.0)
		shots_hit += 1
		add_effect(hit.global_position, "hit", 0.16)
	add_tracer(origin, end)
	shake(0.05, 2.5)
	if ammo <= 0 and not infinite_ammo: begin_reload()

func ray_pick_enemy(origin: Vector2, dir: Vector2, distance: float):
	var best = null
	var best_dist := distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead: continue
		var rel: Vector2 = enemy.global_position - origin
		var along := rel.dot(dir)
		if along < 0.0 or along > distance: continue
		var perp := absf(rel.cross(dir))
		if perp < 32.0 and along < best_dist:
			best_dist = along
			best = enemy
	return best

func begin_reload() -> void:
	if reloading or ammo == magazine: return
	reloading = true
	reload_timer = weapon_reload

func update_wave(delta: float) -> void:
	if wave_state == "prep":
		prep_timer -= delta
		if prep_timer <= 0.0: begin_wave()
	elif wave_state == "spawning":
		spawn_timer -= delta
		if spawn_timer <= 0.0 and not spawn_queue.is_empty():
			var kind: String = spawn_queue.pop_front()
			spawn_zombie(kind)
			spawn_timer = maxf(0.22, 1.0 - wave * 0.025)
		if spawn_queue.is_empty(): wave_state = "combat"
	elif wave_state == "combat":
		if enemies_remaining <= 0 and get_tree().get_nodes_in_group("enemies").is_empty():
			complete_wave()

func begin_wave() -> void:
	wave += 1
	spawn_queue.clear()
	var count := 10 + wave * 3
	for i in range(count):
		var kind := "basic"
		var roll := rng.randf()
		if wave >= 3 and roll < 0.22: kind = "runner"
		if wave >= 5 and roll < 0.12: kind = "tank"
		if wave >= 7 and roll < 0.15: kind = "armored"
		if wave >= 8 and roll < 0.08: kind = "exploder"
		spawn_queue.append(kind)
	if wave % 10 == 0:
		spawn_queue.append("tank")
		spawn_queue.append("tank")
	enemies_remaining = spawn_queue.size()
	wave_state = "spawning"
	spawn_timer = 0.15
	show_message("WAVE %d" % wave)

func start_wave_early() -> void:
	if wave_state != "prep": return
	var bonus := maxi(0, int(prep_timer * 3.0))
	add_gold(bonus)
	prep_timer = 0.0

func complete_wave() -> void:
	var bonus := 35 + wave * 12
	add_gold(bonus)
	wave_state = "prep"
	prep_timer = 10.0
	show_message("WAVE CLEARED  +%d GOLD" % bonus)

func skip_wave() -> void:
	kill_all_enemies()
	spawn_queue.clear()
	enemies_remaining = 0
	wave_state = "prep"
	prep_timer = 0.2

func spawn_zombie(kind: String) -> void:
	var z = ZombieScript.new()
	z.add_to_group("enemies")
	z.position = Vector2(SPAWN_X + rng.randf_range(0, 160), GROUND_Y - 38 + rng.randf_range(-12, 12))
	z.target_x = TOWER_POS.x
	z.setup(kind, 1.0 + wave * 0.08)
	z.died.connect(_on_zombie_died)
	z.reached_tower.connect(_on_zombie_attack)
	add_child(z)

func _on_zombie_died(zombie, reward: int) -> void:
	kills += 1
	enemies_remaining = maxi(0, enemies_remaining - 1)
	add_gold(reward)
	add_effect(zombie.global_position, "death", 0.35)

func _on_zombie_attack(damage: float) -> void:
	tower_damage_taken += damage
	tower.take_damage(damage)
	shake(0.12, 7.0)

func _on_tower_destroyed() -> void:
	game_over = true
	var stats: Label = game_over_panel.get_node("Stats")
	var accuracy := (float(shots_hit) / maxf(1.0, float(shots_fired))) * 100.0
	stats.text = "Wave reached: %d\nZombies killed: %d\nGold earned: %d\nTime survived: %s\nShots: %d\nAccuracy: %.1f%%" % [wave, kills, gold_earned, format_time(playtime), shots_fired, accuracy]
	game_over_panel.visible = true

func _on_tower_health_changed(_current: float, _maximum: float) -> void:
	refresh_ui()

func _on_floor_added(_level: int) -> void:
	show_message("TOWER EXPANDED")

func _on_mine_gold(amount: int) -> void:
	add_gold(amount)

func add_gold(amount: int) -> void:
	gold += amount
	gold_earned += amount

func spend_gold(amount: int) -> bool:
	if gold < amount:
		show_message("NOT ENOUGH GOLD")
		return false
	gold -= amount
	gold_spent += amount
	return true

func upgrade_mine() -> void:
	var cost: int = mine.next_upgrade_cost()
	if cost < 0:
		show_message("MINE MAX LEVEL")
		return
	if spend_gold(cost): mine.upgrade()
	refresh_ui()

func add_tower_floor() -> void:
	var cost: int = tower.next_floor_cost()
	if cost < 0:
		show_message("TOWER MAX LEVEL")
		return
	if spend_gold(cost): tower.add_floor()
	refresh_ui()

func repair_tower() -> void:
	if tower.health >= tower.max_health:
		show_message("TOWER ALREADY FULL")
		return
	if spend_gold(75): tower.repair(100.0)

func try_select_hardpoint(mouse: Vector2) -> bool:
	var points: Array[Vector2] = tower.hardpoint_positions()
	for i in range(points.size()):
		var world := tower.global_position + points[i]
		if mouse.distance_to(world) <= 28.0 and not occupied_hardpoints.has(i):
			selected_hardpoint = i
			close_context_panels()
			build_panel.visible = true
			return true
	return false

func try_select_turret(mouse: Vector2) -> bool:
	for t in turrets:
		if is_instance_valid(t) and mouse.distance_to(t.global_position) <= 32.0:
			selected_turret = t
			close_context_panels()
			detail_panel.visible = true
			refresh_turret_panel()
			return true
	return false

func build_turret(kind: String, cost: int) -> void:
	if selected_hardpoint < 0 or occupied_hardpoints.has(selected_hardpoint): return
	if not spend_gold(cost): return
	var points: Array[Vector2] = tower.hardpoint_positions()
	if selected_hardpoint >= points.size(): return
	var t = TurretScript.new()
	t.position = tower.global_position + points[selected_hardpoint]
	t.setup(kind)
	t.request_projectile.connect(_on_turret_fire)
	add_child(t)
	turrets.append(t)
	occupied_hardpoints[selected_hardpoint] = t
	build_panel.visible = false
	selected_turret = t
	selected_hardpoint = -1

func _on_turret_fire(origin: Vector2, target, damage: float, splash: float, turret_type: String) -> void:
	if not is_instance_valid(target) or target.dead: return
	var hit_pos: Vector2 = target.global_position
	if splash > 0.0:
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.dead and e.global_position.distance_to(hit_pos) <= splash:
				e.take_damage(damage, 5.0)
		add_effect(hit_pos, "explosion", 0.3)
		shake(0.09, 5.0)
	else:
		target.take_damage(damage, 2.0)
		add_effect(hit_pos, "hit", 0.12)
	add_tracer(origin, hit_pos, turret_type)

func upgrade_selected_turret() -> void:
	if not is_instance_valid(selected_turret): return
	var cost: int = selected_turret.get_upgrade_cost()
	if cost < 0:
		show_message("TURRET MAX LEVEL")
		return
	if spend_gold(cost): selected_turret.upgrade()
	refresh_turret_panel()

func sell_selected_turret() -> void:
	if not is_instance_valid(selected_turret): return
	var value: int = selected_turret.sell_value()
	add_gold(value)
	var remove_key = null
	for key in occupied_hardpoints.keys():
		if occupied_hardpoints[key] == selected_turret:
			remove_key = key
			break
	if remove_key != null: occupied_hardpoints.erase(remove_key)
	turrets.erase(selected_turret)
	selected_turret.queue_free()
	selected_turret = null
	detail_panel.visible = false

func upgrade_weapon(stat: String) -> void:
	var lvl: int = weapon_upgrade_levels[stat]
	if lvl >= 3:
		show_message("UPGRADE MAX LEVEL")
		return
	var cost := 130 + lvl * 170
	if not spend_gold(cost): return
	weapon_upgrade_levels[stat] = lvl + 1
	match stat:
		"damage": weapon_damage *= 1.28
		"magazine": magazine += 10 if lvl < 2 else 15; ammo = magazine
		"reload": weapon_reload *= 0.82
		"rate": weapon_fire_rate += 1.0
		"accuracy": weapon_spread *= 0.7
	show_message("WEAPON UPGRADED")

func refresh_turret_panel() -> void:
	if not is_instance_valid(selected_turret): return
	var stats: Label = detail_panel.get_node("Stats")
	stats.text = "%s  LVL %d\nDamage: %.1f\nFire rate: %.2f/s\nRange: %.0f\nUpgrade: %s\nSell: %dG" % [selected_turret.turret_type.to_upper(), selected_turret.level, selected_turret.damage, selected_turret.fire_rate, selected_turret.range_px, ("MAX" if selected_turret.get_upgrade_cost() < 0 else str(selected_turret.get_upgrade_cost()) + "G"), selected_turret.sell_value()]

func close_context_panels() -> void:
	for p in [build_panel, detail_panel, mine_panel, tower_panel, weapon_panel]: p.visible = false

func toggle_panel(panel: Panel) -> void:
	var was_visible := panel.visible
	close_context_panels()
	panel.visible = not was_visible
	refresh_ui()

func toggle_pause() -> void:
	if game_over: return
	paused_game = not paused_game
	pause_panel.visible = paused_game

func restart_game() -> void:
	get_tree().reload_current_scene()

func kill_all_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.dead: e.die(true)

func refresh_ui() -> void:
	if gold_label == null: return
	gold_label.text = "GOLD  %s" % str(gold)
	mine_rate_label.text = "MINE  +%d / sec   LVL %d" % [int(mine.current_rate()), mine.level]
	wave_label.text = "WAVE %d" % wave
	enemy_label.text = "ENEMIES  %d" % maxi(enemies_remaining, get_tree().get_nodes_in_group("enemies").size())
	timer_label.text = ("NEXT WAVE  %.1fs" % prep_timer) if wave_state == "prep" else wave_state.to_upper()
	hp_label.text = "TOWER  %d / %d HP" % [int(tower.health), int(tower.max_health)]
	ammo_label.text = "RELOADING..." if reloading else "AMMO  %d / %d" % [ammo, magazine]
	reload_bar.value = 1.0 - clamp(reload_timer / weapon_reload, 0.0, 1.0) if reloading else 0.0
	var mstats: Label = mine_panel.get_node("Stats")
	mstats.text = "Level: %d / 6\nProduction: %d gold/sec\nNext upgrade: %s" % [mine.level, int(mine.current_rate()), ("MAX" if mine.next_upgrade_cost() < 0 else str(mine.next_upgrade_cost()) + "G")]
	var tstats: Label = tower_panel.get_node("Stats")
	tstats.text = "Level: %d / 6\nHealth: %d / %d\nNext floor: %s\nTurret slots: %d" % [tower.level, int(tower.health), int(tower.max_health), ("MAX" if tower.next_floor_cost() < 0 else str(tower.next_floor_cost()) + "G"), tower.hardpoint_positions().size()]
	if detail_panel.visible: refresh_turret_panel()
	if debug_overlay.visible:
		debug_overlay.text = "DEBUG OVERLAY F2\nFPS: %d\nEnemies: %d\nTurrets: %d\nWave: %d\nTower: %d HP\nGold: %d\nMine: %d/sec\nInvincible: %s\nInfinite ammo: %s" % [Engine.get_frames_per_second(), get_tree().get_nodes_in_group("enemies").size(), turrets.size(), wave, int(tower.health), gold, int(mine.current_rate()), str(tower.invincible), str(infinite_ammo)]

func show_message(text_: String) -> void:
	message_label.text = text_
	var timer := get_tree().create_timer(1.6)
	timer.timeout.connect(func(): if message_label.text == text_: message_label.text = "")

func update_crosshair() -> void:
	crosshair.position = get_viewport().get_mouse_position() - Vector2(17, 17)

func add_tracer(from: Vector2, to: Vector2, kind: String = "rifle") -> void:
	effects.append({"type":"tracer", "a":from, "b":to, "time":0.07, "max":0.07, "kind":kind})

func add_effect(pos: Vector2, kind: String, duration: float) -> void:
	effects.append({"type":kind, "pos":pos, "time":duration, "max":duration})

func update_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i]["time"] -= delta
		if effects[i]["time"] <= 0.0: effects.remove_at(i)
	if shake_time > 0.0:
		shake_time -= delta
		position = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
	else:
		position = Vector2.ZERO

func shake(duration: float, strength: float) -> void:
	shake_time = maxf(shake_time, duration)
	shake_strength = strength

func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

func _draw() -> void:
	# layered post-apocalyptic background
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("11181b"), true)
	draw_rect(Rect2(0, 420, VIEW_W, 460), Color("222727"), true)
	for i in range(16):
		var x := float(i) * 135.0 - 40.0
		var h := 110.0 + float((i * 47) % 180)
		draw_rect(Rect2(x, GROUND_Y - h - 120, 100, h), Color("1c2223"), true)
		if i % 3 == 0: draw_line(Vector2(x + 20, GROUND_Y - h - 120), Vector2(x + 80, GROUND_Y - h - 150), Color("14191a"), 8)
	draw_rect(Rect2(0, GROUND_Y, VIEW_W, VIEW_H - GROUND_Y), Color("302b23"), true)
	draw_line(Vector2(0, GROUND_Y), Vector2(VIEW_W, GROUND_Y), Color("766247"), 5)
	for i in range(30):
		var dx := float((i * 191) % 1920)
		draw_line(Vector2(dx, GROUND_Y + 12 + (i % 5) * 20), Vector2(dx + 30, GROUND_Y + 15 + (i % 5) * 20), Color("433a2e"), 4)
	# player gun emplacement
	draw_circle(Vector2(900, 760), 38, Color("252b2c"))
	draw_rect(Rect2(900, 750, 78, 18), Color("72563d"), true)
	draw_circle(Vector2(900, 760), 12, Color("a16b3d"))
	# hardpoints
	if tower != null:
		var points: Array[Vector2] = tower.hardpoint_positions()
		for i in range(points.size()):
			if occupied_hardpoints.has(i): continue
			var p := tower.global_position + points[i]
			draw_circle(p, 13, Color(0.82, 0.55, 0.25, 0.7))
			draw_circle(p, 6, Color("252b2b"))
	# effects
	for fx in effects:
		var alpha: float = clamp(float(fx["time"]) / float(fx["max"]), 0.0, 1.0)
		if fx["type"] == "tracer":
			var c := Color(1.0, 0.82, 0.38, alpha)
			if fx.get("kind", "") == "rocket": c = Color(1.0, 0.42, 0.2, alpha)
			draw_line(fx["a"], fx["b"], c, 3.0)
		elif fx["type"] == "explosion":
			draw_circle(fx["pos"], 70.0 * (1.0 - alpha * 0.4), Color(1.0, 0.34, 0.12, alpha * 0.55))
		elif fx["type"] == "death":
			draw_circle(fx["pos"], 28.0, Color(0.35, 0.06, 0.04, alpha * 0.6))
		else:
			draw_circle(fx["pos"], 10.0, Color(0.8, 0.18, 0.12, alpha))
