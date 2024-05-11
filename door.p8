pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main

-- globals --
-------------

objects = {}
types = {}

k_left = 0
k_right = 1
k_up = 2
k_down = 3
k_shoot = 4

-- entry point --
-----------------

function _init()
	cls()
	plr = init_object(player, 64,64)
end

function _update60()
	foreach(objects,function(obj)
		obj.move()
		if obj.type.update~=nil then
			obj.type.update(obj)
		end
	end)
end

function _draw()
	cls()
	map()
	foreach(objects,function(obj)
		draw_object(obj)
	end)
end

-- player --
------------

player = {
	init=function(this)
		this.tile = 32
		this.fire_rate=20 -- shoot every {fire_rate} ticks
		this.fire_ticks=0
		this.reload_rate=30 -- reload in {reloat_rate} ticks
		this.reload_ticks=0
		this.hitbox={2,2,4,4}
		this.target=nil
		this.spr = this.tile
	end,
	update=function(this)
		local dx = 0
		local dy = 0
		if btnp(k_left) then
			dx = -8
		elseif btnp(k_right) then
			dx = 8
		elseif btnp(k_up) then
			dy = -8
		elseif btnp(k_down) then
			dy = 8
		end
		if dx ~= 0 or dy ~= 0 then
			local from = count(this.moves) and this.moves[#this.moves] or {x=this.x,y=this.y}
			dx += from.x
			dy += from.y
			if this.can_move_to(dx/8, dy/8) then
				add(this.moves, {x=dx,y=dy})
			end
		end
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
	obj.interactive = true
	obj.spr = type.tile
	obj.flip = {x=false,y=false}
	obj.x = x
	obj.y = y
	obj.hitbox = {x=0,y=0,w=8,h=8}
	obj.spd=1
	obj.moves = {}

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

-- drawing --
-------------
function draw_object(obj)
	if obj.type.draw ~= nil then
		obj.type.draw(obj)
	elseif obj.spr > 0 then
		spr(obj.spr, obj.x, obj.y, 1, 1)
	end
end
__gfx__
00000000555555556666666644444444111111119999999900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555556666666644444444111111119aaaaaa900000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555556666666644444444111111119a9999a900000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555556666666644444444111111119a9aa9a900000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555556666666644444444111111119a9aa9a900000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555556666666644444444111111119a9999a900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555556666666644444444111111119aaaaaa900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555556666666644444444111111119999999900000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666667666766666666655555555008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666667766776666666655155155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66556655665566556655556655555555800880080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666656656651555515808000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666676667666656656651555515800008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666677667766655556655555555800880080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65566556655665566666666655155155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666655555555008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03535300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03353300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08535800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
__gff__
0001000300011400000000000000000000020409000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010505010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020201050505050102020101011010101010101010101010101010101010100113020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050102020201100210100202020202020202020202020202020302020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050102020201011010101010101010101010101010101010100102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020201050505050102020201010101010101010101010101010101010101010102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020201010202020202020202020202020101010202010102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020203020202020202020202020202020203020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020203020202020202020202020202020203020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020201010202020202020202020202020101020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020201010101010101010101010101010101020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020201010202020202020202020202020101020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020201020202020202020202020202020201020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020101020202020202020202020202020201020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010303010101010101020202020202020202020202020201020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020201020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020201020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020201020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020203020202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020203100202020102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020201010202010102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020201010101010102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020201010202010102020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001010202020202020202020202020201020202020312020202020202020202021300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001010101010101030301010101010101020202020312020202020202020202021300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001010202020202020202020202020202020202020101020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020202020202020101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001020202020202020202020202020202020202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000001010202020202020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000340503505037050380503b0503b050170502c0502c050230501405023050110502105012050200502a050140501205016050250500a05011050180501005010050100502505010050100501005011050
