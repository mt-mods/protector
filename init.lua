
-- older privelage for admins to rbypass protected nodes, do not use anymore
-- instead grant admin 'protection_bypass' privelage.

-- 'delprotect' priv removed, use 'protection_bypass' instead
--minetest.register_privilege("delprotect","Ignore player protection")

-- get minetest.conf settings
protector = {}
protector.mod = "redo"
protector.radius = tonumber(minetest.setting_get("protector_radius")) or 5
protector.drop = minetest.setting_getbool("protector_drop") or false
protector.flip = minetest.setting_getbool("protector_flip") or false
protector.hurt = tonumber(minetest.setting_get("protector_hurt")) or 0
protector.spawn = tonumber(minetest.setting_get("protector_spawn")
	or minetest.setting_get("protector_pvp_spawn")) or 0

-- get static spawn position
local statspawn = minetest.setting_get_pos("static_spawnpoint") or {x = 0, y = 2, z = 0}

-- Intllib
local S
if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s, a, ...)
		if a == nil then
			return s
		end
		a = {a, ...}
		return s:gsub("(@?)@(%(?)(%d+)(%)?)",
			function(e, o, n, c)
				if e == ""then
					return a[tonumber(n)] .. (o == "" and c or "")
				else
					return "@" .. o .. n .. c
				end
			end)
		end
end
protector.intllib = S

-- return list of members as a table
protector.get_member_list = function(meta)

	return meta:get_string("members"):split(" ")
end

-- write member list table in protector meta as string
protector.set_member_list = function(meta, list)

	meta:set_string("members", table.concat(list, " "))
end

-- check if player name is a member
protector.is_member = function (meta, name)

	for _, n in pairs(protector.get_member_list(meta)) do

		if n == name then
			return true
		end
	end

	return false
end

-- add player name to table as member
protector.add_member = function(meta, name)

	if protector.is_member(meta, name) then
		return
	end

	local list = protector.get_member_list(meta)

	table.insert(list, name)

	protector.set_member_list(meta, list)
end

-- remove player name from table
protector.del_member = function(meta, name)

	local list = protector.get_member_list(meta)

	for i, n in pairs(list) do

		if n == name then
			table.remove(list, i)
			break
		end
	end

	protector.set_member_list(meta, list)
end

-- protector interface
protector.generate_formspec = function(meta)

	local formspec = "size[8,7]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "label[2.5,0;" .. S("-- Protector interface --") .. "]"
		.. "label[0,1;" .. S("PUNCH node to show protected area or USE for area check") .. "]"
		.. "label[0,2;" .. S("Members:") .. "]"
		.. "button_exit[2.5,6.2;3,0.5;close_me;" .. S("Close") .. "]"

	local members = protector.get_member_list(meta)
	local npp = 12 -- max users added to protector list
	local i = 0

	for n = 1, #members do

		if i < npp then

			-- show username
			formspec = formspec .. "button[" .. (i % 4 * 2)
			.. "," .. math.floor(i / 4 + 3)
			.. ";1.5,.5;protector_member;" .. members[n] .. "]"

			-- username remove button
			.. "button[" .. (i % 4 * 2 + 1.25) .. ","
			.. math.floor(i / 4 + 3)
			.. ";.75,.5;protector_del_member_" .. members[n] .. ";X]"
		end

		i = i + 1
	end
	
	if i < npp then

		-- user name entry field
		formspec = formspec .. "field[" .. (i % 4 * 2 + 1 / 3) .. ","
		.. (math.floor(i / 4 + 3) + 1 / 3)
		.. ";1.433,.5;protector_add_member;;]"

		-- username add button
		.."button[" .. (i % 4 * 2 + 1.25) .. ","
		.. math.floor(i / 4 + 3) .. ";.75,.5;protector_submit;+]"

	end

	return formspec
end

-- check if pos is inside a protected spawn area
local function inside_spawn(pos, radius)

	if protector.spawn <= 0 then
		return false
	end

	if pos.x < statspawn.x + radius
	and pos.x > statspawn.x - radius
	and pos.y < statspawn.y + radius
	and pos.y > statspawn.y - radius
	and pos.z < statspawn.z + radius
	and pos.z > statspawn.z - radius then

		return true
	end

	return false
end

-- Infolevel:
-- 0 for no info
-- 1 for "This area is owned by <owner> !" if you can't dig
-- 2 for "This area is owned by <owner>.
-- 3 for checking protector overlaps

protector.can_dig = function(r, pos, digger, onlyowner, infolevel)

	if not digger
	or not pos then
		return false
	end

	-- delprotect and protector_bypass privileged users can override protection
	if ( minetest.check_player_privs(digger, {delprotect = true})
	or minetest.check_player_privs(digger, {protection_bypass = true}) )
	and infolevel == 1 then
		return true
	end

	-- infolevel 3 is only used to bypass priv check, change to 1 now
	if infolevel == 3 then infolevel = 1 end

	-- is spawn area protected ?
	if inside_spawn(pos, protector.spawn) then

		minetest.chat_send_player(digger,
			S("Spawn @1 has been protected up to a @2 block radius.",
			minetest.pos_to_string(statspawn), protector.spawn))

		return false
	end

	-- find the protector nodes
	local pos = minetest.find_nodes_in_area(
		{x = pos.x - r, y = pos.y - r, z = pos.z - r},
		{x = pos.x + r, y = pos.y + r, z = pos.z + r},
		{"protector:protect", "protector:protect2"})

	local meta, owner, members

	for n = 1, #pos do

		meta = minetest.get_meta(pos[n])
		owner = meta:get_string("owner") or ""
		members = meta:get_string("members") or ""

		-- node change and digger isn't owner
		if owner ~= digger
		and infolevel == 1 then

			-- and you aren't on the member list
			if onlyowner
			or not protector.is_member(meta, digger) then

				minetest.chat_send_player(digger,
					S("This area is owned by @1!", owner))

					return false
			end
		end

		-- when using protector as tool, show protector information
		if infolevel == 2 then

			minetest.chat_send_player(digger,
			S("This area is owned by @1.", owner))

			minetest.chat_send_player(digger,
			S("Protection located at: @1", minetest.pos_to_string(pos[n])))

			if members ~= "" then

				minetest.chat_send_player(digger,
				S("Members: @1.", members))
			end

			return false
		end

	end

	-- show when you can build on unprotected area
	if infolevel == 2 then

		if #pos < 1 then

			minetest.chat_send_player(digger,
			S("This area is not protected."))
		end

		minetest.chat_send_player(digger, S("You can build here."))
	end

	return true
end


protector.old_is_protected = minetest.is_protected

-- check for protected area, return true if protected and digger isn't on list
function minetest.is_protected(pos, digger)

	-- is area protected against digger?
	if not protector.can_dig(protector.radius, pos, digger, false, 1) then

		local player = minetest.get_player_by_name(digger)

		-- hurt player if protection violated
		if protector.hurt > 0
		and player then
			player:set_hp(player:get_hp() - protector.hurt)
		end

		-- flip player when protection violated
		if protector.flip
		and player then

			-- yaw + 180°
			--local yaw = player:get_look_horizontal() + math.pi
			local yaw = player:get_look_yaw() + math.pi

			if yaw > 2 * math.pi then
				yaw = yaw - 2 * math.pi
			end

			--player:set_look_horizontal(yaw)
			player:set_look_yaw(yaw)

			-- invert pitch
			--player:set_look_vertical(-player:get_look_vertical())
			player:set_look_pitch(-player:get_look_pitch())

			-- if digging below player, move up to avoid falling through hole
			local pla_pos = player:getpos()

			if pos.y < pla_pos.y then

				player:setpos({
					x = pla_pos.x,
					y = pla_pos.y + 0.8,
					z = pla_pos.z
				})
			end
		end

		-- drop tool/item if protection violated
		if protector.drop == true
		and player then

			local holding = player:get_wielded_item()

			if holding:to_string() ~= "" then

				-- take stack
				local sta = holding:take_item(holding:get_count())
				player:set_wielded_item(holding)

				-- incase of lag, reset stack
				minetest.after(0.1, function()
					player:set_wielded_item(holding)

					-- drop stack
					local obj = minetest.add_item(player:getpos(), sta)
					if obj then
						obj:setvelocity({x = 0, y = 5, z = 0})
					end
				end)

			end
		end

		return true
	end

	-- otherwise can dig or place
	return protector.old_is_protected(pos, digger)

end

-- make sure protection block doesn't overlap another protector's area
function protector.check_overlap(itemstack, placer, pointed_thing)

	if pointed_thing.type ~= "node" then
		return itemstack
	end

	local pos = pointed_thing.above

	-- make sure protector doesn't overlap onto protected spawn area
	if inside_spawn(pos, protector.spawn + protector.radius) then

		minetest.chat_send_player(placer:get_player_name(),
			S("Spawn @1 has been protected up to a @2 block radius.",
			minetest.pos_to_string(statspawn), protector.spawn))

		return itemstack
	end

	-- make sure protector doesn't overlap any other player's area
	if not protector.can_dig(protector.radius * 2, pos,
		placer:get_player_name(), true, 3) then

		minetest.chat_send_player(placer:get_player_name(),
			S("Overlaps into above players protected area"))

		return itemstack
	end

	return minetest.item_place(itemstack, placer, pointed_thing)

end

-- protection node
minetest.register_node("protector:protect", {
	description = S("Protection Block"),
	drawtype = "nodebox",
	tiles = {
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png^protector_logo.png"
	},
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, unbreakable = 1},
	is_ground_content = false,
	paramtype = "light",
	light_source = 4,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)

		local meta = minetest.get_meta(pos)

		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
		meta:set_string("members", "")
	end,

	on_use = function(itemstack, user, pointed_thing)

		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, pointed_thing.under, user:get_player_name(), false, 2)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)

		local meta = minetest.get_meta(pos)

		if meta
		and protector.can_dig(1, pos,clicker:get_player_name(), true, 1) then
			minetest.show_formspec(clicker:get_player_name(), 
			"protector:node_" .. minetest.pos_to_string(pos), protector.generate_formspec(meta))
		end
	end,

	on_punch = function(pos, node, puncher)

		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end

		minetest.add_entity(pos, "protector:display")
	end,

	can_dig = function(pos, player)

		return protector.can_dig(1, pos, player:get_player_name(), true, 1)
	end,

	on_blast = function() end,
})

minetest.register_craft({
	output = "protector:protect",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "default:steel_ingot", "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	}
})

-- protection logo
minetest.register_node("protector:protect2", {
	description = S("Protection Logo"),
	tiles = {"protector_logo.png"},
	wield_image = "protector_logo.png",
	inventory_image = "protector_logo.png",
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, unbreakable = 1},
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,
	light_source = 4,
	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = true,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)

		local meta = minetest.get_meta(pos)

		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
		meta:set_string("members", "")
	end,

	on_use = function(itemstack, user, pointed_thing)

		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, pointed_thing.under, user:get_player_name(), false, 2)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)

		local meta = minetest.get_meta(pos)

		if protector.can_dig(1, pos, clicker:get_player_name(), true, 1) then

			minetest.show_formspec(clicker:get_player_name(), 
			"protector:node_" .. minetest.pos_to_string(pos), protector.generate_formspec(meta))
		end
	end,

	on_punch = function(pos, node, puncher)

		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end

		minetest.add_entity(pos, "protector:display")
	end,

	can_dig = function(pos, player)

		return protector.can_dig(1, pos, player:get_player_name(), true, 1)
	end,

	on_blast = function() end,
})

minetest.register_craft({
	output = "protector:protect2",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "default:copper_ingot", "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	}
})

-- check formspec buttons or when name entered
minetest.register_on_player_receive_fields(function(player, formname, fields)

	-- protector formspec found
	if string.sub(formname, 0, string.len("protector:node_")) == "protector:node_" then

		local pos_s = string.sub(formname, string.len("protector:node_") + 1)
		local pos = minetest.string_to_pos(pos_s)
		local meta = minetest.get_meta(pos)

		-- only owner can add names
		if not protector.can_dig(1, pos, player:get_player_name(), true, 1) then
			return
		end

		-- add member [+]
		if fields.protector_add_member then

			for _, i in pairs(fields.protector_add_member:split(" ")) do
				protector.add_member(meta, i)
			end
		end

		-- remove member [x]
		for field, value in pairs(fields) do

			if string.sub(field, 0,
				string.len("protector_del_member_")) == "protector_del_member_" then

				protector.del_member(meta,
					string.sub(field,string.len("protector_del_member_") + 1))
			end
		end

		-- reset formspec until close button pressed
		if not fields.close_me then
			minetest.show_formspec(player:get_player_name(), formname, protector.generate_formspec(meta))
		end
	end
end)

-- display entity shown when protector node is punched
minetest.register_entity("protector:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"protector:display_node"},
	timer = 0,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		-- remove after 5 seconds
		if self.timer > 5 then
			self.object:remove()
		end
	end,
})

-- Display-zone node, Do NOT place the display as a node,
-- it is made to be used as an entity (see above)

local x = protector.radius
minetest.register_node("protector:display_node", {
	tiles = {"protector_display.png"},
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
			{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
			-- top
			{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
			-- bottom
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
			-- middle (surround protector)
			{-.55,-.55,-.55, .55,.55,.55},
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})

local path = minetest.get_modpath("protector")

dofile(path .. "/doors_chest.lua")
dofile(path .. "/pvp.lua")
dofile(path .. "/admin.lua")
dofile(path .. "/tool.lua")
dofile(path .. "/lucky_block.lua")

print (S("[MOD] Protector Redo loaded"))
