pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main

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
is_room_transition = false
debug=false

update_fn = function()
end

-- entry point --
-----------------

function _init()
	cls()
	player = init_object(player_type, 120, 64)
	init_object(eye_type, 64, 64)
	init_object(eye_type, 32, 64)
	init_object(door_type, 48, 64)
	update_fn = game_update
end

function _update60()
	update_fn()
end

function _draw()
	cls()
	map()
	foreach(objects,function(obj)
		draw_object(obj)
	end)
	if player.target ~= nil then
		spr(20, player.target.x, player.target.y)
	end
	if debug then
		print(camera_pos.x, camera_pos.x + 1, camera_pos.y + 1, 0)
		print(camera_pos.y, camera_pos.x + 1, camera_pos.y + 1 + 8, 0)
		if player.target ~= nil then
			local range = get_range(player, player.target)
			circ(player.x + 4, player.y + 4, range)
		else
			circ(player.x + 4, player.y + 4, player.target_radius, 0)
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
		obj.move()
	end)
end

-- player --
------------

player_type = {
	init=function(this)
		this.tile = 32
		this.fire_rate=20 -- shoot every {fire_rate} ticks
		this.fire_ticks=0
		this.reload_rate=30 -- reload in {reloat_rate} ticks
		this.reload_ticks=0
		this.hitbox={x=1,y=2,w=4,h=4}
		this.target=nil
		this.target_radius=40 -- distance in pixels for auto-targeting objects
		this.spr = this.tile
		this.face = {x=1,y=0}
	end,
	update=function(this)
		if is_room_transition then
			return
		end
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
			local mx = dx * 8 + from.x
			local my = dy * 8 + from.y
			if this.can_move_to(mx/8, my/8) then
				add(this.moves, {x=mx,y=my})
			end
		end
		find_target_object(this)
		if this.target and get_range(this, this.target) > this.target_radius then
			this.target = nil
		end
		if btnp(k_shoot) then
			local proj = init_object(projectile_type, this.x, this.y)
			if this.target ~= nil then
				proj.direction = get_direction({x=this.x, y=this.y}, {x=this.target.x, y=this.target.y})
			else
				proj.direction = get_direction({x=this.x, y=this.y}, {x=this.x+this.face.x, y=this.y+this.face.y})
			end

		end
	end,
	draw=function(this)
		spr(this.spr,this.x,this.y,1,1)
		if this.target ~= nil then
			spr(20, this.target.x, this.target.y)
		end
	end
}

projectile_type = {
	init=function(this)
		this.tile = 30
		this.targetable = false
		this.target=nil -- TODO: implement homing
		this.spr = this.tile
		this.anim_frame = 1
		this.anim_rate = 8
		this.threat = -1
		this.spd = 1.25
		this.direction = {x=0, y=0}
		this.lifetime = 120
	end,
	update=function(this)
		this.anim_frame += 1
		this.lifetime -= 1
		if this.anim_frame > this.anim_rate then
			this.anim_frame = 1
			this.spr = this.spr == 30 and 31 or 30
		end
		this.x += this.direction.x * this.spd
		this.y += this.direction.y * this.spd
		if this.lifetime <= 0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		spr(this.spr,this.x,this.y,1,1)
	end
}

-- eye --
-----------

eye_type = {
	init=function(this)
		this.tile = 48
		this.fire_rate=20 -- shoot every {fire_rate} ticks
		this.fire_ticks=0
		this.reload_rate=30 -- reload in {reloat_rate} ticks
		this.reload_ticks=0
		this.hitbox={x=1,y=3,w=5,h=4}
		this.target=nil
		this.target_radius=32 -- distance in pixels for auto-targeting objects
		this.spr = this.tile
		this.anim_frame = 1
		this.anim_rate = 16
		this.threat = 1
	end,
	update=function(this)
		this.anim_frame += 1
		if this.anim_frame > this.anim_rate then
			this.anim_frame = 1
			this.spr = this.spr == 49 and 48 or 49
		end
	end,
	draw=function(this)
		spr(this.spr,this.x,this.y,1,1)
	end
}

door_type = {
	init=function(this)
		this.tile = 3
		this.hitbox={x=0,y=0,w=8,h=8}
		this.spr = this.tile
	end,
	update=function(this)
	end,
	draw=function(this)
		spr(this.spr,this.x,this.y,1,1)
	end
}

-- object functions --
----------------------

function init_object(type,x,y)
	local obj = {}
	obj.type = type
	obj.collideable = true
	obj.targetable = true
	obj.spr = type.tile
	obj.flip = {x=false,y=false}
	obj.x = x
	obj.y = y
	obj.hitbox = {x=0,y=0,w=8,h=8}
	obj.spd = 1
	obj.moves = {}
	obj.threat = 0

	obj.collide=function(type,ox,oy)
		local other
		for i=1,count(objects) do
			other = objects[i]
			if other ~= nil and other.type == type and other ~= obj and other.collideable and
				other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and
				other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
				other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and
				other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy then
				return other
			end
		end
	end

	obj.check=function(type,ox,oy)
		return obj.collide(type,ox,oy)
	end

	obj.move=function()
		if count(obj.moves) == 0 then
			return
		end
		local dest = obj.moves[1]
		if obj.x ~= dest.x then
			local sign = obj.x - dest.x > 0 and -1 or 1
			obj.x += sign * 1
		end
		if obj.y ~= dest.y then
			local sign = obj.y - dest.y > 0 and -1 or 1
			obj.y += sign * 1
		end
		if obj.x == dest.x and obj.y == dest.y then
			del(obj.moves, dest)
		end

		-- TODO: try not to depend on is_room_transition
		if type == player_type and not is_room_transition then
			if obj.x + 4 > room.x * 128 + 128 then
				start_room_transition(room.x + 1, room.y)
			elseif obj.x + 4 < room.x * 128 then
				start_room_transition(room.x - 1, room.y)
			elseif obj.y + 4 > room.y * 128 + 128 then
				start_room_transition(room.x, room.y + 1)
			elseif obj.y + 4 < room.y * 128 then
				start_room_transition(room.x, room.y - 1)
			end
		end
	end

	obj.can_move_to = function(x,y)
		return fget(mget(x,y)) == 0
	end

	obj.move_to = function(x,y)
		add(obj.moves, {x=x, y=y})
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

function find_target_object(obj)
	local other = nil
	local range = 0
	local target = {obj = nil, range = 0}
	for i=1,count(objects) do
		other = objects[i]
		if obj ~= other and other.targetable then
			range = get_range(obj, other)
			if range <= obj.target_radius then
				if target.obj == nil or
				(target.obj.threat < other.threat or
					(target.obj.threat == other.threat and target.range > range)
				) then
					target.obj = other
					target.range = range
				end
			end
		end
	end
	obj.target = target.obj
end

-- drawing --
-------------
function draw_object(obj)
	if obj.type.draw ~= nil then
		obj.type.draw(obj)
	elseif obj.spr > 0 then
		spr(obj.spr, obj.x, obj.y, 1, 1)
	end
	if debug then
		rect(obj.x+obj.hitbox.x,obj.y+obj.hitbox.y,obj.x+obj.hitbox.x+obj.hitbox.w,obj.y+obj.hitbox.y+obj.hitbox.h,8)
	end
end

-- rooms --
-----------

function start_room_transition(x_index,y_index)
	if x_index == room.x and y_index == room.y then
		return
	end
	is_room_transition = true
	room.x = x_index
	room.y = y_index
	update_fn = update_room_transition
	-- load next room
end

function update_room_transition()
	player.move()
	local diffx = room.x * 8 * 16 - camera_pos.x
	local diffy = room.y * 8 * 16 - camera_pos.y

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
end

-- utils --
-----------

function sign(v)
	return v > 0 and 1 or -1
end

function get_range(obj, other)
	return sqrt(((other.x + 4) - (obj.x + 4))^2 + ((other.y + 4) - (obj.y + 4))^2)
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
__gfx__
00000000555555556666666644444444111111119999999900000000000000000000000000000000000000000000000000000000000000006666666669a99a96
00000000555555556666666644444444111111119aaaaaa900000000000000000000000000000000000000000000000000000000000000006444444664944946
00700700555555556666666644444444111111119a9999a9000000000000000000000000000000000000000000000000000000000000000049a99a9440000004
00077000555555556666666644444444111111119a9aa9a900000000000000000000000000000000000000000000000000000000000000004494494440000004
00077000555555556666666644444444111111119a9aa9a9000000000000000000000000000000000000000000000000000000000000000049a99a9449a99a94
00700700555555556666666644444444111111119a9999a9000000000000000000000000000000000000000000000000000000000000000049a99a9449a99a94
00000000555555556666666644444444111111119aaaaaa9000000000000000000000000000000000000000000000000000000000000000049a99a9449a99a94
00000000555555556666666644444444111111119999999900000000000000000000000000000000000000000000000000000000000000004444444444444444
66666666667666766666666655555555880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666667766776666666655155155800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6655665566556655665555665555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000d000
666666666666666666566566515555150000000000000000000000000000000000000000000000000000000000000000000000000000000000011d0000d11000
666666666766676666566566515555150000000000000000000000000000000000000000000000000000000000000000000000000000000000d1100000011d00
66666666677667766655556655555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000d0000
65566556655665566666666655155155800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666655555555880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03535300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03353300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08535800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011dd110001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01d88d10011dd1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01d87d1011d88d110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011dd11011d87d110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100011dd1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000300010000000000000000000000020409000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010505050501010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010102020105050505050501020e010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050505010202020101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020202100202020202020202020202021002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020202100202020202020202020202021002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020210020202020101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101010101010101011002010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020202020202020202020202020201010e0202020202020210020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202021002020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010101020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102020101010101010101010101010101010202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102020101010101010101010101010101010202010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102020102020202020101010202020202020202020202020101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102020102020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102020102020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102020102020202020101020202020202020202020202020101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020102020102020202020101020202020202020202020101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010202010102020102020202020101020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020102020202020101020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020102020202020101020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020102020202020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020102020202020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020102020202020101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202010101020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000340503505037050380503b0503b050170502c0502c050230501405023050110502105012050200502a050140501205016050250500a05011050180501005010050100502505010050100501005011050
