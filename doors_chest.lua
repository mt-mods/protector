
-- Register Protected Doors

local function on_rightclick(pos, dir, check_name, replace, replace_dir, params)

	pos.y = pos.y+dir

	if not minetest.get_node(pos).name == check_name then
		return
	end

	local p2 = minetest.get_node(pos).param2

	p2 = params[p2 + 1]

	minetest.swap_node(pos, {name = replace_dir, param2 = p2})

	pos.y = pos.y - dir

	minetest.swap_node(pos, {name = replace, param2 = p2})

	local snd_1 = "doors_door_close"
	local snd_2 = "doors_door_open" 

	if params[1] == 3 then
		snd_1 = "doors_door_open"
		snd_2 = "doors_door_close"
	end

	if minetest.get_meta(pos):get_int("right") ~= 0 then

		minetest.sound_play(snd_1, {
			pos = pos, gain = 0.3, max_hear_distance = 10})
	else

		minetest.sound_play(snd_2, {
			pos = pos, gain = 0.3, max_hear_distance = 10})
	end
end

-- Protected Wooden Door

local name = "protector:door_wood"

doors.register_door(name, {
	description = "Protected Wooden Door",
	inventory_image = "doors_wood.png^protector_logo.png",
	groups = {
		snappy = 1, choppy = 2, oddly_breakable_by_hand = 2,
		door = 1, unbreakable = 1
	},
	tiles_bottom = {"doors_wood_b.png^protector_logo.png", "doors_brown.png"},
	tiles_top = {"doors_wood_a.png", "doors_brown.png"},
	sounds = default.node_sound_wood_defaults(),
	sunlight = false,
})

minetest.override_item(name .. "_b_1", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, 1, name .. "_t_1",
				name .. "_b_2", name .. "_t_2", {1, 2, 3, 0})
		end
	end,
})

minetest.override_item(name.."_t_1", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, -1, name .. "_b_1",
				name .. "_t_2", name .. "_b_2", {1, 2, 3, 0})
		end
	end,
})

minetest.override_item(name.."_b_2", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, 1, name .. "_t_2",
				name .. "_b_1", name .. "_t_1", {3, 0, 1, 2})
		end
	end,
})

minetest.override_item(name.."_t_2", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, -1, name .. "_b_2",
				name .. "_t_1", name .. "_b_1", {3, 0, 1, 2})
		end
	end,
})

minetest.register_craft({
	output = name,
	recipe = {
		{"group:wood", "group:wood"},
		{"group:wood", "default:copper_ingot"},
		{"group:wood", "group:wood"}
	}
})

minetest.register_craft({
	output = name,
	recipe = {
		{"doors:door_wood", "default:copper_ingot"}
	}
})

-- Protected Steel Door

local name = "protector:door_steel"

doors.register_door(name, {
	description = "Protected Steel Door",
	inventory_image = "doors_steel.png^protector_logo.png",
	groups = {
		snappy = 1, bendy = 2, cracky = 1,
		level = 2, door = 1, unbreakable = 1
	},
	tiles_bottom = {"doors_steel_b.png^protector_logo.png", "doors_grey.png"},
	tiles_top = {"doors_steel_a.png", "doors_grey.png"},
	sounds = default.node_sound_wood_defaults(),
	sunlight = false,
})

minetest.override_item(name.."_b_1", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, 1, name .. "_t_1",
				name .. "_b_2", name .. "_t_2", {1, 2, 3, 0})
		end
	end,
})

minetest.override_item(name.."_t_1", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, -1, name .. "_b_1",
				name .. "_t_2", name .. "_b_2", {1, 2, 3, 0})
		end
	end,
})

minetest.override_item(name.."_b_2", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, 1, name .. "_t_2",
				name .. "_b_1", name .. "_t_1", {3, 0, 1, 2})
		end
	end,
})

minetest.override_item(name.."_t_2", {

	on_rightclick = function(pos, node, clicker)

		if not minetest.is_protected(pos, clicker:get_player_name()) then
			on_rightclick(pos, -1, name .. "_b_2",
				name .. "_t_1", name .. "_b_1", {3, 0, 1, 2})
		end
	end,
})

minetest.register_craft({
	output = name,
	recipe = {
		{"default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:copper_ingot"},
		{"default:steel_ingot", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = name,
	recipe = {
		{"doors:door_steel", "default:copper_ingot"}
	}
})

-- Protected Chest

minetest.register_node("protector:chest", {
	description = "Protected Chest",
	tiles = {
		"default_chest_top.png", "default_chest_top.png",
		"default_chest_side.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_front.png^protector_logo.png"
	},
	paramtype2 = "facedir",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, unbreakable = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		meta:set_string("infotext", "Protected Chest")
		meta:set_string("name", "")
		inv:set_size("main", 8 * 4)
	end,

	can_dig = function(pos,player)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if inv:is_empty("main") then

			if not minetest.is_protected(pos, player:get_player_name()) then
				return true
			end
		end
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)

		minetest.log("action", player:get_player_name()
		.. " moves stuff to protected chest at "
		.. minetest.pos_to_string(pos))
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)

		minetest.log("action", player:get_player_name()
		.. " takes stuff from protected chest at "
		.. minetest.pos_to_string(pos))
	end,

	on_rightclick = function(pos, node, clicker)

		if minetest.is_protected(pos, clicker:get_player_name()) then
			return
		end

		local meta = minetest.get_meta(pos)
		local spos = pos.x .. "," .. pos.y .. "," ..pos.z
		local formspec = "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "list[nodemeta:".. spos .. ";main;0,0.3;8,4;]"
			.. "button[0,4.5;2,0.25;toup;To Chest]"
			.. "field[2.3,4.8;4,0.25;chestname;;"
			.. meta:get_string("name") .. "]"
			.. "button[6,4.5;2,0.25;todn;To Inventory]"
			.. "list[current_player;main;0,5;8,1;]"
			.. "list[current_player;main;0,6.08;8,3;8]"
			.. "listring[nodemeta:" .. spos .. ";main]"
			.. "listring[current_player;main]"
			.. default.get_hotbar_bg(0,5)

			minetest.show_formspec(
				clicker:get_player_name(),
				"protector:chest_" .. minetest.pos_to_string(pos),
				formspec)
	end,
})

-- Protected Chest formspec buttons

minetest.register_on_player_receive_fields(function(player, formname, fields)

	if string.sub(formname, 0, string.len("protector:chest_")) == "protector:chest_" then

		local pos_s = string.sub(formname,string.len("protector:chest_") + 1)
		local pos = minetest.string_to_pos(pos_s)
		local meta = minetest.get_meta(pos)
		local chest_inv = meta:get_inventory()
		local player_inv = player:get_inventory()
		local leftover

		if fields.toup then

			-- copy contents of players inventory to chest
			for i, v in ipairs (player_inv:get_list("main") or {}) do

				if chest_inv
				and chest_inv:room_for_item('main', v) then

					leftover = chest_inv:add_item('main', v)

					player_inv:remove_item("main", v)

					if leftover
					and not leftover:is_empty() then
						player_inv:add_item("main", v)
					end
				end
			end
	
		elseif fields.todn then

			-- copy contents of chest to players inventory
			for i, v in ipairs (chest_inv:get_list('main') or {}) do

				if player_inv:room_for_item("main", v) then

					leftover = player_inv:add_item("main", v)

					chest_inv:remove_item('main', v)

					if leftover
					and not leftover:is_empty() then
						chest_inv:add_item('main', v)
					end
				end
			end

		elseif fields.chestname then

			-- change chest infotext to display name
			if fields.chestname ~= "" then

				meta:set_string("name", fields.chestname)
				meta:set_string("infotext",
				"Protected Chest (" .. fields.chestname .. ")")
			else
				meta:set_string("infotext", "Protected Chest")
			end

		end
	end

end)

-- Protected Chest recipes

minetest.register_craft({
	output = 'protector:chest',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'group:wood', 'default:copper_ingot', 'group:wood'},
		{'group:wood', 'group:wood', 'group:wood'},
	}
})

minetest.register_craft({
	output = 'protector:chest',
	recipe = {
		{'default:chest', 'default:copper_ingot', ''},
	}
})
