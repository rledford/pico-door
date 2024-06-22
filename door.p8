pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main

-- todo --
----------

-- [x] enemies shoot projectile at player
-- [x] player take damage from enemy projectiles
-- [x] projectiles colliding with walls should destroy the projectile
-- [x] create reusable animation controller
-- [x] use make_projectile
-- [x] enemies move toward player when close enough
-- [x] add spawning points
-- [x] when player takes damage, do flash animation and make temporarily invulnerable (and not collidable)
-- [x] player takes damage when touching enemies
-- [x] add max objects and prevent spawning more enemies when max is reached
-- [x] implement room load/unload
-- [x] persist which doors have been destroyed
-- [x] make destroyed doors not respawn when reentering room
-- [x] despawn enemies when switching rooms
-- [x] animate enemy spawning in
-- [x] add particle effects when destroying objects
-- [x] add xp drops
-- [x] make destoyed enemy particles match enemy colors
-- [x] add floor spike traps
-- [x] make doors do hurt-flash
-- [x] add player death screen with restart option
-- [x] add wall projectile traps activated by floor tiles (hits player and enemies)
-- [x] add portals to port back to main room (and back to room ported from)
-- [x] add UI elements for player info
-- [x] add health pickup
-- [x] enemies have low chance to drop health pickup
-- [x] add player projectiles bounce off walls
-- [x] swap player and xp drops to gems
-- [x] cap max player gems (upgradable)
-- [x] make enemies drop gems
-- [x] gems not picked up explode if player dies
-- [x] immediately create random enemies on spawn points when player enters room
-- [x] add npc vendor
-- [x] add window
-- [x] make window interactive
-- [x] interacting close to vendor shows upgrade purchase window
-- [x] add sfx when vendor window opens and closes
-- [x] add sfx for vendor purchase success and fail
-- [x] add upgrades, navigation and purchase to vendor window
-- [x] add tile or use X input to activate vendor purchase window when next to vendor
-- [x] add projectile upgrade to damage and pass-through instead of destroy on hit
-- [x] add projectile fire-rate upgrade
-- [x] add calculate str width util
-- [x] show player stats in vendor window (gems, hp)
-- [x] make overload portal limited to 1 (stop spawning a bunch of portals you monster)
-- [x] add emeny stats vary on difficulty
-- [x] increases difficulty by x % every time player purchases an upgrade
-- [x] add chests with pickups
-- [x] add torch object with animation
-- [x] reduce tokens and make things look terrible
-- [x] add boss-door room in separate map area
-- [x] add boss-door health to UI
-- [x] add boss-door destroyed effects
-- [x] spawn moose behind boss-door when destroyed
-- [x] add toast messages
-- [x] add artifact (holy grail)
-- [x] add stats (doors destroyed, enemies destroyed, ...)
-- [x] add win screen and show stats
-- [x] show stats on death and win screen
-- [x] add "achievements"
-- [x] make enemy spawn points configurable or pull from different type pools based on conditions
-- [x] tune enemy movement and damage
-- [x] add some music
-- [x] refine sfx
-- [] add different music for boss fight
-- [] stop music during death sequence
-- [] fix projectiles get stuck on corners
-- [] fix toast message queue flooding when dismissing next to interactive object

-- constants --
---------------

TILE_SIZE,
SCREEN_SIZE,
MAX_ROOM_OBJECTS,
TILE_HALF_SIZE,
SCREEN_TILES = 8, 128, 50, 4, 16

NO_GROUP,
PLAYER_GROUP,
ENEMY_GROUP,
BLOCK_TILE,
WALL_TILE,
FLOOR_TILE,
NO_PASS_FLOOR_TILE,
DOOR_TILE,
SPIKE_TILE,
ENEMY_SPAWN_TILE,
TRAP_TILE,
PORTAL_TILE,
VENDOR_TILE,
HP_TILE,
CHEST_TILE,
TORCH_TILE,
SATCHEL_TILE,
UPGRADE_DMG_TILE,
RICOCHET_TILE,
UPGRADE_HP_TILE,
FAST_SHOT_TILE,
PIERCE_TILE,
OVERLOAD_TILE,
BOSS_TILE,
MOOSE_TILE,
MIRROR_TILE,
ARTIFACT_TILE,
SNOIPER_TILE,
THE_DISTANCE_TILE,
DESK_TILE,
BROKEN_DESK_TILE,
HURT_FLASH_PAL = 
	0,1,2,0,1,2,4,3,16,6,19,21,37,27,14,57,40,41,42,43,44,45,22,5,35,12,60,39,40,9,10,
	{8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8}

-- globals --
-------------

room,
-- overload_portal,
-- last_portal_used,
camera_pos,
camera_spd,
objects,
transition_objects,
difficulty,
enemy_hp_scale,
enemy_dmg_scale =
	{x=0,y=0}, -- room
	-- nil, -- overload portal
	-- {room={x=0,y=0},pos={0,0}}, -- last portal used
	{x=0,y=0},
	4, -- camera speed
	{}, -- objects
	{}, -- transition objects
	1.0, -- difficulty
	0.75, -- enemy hp scale
	0.5 -- enemy dmg scale

k_left,
k_right,
k_up,
k_down,
k_shoot,
k_action,
is_room_transition,
debug,
window,
toast_msg_window,
toast_msg_queue = 
	0, -- left
	1, -- right
	2, -- up
	3, -- down
	4, -- shoot
	5, -- action
	false, -- room transition
	false, -- debug
	nil, -- window
	nil, -- toast msg window
	{} -- toast msg queue

-- stats --
doors_destroyed,
total_doors,
enemies_destroyed,
chests_looted,
total_chests,
total_dmg_dealt,
total_dmg_taken = 
	0, -- doors destroyed
	0, -- total doors
	0, --enemies destroyed
	0, -- chests looted
	0, -- total chests
	0, -- total dmg dealt
	0 -- total dmg taken


-- boss --
----------
is_all_powerful,
has_shown_is_all_powerful_msg,
has_started_boss_room,
has_spoken_to_moose,
did_anger_moose,
did_take_the_artifact,
has_started_win_sequence,
max_boss_hp =
	false, -- is all powerful
	false, -- has show all powerful msg
	false, -- has started boss room
	false, -- has spoken to moose
	false, -- did anger moose
	false, -- did take artifact
	false, -- has started win sequence
	12000 -- max boss hp
boss_hp = max_boss_hp

update_fn = function()
end

-- entry point --
-----------------

function _init()
	cls()
	player = init_object(player_type, 16, 40)
	calculate_stat_totals_from_map()
	start_room_transition(0,0)
	show_select_difficulty_window()
	show_toast_message({
		"⬆️⬇️⬅️➡️ - move",
		"      🅾️ - shoot",
		"      ❎ - interact",
		"",
		"   break down the doors   ",
		"     loot every chest     ",
		" find the goblet of grail ",
		"      don't get doid      ",
	}, 750)
end

function calculate_stat_totals_from_map()
	for c=0,64,1 do
		for r=0,48,1 do
			local t = mget(c,r)
			if t == DOOR_TILE then
				total_doors += 1
			end
			if t >= 39 and t <= 45 then
				total_chests += 1
			end
		end
	end
	-- add one for the boss door
	total_doors += 1
end

function _update60()
	update_fn()
end

function _draw()
	cls()
	map()
	foreach(objects, function(obj)
		if obj.type ~= player_type then
			draw_object(obj)
		end
	end)
	if count(transition_objects) > 0 then
		foreach(transition_objects, function(obj)
			if obj.type ~= player.type then
				draw_object(obj)
			end
		end)
	end
	draw_object(player)
	if player.target ~= nil then
		spr(13, player.target.x, player.target.y)
	end
	if toast_msg_window != nil then
		toast_msg_window.draw(toast_msg_window)
	end
	if window ~= nil then
		window.draw(window)
	end
	if not has_started_win_sequence then
		draw_ui()
	end
	draw_particles()
end

-- game update --
-----------------

function game_update()
	foreach(objects,function(obj)
		if obj.type.update~=nil then
			obj.type.update(obj)
		end
		if obj.is_hurt then
			update_hurt_object(obj)
		end
		obj.move()
	end)
	update_particles()
	update_toasts()
	if not is_all_powerful then
		is_all_powerful = chests_looted == total_chests
		if is_all_powerful and not has_shown_is_all_powerful_msg then
			show_toast_message({
				"you're all-powerful now..."
			},90)
			show_toast_message({
				"get to the goblet of grail.",
				"!! hurry !! <sqeal>"
			},90)
			has_shown_is_all_powerful_msg = true
		end
	end
end

-- player --
------------

player_type = {
	init=function(this)
		this.fire_rate = 20
		this.fire_timer = 0
		this.hitbox={x=2,y=2,w=3,h=4}
		this.target=nil
		this.auto_target_radius = 30
		this.projectile_damage = 2
		this.projectile_speed = 1.3
		this.projectile_lifetime = 60
		this.has_ricochet = false
		this.has_pierce = false
		this.has_overload = false
		this.face = {x=1,y=0}
		this.max_hp = 20
		this.hp = this.max_hp
		this.group = PLAYER_GROUP
		this.anim = make_animation({32})
		this.hurt_collidable = false
		this.hurt_duration = 45
		this.can_move = true
		-- this.max_gems = 250
		-- this.gems = 0
		this.dead = false
	end,
	take_damage=function(this, amt)
		total_dmg_taken += amt
		sfx(4)
		if this.dead then
			return
		end
		this.hp = clamp(this.hp - amt, 0, this.max_hp)
		start_hurt_object(this)
		if this.hp <= 0 then
			this.dead = true
			for i=0,5 do
				make_particle_group(this.x+TILE_HALF_SIZE, this.y+TILE_HALF_SIZE, nil, 1000)
				make_particle_group(this.x+TILE_HALF_SIZE, this.y+TILE_HALF_SIZE, nil, 1000)
				make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame],1000)
			end
			this.anim = nil
			start_death_transition()
		end
	end,
	update=function(this)
		if this.dead then
			return
		end
		this.anim.update()
		local dx,dy = 0,0
		if btnp(k_left) then
			dx = -1
		elseif btnp(k_right) then
			dx = 1
		elseif btnp(k_up) then
			dy = -1
		elseif btnp(k_down) then
			dy = 1
		end
		if dx ~= 0 or dy ~= 0 then
			local from = count(this.moves) and this.moves[#this.moves] or {x=this.x,y=this.y}
			this.face.x,this.face.y = dx,dy
			local mx,my = dx * TILE_SIZE + from.x, dy * TILE_SIZE + from.y
			if this.can_move and this.can_move_to(pos_to_tile(mx), pos_to_tile(my)) then
				add(this.moves, {x=mx,y=my})
				if is_move_to_next_room(mx,my) then
					start_room_transition(room.x + dx, room.y + dy)
				end
			end
		end
		this.find_target_in_group(ENEMY_GROUP)
		if this.target and get_range(this, this.target) > this.auto_target_radius then
			this.target = nil
		end
		if btn(k_shoot) and this.fire_timer <= 0 then
			sfx(0)
			this.fire_timer = this.fire_rate
			local dir
			if this.target ~= nil then
				dir = get_direction({x=this.x, y=this.y}, {x=this.target.x, y=this.target.y})
			else
				dir = get_direction({x=this.x, y=this.y}, {x=this.x+this.face.x, y=this.y+this.face.y})
			end
			if dir.x == 0 and dir.y == 0 then
				dir.y = 1
			end
			local proj = make_projectile(
				this.x,
				this.y,
				make_animation({30,31}, 4),
				this.projectile_damage,
				this.projectile_speed,
				dir
			)
			proj.ricochet = this.has_ricochet
			proj.pierce = this.has_pierce
			proj.lifetime = this.projectile_lifetime
			add(proj.collision_groups, ENEMY_GROUP)
		end
		this.fire_timer = clamp(this.fire_timer - 1, 0, this.fire_rate)
		foreach(objects, function(obj)
			if this.collides_with(obj) then
				if obj.touch_damage > 0 then
					this.type.take_damage(
						this,
						get_enemy_dmg_for_difficulty(obj.touch_damage)
					)
				elseif obj.on_pickup ~= nil then
					obj.on_pickup(this)
				elseif obj.type.on_activate ~= nil then
					obj.type.on_activate(obj)
				end
			end
		end)
	end
}

-- vendor --
------------

vendor_type = {
	init=function(this)
		this.inventory,
		this.anim,
		this.can_interact = {
			upgrade_hp,
			upgrade_damage,
			upgrade_fire_rate,
		},
		make_animation({37,38}, 20),
		false
	end,
	update=function(this)
		this.can_interact = check_player_can_interact() and flr(get_range(this, player)) <= TILE_SIZE*2
		if this.can_interact and btnp(k_action) then
			show_toast_message({
				"i am the all-powerful lunkik.",
				"",
				"i used to be a vendor but i",
				"required too many tokens..."
			})
		end
		this.anim.update()
	end,
}

upgrade_hp = {
	spr = UPGRADE_HP_TILE,
	name = "let me live",
	description = "increase hp and healz",
	on_upgrade = function()
		player.max_hp += 3.75
		player.hp = player.max_hp
		increase_difficulty(0.15)
	end
}

upgrade_damage = {
	spr = UPGRADE_DMG_TILE,
	name = "tis more than a scratch",
	description = "increase damage",
	on_upgrade = function()
		player.projectile_damage += 2
		increase_difficulty(0.15)
	end
}

upgrade_fire_rate = {
	spr = FAST_SHOT_TILE,
	name = "it's high noon",
	description = "increase fire rate",
	on_upgrade = function()
		player.fire_rate = clamp(player.fire_rate - 1.5, 8, 20)
		player.fire_timer = 0
		increase_difficulty(0.15)
	end
}

upgrade_projectile_ricochet = {
	spr = RICOCHET_TILE,
	name = "(bounce) pogo pogo...",
	description = "shots bounce",
	on_upgrade = function()
		player.has_ricochet = true
		increase_difficulty(0.3)
	end
}

upgrade_projectile_pierce = {
	spr = PIERCE_TILE,
	name = "nice earings",
	description = "shots pierce enemies",
	on_upgrade = function()
		player.has_pierce = true
		increase_difficulty(0.3)
	end
}

upgrade_target_radius = {
	spr = SNOIPER_TILE,
	name = "snoiper",
	description = "increase target range",
	on_upgrade = function()
		player.auto_target_radius += 8
		increase_difficulty(0.5)
	end
}

upgrade_projectile_lifetime = {
	spr = THE_DISTANCE_TILE,
	name = "cake",
	description = "increase the distance of shots",
	on_upgrade = function()
		player.projectile_lifetime += 15
		increase_difficulty(0.25)
	end
}

-- toast message --
-------------------
function show_toast_message(text_list,lifetime,callback)
	local line_count = count(text_list)
	local w,h,pad,lifetime = 
	get_total_text_width(text_list), -- w
	count(text_list) * 4, -- h
	2, -- pad
	lifetime or 600 -- lifetime
	w += pad * 2
	h += pad * 2 + line_count * 2
	local toast = {
		update=function(this)
			lifetime -= 1
			if lifetime <= 0 or btnp(k_action) then
				toast_msg_window = nil
				if callback ~= nil then
					callback()
				end
			end
		end,
		draw=function(this)
			local left,top =
				camera_pos.x + SCREEN_SIZE/2 - w/2,
				camera_pos.y + SCREEN_SIZE - h + 1
			local right,bottom =
				left + w - 1,
				top + h - 2

			rectfill(left,top,right,bottom,13)
			rect(left,top,right,bottom,2)
			for i=1,line_count do
				print(text_list[i],left + pad,(4+2) *(i-1) + top + pad,7)
			end
		end
	}
	add(toast_msg_queue, toast)
end

-- pickups --
-------------

pickup_type = {
	init=function(this)
		this.spr,
		this.pickup_range,
		this.can_expire,
		this.expiration_time,
		this.expiration_timer = 0,0,true,500,500
	end,
	update=function(this)
		if this.can_expire then
			this.expiration_timer -= 1
			this.anim.frame_time = this.expiration_timer/this.expiration_time <= 0.25 and 4 or this.anim.frame_time
		end
		if this.expiration_timer <= 0 then
			make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame], 100)
			destroy_object(this)
			return
		end
		if get_range(this, player) <= this.pickup_range then
			local dir = get_direction(this, player)
			this.x += dir.x
			this.y += dir.y
		end
		this.anim.update()
	end
}

function make_pickup(x, y, anim, pickup_range, can_expire)
	local pickup = init_object(pickup_type, x, y)
	pickup.pickup_range,
	pickup.anim,
	pickup.hitbox,
	pickup.can_expire =
		pickup_range,
		anim,
		{x=2,y=2,w=3,h=3},
		can_expire
		
	return pickup
end

function make_hp_pickup(x, y, amount)
	local pickup = make_pickup(x, y, make_animation({26,27}, 16), 16,true)
		pickup.on_pickup =	function(player)
				sfx(10,3)
				player.hp = clamp(player.hp + amount, player.hp, player.max_hp)
				destroy_object(pickup)
			end

	return pickup
end

function make_upgrade_pickup(x, y, type)
	local pickup = make_pickup(x, y, make_animation({type.spr}), 0, false)
		pickup.spr = type.spr
		pickup.on_pickup = function()
			type.on_upgrade()
			chests_looted += 1
			sfx(11,3)
			show_toast_message({type.name},100)
			show_toast_message({type.description},100)
			destroy_object(pickup)
		end

	return pickup
end

-- projectiles --
-----------------

projectile_type = {
	init=function(this)
		this.targetable,
		this.target,
		this.hitbox,
		this.spd,
		this.direction,
		this.lifetime,
		this.collision_groups,
		this.damage,
		this.ricochet,
		this.pierce,
		this.ignore_walls,
		this.hit_list = false,nil,{x=3,y=3,w=2,h=2},0,{x=0, y=0},120,{},1,false,false,false,{}
	end,
	update=function(this)
		this.lifetime -= 1
		this.anim.update()
		local nextx = this.x + this.direction.x * this.spd
		local nexty = this.y + this.direction.y * this.spd
		if this.lifetime <= 0 or is_move_to_next_room(this.x, this.y) then
			destroy_object(this)
			return
		end
		local col = this.collide(this.collision_groups)
		if col ~= nil and index_of(this.hit_list, col) == 0 then
			if col.take_damage ~= nil then
				col.take_damage(this.damage)
				add(this.hit_list, col)
			end
			if not this.pierce or col.type == door_type  or col.type == chest_type then
				destroy_object(this)
			end
		end
		if not this.ignore_walls then
			local t = mget(pos_to_tile(nextx + TILE_HALF_SIZE), pos_to_tile(nexty + TILE_HALF_SIZE))
			local is_blocked = t == WALL_TILE or t == BLOCK_TILE or t == DESK_TILE or t == BROKEN_DESK_TILE or (t == BOSS_TILE and not has_started_boss_room)
			local is_enemy_hitting_door = t == DOOR_TILE and this.group ~= ENEMY_GROUP

			if is_blocked or is_enemy_hitting_door then
				if this.ricochet then
					this.hit_list = {}
					-- cheap bounce calc without normals since all walls are axis-aligned
					if not this.can_move_through(pos_to_tile(this.x + TILE_HALF_SIZE), pos_to_tile(nexty + TILE_HALF_SIZE)) then
						-- hit top or bottom of wall so reverse y
						this.direction.y *= -1
					elseif not this.can_move_through(pos_to_tile(nextx + TILE_HALF_SIZE), pos_to_tile(this.y + TILE_HALF_SIZE)) then
						-- hit left or right of wall so reverse x
						this.direction.x *= -1
					else 
						this.direction.x *= -1
						this.direction.y *= -1
					end
					-- skip setting position to nextx,nexty to prevent drilling through corners
					return
				else
					destroy_object(this)
				end
			end
		end
		this.x = nextx
		this.y = nexty
	end
}

function make_projectile(x, y, anim, damage, spd, direction)
	local proj = init_object(projectile_type, x, y)
	proj.anim,proj.damage,proj.spd,proj.direction = anim,damage,spd,direction
	return proj
end

chest_type = {
	init=function(this)
		this.group,this.hp,this.anim,this.static = ENEMY_GROUP,25,make_animation({CHEST_TILE}),true
	end,
	take_damage=function(this, amount)
		this.hp -= amount
		track_dmg_dealt(amount)
		start_hurt_object(this)
		if this.hp <= 0 then
			sfx(8)
			mset(pos_to_tile(this.x), pos_to_tile(this.y), FLOOR_TILE)
			make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame])
			destroy_object(this)
		else
			-- play hit sound
		end
	end,
	update=function(this)
	end,
}

shield_type = {
	init=function(this)
		this.anim = make_animation({59})
	end,
	update=function(this)
	end
}

moose_type = {
	init=function(this)
		this.anim,
		this.can_interact,
		this.is_speaking,
		this.explode_in_anger_timer =
			make_animation({35,36}, 8), -- animation
			false, -- can interact
			false, -- is speaking
			150 -- explode timer
	end,
	update=function(this)
		if did_anger_moose then
			return
		end
		this.anim.update()
		this.can_interact = check_player_can_interact() and not this.is_speaking and not did_anger_moose and flr(get_range(this, player)) <= TILE_SIZE
		if this.can_interact and btnp(k_action) then
			if has_spoken_to_moose and not did_anger_moose then
				did_anger_moose = true
				show_toast_message({
					"destroy it or don't!",
					"!! gah !!",
					"<gets unreasonably angry>",
				},
				120,
				function()
					destroy_object(this)
					for i=0,10 do
						make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame], 500)
					end
					mset(pos_to_tile(this.x),pos_to_tile(this.y), FLOOR_TILE)
					show_toast_message({
						"         r.i.p.        ",
						"       mr. mooshe      "
					},90)
				end)
			else
				this.is_speaking = true
				show_toast_message({
					"!! eeeeeeeeeeeeeeeeeeeeeee !!"
				})
				show_toast_message({
					"penetant one! i mean...",
					"",
					"all-powerful one!",
				})
				show_toast_message({
					"the goblet of grail is",
					"not what it seems!",
					"<panting heavily>"
				})
				show_toast_message({
					"it makes you immortal but..."
				})
				show_toast_message({
					"life becomes a never-ending",
					"grind full of neck problems."
				})
				show_toast_message({
					"you get suuuuper old <gags>",
					"because that's what happens",
					"when you can't get doid."
				})
				show_toast_message({
					"destroy the grail or...",
					"<looong sigh>"
				})
				show_toast_message({
						"take it knowing it's",
						"probably a bad idea."
					},
					600,
					function()
						has_spoken_to_moose = true
						this.is_speaking = false
					end)
			end
		end
	end
}

-- enemies --
-------------

eye_type = {
	init=function(this)
		this.fire_rate,
		this.fire_timer,
		this.hitbox,
		this.target,
		this.auto_target_radius,
		this.group,
		this.hp,
		this.move_rate,
		this.move_timer,
		this.anim,
		this.touch_damage,
		this.projectile_damage,
		this.is_enemy =
			90, -- fire rate
			0, -- fire timer
			{x=2,y=3,w=4,h=5}, -- hitbox
			nil, -- target
			40, -- auto target radius
			ENEMY_GROUP, -- group
			get_enemy_hp_for_difficulty(2), -- hp
			30, -- move rate
			0, -- move timer
			make_animation({48,49}, 16), -- anim
			2.25, -- touch damage
			2.5, -- range damage
			true -- is enemy
	end,
	update=function(this)
		this.fire_timer = clamp(this.fire_timer - 1, 0, this.fire_rate)
		this.move_timer = clamp(this.move_timer - 1, 0, this.move_rate)
		if this.move_timer <= 0  and ceil(rnd(100)) == 100 then
			this.move_timer = this.move_rate
			plan_next_move(this)
		end
		this.find_player_target()
		if this.target ~= nil and this.fire_timer <= 0 and ceil(rnd(100)) > 95 then
			this.fire_timer = this.fire_rate
			local dir = get_direction({x=this.x, y=this.y}, {x=this.target.x, y=this.target.y})
			local proj = make_projectile(
				this.x,
				this.y,
				make_animation({46,47}, 8),
				get_enemy_dmg_for_difficulty(this.projectile_damage),
				0.5,
				dir
			)
			sfx(3)
			add(proj.collision_groups, PLAYER_GROUP)
		end
		this.anim.update()
	end
}

bug_type = {
	init=function(this)
		this.hitbox,
		this.target,
		this.auto_target_radius,
		this.anim,
		this.group,
		this.hp,
		this.move_rate,
		this.move_timer,
		this.touch_damage,
		this.is_enemy =
			{x=1,y=2,w=6,h=5}, -- hitbox
			nil, -- target
			40, -- auto target radius
			make_animation({50,51}, 25), -- anim
			ENEMY_GROUP, -- group
			get_enemy_hp_for_difficulty(4), -- hp
			15, -- move rate
			0, -- move timer
			4, -- touch damage
			true -- is enemy
	end,
	update=function(this)
		this.move_timer = clamp(this.move_timer - 1, 0, this.move_rate)
		if this.move_timer <= 0  and ceil(rnd(100)) == 100 then
			this.move_timer = this.move_rate
			plan_next_move(this)
		end
		this.anim.update()
	end
}

fang_type = {
	init=function(this)
		this.hitbox,
		this.target,
		this.auto_target_radius,
		this.anim,
		this.group,
		this.hp,
		this.move_rate,
		this.move_timer,
		this.touch_damage,
		this.is_enemy =
			{x=1,y=2,w=6,h=5}, -- hitbox
			nil, -- target
			40, -- auto target radius
			make_animation({53,54}, 40), -- animation
			ENEMY_GROUP, -- group
			get_enemy_hp_for_difficulty(5), -- hp
			5, -- move rate
			0, -- move timer
			3.5, -- touch damage
			true -- is enemy
	end,
	update=function(this)
		this.move_timer = clamp(this.move_timer - 1, 0, this.move_rate)
		if this.move_timer <= 0  and ceil(rnd(100)) > 95 then
			this.move_timer = this.move_rate
			plan_next_move(this)
		end
		this.anim.update() 
	end
}

skull_type = {
	init=function(this)
		this.hitbox,
		this.target,
		this.auto_target_radius,
		this.anim,
		this.group,
		this.hp,
		this.move_rate,
		this.move_timer,
		this.touch_damage,
		this.projectile_damage,
		this.fire_rate,
		this.fire_timer,
		this.is_enemy =
			{x=1,y=2,w=6,h=5}, -- hitbox
			nil, -- target
			40, -- auto target radius
			make_animation({55,56}, 30), -- anim
			ENEMY_GROUP, -- group
			get_enemy_hp_for_difficulty(6), -- hp
			5, -- move rate
			0, -- move timer
			2.5, -- touch damage
			3.5, -- projectile damage
			45, --fire rate
			0, -- fire timer
			true -- is enemy
	end,
	update=function(this)
		this.fire_timer = clamp(this.fire_timer - 1, 0, this.fire_rate)
		this.move_timer = clamp(this.move_timer - 1, 0, this.move_rate)
		if this.move_timer <= 0  and ceil(rnd(100)) > 75 then
			this.move_timer = this.move_rate
			plan_next_move(this)
		end
		this.find_player_target()
		if this.target ~= nil and this.fire_timer <= 0 and ceil(rnd(100)) > 50 then
			this.fire_timer = this.fire_rate
			local dir = get_direction({x=this.x, y=this.y}, {x=this.target.x, y=this.target.y})
			local proj = make_projectile(
				this.x,
				this.y,
				make_animation({46,47}, 8),
				get_enemy_dmg_for_difficulty(this.projectile_damage),
				0.75,
				dir
			)
			sfx(3)
			add(proj.collision_groups, PLAYER_GROUP)
		end
		this.anim.update()
	end
}

-- other --
-----------

door_type = {
	init=function(this)
		this.group,
		this.hp,
		this.anim,
		this.static = ENEMY_GROUP,15,make_animation({3}),true
	end,
	take_damage=function(this, amount)
		this.hp -= amount
		track_dmg_dealt(amount)
		start_hurt_object(this)
		if this.hp <= 0 then
			sfx(8)
			doors_destroyed += 1
			mset(pos_to_tile(this.x), pos_to_tile(this.y), FLOOR_TILE)
			make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame])
			destroy_object(this)
		end
	end,
	update=function(this)
	end,
}

trap_type = {
	init=function(this)
		this.inactive_anim,
		this.active_anim,
		this.reset_time,
		this.reset_timer,
		this.targetable,
		this.active,
		this.collidable,
		this.projectile_damage,
		this.projectile_speed,
		this.static = make_animation({19}),make_animation({20}),300,0,false,false,true,1,1,true

		this.anim = this.inactive_anim
	end,
	update=function(this)
		if this.active and this.reset_timer > 0 then
			this.reset_timer -= 1
			if this.reset_timer == 0 then
				this.anim = this.inactive_anim
				this.active = false
			end
		end
	end,
	on_activate=function(this)
		if this.active then
			return
		end
		this.active = true
		this.reset_timer = this.reset_time
		this.anim = this.active_anim
		local col,row,walls,mincol,maxcol,minrow,maxrow,projectiles = flr(pos_to_tile(this.x)),
			flr(pos_to_tile(this.y)),
			{top=false,right=false,bottom=false,left=false},
			flr(pos_to_tile(tile_to_screen(room.x))),
			flr(pos_to_tile(tile_to_screen(room.x) + SCREEN_SIZE - 1)),
			flr(pos_to_tile(tile_to_screen(room.y))),
			flr(pos_to_tile(tile_to_screen(room.y) + SCREEN_SIZE - 1)),
			{}
		-- yes this for-loop is terrible
		for offset=0,15 do
			if col - offset >= mincol and not walls.left then
				if mget(col - offset, row) == WALL_TILE then
					walls.left = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile((col - offset) * TILE_SIZE + TILE_HALF_SIZE, this.y, make_animation({52}), this.projectile_damage, this.projectile_speed, {x=1,y=0})
						)
					end
				end
			end
			if col + offset <= maxcol and not walls.right then
				if mget(col + offset, row) == WALL_TILE then
					walls.right = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile((col + offset) * TILE_SIZE - TILE_HALF_SIZE, this.y, make_animation({52}), this.projectile_damage, this.projectile_speed, {x=-1,y=0})
						)
					end
				end
			end
			if row - offset >= minrow and not walls.top then
				if mget(col, row - offset) == WALL_TILE then
					walls.top = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile(this.x, (row - offset) * TILE_SIZE + TILE_HALF_SIZE, make_animation({52}), this.projectile_damage, this.projectile_speed, {x=0,y=1})
						)
					end
				end
			end
			if row + offset <= maxrow and not walls.bottom then
				if mget(col, row + offset) == WALL_TILE then
					walls.bottom = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile(this.x, (row + offset) * TILE_SIZE - TILE_HALF_SIZE, make_animation({52}), this.projectile_damage, this.projectile_speed, {x=0,y=-1})
						)
					end
				end
			end
		end
		foreach(projectiles, function(proj)
			add(proj.collision_groups, PLAYER_GROUP)
			-- add(proj.collision_groups, ENEMY_GROUP)
		end)
	end
}

spike_type = {
	init=function(this)
		this.hitbox,
		this.frames,
		this.frame_times,
		this.current_frame,
		this.frame_time,
		this.frame_step,
		this.reset_time,
		this.reset_timer,
		this.touch_damage,
		this.targetable,
		this.collidable,
		this.static = {x=1,y=1,w=6,h=6},{16,17,18},{5,5,100},1,0,1,100,0,0,false,true,true
	end,
	update=function(this)
		if this.reset_timer > 0 then
			this.reset_timer -= 1
			return
		end
		this.frame_time += 1
		if this.frame_time >= this.frame_times[this.current_frame] then
			this.frame_time = 0
			if this.current_frame == count(this.frames) then
				this.frame_step = -1
				-- sfx(6,3)
			elseif this.current_frame == 1 then
				if this.frame_step == -1 then
					this.frame_step = 1
					this.reset_timer = this.reset_time
					return
				else
					-- sfx(5,3)
				end
			end
			this.current_frame += this.frame_step
			this.touch_damage = this.current_frame == count(this.frames) and 10 or 0
		end
	end,
	draw=function(this)
		spr(this.frames[this.current_frame], this.x, this.y)
	end
}

-- torch --
-----------

torch_type = {
	init=function(this)
		this.hitbox,
		this.targetable,
		this.collidable,
		this.target,
		this.anim,
		this.static={x=1,y=2,w=6,h=5},false,false,nil,make_animation({57,58}, 6),true
		this.auto_target_radius = 1000
		this.aggressive = (room.y >= 2 and room.x <= 4) and boss_hp > 0
		this.fire_timer = rnd(10) + rnd(50) + 150
	end,
	update=function(this)
		this.anim.update()

		if not this.aggressive then
			return
		end

		this.fire_timer -= 1
		this.find_player_target()
		if this.target ~= nil and this.fire_timer <= 0 and ceil(rnd(100)) > 50 then
			this.fire_timer = rnd(10) + rnd(50) + 150
			local dir = get_direction({x=this.x, y=this.y+TILE_HALF_SIZE}, {x=this.target.x, y=this.target.y})
			local proj = make_projectile(this.x, this.y + TILE_HALF_SIZE, make_animation({52}), 2, 0.75, dir)
			proj.ignore_walls = true
			sfx(3,2)
			add(proj.collision_groups, PLAYER_GROUP)
		end
	end
}

-- artifact --
--------------

artifact_type = {
	init=function(this)
		this.anim,
		this.can_interact,
		this.has_insulted_player,
		this.collidable,
		this.targetable,
		this.group =
		make_animation({60,61}, 20),
		false,
		false,
		false,
		false,
		ENEMY_GROUP
	end,
	update=function(this)
		this.collidable = has_spoken_to_moose
		this.targetable = has_spoken_to_moose
		if not has_started_boss_room then
			this.can_interact = check_player_can_interact() and flr(get_range(this, player)) <= TILE_SIZE
		else
			this.can_interact = check_player_can_interact() and flr(get_range(this, player)) <= TILE_SIZE and has_spoken_to_moose
		end
		if this.can_interact and btnp(k_action) then
			if has_spoken_to_moose then
				player.can_move = false
				did_take_the_artifact = true
				destroy_object(this)
				show_toast_message({
					"the goblet of grail is yours",
					"  you are no longer mortal  ",
					"   and still all-powerful   ",
					"     <mrrrrggghllhlhlh>     "
				},
				600,
				start_win_sequence
			)
				return
			end
			if is_all_powerful and not has_started_boss_room then
				goto_boss_room()
			elseif not this.has_insulted_player and not has_started_boss_room then
				show_toast_message({
					"weakling!! this is",
					"arthur's quest, not yours.",
					"<mumbles more insults>"
				})
				show_toast_message({
					"* loot the remaining chests *"
				})
			end
		end
		this.anim.update()
	end,
	take_damage = function(this, amount)
		player.can_move = false
		for i=0,10 do
			make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame],500)
		end
		destroy_object(this)
		show_toast_message(
			{
				"the goblet of grail is doid",
				"    you're still mortal    ",
				"but all-powerful nonetheless",
				"          <boom>            "
			},
			600,
			start_win_sequence
		)
	end
}

-- mirror --
mirror_type = {
	init=function(this)
		this.anim,
		this.can_interact,
		this.static =
		make_animation({12}),
		false,true
	end,
	update=function(this)
		this.can_interact = check_player_can_interact() and flr(get_range(this, player)) <= TILE_SIZE
		if this.can_interact and btnp(k_action) then
			show_player_stats_toast()
		end
		this.anim.update()
	end,
}

function show_player_stats_toast()
	local info = {
		"     health: "..tostr(flr(player.hp)).."/"..tostr(player.max_hp),
		"     damage: "..tostr(player.projectile_damage),
		"  fire dist: "..tostr(flr(30/player.projectile_speed/player.projectile_lifetime*30)*8),
		"  fire rate: "..tostr(30/player.fire_rate).."/sec",
		"target dist: "..tostr(player.auto_target_radius),
	}
	show_toast_message(info)
	show_toast_message(get_brief_world_stat_text())
end

function get_brief_world_stat_text()
	local stat_text = {
		"      doors: "..tostr(doors_destroyed).."/"..tostr(total_doors).."      ",
		"     chests: "..tostr(chests_looted).."/"..tostr(total_chests).."      ",
		"    enemies: "..tostr(enemies_destroyed).."      ",
	}

	return stat_text
end

function get_dmg_stat_text()
	return {
		"  dmg dealt: "..flr(total_dmg_dealt).."  ",
		"  dmg taken: "..flr(total_dmg_taken).."  ",
	}
end

function get_win_stat_text()
	local stat_text = get_brief_world_stat_text()
	add_each(stat_text, get_dmg_stat_text())
	local extra_text = {
		" difficulty: "..tostr(selected_difficulty == 1 and "easy" or "normal"),
		"",
		"",
		"       ★ achievements ★        ",
		""
	}
	-- add more with add_each(stat_text, rest)
	if doors_destroyed >= total_doors then
		add_each(extra_text,{
			"◆ fbi, open up!",
			"   -> destroy all doors"
		})
	end
	if did_anger_moose then
		add_each(extra_text,{
			"◆ annoyer of moose",
			"   -> he 'sploded"
		})
	end
	if did_take_the_artifact then
		add_each(extra_text,{
			"◆ neck problems",
			"   -> take the goblet of grail"
		})
	else
		add_each(extra_text,{
			"◆ no thanks",
			"   -> doid the goblet of grail"
		})
	end

	add_each(stat_text,extra_text)

	return stat_text
end

-- enemy spawn point --
-----------------------

enemy_spawn_point_type = {
	init=function(this)
		this.enemy_types,
		this.spawn_time,
		this.spawn_timer,
		this.spawn_duration,
		this.spawn_duration_timer,
		this.anim,
		this.spawn_anim,
		this.is_spawning,
		this.static = {},0,0,45,0,make_animation({6}),make_animation({7,8}, 8),false,true
	end,
	update=function(this)
		if not this.is_spawning then
			this.spawn_timer -= 1
			if this.spawn_timer <= 0 and count(objects) < MAX_ROOM_OBJECTS then
				this.is_spawning,
				this.spawn_timer,
				this.spawn_duration_timer = true,this.spawn_time,this.spawn_duration
			end
		end
		if this.is_spawning then
			this.spawn_duration_timer -= 1
			if this.spawn_duration_timer <= 0 then
				this.is_spawning = false
				local e = init_object(rnd(this.enemy_types), this.x, this.y)
				plan_next_move(e)
				sfx(2,3)
			end
		end
		this.anim.update()
		if this.is_spawning then
			this.spawn_anim.update()
		end
	end,
	draw=function(this)
		this.anim.draw(this)
		if this.is_spawning then
			this.spawn_anim.draw(this)
		end
	end
}

function make_enemy_spawn_point(x, y)
	local spawn_time = rnd(100) + 165
	sp = init_object(enemy_spawn_point_type, x, y)
	sp.spawn_time = spawn_time
	if difficulty <= 2.5 then
		sp.enemy_types = {eye_type, bug_type}
	elseif difficulty <= 3.5 then
		sp.enemy_types = {eye_type, bug_type, fang_type}
	else
		sp.enemy_types = {eye_type, bug_type, fang_type, skull_type}
	end
	return sp
end

-- boss door --
---------------
boss_door_type = {
	init = function(this)
		this.group,this.anim,this.static = ENEMY_GROUP,make_animation({BOSS_TILE}),true
		this.hurt_duration = 30
		this.hurt_duration_timer = 0
	end,
	take_damage = function(this, amount)
		if this.hurt_duration_timer > 0 then
			this.hurt_duration_timer -= 1
			return
		end
		this.hurt_duration_timer = this.hurt_duration
		boss_hp -= amount
		if boss_hp <= 0 then
			doors_destroyed += 1
			start_boss_defeated()
		else
			start_hurt_object(this)
		end
	end
}

function start_boss_defeated()
	music(-1)
	sfx(8,0)
	sfx(8,1)
	sfx(8,2)
	sfx(8,3)
	local obj = nil
	for i=count(objects),1,-1 do
		local should_destroy = true
		obj = objects[i]
		if obj ~= player then
			if obj.static then
				make_particle_group(obj.x,obj.y,BOSS_TILE,rnd(250) + 250)
				if obj.type == boss_door_type then
					mset(pos_to_tile(obj.x),pos_to_tile(obj.y),FLOOR_TILE)
				elseif obj.type == torch_type then
					should_destroy = false
					obj.aggressive = false
				elseif obj.type == mirror_type then
					should_destroy = false
				else
					mset(pos_to_tile(obj.x),pos_to_tile(obj.y),FLOOR_TILE)
				end
			end
			if should_destroy then
				destroy_object(obj)
			end
		end
	end
	make_particle_group(72*TILE_SIZE,48*TILE_SIZE,BOSS_TILE,rnd(250) + 250)
	mset(72,48,FLOOR_TILE)
	show_toast_message({
		"everything's doid",
		"nice work!",
	})
	show_toast_message({
		"let's see what's going",
		"on back there...",
	}, 600, function()
		music(61,4000)
	end)
end

-- object functions --
----------------------

function init_object(type,x,y)
	local obj = {}

	obj.type,
	obj.collidable,
	obj.targetable,
	obj.flip,
	obj.x,
	obj.y,
	obj.hitbox,
	obj.spd,
	obj.moves,
	obj.group,
	obj.hp,
	obj.anim,
	obj.is_hurt,
	obj.hurt_duration,
	obj.hurt_duration_timer,
	obj.hurt_collidable,
	obj.static,
	obj.touch_damage,
	obj.can_interact,
	obj.is_enemy =
	type, -- type
	true, -- collidable
	true, -- targetable
	{x=false,y=false}, -- flip
	x, -- pos y
	y, -- pos x
	{x=0,y=0,w=TILE_SIZE,h=TILE_SIZE}, -- hitbox
	1, -- speed
	{}, -- moves
	NO_GROUP, -- group
	1, -- hp
	nil, -- anim
	false, -- is hurt
	30, -- hurt duration
	0, -- hurt duration timer
	true, -- hurt collidable
	false, -- static
	0, -- touch damage
	false, -- can interact
	false -- is enemey

	obj.collide=function(groups)
		local other
		for i=1,count(objects) do
			other = objects[i]
			if obj.collides_with(other) and index_of(groups, other.group) > 0 then
				return other
			end
		end
	end

	obj.collides_with=function(other)
		return other ~= nil and other ~= obj and
			obj.collidable and other.collidable and
			other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x and
			other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y and
			other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w and
			other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h
	end

	obj.move=function()
		if count(obj.moves) == 0 then
			return
		end
		local dest = obj.moves[1]
		if obj.x ~= dest.x then
			local sign = obj.x - dest.x > 0 and -1 or 1
			obj.x += sign
		end
		if obj.y ~= dest.y then
			local sign = obj.y - dest.y > 0 and -1 or 1
			obj.y += sign
		end
		if obj.x == dest.x and obj.y == dest.y then
			del(obj.moves, dest)
		end
	end

	obj.can_move_to = function(x,y)
		return fget(mget(x,y)) == 0
	end

	obj.can_move_through = function(x,y)
		local t = mget(x,y)
		return fget(t) == 0 or (fget(t,7))
	end

	obj.move_to = function(x,y)
		add(obj.moves, {x=x, y=y})
	end

	obj.take_damage = function(amount)
		if obj.type.take_damage ~= nil then
			obj.type.take_damage(obj, amount)
			if obj.is_enemy then
			end
		else
			if obj.is_enemy then
				track_dmg_dealt(amount)
			end
			obj.hp -= amount
			if obj.hp <= 0 then
				if obj.is_enemy then
					track_enemy_destroyed()
				end
				if obj.anim ~= nil then
					make_particle_group(obj.x,obj.y, obj.anim.frames[obj.anim.current_frame])
				else
					make_particle_group(obj.x, obj.y)
				end
				destroy_object(obj)
				-- instead check if obj has on_destroy
				-- which should handle spawning pickups
				if obj.type ~= player_type then
					if rnd(1000) > 750 then
						make_hp_pickup(obj.x,obj.y,ceil(player.max_hp * 0.12))
					end
					sfx(9,2)
				end
				return
			end
			start_hurt_object(obj)
		end
	end

	obj.find_player_target = function()
		if player == nil or player.dead then
			obj.target = nil
			return
		end
		local range = get_range(obj, player)
		if range > 0 and range <= obj.auto_target_radius then
			obj.target = player
		else
			obj.target = nil
		end
	end


	obj.find_target_in_group = function(group)
		local group,other,range,target = group or NO_GROUP, nil, 0, {obj = nil, range = 0}

		for i=1,count(objects) do
			other = objects[i]
			if obj ~= other and other.targetable and other.group == group then
				range = get_range(obj, other)
				if range > 0 and range <= obj.auto_target_radius then
					if target.obj == nil or range < target.range then
						target.obj = other
						target.range = range
					end
					-- prioritized by threat
					-- if target.obj == nil or
					-- (target.obj.threat < other.threat or
					-- 	(target.obj.threat == other.threat and target.range > range)
					-- ) then
					-- 	target.obj = other
					-- 	target.range = range
					-- end
				end
			end
		end
		obj.target = target.obj
	end

	add(objects, obj)
	
	if obj.type.init~=nil then
		obj.type.init(obj)
	end

	return obj
end

function destroy_object(obj)
	del(objects, obj)
end

function move_object(obj)
	if obj.type.move ~= nil then
		obj.type.move(obj)
	end
end

function start_hurt_object(obj)
	obj.is_hurt,
	obj.hurt_duration_timer,
	obj.collidable =
		true,
		obj.hurt_duration,
		obj.hurt_collidable
end

function update_hurt_object(obj)
	obj.hurt_duration_timer -= 1
	if obj.hurt_duration_timer <= 0 then
		obj.is_hurt = false
		obj.collidable = true
	end
end

function update_toasts()
	if toast_msg_window != nil then
		toast_msg_window.update(toast_msg_window)
	elseif count(toast_msg_queue) > 0 then
		toast_msg_window = toast_msg_queue[1]
		del(toast_msg_queue, toast_msg_window)
	end
end

function add_random_move(obj)
	if count(obj.moves) ~= 0 then
		return
	end
	local possible_moves,mx,my = {},0,0
	for dx=-1,1 do
		for dy=-1,1 do
			if (dx == 0 and dy ~= 0) or (dy == 0 and dx ~= 0) then
				mx = dx * TILE_SIZE + obj.x
				my = dy * TILE_SIZE + obj.y
				if obj.can_move_to(pos_to_tile(mx),pos_to_tile(my)) and not is_move_to_next_room(mx,my) then
					add(possible_moves, {x=mx,y=my})
				end
			end
		end
	end
	if count(possible_moves) > 0 then
		add(obj.moves, rnd(possible_moves))
	end
end

function plan_next_move(obj)
	if player == nil or count(obj.moves) > 0 or obj.is_hurt then
		return
	end
	local range = get_range(obj, player)
	if player.dead or range > obj.auto_target_radius then
		add_random_move(obj)
		return
	end
	local m = get_manhattan(obj, player)
	if (m.x == 0 and m.y == 0) then
		return
	end
	local dx,dy = sign(m.x), sign(m.y)
	if dx ~= 0 and dy ~= 0 then
		if rnd() > 0.5 then
			dx = 0
		else
			dy = 0
		end
	end
	local mx,my = dx * TILE_SIZE + obj.x, dy * TILE_SIZE + obj.y
	if (obj.can_move_to(pos_to_tile(mx), pos_to_tile(my))) then
		add(obj.moves, {x=mx, y=my})
	end
end

-- animation --
---------------

function make_animation(frames, frame_time)
	local anim = {
		current_frame = 1,
		frames = frames or {0},
		frame_time = frame_time or 0,
		frame_timer = frame_time or 0
	}

	anim.current_frame = ceil(rnd(count(anim.frames)))

	anim.update = function()
		anim.frame_timer -= 1
		if anim.frame_timer <= 0 then
			anim.current_frame += 1
			anim.frame_timer = anim.frame_time
		end
		if anim.current_frame > count(anim.frames) then
			anim.current_frame = 1
		end
	end

	anim.draw = function(obj)
		if obj.is_hurt and (obj.hurt_duration_timer%4 == 0) then
			pal(HURT_FLASH_PAL)
		end
		spr(anim.frames[anim.current_frame], obj.x, obj.y)
		pal()
	end

	return anim
end

-- particles --
---------------

particles = {}
particle_pool = {}
function make_particle_group(x,y,sprite,lifetime)
	local pgroup

	if count(particle_pool) > 0 then
		pgroup = particle_pool[1]
		del(particle_pool, pgroup)

		pgroup.init(x,y,sprite,lifetime)
		add(particles, pgroup)

		return
	end
	
	pgroup = {
		lifetime = 0,
		particles={}
	}

	for i=1,64 do
		add(pgroup.particles, {x=0,y=0,spd=1,dir={x=1,y=0},color=8})
	end

	pgroup.init = function(x, y, sprite, lifetime)
		pgroup.lifetime = lifetime or 80
		if sprite ~= nil then
			local col,row,p = flr(sprite % 16),flr(sprite / 16)
			for px=0,7 do
				for py=0,7 do
					p = pgroup.particles[px * 8 + py + 1]
					p.x,
					p.y,
					p.spd,
					p.dir.x,
					p.dir.y,
					p.color = x + px,y + py,0.4,rnd() * (rnd() >= 0.5 and -1 or 1),rnd() * (rnd() >= 0.5 and -1 or 1),sget(col * TILE_SIZE + px, row * TILE_SIZE + py)
				end
			end
		else
			local r,theta = 6, 1
			foreach(pgroup.particles, function(p)
				theta,
				p.x,
				p.y,
				p.spd,
				p.dir.x,
				p.dir.y,
				p.color = rnd() * 2 * 3.14,x + r * cos(theta),y + r * sin(theta),0.5,rnd() > 0.5 and -rnd() or rnd(),rnd() > 0.5 and -rnd() or rnd(),8
			end)
		end
	end

	pgroup.init(x,y,sprite,lifetime)
	add(particles, pgroup)
end

update_particles = function()
	local pgroup
	for i=count(particles),1,-1 do
		pgroup = particles[i]
		pgroup.lifetime -= 1
		if pgroup.lifetime > 0 then
			for p in all(pgroup.particles) do
				p.dir.y += 0.005
				p.x += p.dir.x * p.spd
				p.y += p.dir.y * p.spd
			end
		else
			del(particles, pgroup)
			add(particle_pool, pgroup)
		end
	end
end

-- drawing --
-------------
function draw_object(obj)
	if obj.type.draw ~= nil then
		obj.type.draw(obj)
	elseif obj.anim ~= nil then
		obj.anim.draw(obj)
	end
	if obj.can_interact then
		print("❎", obj.x,obj.y-6,12)
	end
	if debug then
		rect(obj.x+obj.hitbox.x,obj.y+obj.hitbox.y,obj.x+obj.hitbox.x+obj.hitbox.w-1,obj.y+obj.hitbox.y+obj.hitbox.h-1,8)
	end
end

function draw_particles()
	for group in all(particles) do
		for p in all(group.particles) do
			if p.color ~= 0 then
				pset(p.x, p.y, p.color)
			end
		end
	end
end

function draw_ui()
	if player == nil then
		return
	end
	draw_hp_bar()
	if has_started_boss_room and boss_hp > 0 then
		draw_boss_hp_bar()
	end
end

function draw_hp_bar()
	local pad,w,h = 1,31,2
	rectfill(camera_pos.x + pad, camera_pos.y + pad, camera_pos.x + w + pad, camera_pos.y + h + pad, 0)
	rectfill(camera_pos.x + pad, camera_pos.y + pad, camera_pos.x + pad + flr(player.hp/player.max_hp*w), camera_pos.y + h + pad, 8)
	if player.is_hurt and (player.hurt_duration_timer%4 == 0) then
		pal(HURT_FLASH_PAL)
	end
	rect(camera_pos.x + pad, camera_pos.y + pad, camera_pos.x + w + pad, camera_pos.y + h + pad, 7)
	pal()
end

function draw_boss_hp_bar()
	left,top,w,h=camera_pos.x+6*TILE_SIZE,camera_pos.y+1,39,5
	rectfill(left, top, left + w, top + h, 0)
	rectfill(left, top, left + flr(boss_hp/max_boss_hp*w), top + h, 8)
	rect(left, top, left+w, top+h, 7)
end


-- rooms --
-----------

function start_room_transition(x_index, y_index)
	foreach(objects, function(obj)
		if obj.type ~= player_type then
			add(transition_objects, obj)
			del(objects, obj)
		end
	end)

	
	is_room_transition,
	room.x,
	room.y,
	update_fn = true,x_index,y_index,update_room_transition

	local tile_type,tx,ty = nil,0,0

	for c=x_index*SCREEN_TILES,x_index*SCREEN_TILES+SCREEN_TILES-1 do
		for r=y_index*SCREEN_TILES,y_index*SCREEN_TILES+SCREEN_TILES-1 do
			tx = c*TILE_SIZE
			ty = r*TILE_SIZE
			tile_type = mget(c,r)
			if tile_type == DOOR_TILE then
				-- this does allow projectiles to go through doors when "pierce" is true
				mset(c,r,DOOR_TILE)
				init_object(door_type, tx, ty)
			elseif tile_type == ENEMY_SPAWN_TILE then
				make_enemy_spawn_point(tx,ty)
			elseif tile_type == SPIKE_TILE then
				mset(c,r,FLOOR_TILE)
				init_object(spike_type, tx, ty)
			elseif tile_type == TORCH_TILE then
				mset(c, r, WALL_TILE)
				init_object(torch_type, tx, ty)
			elseif tile_type == TRAP_TILE then
				init_object(trap_type, tx, ty)
			elseif tile_type == VENDOR_TILE then
				mset(c, r, FLOOR_TILE)
				if vendor == nil then
					vendor = init_object(vendor_type, tx, ty)
				else
					add(objects, vendor)
				end
			elseif tile_type == UPGRADE_HP_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_hp)
			elseif tile_type == UPGRADE_DMG_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_damage)
			elseif tile_type == RICOCHET_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_projectile_ricochet)
			elseif tile_type == PIERCE_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_projectile_pierce)
			elseif tile_type == FAST_SHOT_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_fire_rate)
			elseif tile_type == SNOIPER_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_target_radius)
			elseif tile_type == THE_DISTANCE_TILE then
				place_upgrade_chest(c,r,tx,ty,upgrade_projectile_lifetime)
			elseif tile_type == BOSS_TILE and room.x == 4 and room.y == 3 then
				init_object(boss_door_type,tx,ty)
			elseif tile_type == MOOSE_TILE then
				mset(c,r,NO_PASS_FLOOR_TILE)
				init_object(moose_type,tx,ty)
			elseif tile_type == MIRROR_TILE then
				mset(c,r,BLOCK_TILE)
				init_object(mirror_type,tx,ty)
			elseif tile_type == ARTIFACT_TILE then
				mset(c,r,NO_PASS_FLOOR_TILE)
				init_object(artifact_type,tx,ty)
			end
		end
	end
end

function place_upgrade_chest(c,r,x,y,upgrade_type)
	mset(c, r, NO_PASS_FLOOR_TILE)
	make_upgrade_pickup(x, y, upgrade_type)
	init_object(chest_type, x, y)
end

function update_room_transition()
	player.move()
	local diffx,diffy = tile_to_screen(room.x) - camera_pos.x, tile_to_screen(room.y) - camera_pos.y

	if diffx ~= 0 then
		camera_pos.x += camera_spd * sign(diffx)
	end
	if diffy ~= 0 then
		camera_pos.y += camera_spd * sign(diffy)
	end

	is_room_transition = diffx ~= 0 or diffy ~= 0
	camera(camera_pos.x, camera_pos.y)

	if not is_room_transition then
		end_room_transition()
	end
end

function end_room_transition()
	update_fn = game_update
	local obj,t,tilex,tiley =
	nil,nil,0,0
	for i=count(transition_objects),1,-1 do
		obj = transition_objects[i]
		t = obj.type
		tilex,tiley = pos_to_tile(obj.x),pos_to_tile(obj.y)
		del(transition_objects, obj)
		if t == door_type then
			mset(tilex,tiley,DOOR_TILE)
		elseif t == spike_type then
			mset(tilex,tiley,SPIKE_TILE)
		elseif t == torch_type then
			mset(tilex,tiley,TORCH_TILE)
		elseif t == vendor_type then
			mset(tilex,tiley,VENDOR_TILE)
		elseif t == pickup_type and obj.spr > 0 then
			mset(tilex,tiley,obj.spr)
		elseif t == moose_type then
			mset(tilex,tiley,MOOSE_TILE)
		elseif t == artifact_type then
			mset(tilex,tiley,ARTIFACT_TILE)
		elseif t == mirror_type then
			mset(tilex,tiley,MIRROR_TILE)
		end
	end
end

function goto_boss_room()
	room.x,
	room.y,
	has_started_boss_room,
	camera_pos.x,
	camera_pos.y,
	player.x,
	player.y =
	4, -- room y
	3, -- room x
	true, -- started boss room
	tile_to_screen(4), -- cam x
	tile_to_screen(3), -- cam y
	66 * TILE_SIZE, -- player y
	49 * TILE_SIZE -- player x

	start_room_transition(room.x,room.y)
	camera(camera_pos.x, camera_pos.y)
	end_room_transition()
	music(-1)
	music(54,4000)
end

-- difficulty --
----------------

difficulty_choices ={
	"easy",
	"normal",
}
selected_difficulty = 2
difficulty_window = {
	update=function()
		if btnp(k_up) then
			selected_difficulty = clamp(selected_difficulty - 1, 1, 2)
		elseif btnp(k_down) then
			selected_difficulty = clamp(selected_difficulty + 1, 1, 2)
		elseif btnp(k_action) then
			if selected_difficulty == 1 then
				enemy_hp_scale = 0.35
				enemy_dmg_scale = 0.25
			end
			window = nil
			update_fn = game_update
			music(59,4000)
		end
	end,
	draw=function()
		rectfill(29,48,106,88,5)
		rect(28,48,106,88,0)
		print("choose difficulty",34,50,7)
		for i=1,count(difficulty_choices) do
			local is_selected = selected_difficulty == i
			print(
				(is_selected and "* " or "  ")..difficulty_choices[i],
				52,
				62 + ((i-1) * 7),
				is_selected and 12 or 7
			)
		end
		print("press ❎ to confirm", 30,82, 7)
	end
}
function show_select_difficulty_window()
	window = difficulty_window
	update_fn = difficulty_window.update
end

-- death --
-----------

death_window_delay = 120
death_window_delay_timer = 0
start_death_transition = function()
	music(-1)
	sfx(1)
	death_window_delay_timer = death_window_delay
	update_fn = update_death
end

update_death = function()
	death_window_delay_timer = clamp(death_window_delay_timer - 1, 0, death_window_delay)
	if death_window_delay_timer <= 0 and window ~= death_window then
		window = death_window
		sfx(7)
	end
	game_update()
	death_window.update()
end

death_window = {
	update = function()
		if btnp(k_action) then
			run()
		end
	end,
	draw = function()
		local stat_text = get_brief_world_stat_text()
		add_each(stat_text, get_dmg_stat_text())
		local pad,stats_top_offset,window_rect = 
			4,
			17,
			{left=camera_pos.x + 8, top=camera_pos.y+40, right=camera_pos.x + 119, bottom=camera_pos.y + 100}
		rectfill(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 0)
		rect(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 8)
		spr(11, window_rect.left + 27, window_rect.top + pad - 2)
		print("you doid", window_rect.left + 40, window_rect.top + pad)
		for i=1,count(stat_text) do
			print(stat_text[i], window_rect.left + pad + 1, window_rect.top + ((4+2) *(i-1)) + stats_top_offset, 7)
		end
		spr(11, window_rect.left + 76, window_rect.top + pad - 2, 1, 1, true)
		print("press ❎ to play again", window_rect.left + 13, window_rect.bottom - pad * 1.5, 7)
	end
}

-- win --
---------

win_window_restart_timer = 500
win_player_spr = nil
win_fireworks_timer = 0
win_window = {
	update = function()
		if win_window_restart_timer > 0 then
			win_window_restart_timer -= 1
		end
		if win_window_restart_timer <= 0 and btnp(k_action) then
			run()
		end
		if win_fireworks_timer <= 0 then
			win_fireworks_timer = 600
			for i=1,10 do
				make_particle_group(camera_pos.x + rnd(SCREEN_SIZE), camera_pos.y + rnd(SCREEN_SIZE-8) + 8, flr(rnd(64))+1, win_fireworks_timer)
			end
		else
			win_fireworks_timer -= 1
		end
	end,
	draw = function()
		local pad,stats_top_offset,text_content,window_rect = 
			2,
			12,
			get_win_stat_text(),
			{left=camera_pos.x, top=camera_pos.y, right=camera_pos.x + 127, bottom=camera_pos.y + 127}
		rectfill(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 0)
		rect(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 3)
		spr(ARTIFACT_TILE + 1, window_rect.left + pad + 1, window_rect.top + pad + 1)
		spr(ARTIFACT_TILE, window_rect.right - TILE_SIZE - pad + 1, window_rect.top + pad, 1, 1)
		spr(ARTIFACT_TILE, window_rect.left + pad + 1, window_rect.bottom - pad * 5)
		spr(ARTIFACT_TILE + 1, window_rect.right - TILE_SIZE - pad + 1, window_rect.bottom - pad * 5 + 1, 1, 1)
		spr(win_player_spr, window_rect.left + SCREEN_SIZE/2 - TILE_HALF_SIZE, window_rect.top + 49)
		for i=1,count(text_content) do
			print(text_content[i], window_rect.left + pad, window_rect.top + ((4+2) *(i-1)) + stats_top_offset, 13)
		end
		if win_window_restart_timer <= 0 then
			print("press ❎ to play again", window_rect.left + 21, window_rect.bottom - pad * 4, 3)
		end
	end
}

function start_win_sequence()
	win_player_spr = did_take_the_artifact and 33 or 32
	has_started_win_sequence = true
	update_fn = win_update
	window = win_window
end

function win_update()
	if window ~= nil then
		window.update()
	end
	foreach(objects,function(obj)
		if obj ~= player and obj.type.update~=nil then
			obj.type.update(obj)
		end
	end)
	update_toasts()
	update_particles()
end

-- utils --
-----------

function get_total_text_width(text_list)
	local tmp_w, w = 0,0
	foreach(text_list, function(msg)
		tmp_w = text_w_px(msg)
		if tmp_w > w then
			w = tmp_w
		end
	end)

	return w
end

function add_each(list_a, list_b)
	foreach(list_b, function(item)
		add(list_a, item)
	end)
end

function check_player_can_interact()
	return window == nil and count(toast_msg_queue) == 0 and player ~= nil and not player.dead and not has_started_win_sequence
end

function increase_difficulty(amount)
	difficulty += amount
end

function track_dmg_dealt(amount)
	total_dmg_dealt += amount
end
function track_enemy_destroyed()
	enemies_destroyed += 1
end

function get_enemy_hp_for_difficulty(base_hp)
	return base_hp * difficulty * enemy_hp_scale
end

function get_enemy_dmg_for_difficulty(base_dmg)
	return base_dmg * difficulty * enemy_dmg_scale
end

function tile_to_screen(v)
	return v * SCREEN_SIZE
end

function pos_to_tile(v)
	return flr(v/TILE_SIZE)
end

function text_w_px(text)
	return #text * 4 - 1
end

function get_open_pos_next_to(x, y)
	local c = flr(pos_to_tile(x))
	local r = flr(pos_to_tile(y))
	if fget(mget(c+1,r)) == 0 then
		return {x=x+TILE_SIZE,y=y}
	elseif fget(mget(c,r+1)) == 0 then
		return {x=x,y=y+TILE_SIZE}
	elseif fget(mget(c-1,r)) == 0 then
		return {x=x-TILE_SIZE,y=y}
	elseif fget(mget(c,r-1)) == 0 then
		return {x=x,y=y-TILE_SIZE}
	else
		return {x=x,y=y}
	end
end

function is_move_to_next_room(x,y)
	return x > tile_to_screen(room.x) + SCREEN_SIZE - 1 or
		x < tile_to_screen(room.x) or
		y > tile_to_screen(room.y) + SCREEN_SIZE - 1 or
		y < tile_to_screen(room.y)
end

function clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end

function sign(v)
	return v > 0 and 1 or -1
end

function get_range(obj, other)
	return sqrt(
		((other.x + TILE_HALF_SIZE) - (obj.x + TILE_HALF_SIZE))^2 + ((other.y + TILE_HALF_SIZE) - (obj.y + TILE_HALF_SIZE))^2
	)
end

function index_of(tbl, value)
	for i=1,#tbl do
		if tbl[i] == value then
			return i
		end
	end

	return 0
end

function get_direction(pos,dest)
	local dx,dy = dest.x - pos.x,dest.y - pos.y
	local norm = sqrt(dx^2 + dy^2)
	return {x=dx/norm, y=dy/norm}
end

function get_manhattan(pos,dest)
	return {x=flr(dest.x-pos.x),y=flr(dest.y-pos.y)}
end
__gfx__
00000000555005556777777644c44c4467777776aa5555aa67766776000000000888888044444444454454540085880044455444880000884444444400444400
000000005050050576777767cc4444cc76777767a9a55a9a765555670088880080000008444444444454544508588580445c75448000000849a99a9404000040
0070070055000055776776774c4cc4c4776776775a5aa5a575566557080000808008800844444444554544540578778045c77c540000000049a99a9404033040
00077000000000007776677744cccc447776677755aaaa556567765608088080808008086666666666656656056876506577c7560000000044944944403bb304
00077000000000007776677744cccc447776677755aaaa55656776560808808080800808994999499959955908777750957c77590000000049a99a94943bb344
0070070055000055776776774c4cc4c4776776775a5aa5a575566557080000808008800844444444454454440587785045c77c540000000049a99a9444444444
000000005050050576777767cc4444cc76777767a9a55a9a7655556700888800800000084444444444544544058585804457c5448000000849a99a9444944944
00000000555005556777777644c44c4467777776aa5555aa67766776000000000888888094999499959995990855858099455499880000884444444404444440
000000000000000005000500677667766776677600cccc0000cccc0000cccc0000cccc0000000000000000000000000000000088000000000000000000000000
0000000005000500055005507ffffff7767777670c0cccc00c00ccc00c000cc00c0000c0000111000000000000000000000008080088880000cc0000000cc000
0555055505550555055505557f6ff6f77ffffff7c00cccccc00cccccc00000ccc000000c011000100008080000020200088888088888880000c1ccc000cc1c00
000000000000000000000000677667766f7ff7f6c0ccccccc00cccccc00000ccc000000c100000010082828000282820080088088800888800c111c00c111cc0
000000000000000000000000677667766f7ff7f6c0ccccccc00cccccc00000ccc000000c10000001008222800028882000088888008888880c111c000cc111c0
0000000000000000500050007f6ff6f77ffffff7c00cccccc00cccccc00000ccc000000c01000110000828000002820000088888008808880ccc1c0000c1cc00
0000000050005000550055007ffffff7767777670c0cccc00c00ccc00c000cc00c0000c000111000000080000000200000880000008000080000cc00000cc000
555055505550555055505550677667766776677600cccc0000cccc0000cccc0000cccc0000000000000000000000000000000000008888880000000000000000
00333000003510006777777650000005500000050002200000022000000110000000a0000ccc000011555511022002200000100000cccc000000000000000000
0053500000338000867ff7685000000550000005002112000021120000001100000600000b11cccc001551002b8228820001d1000ccccbc00099990000aaaa00
00181000003510007865567805000050050000500028e200002e82001000011000e6e000bbb1111c00111100bbb88882011ddd100cccccc0099aa9900aa99aa0
0353530003535300785ff5870044440000444400025115200251152011011b710eeeee000b11b11c001bb1002b88b8821dbdd1d10cc1cbc009a99a900a9aa9a0
033533000335330087fb3f780454450000544540021b31200213b120011bbbb10ebbbb20c11bbbc000b11b00288bbb821ddbbdd10cc1cc0009a99a900a9aa9a0
085358000853580078f3bf8700411440044114000213b120021b3120001bb11002222222c111b1c0055115500288b82001ddd1100cccbc00099aa9900aa99aa0
0030300000303000887ff8880444440000444440020dd020020dd0200001100002bbbbb2cccc11c000022000002882000011100000cbc0000099990000aaaa00
0030300000303000878ff7780000044004400000020dd020020dd02000000000022222220000ccc000022000000220000000000000cc00000000000000000000
00003000000000000111111001111110000000000009900000999900000000000e2ee2e09000000000000009099999900000000044444440a000000000000000
000330000000300011111111011111100000000009299290009229000e2ee2e0022ee220000a00000090a000900dd009444444404a989a4000ee920000e22200
00333300000330001211112111111111008888000299992009722790022ee220022ee2200009990000a99900900dd009489a984049999940a2e22ee0029ee9e0
033bb33000333300122112211111111108aa9a809299992992722729022ee2202ee22ee20059a5099059a50090dddd0949999940049994000929a2e002ea9e20
03b33b30033bb33012e11e211211112189a99a9899999999922222292ee22ee2029a9a20005555000055550009dddd9004999400004940000e2a929002e9ae20
03b37b3033b33b3312e11e2112e11e2108aaa980997227999722227902eeee200ea9a9e00004400000044000090dd09000494000004940000ee22e200e9ee920
033bb33033b37b33111111111111111100888800097997900972279002eeee2002eeee2000044000000440000090090000494000049994000029ee0000222e00
00333300033bb3300111111001111110000000000099990000999900002ee200002ee20000000000000000000009900004999400000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000101020101000000000000000001010101010101010101010101010100000000010101010101020100000000000
00000000101093202020931010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000102031201000000000000000101020012020202020200120202020100000000010202020202020100000000000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000010b220201000000000000000102001202020202020202001202020100000000010202020202020100000000000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010000000000000101020101000000000000000102031101010101010101010206020100000000010209320202020100000000000
00000000101093202020931010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202010000000000000102031c21000000000000000101020101010101010100010202020100000000010202020202020100000000000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10209320202020202020202010101010100000102020201000000000000000101020102020202020100010202020100010101010202020202020100000000000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020200120012020202020202020100000101020101000000000000000102031300120202020100010208220100010202020010120209320100000000000
00000000101093202020931010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
102020200120202001202020102020821010101010311010101010101010101020c2102020602020100010101010100010202020208220202020100000000000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202001202031202001202010c0a0a0101020202020209320202020202010101010102020202020100000000000000010202020200101101010101010100000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
102020722020c3222020202020202020203020202020202020202020202030202020202020202020931010101010101010209320202020102020202020100000
00000000101093202020931010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202001202031202001202010101010101020932020202020202020202010101010101010102020202020202020201010202020202020102001200120100000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
102020200120202001202020100000000010101010100101100101101010101010b2012020102020202020202020101010102020202020102020b22020100000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020200120012020202010000000000000102020202020202020201000001001202020102020202020602020302020302020209320102001200120100000
00000000101093202020931010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10209320202020202020202010000000000000102060202092202060201000001020202020102020202020202020101010102020202020300120202020100000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202010000000000000102020202020202020201000001020202031302020202020202020100000102020202020102001202020100000
00000000101010202020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010000000000000101010101010101010101000001010101010101010101010101010100000101010101010101010101010100000
00000000101093202020931010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020100010105010100010202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202220101010505050101010202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10c00190101050505050501010202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10203120939350505050509393202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020206020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202060206020602020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020602020206020202060202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020206020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020206020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
55555555555555555555555555555555555555555555555599999999999999999999999999999999555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa9555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559a9999a99a9999a99a9999a99a9999a9555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a9555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a9555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559a9999a99a9999a99a9999a99a9999a9555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa9555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555599999999999999999999999999999999555555555555555555555555555555555555555555555555
55555555555555556666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666665555555555555555
55555555555555556666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566662666644444465555555555555555
55555555555555556666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a9555555556662266649a99a945555555555555555
55555555555555556666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566222266449449445555555555555555
55555555555555556666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a955555555622ee22649a99a945555555555555555
55555555555555556666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555522e22e2249a99a945555555555555555
55555555555555556666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555522e2fe2249a99a945555555555555555
555555555555555566666666666666665555555599999999999999999999999999999999999999999999999955555555622ee226444444445555555555555555
55555555666666666666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666666666666655555555
55555555666666666666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566666666666666666666666655555555
55555555666666666666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666666666666655555555
55555555666666666666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666666666666655555555
55555555666666666666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566666666666666666666666655555555
55555555666666666666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666666666666655555555
55555555666666666666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666666666666655555555
55555555666666666666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a99a9aa9a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559a9999a99a9999a99a9999a99a9999a99a9999a99a9999a95555555566666666666666666666666655555555
55555555666666666666666666666666555555559aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa95555555566666666666666666666666655555555
55555555666666666666666666666666555555559999999999999999999999999999999999999999999999995555555566666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666266666666666666626666666666666662666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666662266666666666666226666666666666622666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666622226666666666662222666666666666222266666666666666666666666666666666666666666666666666666666666666666655555555
5555555566666666622ee22666666666622ee22666666666622ee226666666666666666666666666666666666666666666666666666666666666666655555555
555555556666666622e22e226666666622e22e226666666622e22e22666666666666666666666666666666666666666666666666666666666666666655555555
555555556666666622e2fe226666666622e2fe226666666622e2fe22666666666666666666666666666666666666666666666666666666666666666655555555
5555555566666666222ee22266666666622ee22666666666622ee226666666666666666666666666666666666666666666666666666666666666666655555555
5555555566666666622ee22666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666666626666666666666666666666626666666666666666666666626666666666666666666
55555555666666666666666666666666666666666666666666666666666226666666666666666666666226666666666666666666666226666666666666666666
55555555666666666666666666666666666666666666666666666666662222666666666666666666662222666666666666666666662222666666666666666666
55555555666666666666666666666666666666666666666666666666622ee2266666666666666666622ee2266666666666666666622ee2266666666666666666
5555555566666666666666666666666666666666666666666666666622e22e22666666666666666622e22e22666666666666666622e22e226666666666666666
5555555566666666666666666666666666666666666666666666666622e2fe22666666666666666622e2fe22666666666666666622e2fe226666666666666666
55555555666666666666666666666666666666666666666666666666622ee2266666666666666666622ee2266666666666666666622ee2266666666666666666
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666666626666666266666666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666666226666662266666666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666662222666622226666666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666622ee226622ee22666666666666666666666666666666666666666666666666666666666
5555555566666666666666666666666666666666666666666666666622e22e2222e22e2266666666666666666666666666666666666666666666666666666666
5555555566666666666666666666666666666666666666666666666622e2fe2222e2fe2266666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666622ee226622ee22666666666666666666666666666666666666666666666666666666666
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666688666688666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666626666666666686662668666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666226666666666666622666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666662222666666666666222266666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666622ee22666666666622ee226666666666666666666666666666666666666666655555555
5555555566666666666666666666666666666666666666666666666622e22e226666666622e22e22666666666666666666666666666666666666666655555555
5555555566666666666666666666666666666666666666666666666622e2fe226666666682e2fe28666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666622ee22666666666882ee288666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666626666666266666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666226666662266666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666662222666622226666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666622ee226622ee22666666666666666666666666655555555
5555555566666666666666666666666666666666666666666666666666666666666666666666666622e22e2222e22e2266666666666666666666666655555555
5555555566666666666666666666666666666666666666666666666666666666666666666666666622e2fe2222e2fe2266666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666622ee226622ee22666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666633366666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666653566666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666618166666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666353536666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666335336666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666853586666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666636366666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666636366666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666626666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666226666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666662222666666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666622ee2266666666655555555
5555555566666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666622e22e226666666655555555
5555555566666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666622e2fe226666666655555555
55555555666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666622ee2266666666655555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666665555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555666666666666666655555555555555555555555555555555555555555555555555555555

__gff__
0101000381810000000101000100010000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000101010101000101010101010000000000000000000000000000000000000000000000000000010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020202010001010501010001020201000000000000000000000001022c0201000102020202010000000000000000000000000000000000000001010101010000010101010101013901010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102250201010105050501010102020100000000000000000000000102020201010101021002010000000000000000000000000000000000000001102a10010000010101020202020202020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c090901010505050505010102020100000000000000000000000102020202020203100202010000000000000000000000000000000000000001021002010000000101020202023c02020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020239390505050505393902020100000000000000000000000102020201010139021002010000000000000000000000000000000000000001020202010000000101390202020202020239010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100010101010101010000000102060201000102020202010000000000000000000000000000000000000001020202010000000001010202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100010202020202010000000102020201000102020202010101010000000000000000000000000101010101020202010000000001010202022302020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010202020202020202020202020202010101020202020201000000010202020100010202020202022901000000000000000000000000012b020202020602010000000001010202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020202030202020202010101010102020201000102060202020202010000000000000000000000000102020202020202010000000001013902020202023901010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101010202020602020202020102020201000102020202020202010101010100000001010101010102020202020202010000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100010202020202020202020302020201000102020202020202020202020100000001020202020202020202020202010000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100010101010102020602020102020201000102020202020202020202390101010101010210020202020202020602010000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020202020202020202020202020201000000000001020202020201010101010001022b0202020206020202030202020202031002020202060202020202010000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000102020202020100000000000102020202020202020202010101010101390210020202021002020202010000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020100000000000101013903010100000000000102020202020202020202020100000001020202020202390301020202010000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000102010000000000000101010101010101010101010100000001010101010101010201010101010000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101000000000000000000000102010000000000000000000000000000000000000000000000000000000000010201000000000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202030202021002020201000000000000000001010102010101000000000000000000000000000000000000000000000000010101010201010101000000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102130101010202102d10020201000000000000000001020103390201000000000000000000000000000000000000000000000000012c02010339020201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020100010202021002020201000000000000000001020213020201000000000000000000000000000000000000000000000000010210020202020201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020100010202020202020201000000000000000001020202020201000000000000000000000000000000000000000000000000011002020202020201000000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020100010202020202020201000001010101010101020202020201000000000000000000000000000000000000000000000000010202020202020201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102130100010202020602020201000001020213020202020206021001000000000000000000000000000000000000000000000000010202060206020201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020100010101010101010101000001023901010202020202100201000000000000000000000000000000000000000000000000010202020202020201000000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020100000001010101010000000001020100010202020210022701000000000101010101010101010101010000000000000000010202060206020201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010202010101010102290201010000000110010001020201010101010100000000012b020201280202020206010101010101010101010202020202020201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102130202020210020602100100000001030100010202010000000000000000000102220201020202020202011002020202020210390202020202021001000000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010102020101010201010102010101010110010001020201010101010101010101010c0a1001020202020213031010020202021010031302020202100201000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020201000102010001020202100101020100010202020202020202020302023902100210060202020202391002020202020210010202020210022b01000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201000102010101020210020202100100010202020206290602023902020313020202020202020202010101010101010101010101390201010101000000000000010139020202390101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01022b0201000102020202020202100101010100010339020202020202020101010102020202020202020202010000000000000000000000010301000000000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000010201010101010101010100000101010101010101010101010000000000000000000000010201000000000000000000010101020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001952019530185301652013510115100e5100b520075200152000520123001430017300113001430016300193001b3000970009700097001500013000120001100011000100000e0000d0000c0000b000
000600001d0302304026020280102901025010220201d0301802015020130201201012010130101501016020180201b0301f030250202b0202d0102b0102901026020220201f0301a03017020150201402014010
1f020000076140c6140f61011610116101361013610166101661018610186101861018610186101661013610116100c6100761003615016151860016600166001360013600136000f6000d6000c6050a60007600
4801000003530075400c5300f5201352016520185201b5201d5201f5201f5101f5101d5101b510185101651013510115100f5100c510000000000000000000000000000000000000000000000000000000000000
4d0100001c420204201f4201b4201842017420194201b4201f4202342024420214201e4201a42015420184201c420234202642024420214201e420184201b4201e4202142023420224201f4201c4201942015420
01010000026240462006620086200a6200c620116201461019615266153a615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002b6202962027620226201d62018620136200c620076150361500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800002502520110242102431023425215101f7101d0101a1251921017310184101a72512710140101611013125122100f4100e7100d7250d0100e1100e21016025192101a5101871015025117100e7100c710
050200002161025610286102b6102d6102e6102d6102d6102c6102b610286102661023610206101d6101c6101a610196101761016615156151561500600006000060000600000000000000000000000000000000
4d0200001b6161d6161a616126161761617616146160f61610616126160e616076160461603616006160060600606006060060600606006060060600606006060060600606006060060600606006060060600606
09020000185111f5111d51129511315213a5213a50100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
15030000163201132015320193201d3202032023320263202a3250c3000b3000f30019300263002230025300283002c3002c30000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111800001d0240e0210e0241d0350e0241c0240e0240e0241d0240e0241c0240e0241d0240e0241d0241d0241d0240e0210e0241d0350e0241c0240e0240e0241d0240e0241c0240e0211d0221d0121d0221d012
011800000c0230c0230c0002b615306000c5000c0230c6000c0230c0000c0000c0232b6150c5000c0230c6000c0230c0230c0232b615306000c5000c0230c6002b615006000c023006002b6141f6150c0232b615
011800002b215242152421224212306000c5000c0230c6002b6152b2150c023242152b2150c5000c0230c6000c023272150c600272150c0232721227212272122b6152b2150c023006002b600242140c02324215
231800002b21524215242122421224200242002b2152b2002b2002b21524215242152b21500000272150000000000272150000027215272122721227212242002b2002b215242152420024200242142421524215
011800000c023130003060000600306000c5000c0230c6002b615006000c02300600006000c5000c0230c6000c0230c6000c6000c6000c0230c5000c023006002b615006000c023006002b6000c0000c02300000
011800000701000011030200001003010000100302007010030210001003010000100301000010030200001007010000210701000010030100001007010000100301000021070100001003020070100302000010
__music__
00 01020344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 3a3b4344
02 3a3b4344
02 78424344
00 41424344
00 7a794344
00 3f7e7d44
00 3f424344
01 3f3e4344
00 3f3e7d44
02 3f3e7c44

