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
-- [] add projectiles use palette
-- [] add doors require matching color palette to destroy (room x + y <= palette?)
-- [] add portals to port back to main room (and back to room ported from)
-- [] add wall projectile traps activated by floor tiles (hits player and enemies)
-- [] add health pickup
-- [] enemies have low chance to drop health pickup
-- [] make pickups have random position within area of the enemy sprite
-- [] add levelup
-- [] add when player levleup all existing enemies get destroyed
-- [] add UI elements for player info
-- [] add main door with minimum damage requirement to take damage
-- [] add main door health to UI
-- [] add main door destroyed effects
-- [] add win screen and show stats
-- [] add stats (doors destroyed, enemies destroyed, ...)
-- [] show stats on death and win screen


-- other --
-----------

-- [x] add window
-- [x] make window interactive
-- [] show window on levelup
-- [] add upgrade choices to levelup window
-- [] apply selected upgrade to player and close levelup window
-- [] persist which chests have been destroyed
-- [] make destroyed chests not respawn when reentering room
-- [] tune enemy movement and damage
-- [] make enemy spawn points configurable or pull from different type pools based on conditions

-- ideas --
-----------

-- make enemies drop gold
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
FLOOR_TILE = 2
DOOR_TILE = 3
SPIKE_TILE = 4
ENEMY_SPAWN_TILE = 6
TRAP_TILE = 19

-- globals --
-------------

room = {x=0,y=0}
camera_pos = {x=0,y=0}
camera_spd = 4
objects = {}
transition_objects = {}
types = {}

k_left = 0
k_right = 1
k_up = 2
k_down = 3
k_shoot = 4
k_action = 5
is_room_transition = false
debug=false
window = nil

update_fn = function()
end

-- entry point --
-----------------

function _init()
	cls()
	player = init_object(player_type, 64, 64)
	end_room_transition(0,0)
	update_fn = game_update
end

function _update60()
	update_fn()
	if btnp(k_action) then
		debug = not debug
	end
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
		window.draw()
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
		this.fire_rate = 10
		this.fire_timer = 0
		this.hitbox={x=2,y=2,w=3,h=4}
		this.target=nil
		this.auto_target_radius = 40
		this.pickup_radius = 16
		this.projectile_dmg = 1
		this.projectile_spd = 1.3
		this.face = {x=1,y=0}
		this.hp = 100
		this.group = PLAYER_GROUP
		this.anim = make_animation({32})
		this.hurt_collidable = false
		this.level = 1
		this.xp = 0
		this.max_xp = 10
		this.dead = false
	end,
	take_damage=function(this, amt)
		if this.dead then
			return
		end
		this.hp -= amt
		start_hurt_object(this)
		if this.hp <= 0 then
			this.dead = true
			for i=0,5 do
				-- make_particle_group(this.x + 2, this.y + 2, nil, 1000)
				-- make_particle_group(this.x+TILE_SIZE - 2, this.y + 2, nil, 1000)
				-- make_particle_group(this.x+TILE_SIZE - 2, this.y+TILE_SIZE - 2, nil, 1000)
				-- make_particle_group(this.x + 2, this.y + TILE_SIZE - 2, nil, 1000)
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
			local proj = make_projectile(this.x, this.y, make_animation({30,31}, 4), this.projectile_dmg, this.projectile_spd, dir)
			add(proj.collision_groups, ENEMY_GROUP)
		end
		this.fire_timer = clamp(this.fire_timer - 1, 0, this.fire_rate)
		foreach(objects, function(obj)
			if this.collides_with(obj) then
				if obj.touch_damage > 0 then
					this.type.take_damage(this, obj.touch_damage)
				elseif obj.on_pickup ~= nil then
					obj.on_pickup(this)
				elseif obj.type.on_activate ~= nil then
					obj.type.on_activate(obj)
				end
			end
		end)
	end
}

-- pickups --
-------------

pickup_type = {
	init=function(this)
	end,
	update=function(this)
		if get_range(this, player) <= player.pickup_radius then
			local dir = get_direction(this, player)
			this.x += dir.x
			this.y += dir.y
		end
		this.anim.update()
	end
}

function make_pickup(x, y, anim)
	local pickup = init_object(pickup_type, x, y)
	pickup.anim = anim
	return pickup
end

function make_xp_pickkup(x, y, amount)
	local pickup = make_pickup(x, y, make_animation({28,29}, 10))
	local on_pickup = function(player)
		player.xp += amount
		destroy_object(pickup)
	end
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
	end,
	update=function(this)
		this.lifetime -= 1
		this.x += this.direction.x * this.spd
		this.y += this.direction.y * this.spd
		if this.lifetime <= 0 or is_move_to_next_room(this.x, this.y) then
			destroy_object(this)
			return
		end
		local col = this.collide(this.collision_groups)
		if col ~= nil then
			if col.take_damage ~= nil then
				col.take_damage(this.damage)
			end
			destroy_object(this)
			return
		end
		if not this.can_move_to((this.x + TILE_HALF_SIZE)/TILE_SIZE, (this.y + TILE_HALF_SIZE)/TILE_SIZE) then
			destroy_object(this)
		end
		this.anim.update()
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

eye_type = {
	init=function(this)
		this.fire_rate=90
		this.fire_timer=0
		this.hitbox={x=2,y=3,w=4,h=5}
		this.target=nil
		this.auto_target_radius=40
		this.threat = 1
		this.group = ENEMY_GROUP
		this.hp = 1
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
		this.hp = 1
		this.move_rate=15
		this.move_timer=0
		this.touch_damage = 10
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
		this.hp = 1
		this.move_rate=5
		this.move_timer=0
		this.touch_damage = 15
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
		this.hp = 2
		this.move_rate=5
		this.move_timer=0
		this.touch_damage = 20
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
		this.projectile_dmg = 1
		this.projectile_spd = 1
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
							make_projectile((col - offset) * TILE_SIZE + TILE_HALF_SIZE, this.y, make_animation({52}), this.projectile_dmg, this.projectile_spd, {x=1,y=0})
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
							make_projectile((col + offset) * TILE_SIZE - TILE_HALF_SIZE, this.y, make_animation({52}), this.projectile_dmg, this.projectile_spd, {x=-1,y=0})
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
							make_projectile(this.x, (row - offset) * TILE_SIZE + TILE_HALF_SIZE, make_animation({52}), this.projectile_dmg, this.projectile_spd, {x=0,y=1})
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
							make_projectile(this.x, (row + offset) * TILE_SIZE - TILE_HALF_SIZE, make_animation({52}), this.projectile_dmg, this.projectile_spd, {x=0,y=-1})
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

function make_enemy_spawn_point(x, y, enemy_types, spawn_time)
	sp = init_object(enemy_spawn_point_type, x, y)
	sp.spawn_time = spawn_time
	sp.spawn_timer = spawn_time
	for i=1,count(enemy_types) do
		add(sp.enemy_types, enemy_types[i])
	end
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
					make_xp_pickkup(obj.x,obj.y,1)
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
		if obj.is_hurt and (obj.hurt_duration_timer%2 == 0) then
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

-- rooms --
-----------

function start_room_transition(x_index, y_index)
	if x_index == room.x and y_index == room.y then
		return
	end

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
	-- load next room
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
		end
	end

	local tile_type
	for c=room.x*SCREEN_TILES,room.x*SCREEN_TILES+SCREEN_TILES-1 do
		for r=room.y*SCREEN_TILES,room.y*SCREEN_TILES+SCREEN_TILES-1 do
			tile_type = mget(c,r)
			if tile_type == DOOR_TILE then
				init_object(door_type, c*TILE_SIZE, r*TILE_SIZE)
			elseif tile_type == ENEMY_SPAWN_TILE then
				make_enemy_spawn_point(c*TILE_SIZE,r*TILE_SIZE, {eye_type,fang_type,bug_type, skull_type}, 100)
			elseif tile_type == SPIKE_TILE then
				init_object(spike_type, c*TILE_SIZE, r*TILE_SIZE)
			elseif tile_type == TRAP_TILE then
				test = init_object(trap_type, c*TILE_SIZE, r*TILE_SIZE)
			end
		end 
	end
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
		local window_rect = {left=camera_pos.x + 8, top=camera_pos.y+32, right=camera_pos.x + 119, bottom=camera_pos.y + 83}
		local pad = 4
		rectfill(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 0)
		rect(window_rect.left, window_rect.top, window_rect.right, window_rect.bottom, 8)
		spr(12, window_rect.left + 27, window_rect.top + pad - 2)
		print("you doid", window_rect.left + 40, window_rect.top + pad)
		spr(12, window_rect.left + 76, window_rect.top + pad - 2, 1, 1, true)
		print("press x to restart", window_rect.left + 21, window_rect.bottom - pad * 2, 7)
	end
}

-- utils --
-----------

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
0000000055500555677777764474474467777776aa5555aa67766776090000900900009008800880088008800085880000858800880000886666666669a99a96
0000000050500505767777677744447776777767a9a55a9a76555567909090099909909988888888800880080858858008588580800000086444444664944946
00700700550000557767767747477474755575555a5aa5a5755665570000009009000000888888888000000805787780057877800000000049a99a9440000004
000770000000000077766777447777447776677755aaaa5565677656090900000000909088888888800000080568765005687650000000004494494440000004
000770000000000077766777447777447776677755aaaa55656776560000909009090000088888800800008008777750087777500000000049a99a9449a99a94
00700700550000557767767747477474776776775a5aa5a5755665570900000000000090008888000080080005877850058778500000000049a99a9449a99a94
0000000050500505767777677744447776777767a9a55a9a765555679009090999909099000880000008800005858580058585808000000849a99a9449a99a94
0000000055500555677777764474474455575556aa5555aa67766776090000900900009000000000000000000855858008558580880000884444444444444444
00000000000000000500050067766776677667768888888600000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000500055005507ffffff77677776786878787000000000000000000000000000000000000000000000000000000000000000000cc0000000cc000
0555055505550555055505557f6ff6f77ffffff7878786870000000000000000000000000000000000000000000000000000b0000000300000c1ccc000cc1c00
000000000000000000000000677667766f7ff7f677766777000000000000000000000000000000000000000000000000000b3b000003b30000c111c00c111cc0
000000000000000000000000677667766f7ff7f6777667770000000000000000000000000000000000000000000000000000b000000030000c111c000cc111c0
0000000000000000500050007f6ff6f77ffffff77878787800000000000000000000000000000000000000000000000000000000000000000ccc1c0000c1cc00
0000000050005000550055007ffffff7767777677868786800000000000000000000000000000000000000000000000000000000000000000000cc00000cc000
55505550555055505550555067766776677667766888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099990000aaaa00
0018100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099aa9900aa99aa0
035353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a99a900a9aa9a0
033533000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a99a900a9aa9a0
0853580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099aa9900aa99aa0
00303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099990000aaaa00
00303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003000000000000111111001111110000000000009900000999900000000000e2ee2e000000000000000000000000000000000000000000000000000000000
000330000000300011111111011111100008888809299290009229000e2ee2e0022ee220000000000011d0000001110000999a00009aaa0000ee920000e22200
00333300000330001211112111111111008999980299992009722790022ee220022ee220000000000010011001d00d000a9aa9900aa99a9002e22ee0029ee9e0
033bb33000333300122112211111111108aa9aa89299992992722729022ee2202ee22ee2000000000d0d10100101d01009a9aa900a99a9a00929a2e002ea9e20
03b33b30033bb33012e11e211211112189a99a9899999999922222292ee22ee2029a9a20000000000101d0d0010d101009aa9a900a9a99a00e2a929002e9ae20
03b37b3033b33b3312e11e2112e11e2108aaa988997227999722227902eeee200ea9a9e0000000000110010000d00d10099aa9a009a99aa00ee22e200e9ee920
033bb33033b37b33111111111111111100888800097997900972279002eeee2002eeee2000000000000d11000011100000a9990000aaa9000029ee0000222e00
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
0001000300010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010505050501010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020202020203040204020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020101010101020402020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020101020202040204020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020101020202020202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020204020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202060402040602020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020204020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020203131301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101020202060202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102040202020204020202130202020202020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102010101010101010101010101010101010102010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102010101010101010101010101010101010102010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102010202020202020101020202020202020102010202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102010202020202020101020202020202020102010202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020103010202020202020101020202020202020103010202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106020202020402040202020202060101020202020202020213020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020204020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020602020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020206020202020202020101130102020202020202020203060202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020101010101010101010101010101030102020602020202020201020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101040304020402040402020404020202020101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001952019550185301653013510115100e5100b520075200152000520123001430017300113001430016300193001b3000970009700097001500013000120001100011000100000e0000d0000c0000b000
000600001d0702307026070280702907025070220701d0701807015070130701207012070130701507016070180701b0701f070250702b0702d0702b0702907026070220701f0701a07017070150701407014070
000200001262013630146401565016650176501865018650196501a6501a6501b6501b6501c6501d6501d6501d6501d6501d6501c6501b6501a65019640186401763016630156301462013620136101260012600
0001000003550065500a5500f5501455017550195501b5501d5501e5501f5501f5501f5501e5501d5501c55019550165501255010550000000000000000000000000000000000000000000000000000000000000
000100001c650206501f6501b6501865017650196501b6501f6502365024650216501e6501a65015650186501c650236502665024650216501e650186501b6501e6502165023650226501f6501c6501965015650
00010000026500465006650086500a6500c650116501465019650266503a650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002e6502c65028650246501e65019650146500c650036500265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800002505020150242502435023450215501f7501d0501a1501925017350184501a75012750140501615013250123500f4500e7500d7500d0500e1500e25016350194501a5501875015050117500e7500c750
