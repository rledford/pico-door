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
-- [] add boss-door room in separate map area
-- [] add boss-door health to UI
-- [] add boss-door destroyed effects
-- [] spawn moose behind boss-door when destroyed
-- [] add stats (doors destroyed, enemies destroyed, ...)
-- [] add win screen and show stats
-- [] show stats on death and win screen


-- other --
-----------

-- when difficulty reach X then a message appears that the door is angry
-- and a red portal spawns to to port the player back to the main room (boss-door room).
-- the boss is the door with torches on either side that shoot random shtuff.
-- at interval or at specific door hp breakpoints, forcefields (special wall tiles)
-- spawn that, if the player purchased pierce will damage and pass through forcefield
-- also, there should be targetable hitboxes for the door so that the player can
-- shoot projectiles at an angle which will make "ricochet" useful if player purchased

-- boss room (looks same as main room) is in different map region and has all passages
-- blocked so player can not leave (and despawn everything)
-- merchant is dead (skeleton) but can speak (says "what'd you do?!?")

-- change floor and wall tiles (switch) and invert colors
-- moose is behind door and does a pee-wee herman scream

-- [x] add window
-- [x] make window interactive
-- [] tune enemy movement and damage
-- [] make enemy spawn points configurable or pull from different type pools based on conditions

-- ideas --
-----------

-- vendors and/or traveling vendors to sell pickukps
-- add a skeleton behind a desk who says "hello"
-- projectiles bounce off walls
-- using particle system instead of sprites
--   to rotate "blades around the saw"
--   different blades have different colors
-- different saw blades
-- puzzle: player has to bounce blade around a wall
--   the wall is solid except for one section that
--   is a forcefield tile that only a certain saw blad
--   can go through. the blade must be shot to bounce
--   destroy the forcefield controls

-- constants --
---------------

TILE_SIZE = 8
TILE_HALF_SIZE = TILE_SIZE/2
SCREEN_SIZE = 128
SCREEN_TILES = SCREEN_SIZE/TILE_SIZE
MAX_ROOM_OBJECTS = 50

NO_GROUP = 0
PLAYER_GROUP = 1
ENEMY_GROUP = 2
HURT_FLASH_PAL = {8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8}
BLOCK_TILE = 0
WALL_TILE = 1
FLOOR_TILE = 2
DOOR_TILE = 3
SPIKE_TILE = 4
ENEMY_SPAWN_TILE = 6
TRAP_TILE = 19
PORTAL_TILE = 21
VENDOR_TILE = 37
GEM_TILE = 28
HP_TILE = 27
CHEST_TILE = 14
CHECK_OPEN_TILE = 15
TORCH_TILE = 57

SATCHEL_TILE = 40
UPGRADE_DMG_TILE = 41
RICOCHET_TILE = 42
UPGRADE_HP_TILE = 43
FAST_SHOT_TILE = 44
PIERCE_TILE = 45
OVERLOAD_TILE = 22


-- globals --
-------------

room = {x=0,y=0}
overload_portal = nil
last_portal_used = {room={x=0,y=0},pos={0,0}}
camera_pos = {x=0,y=0}
camera_spd = 4
objects = {}
transition_objects = {}
types = {}
difficulty = 1.0

k_left = 0
k_right = 1
k_up = 2
k_down = 3
k_shoot = 4
k_action = 5
is_room_transition = false
debug=false
window = nil
vendor = nil

update_fn = function()
end

-- entry point --
-----------------

function _init()
	cls()
	player = init_object(player_type, 16, 40)
	start_room_transition(0,0)
	init_object(moose_type, 64,64)
	update_fn = game_update
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
	draw_particles()
	if window ~= nil then
		window.draw(window)
	end
	if debug then
		print("mem kb: "..stat(0),  camera_pos.x + 1, camera_pos.y + 1 + 8, 8)
		print("player x: "..player.x, camera_pos.x + 1, camera_pos.y + 1 + 16, 8)
		print("player y: "..player.y, camera_pos.x + 1, camera_pos.y + 1 + 24, 8)
		print("objects: "..count(objects), camera_pos.x + 1, camera_pos.y + 1 + 32, 8)
		print("transition objects: "..count(transition_objects), camera_pos.x + 1, camera_pos.y + 1 + 48, 8)
		if player.target ~= nil then
			local range = get_range(player, player.target)
			print("target rng: "..flr(range), camera_pos.x + 1, camera_pos.y + 1 + 40, 8)
			circ(player.x + 4, player.y + 4, range)
		else
			circ(player.x + 4, player.y + 4, player.auto_target_radius, 8)
		end
	end
	draw_ui()
	-- print(tostring(difficulty), 0,16,8)
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
end

-- player --
------------

player_type = {
	init=function(this)
		this.fire_rate = 20
		this.fire_timer = 0
		this.hitbox={x=2,y=2,w=3,h=4}
		this.target=nil
		this.auto_target_radius = 40
		this.projectil_damage = 1
		this.projectile_speed = 1.3
		this.has_ricochet = false
		this.has_pierce = false
		this.has_overload = false
		this.face = {x=1,y=0}
		this.max_hp = 10
		this.hp = this.max_hp
		this.group = PLAYER_GROUP
		this.anim = make_animation({32})
		this.hurt_collidable = false
		this.max_gems = 250
		this.gems = 0
		this.dead = false
	end,
	take_damage=function(this, amt)
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
		local dx = 0
		local dy = 0
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
			this.face.x = dx
			this.face.y = dy
			local mx = dx * TILE_SIZE + from.x
			local my = dy * TILE_SIZE + from.y
			if this.can_move_to(mx/TILE_SIZE, my/TILE_SIZE) then
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
			local proj = make_projectile(this.x, this.y, make_animation({30,31}, 4), this.projectil_damage, this.projectile_speed, dir)
			proj.ricochet = this.has_ricochet
			proj.pierce = this.has_pierce
			add(proj.collision_groups, ENEMY_GROUP)
		end
		this.fire_timer = clamp(this.fire_timer - 1, 0, this.fire_rate)
		foreach(objects, function(obj)
			if this.collides_with(obj) then
				if obj.touch_damage > 0 then
					this.type.take_damage(this, obj.touch_damage)
				elseif obj.on_pickup ~= nil then
					obj.on_pickup(this)
				-- elseif obj.type.on_activate ~= nil then
				-- 	obj.type.on_activate(obj)
				end
			end
		end)
	end
}

-- vendor --
------------

vendor_type = {
	init=function(this)
		this.inventory = {
			upgrade_max_gems,
			upgrade_max_hp,
			upgrade_projectile_damage,
			upgrade_fast_shot,
		}
		this.anim = make_animation({37,38}, 20)
	end,
	update=function(this)
		if window == nil and player ~= nil and not player.dead and btnp(k_action) and flr(get_range(this, player)) <= TILE_SIZE*2 then
			show_vendor_window(this)
		end
		this.anim.update()
	end,
}

upgrade_max_gems = {
	spr = SATCHEL_TILE,
	name = "satchel",
	description = "+50 to max gems.",
	cost = 50,
	persist = true,
	on_upgrade = function()
		player.max_gems += 50
		difficulty *= 1.05
	end
}

upgrade_max_hp = {
	spr = UPGRADE_HP_TILE,
	name = "hp",
	description = "+1 to max hp.",
	cost = 100,
	persist = true,
	on_upgrade = function()
		player.max_hp += 1
		player.hp = player.max_hp
		difficulty *= 1.05
	end
}

upgrade_fast_shot = {
	spr = FAST_SHOT_TILE,
	name = "fast-shot",
	description = "increase rate of fire.",
	cost = 500,
	persist = true,
	on_upgrade = function()
		player.fire_rate = clamp(player.fire_rate - 1, 8, 20)
		player.fire_timer = 0
		difficulty *= 1.1
		if player.fire_rate <= 8 then
			upgrade_fast_shot.persist = false
		end
	end
}

upgrade_projectile_ricochet = {
	spr = RICOCHET_TILE,
	name = "ricochet",
	description = "projectiles bounce.",
	cost = 500,
	persist = false,
	on_upgrade = function()
		player.has_ricochet = true
		difficulty *= 1.1
	end
}

upgrade_projectile_damage = {
	spr = UPGRADE_DMG_TILE,
	name = "damage",
	description = "+1 to projectile damage.",
	cost = 300,
	persist = true,
	on_upgrade = function()
		player.projectil_damage += 1
		difficulty *= 1.1
	end
}

upgrade_projectile_pierce = {
	spr = PIERCE_TILE,
	name = "pierce",
	description = "projectiles pierce.",
	cost = 1000,
	persist = false,
	on_upgrade = function()
		player.has_pierce = true
		difficulty *= 1.1
	end
}

upgrade_overload = {
	spr = OVERLOAD_TILE,
	name = "overload",
	description = "spawn portal on full gems.",
	cost = 750,
	persist = false,
	on_upgrade = function()
		player.has_overload = true
	end
}

function show_vendor_window(vendor_obj)
	sfx(8)
	local win = {
		selected_upgrade = 1,
		update = function(this)
			if btnp(k_action) then
				window = nil
				update_fn = game_update
				sfx(9)
				return
			elseif btnp(k_shoot) then
				local upgrade = vendor_obj.inventory[this.selected_upgrade]
				if player.gems - upgrade.cost < 0 then
					sfx(10)
					return
				end
				if not upgrade.persist then
					del(vendor_obj.inventory, upgrade)
					this.selected_upgrade = clamp(this.selected_upgrade, 1, count(vendor_obj.inventory))
				end
				sfx(11)
				player.gems -= upgrade.cost
				upgrade.on_upgrade()
			elseif btnp(k_left) then
				this.selected_upgrade = clamp(this.selected_upgrade-1, 1, count(vendor_obj.inventory))
			elseif btnp(k_right) then
				this.selected_upgrade = clamp(this.selected_upgrade+1, 1, count(vendor_obj.inventory))
			end
		end,
		draw = function(this)
			local window_rect = {left=camera_pos.x + 8, top=camera_pos.y+40, right=camera_pos.x + 119, bottom=camera_pos.y + 91}
			local pad = 4
			local gems_text = tostring(player.gems).."/"..tostring(player.max_gems)
			local hp_text = tostring(player.hp).."/"..tostring(player.max_hp)
			rectfill(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 13)
			rect(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 2)
			print("lunkik", window_rect.left + pad, window_rect.top + pad/2, 2)
			spr(HP_TILE, window_rect.right - text_w_px(hp_text) - TILE_SIZE - 2, window_rect.top)
			print(hp_text, window_rect.right - text_w_px(hp_text) - pad/2, window_rect.top + pad/2, 2)
			spr(GEM_TILE, window_rect.right - text_w_px(gems_text) - TILE_SIZE - 1, window_rect.top + 6)
			print(gems_text, window_rect.right - text_w_px(gems_text) - pad/2, window_rect.top + pad/2 + 6, 11)
			local itemx
			for i=0,count(vendor_obj.inventory)-1 do
				itemx = window_rect.left + 32 + TILE_SIZE * i + pad + (pad * i)
				itemy = window_rect.top + pad*2 + TILE_SIZE
				rectfill(itemx-1, itemy-1, itemx + TILE_SIZE, itemy + TILE_SIZE, 0)
				spr(vendor_obj.inventory[i+1].spr, itemx, itemy)
				if i+1 == this.selected_upgrade then
					rect(itemx-2, itemy-2, itemx + TILE_SIZE + 1, itemy + TILE_SIZE + 1, 2)
				end
			end
			local details_left = window_rect.left + pad
			local details_top = window_rect.top + 29
			local details_line_h = 8

			print(vendor_obj.inventory[this.selected_upgrade].name, details_left, details_top, 7)
			print(vendor_obj.inventory[this.selected_upgrade].description, details_left, details_top + details_line_h)
			spr(GEM_TILE, details_left - 2, details_top + details_line_h * 2 - 2)
			print(vendor_obj.inventory[this.selected_upgrade].cost, details_left + 5,  details_top  + details_line_h * 2, 11)
		end
	}
	window = win
	update_fn = function()
		vendor_obj.type.update(vendor_obj)
		window.update(window)
	end
end

-- pickups --
-------------

pickup_type = {
	init=function(this)
		this.spr = 0
		this.pickup_range = 0
		this.can_expire = true
		this.expiration_time = 500
		this.expiration_timer = this.expiration_time
	end,
	update=function(this)
		if this.can_expire then
			this.expiration_timer -= 1
			this.anim.frame_time = this.expiration_timer/this.expiration_time <= 0.25 and 4 or this.anim.frame_time
		end
		if player.dead or this.expiration_timer <= 0 then
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

function make_pickup(x, y, anim, pickup_range)
	local pickup = init_object(pickup_type, x, y)
	pickup.pickup_range = pickup_range or 0
	pickup.anim = anim
	return pickup
end

function make_gems_pickup(x, y, amount)
	local pickup = make_pickup(x, y, make_animation({28,29}, 10), 18)
	local on_pickup = function(player)
		player.gems = clamp(player.gems + amount, 0, player.max_gems)
		destroy_object(pickup)
		if player.gems == player.max_gems and player.has_overload and overload_portal == nil then
			local pos = get_open_pos_next_to(flr(player.x / TILE_SIZE) * TILE_SIZE, flr(player.y / TILE_SIZE) * TILE_SIZE)
			overload_portal = init_object(portal_type, pos.x, pos.y)
		end
	end
	pickup.hitbox={x=2,y=2,w=3,h=3}
	pickup.on_pickup = on_pickup
	return pickup
end

function make_hp_pickup(x, y, amount)
	local pickup = make_pickup(x, y, make_animation({26,27}, 16), 10)
	local on_pickup = function(player)
		player.hp = clamp(player.hp + amount, player.hp, player.max_hp)
		destroy_object(pickup)
	end
	pickup.hitbox={x=2,y=2,w=3,h=3}
	pickup.on_pickup = on_pickup
	return pickup
end

function make_upgrade_pickup(x, y, type)
	local pickup = make_pickup(x, y, make_animation({type.spr}), 0)
	local on_pickup = function()
		type.on_upgrade()
		sfx(11)
		destroy_object(pickup)
	end
	pickup.spr = type.spr
	pickup.can_expire = false
	pickup.hitbox={x=2,y=2,w=3,h=3}
	pickup.on_pickup = on_pickup
	return pickup
end

-- projectiles --
-----------------

projectile_type = {
	init=function(this)
		this.targetable = false
		this.target = nil -- could implement homing
		this.hitbox = {x=3,y=3,w=2,h=2}
		this.threat = -1
		this.spd = 0
		this.direction = {x=0, y=0}
		this.lifetime = 120
		this.collision_groups = {}
		this.damage = 1
		this.ricochet = false
		this.pierce = false
		this.hit_list = {}
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
			if not this.pierce then
				destroy_object(this)
			end
			return
		end
		if not this.can_move_to((nextx + TILE_HALF_SIZE)/TILE_SIZE, (nexty + TILE_HALF_SIZE)/TILE_SIZE) then
			if this.ricochet then
				this.hit_list = {}
				-- cheap bounce calc without normals since all walls are axis-aligned
				if not this.can_move_to((this.x + TILE_HALF_SIZE)/TILE_SIZE, (nexty + TILE_HALF_SIZE)/TILE_SIZE) then
					-- hit top or bottom of wall so reverse y
					this.direction.y *= -1
				elseif not this.can_move_to((nextx + TILE_HALF_SIZE)/TILE_SIZE, (this.y + TILE_HALF_SIZE)/TILE_SIZE) then
					-- hit left or right of wall so reverse x
					this.direction.x *= -1
				end
				-- skip setting position to nextx,nexty to prevent drilling through corners
				return
			else
				destroy_object(this)
			end
		end
		this.x = nextx
		this.y = nexty
	end
}

function make_projectile(x, y, anim, damage, spd, direction)
	local proj = init_object(projectile_type, x, y)
	proj.anim = anim
	proj.damage = damage
	proj.spd = spd
	proj.direction = direction
	return proj
end

-- enemies --
-------------

chest_type = {
	init=function(this)
		this.group = ENEMY_GROUP
		this.hp = 25
		this.anim = make_animation({CHEST_TILE})
	end,
	take_damage=function(this, amount)
		this.hp -= amount
		start_hurt_object(this)
		if this.hp <= 0 then
			--play destroy sound
			mset(this.x/TILE_SIZE,this.y/TILE_SIZE, FLOOR_TILE)
			make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame])
			destroy_object(this)
		else
			-- play hit sound
		end
	end,
	update=function(this)
	end,
}

moose_type = {
	init=function(this)
		this.anim = make_animation({35,36}, 8)
	end,
	update=function(this)
		this.anim.update() 
	end
}

eye_type = {
	init=function(this)
		this.fire_rate=90
		this.fire_timer=0
		this.hitbox={x=2,y=3,w=4,h=5}
		this.target=nil
		this.auto_target_radius=40
		this.threat = 1
		this.group = ENEMY_GROUP
		this.hp = flr(1.5 * difficulty)
		this.move_rate=30
		this.move_timer=0
		this.anim = make_animation({48,49}, 16)
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
			local proj = make_projectile(this.x, this.y, make_animation({46,47}, 8), 1, 0.5, dir)
			sfx(3)
			add(proj.collision_groups, PLAYER_GROUP)
		end
		this.anim.update()
	end
}

bug_type = {
	init=function(this)
		this.hitbox={x=1,y=2,w=6,h=5}
		this.target=nil
		this.auto_target_radius=40
		this.anim = make_animation({50,51}, 25)
		this.threat = 1
		this.group = ENEMY_GROUP
		this.hp = flr(3 * difficulty)
		this.move_rate=15
		this.move_timer=0
		this.touch_damage = 2
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
		this.hitbox={x=1,y=2,w=6,h=5}
		this.target=nil
		this.auto_target_radius=40
		this.anim = make_animation({53,54}, 40)
		this.threat = 1
		this.group = ENEMY_GROUP
		this.hp = flr(2 * difficulty)
		this.move_rate=5
		this.move_timer=0
		this.touch_damage = 2
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
		this.fire_rate=45
		this.fire_timer=0
		this.hitbox={x=1,y=2,w=6,h=5}
		this.target=nil
		this.auto_target_radius=40
		this.anim = make_animation({55,56}, 30)
		this.threat = 1
		this.group = ENEMY_GROUP
		this.hp = flr(4 * difficulty)
		this.move_rate=5
		this.move_timer=0
		this.touch_damage = 1
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
			local proj = make_projectile(this.x, this.y, make_animation({60,61}, 8), 2, 0.75, dir)
			sfx(3)
			add(proj.collision_groups, PLAYER_GROUP)
		end
		this.anim.update()
	end
}

door_type = {
	init=function(this)
		this.group = ENEMY_GROUP
		this.hp = 15
		this.anim = make_animation({3})
	end,
	take_damage=function(this, amount)
		this.hp -= amount
		start_hurt_object(this)
		if this.hp <= 0 then
			--play destroy sound
			mset(this.x/TILE_SIZE,this.y/TILE_SIZE, FLOOR_TILE)
			make_particle_group(this.x, this.y, this.anim.frames[this.anim.current_frame])
			destroy_object(this)
		else
			-- play hit sound
		end
	end,
	update=function(this)
	end,
}

trap_type = {
	init=function(this)
		this.inactive_anim = make_animation({19})
		this.active_anim = make_animation({20})
		this.anim = this.inactive_anim
		this.reset_time = 300
		this.reset_timer = 0
		this.targetable = false
		this.active = false
		this.collidable = true
		this.projectil_damage = 1
		this.projectile_speed = 1
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
		local col = flr(this.x / TILE_SIZE)
		local row = flr(this.y / TILE_SIZE)
		local walls = {top=false,right=false,bottom=false,left=false}
		local mincol = flr((room.x * SCREEN_SIZE) / TILE_SIZE)
		local maxcol = flr((room.x * SCREEN_SIZE + SCREEN_SIZE - 1) / TILE_SIZE)
		local minrow = flr((room.y * SCREEN_SIZE) / TILE_SIZE)
		local maxrow = flr((room.y * SCREEN_SIZE + SCREEN_SIZE - 1) / TILE_SIZE)
		local projectiles = {}
		-- yes this for-loop is terrible
		for offset=0,15 do
			if col - offset >= mincol and not walls.left then
				if mget(col - offset, row) == 1 then
					walls.left = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile((col - offset) * TILE_SIZE + TILE_HALF_SIZE, this.y, make_animation({52}), this.projectil_damage, this.projectile_speed, {x=1,y=0})
						)
					end
				end
			end
			if col + offset <= maxcol and not walls.right then
				if mget(col + offset, row) == 1 then
					walls.right = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile((col + offset) * TILE_SIZE - TILE_HALF_SIZE, this.y, make_animation({52}), this.projectil_damage, this.projectile_speed, {x=-1,y=0})
						)
					end
				end
			end
			if row - offset >= minrow and not walls.top then
				if mget(col, row - offset) == 1 then
					walls.top = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile(this.x, (row - offset) * TILE_SIZE + TILE_HALF_SIZE, make_animation({52}), this.projectil_damage, this.projectile_speed, {x=0,y=1})
						)
					end
				end
			end
			if row + offset <= maxrow and not walls.bottom then
				if mget(col, row + offset) == 1 then
					walls.bottom = true
					if offset > 3 then
						add(
							projectiles,
							make_projectile(this.x, (row + offset) * TILE_SIZE - TILE_HALF_SIZE, make_animation({52}), this.projectil_damage, this.projectile_speed, {x=0,y=-1})
						)
					end
				end
			end
		end
		foreach(projectiles, function(proj)
			add(proj.collision_groups, PLAYER_GROUP)
			add(proj.collision_groups, ENEMY_GROUP)
		end)
	end
}

spike_type = {
	init=function(this)
		this.hitbox = {x=1,y=1,w=6,h=6}
		this.frames = {16,17,18}
		this.frame_times = {5,5,100}
		this.current_frame = 1
		this.frame_time = 0
		this.frame_step = 1
		this.reset_time = 100
		this.reset_timer = 0
		this.touch_damage = 0
		this.targetable = false
		this.collidable = true
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
				sfx(6)
			elseif this.current_frame == 1 then
				if this.frame_step == -1 then
					this.frame_step = 1
					this.reset_timer = this.reset_time
					return
				else
					sfx(5)
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
		this.hitbox={x=1,y=2,w=6,h=5}
		this.targetable = false
		this.collidable = false
		this.target=nil
		this.anim = make_animation({57,58}, 6)
		this.threat = 1
	end,
	update=function(this)
		this.anim.update() 
	end
}


-- portal --
------------

portal_type = {
	init=function(this)
		this.frames = {21,22,23,24}
		this.frame_times = {15,15,15,15}
		this.current_frame = 1
		this.frame_time = 0
		this.frame_step = 1
		this.on_activate = function()
			start_portal_transition(this)
		end
	end,
	update=function(this)
		if player ~= nil and not player.dead and btnp(k_action) and player.x == this.x and player.y == this.y then
			this.on_activate()
		end
		this.frame_time += 1
		if this.frame_time >= this.frame_times[this.current_frame] then
			this.frame_time = 0
			if this.current_frame == count(this.frames) then
				this.frame_step = -1
			elseif this.current_frame == 1 and this.frame_step == -1 then
				this.frame_step = 1
				this.frame_time = 0
				return
			end
			this.current_frame += this.frame_step
		end
	end,
	draw=function(this)
		spr(this.frames[this.current_frame], this.x, this.y, 1, 1, this.frame_step == -1)
	end
}

-- enemy spawn point --
-----------------------

enemy_spawn_point_type = {
	init=function(this)
		this.enemy_types = {}
		this.spawn_time = 0
		this.spawn_timer = 0
		this.spawn_duration = 60
		this.spawn_duration_timer = 0
		this.anim = make_animation({6})
		this.spawn_anim = make_animation({7,8}, 8)
		this.is_spawning = false
	end,
	update=function(this)
		if not this.is_spawning then
			this.spawn_timer -= 1
			if this.spawn_timer <= 0 and count(objects) < MAX_ROOM_OBJECTS then
				this.is_spawning = true
				this.spawn_timer = this.spawn_time
				this.spawn_duration_timer = this.spawn_duration
			end
		end
		if this.is_spawning then
			this.spawn_duration_timer -= 1
			if this.spawn_duration_timer <= 0 then
				this.is_spawning = false
				local e = init_object(rnd(this.enemy_types), this.x, this.y)
				plan_next_move(e)
				sfx(2)
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
	local spawn_time = flr(1/difficulty * 100)
	sp = init_object(enemy_spawn_point_type, x, y)
	sp.spawn_time = spawn_time
	sp.spawn_timer = spawn_time
	if difficulty <= 1.1 then
		sp.enemy_types = {eye_type, bug_type}
	elseif difficulty <= 1.5 then
		sp.enemy_types = {eye_type, bug_type, fang_type}
	else
		sp.enemy_types = {eye_type, bug_type, fang_type, skull_type}
	end
	init_object(rnd(sp.enemy_types), x, y)
	return sp
end

-- object functions --
----------------------

function init_object(type,x,y)
	local obj = {}
	obj.type = type
	obj.collidable = true
	obj.targetable = true
	obj.flip = {x=false,y=false}
	obj.x = x
	obj.y = y
	obj.hitbox = {x=0,y=0,w=TILE_SIZE,h=TILE_SIZE}
	obj.spd = 1
	obj.moves = {}
	obj.threat = 0
	obj.group = NO_GROUP
	obj.hp = 1
	obj.msg = "none"
	obj.anim = nil
	obj.is_hurt = false
	obj.hurt_duration = 30
	obj.hurt_duration_timer = 0
	obj.hurt_collidable = true
	obj.touch_damage = 0
	obj.ricochet = false

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

	obj.move_to = function(x,y)
		add(obj.moves, {x=x, y=y})
	end

	obj.take_damage = function(amount)
		if obj.type.take_damage ~= nil then
			obj.type.take_damage(obj, amount)
		else
			obj.hp -= amount
			if obj.hp <= 0 then
				if obj.anim ~= nil then
					make_particle_group(obj.x,obj.y, obj.anim.frames[obj.anim.current_frame])
				else
					make_particle_group(obj.x, obj.y)
				end
				destroy_object(obj)
				-- instead check if obj has on_destroy
				-- which should handle spawning pickups
				if obj.type ~= player_type then
					if rnd(1000) > 900 then
						make_hp_pickup(obj.x,obj.y,flr((rnd(3) + 1)) * difficulty)
					elseif rnd(1000) > 100 then
						make_gems_pickup(obj.x,obj.y,flr((rnd(5) + 3) * difficulty))
					end
					sfx(4)
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
		local group = group or NO_GROUP
		local other = nil
		local range = 0
		local target = {obj = nil, range = 0}
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
	obj.is_hurt = true
	obj.hurt_duration_timer = obj.hurt_duration
	obj.collidable = obj.hurt_collidable
end

function update_hurt_object(obj)
	obj.hurt_duration_timer -= 1
	if obj.hurt_duration_timer <= 0 then
		obj.is_hurt = false
		obj.collidable = true
	end
end

function add_random_move(obj)
	if count(obj.moves) ~= 0 then
		return
	end
	local possible_moves = {}
	local mx = 0
	local my = 0
	for dx=-1,1 do
		for dy=-1,1 do
			if (dx == 0 and dy ~= 0) or (dy == 0 and dx ~= 0) then
				mx = dx * TILE_SIZE + obj.x
				my = dy * TILE_SIZE + obj.y
				if obj.can_move_to(mx/TILE_SIZE,my/TILE_SIZE) and not is_move_to_next_room(mx,my) then
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
	if player == nil or count(obj.moves) > 0 then
		return
	end
	local range = get_range(obj, player)
	if player.dead or range > obj.auto_target_radius then
		add_random_move(obj)
		return
	-- elseif range <= TILE_SIZE * 1.5 then
	-- 	return
	end
	local m = get_manhattan(obj, player)
	if (m.x == 0 and m.y == 0) then
		return
	end
	local dx = sign(m.x)
	local dy = sign(m.y)
	if dx ~= 0 and dy ~= 0 then
		if rnd() > 0.5 then
			dx = 0
		else
			dy = 0
		end
	end
	local mx = dx * TILE_SIZE + obj.x
	local my = dy * TILE_SIZE + obj.y
	if (obj.can_move_to(mx/TILE_SIZE, my/TILE_SIZE)) then
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
			local col = flr(sprite % 16)
			local row = flr(sprite / 16)
			local p
			for px=0,7 do
				for py=0,7 do
					p = pgroup.particles[px * 8 + py + 1]
					p.x = x + px
					p.y = y + py
					p.spd = 0.4
					p.dir.x = rnd() * (rnd() >= 0.5 and -1 or 1)
					p.dir.y = rnd() * (rnd() >= 0.5 and -1 or 1)
					p.color = sget(col * TILE_SIZE + px, row * TILE_SIZE + py)
				end
			end
		else
			local r = 6
			local theta = 1
			foreach(pgroup.particles, function(p)
				theta = rnd() * 2 * 3.14
				p.x = x + r * cos(theta)
				p.y = y + r * sin(theta)
				p.spd = 0.5
				p.dir.x = rnd() > 0.5 and -rnd() or rnd()
				p.dir.y = rnd() > 0.5 and -rnd() or rnd()
				p.color = 8
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
	if debug then
		rect(obj.x+obj.hitbox.x,obj.y+obj.hitbox.y,obj.x+obj.hitbox.x+obj.hitbox.w-1,obj.y+obj.hitbox.y+obj.hitbox.h-1,8)
	end
	-- if obj.hp and obj ~= player then
	-- 	print(tostring(obj.hp), obj.x, obj.y, 8)
	-- end
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
	draw_gems_bar()
end

function draw_hp_bar()
	local pad = 1
	local w = 31
	local h = 2
	rectfill(camera_pos.x + pad, camera_pos.y + pad, camera_pos.x + w + pad, camera_pos.y + h + pad, 0)
	rectfill(camera_pos.x + pad, camera_pos.y + pad, camera_pos.x + pad + flr(player.hp/player.max_hp*w), camera_pos.y + h + pad, 8)
	if player.is_hurt and (player.hurt_duration_timer%4 == 0) then
		pal(HURT_FLASH_PAL)
	end
	rect(camera_pos.x + pad, camera_pos.y + pad, camera_pos.x + w + pad, camera_pos.y + h + pad, 7)
	pal()
end

function draw_gems_bar()
	local yoffset = 3
	local pad = 1
	local w = 31
	local h = 2
	rectfill(camera_pos.x + pad, camera_pos.y + pad + yoffset, camera_pos.x + w + pad, camera_pos.y + h + pad + yoffset, 0)
	rectfill(camera_pos.x + pad, camera_pos.y + pad + yoffset, camera_pos.x + pad + flr(player.gems/player.max_gems*w), camera_pos.y + h + pad + yoffset, 11)
	rect(camera_pos.x + pad, camera_pos.y + pad + yoffset, camera_pos.x + w + pad, camera_pos.y + h + pad + yoffset, 7)
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

	
	is_room_transition = true
	room.x = x_index
	room.y = y_index
	update_fn = update_room_transition

	local tile_type
	local tx = 0
	local ty = 0
	for c=x_index*SCREEN_TILES,x_index*SCREEN_TILES+SCREEN_TILES-1 do
		for r=y_index*SCREEN_TILES,y_index*SCREEN_TILES+SCREEN_TILES-1 do
			tx = c*TILE_SIZE
			ty = r*TILE_SIZE
			tile_type = mget(c,r)
			if tile_type == DOOR_TILE then
				init_object(door_type, tx, ty)
			elseif tile_type == ENEMY_SPAWN_TILE then
				make_enemy_spawn_point(tx,ty)
			elseif tile_type == SPIKE_TILE then
				init_object(spike_type, tx, ty)
			elseif tile_type == TORCH_TILE then
				mset(c, r, WALL_TILE)
				init_object(torch_type, tx, ty)
			elseif tile_type == TRAP_TILE then
				init_object(trap_type, tx, ty)
			-- elseif tile_type == PORTAL_TILE then
			-- 	mset(c, r, FLOOR_TILE)
			-- 	init_object(portal_type, tx, ty)
			elseif tile_type == VENDOR_TILE then
				mset(c, r, FLOOR_TILE)
				if vendor == nil then
					vendor = init_object(vendor_type, tx, ty)
				else
					add(objects, vendor)
				end
			elseif tile_type == UPGRADE_HP_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_max_hp)
				init_object(chest_type, tx, ty)
			elseif tile_type == UPGRADE_DMG_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_projectile_damage)
				init_object(chest_type, tx, ty)
			elseif tile_type == RICOCHET_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_projectile_ricochet)
				init_object(chest_type, tx, ty)
			elseif tile_type == PIERCE_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_projectile_pierce)
				init_object(chest_type, tx, ty)
			elseif tile_type == SATCHEL_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_max_gems)
				init_object(chest_type, tx, ty)
			elseif tile_type == FAST_SHOT_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_fast_shot)
				init_object(chest_type, tx, ty)
			elseif tile_type == OVERLOAD_TILE then
				mset(c, r, BLOCK_TILE)
				make_upgrade_pickup(tx, ty, upgrade_overload)
				init_object(chest_type, tx, ty)
			end
		end
	end
end

function update_room_transition()
	player.move()
	local diffx = room.x * SCREEN_SIZE - camera_pos.x
	local diffy = room.y * SCREEN_SIZE - camera_pos.y

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
	local transition_obj
	for i=count(transition_objects),1,-1 do
		transition_obj = transition_objects[i]
		del(transition_objects, transition_obj)
		if transition_obj.type == door_type then
			mset(transition_obj.x/TILE_SIZE,transition_obj.y/TILE_SIZE,DOOR_TILE)
		elseif transition_obj.type == torch_type then
			mset(transition_obj.x/TILE_SIZE,transition_obj.y/TILE_SIZE,TORCH_TILE)
		-- elseif transition_obj.type == portal_type then
		-- 	mset(transition_obj.x/TILE_SIZE,transition_obj.y/TILE_SIZE,PORTAL_TILE)
		elseif transition_obj.type == vendor_type then
			mset(transition_obj.x/TILE_SIZE,transition_obj.y/TILE_SIZE,VENDOR_TILE)
		elseif transition_obj.type == pickup_type and transition_obj.spr > 0 then
			mset(transition_obj.x/TILE_SIZE,transition_obj.y/TILE_SIZE,transition_obj.spr)
		end
	end
end

function start_portal_transition(portal)
	if room.x == 0 and room.y == 0 then
		-- leaving main room
		local open_pos = get_open_pos_next_to(last_portal_used.pos.x, last_portal_used.pos.y)
		room.x = last_portal_used.room.x
		room.y = last_portal_used.room.y
		camera_pos.x = last_portal_used.room.x * 128
		camera_pos.y = last_portal_used.room.y * 128
		player.x = open_pos.x
		player.y = open_pos.y
		player.moves = {}
		destroy_object(portal)
		if overload_portal ~= nil then
			destroy_object(overload_portal)
			overload_portal = nil
		end
		start_room_transition(room.x, room.y)
	else
		-- entering main room
		last_portal_used.room.x = room.x
		last_portal_used.room.y = room.y
		last_portal_used.pos.x = portal.x
		last_portal_used.pos.y = portal.y
		room.x = 0
		room.y = 0
		camera_pos.x = 0
		camera_pos.y = 0
		player.x = 64
		player.y = 64
		player.moves = {}
		start_room_transition(room.x, room.y)
		init_object(portal_type, 56, 64)
	end
	camera(camera_pos.x, camera_pos.y)
	end_room_transition()
end

function update_portal_transition()
	end_portal_transition()
end

function end_portal_transition()
	end_room_transition()
end

-- death --
-----------

death_window_delay = 120
death_window_delay_timer = 0
start_death_transition = function()
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
		local window_rect = {left=camera_pos.x + 8, top=camera_pos.y+40, right=camera_pos.x + 119, bottom=camera_pos.y + 91}
		local pad = 4
		rectfill(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 0)
		rect(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 8)
		spr(11, window_rect.left + 27, window_rect.top + pad - 2)
		print("you doid", window_rect.left + 40, window_rect.top + pad)
		spr(11, window_rect.left + 76, window_rect.top + pad - 2, 1, 1, true)
		print("press x to restart", window_rect.left + 21, window_rect.bottom - pad * 2, 7)
	end
}

-- utils --
-----------

function text_w_px(text)
	return #text * 4 - 1
end

function get_open_pos_next_to(x, y)
	local c = flr(x/TILE_SIZE)
	local r = flr(y/TILE_SIZE)
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
	return x > room.x * SCREEN_SIZE + SCREEN_SIZE - 1 or
		x < room.x * SCREEN_SIZE or
		y > room.y * SCREEN_SIZE + SCREEN_SIZE - 1 or
		y < room.y * SCREEN_SIZE
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
	local dx = dest.x - pos.x
	local dy = dest.y - pos.y
	local norm = sqrt(dx^2 + dy^2)
	return {x=dx/norm, y=dy/norm}
end

function get_manhattan(pos,dest)
	return {x=flr(dest.x-pos.x),y=flr(dest.y-pos.y)}
end
__gfx__
00000000555005556777777644c44c4467777776aa5555aa67766776090000900900009000220220008808800085880000858800880000886777777669a99a96
000000005050050576777767cc4444cc76777767a9a55a9a76555567909090099909909902882882082282280858858008588580800000087444444774944947
0070070055000055776776774c4cc4c4755575555a5aa5a5755665570000009009000000028888820822222805787780056866800000000049a99a9445555554
00077000000000007776677744cccc447776677755aaaa5565677656090900000000909002888882082222280568765005786750000000004494494445555554
00077000000000007776677744cccc447776677755aaaa55656776560000909009090000002888200082228008777750086666500000000049a99a9449a99a94
0070070055000055776776774c4cc4c4776776775a5aa5a5755665570900000000000090000282000008280005877850058668500000000049a99a9449a99a94
000000005050050576777767cc4444cc76777767a9a55a9a765555679009090999909099000020000000800005858580058585808000000849a99a9449a99a94
00000000555005556777777644c44c4455575556aa5555aa67766776090000900900009000000000000000000855858008558580880000884444444444444444
000000000000000005000500677667766776677600cccc0000cccc0000cccc0000cccc0000000000000000000000000000000000000000000000000000000000
0000000005000500055005507ffffff7767777670c0cccc00c00ccc00c000cc00c0000c0000000000000000000000000000000000000000000cc0000000cc000
0555055505550555055505557f6ff6f77ffffff7c00cccccc00cccccc00000ccc000000c00000000000808000002020000033000000bb00000c1ccc000cc1c00
000000000000000000000000677667766f7ff7f6c0ccccccc00cccccc00000ccc000000c000000000082828000282820003bb30000b33b0000c111c00c111cc0
000000000000000000000000677667766f7ff7f6c0ccccccc00cccccc00000ccc000000c000000000082228000288820003bb30000b33b000c111c000cc111c0
0000000000000000500050007f6ff6f77ffffff7c00cccccc00cccccc00000ccc000000c00000000000828000002820000033000000bb0000ccc1c0000c1cc00
0000000050005000550055007ffffff7767777670c0cccc00c00ccc00c000cc00c0000c000000000000080000000200000000000000000000000cc00000cc000
555055505550555055505550677667766776677600cccc0000cccc0000cccc0000cccc0000000000000000000000000000000000000000000000000000000000
003330000000000000000000f000000ff000000f000220000002200044444444004444000ccc000000777000022002200c7c0000055775500000000000000000
005350000000000000000000f000000ff000000f002112000021120044444444040000400711cccc0077770c278228820c77cccc555555550099990000aaaa00
0018100000000000000000000f0000f00f0000f00028e200002e820044444444040330407771111c0770777c777888827777711c55555555099aa9900aa99aa0
0353530000000000000000000044440000444400025115200251152066666666403bb3040711711c077007cc278878820c77171c5555555509a99a900a9aa9a0
0335330000000000000000000454450000544540021b31200213b12099499949943bb344c11777c07700cccc28877782c17117705507705509a99a900a9aa9a0
08535800000000000000000000411440044114000213b120021b31204444444444444444c11171c07700000002887820c11777775cc77cc5099aa9900aa99aa0
0030300000000000000000000444440000444440020dd020020dd0204444444444944944cccc11c07000000000288200cccc177055cccc550099990000aaaa00
0030300000000000000000000000044004400000020dd020020dd02094999499044444400000ccc070000000000220000000c7c0055cc5500000000000000000
00003000000000000111111001111110000000000009900000999900000000000e2ee2e090000000000000090000000000000000000000000000000000000000
000330000000300011111111011111100008888809299290009229000e2ee2e0022ee220000a00000090a0000000000000999a00009aaa0000ee920000e22200
00333300000330001211112111111111008999980299992009722790022ee220022ee2200009990000a99900000000000a9aa9900aa99a9002e22ee0029ee9e0
033bb33000333300122112211111111108aa9aa89299992992722729022ee2202ee22ee20059a5099059a5000000000009a9aa900a99a9a00929a2e002ea9e20
03b33b30033bb33012e11e211211112189a99a9899999999922222292ee22ee2029a9a2000555500005555000000000009aa9a900a9a99a00e2a929002e9ae20
03b37b3033b33b3312e11e2112e11e2108aaa988997227999722227902eeee200ea9a9e0000440000004400000000000099aa9a009a99aa00ee22e200e9ee920
033bb33033b37b33111111111111111100888800097997900972279002eeee2002eeee2000044000000440000000000000a9990000aaa9000029ee0000222e00
00333300033bb3300111111001111110000000000099990000999900002ee200002ee20000000000000000000000000000000000000000000000000000000000
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
0101000300010000000000000000010000000000000000000000000000000000000000000000000100000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010505050501010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020202010505050505050102020201010202020202020202020201022b0201010202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102250201050505050505010216020101020202020202020202020102020201010104020402010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0127272701050505050505010202020101020201020202020202020102020202020302040202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020239050505050505390202020101020601020202020202020102020201010104020402010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020102020201010202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020102020201010202020202010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010202020202020202020202020202010102020202020202020202010202020101020206020202022b010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020202020202020206020202020102060201010202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020102020201010202020202020202010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020102020201010202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020102020201010202020202020202020204020401010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020601020202020202020302020201010202060202020206020202040203020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020201020202020202020102020201010202020202020202020204020401010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020102020201010202020202020202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102010101010101010101010101010101010102010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102010101010101010101010101010101010102010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020103010202020202020101020202020202020103010202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020402040202020202020101020202020202020213020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020204020202020202020101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106020202020202020202020202060101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020101010101010101010101010101130202020602020202020201020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020402040202060202020402040101030102020202020202020201060202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102040204020402020202040204020202020102020202020202020201020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020402040202020202020402040101010102020602020202020203020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001952019550185301653013510115100e5100b520075200152000520123001430017300113001430016300193001b3000970009700097001500013000120001100011000100000e0000d0000c0000b000
000600001d0702307026070280702907025070220701d0701807015070130701207012070130701507016070180701b0701f070250702b0702d0702b0702907026070220701f0701a07017070150701407014070
000200001262013630146401565016650176501865018650196501a6501a6501b6501b6501c6501d6501d6501d6501d6501d6501c6501b6501a65019640186401763016630156301462013620136101260012600
0001000003550065500a5500f5501455017550195501b5501d5501e5501f5501f5501f5501e5501d5501c55019550165501255010550000000000000000000000000000000000000000000000000000000000000
000100001c650206501f6501b6501865017650196501b6501f6502365024650216501e6501a65015650186501c650236502665024650216501e650186501b6501e6502165023650226501f6501c6501965015650
00010000026500465006650086500a6500c650116501465019650266503a650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002e6502c65028650246501e65019650146500c650036500265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800002505020150242502435023450215501f7501d0501a1501925017350184501a75012750140501615013250123500f4500e7500d7500d0500e1500e25016350194501a5501875015050117500e7500c750
000f0000060500a050100501105011050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000e0500c0500a0500605003050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000a3500a3500a350190000a3500a3500a35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000163501135015350193501d3502035023350263502a3500c3000b3000f30019300263002230025300283002c3002c30000000000000000000000000000000000000000000000000000000000000000000
