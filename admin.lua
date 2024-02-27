
local S = protector.intllib
local removal_names = ""
local replace_names = ""

minetest.register_chatcommand("protector_remove", {
	params = S("<names list>"),
	description = S("Remove Protectors around players (separate names with spaces)"),
	privs = {server = true},
	func = function(name, param)

		if not param or param == "" then

			minetest.chat_send_player(name,
				S("Protector Names to remove: @1",
					removal_names))

			return
		end

		if param == "-" then

			minetest.chat_send_player(name,
				S("Name List Reset"))

			removal_names = ""

			return
		end

		removal_names = param
	end
})


minetest.register_chatcommand("protector_replace", {
	params = S("<owner name> <name to replace with>"),
	description = S("Replace Protector Owner with name provided"),
	privs = {server = true},
	func = function(name, param)

		-- reset list to empty
		if param == "-" then

			minetest.chat_send_player(name, S("Name List Reset"))

			replace_names = ""

			return
		end

		-- show name info
		if param == ""
		and replace_names ~= "" then

			local names = replace_names:split(" ")

			minetest.chat_send_player(name,
				S("Replacing Protector name @1 with @2",
					names[1] or "", names[2] or ""))

			return
		end

		replace_names = param
	end
})


minetest.register_abm({
	nodenames = {"protector:protect", "protector:protect2", "protector:protect_hidden"},
	interval = 6,
	chance = 1,
	catch_up = false,
	action = function(pos, node)

		if removal_names == ""
		and replace_names == "" then
			return
		end

		local meta = minetest.get_meta(pos)

		if not meta then return end

		local owner = meta:get_string("owner")

		if removal_names ~= "" then

			local names = removal_names:split(" ")

			for _, n in pairs(names) do
				if n == owner then
					minetest.set_node(pos, {name = "air"})
				end
			end
		end

		if replace_names ~= "" then

			local names = replace_names:split(" ")

			if names[1] and names[2] and owner == names[1] then
				meta:set_string("owner", names[2])
				meta:set_string("infotext", S("Protection (owned by @1)", names[2]))
			end
		end
	end
})

-- get protection radius
local r = tonumber(minetest.settings:get("protector_radius")) or 5

-- show protection areas of nearby protectors owned by you (thanks agaran)
minetest.register_chatcommand("protector_show_area", {
	params = "",
	description = S("Show protected areas of your nearby protectors"),
	privs = {},
	func = function(name, param)

		local player = minetest.get_player_by_name(name)
		local ppos = player:get_pos()

		-- find the protector nodes
		local pos = minetest.find_nodes_in_area(
			{x = ppos.x - r, y = ppos.y - r, z = ppos.z - r},
			{x = ppos.x + r, y = ppos.y + r, z = ppos.z + r},
			{"protector:protect", "protector:protect2", "protector:protect_hidden"})

		local meta, owner

		-- show a maximum of 5 protected areas only
		for n = 1, math.min(#pos, 5) do

			meta = minetest.get_meta(pos[n])
			owner = meta:get_string("owner") or ""

			if owner == name
			or minetest.check_player_privs(name, {protection_bypass = true}) then
				minetest.add_entity(pos[n], "protector:display")
			end
		end
	end
})


-- ability to hide protection blocks (borrowed from doors mod :)
minetest.register_node("protector:protect_hidden", {
	description = "Hidden Protector",
	drawtype = "airlike",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	-- has to be walkable for falling nodes to stop falling
	walkable = true,
	pointable = false,
	diggable = false,
	buildable_to = false,
	floodable = false,
	drop = "",
	groups = {not_in_creative_inventory = 1, unbreakable = 1},
	is_ground_content = false,
	on_blast = function() end,
	-- 1px block inside door hinge near node top
	collision_box = {
		type = "fixed",
		fixed = {-15/32, 13/32, -15/32, -13/32, 1/2, -13/32}
	}
})


minetest.register_chatcommand("protector_show", {
	params = "",
	description = S("Show your nearby protection blocks"),
	privs = {interact = true},

	func = function(name, param)

		local player = minetest.get_player_by_name(name)

		if not player then
			return false, "Player not found"
		end

		local pos = player:get_pos()

		local a = minetest.find_nodes_in_area(
			{x = pos.x - r, y = pos.y - r, z = pos.z - r},
			{x = pos.x + r, y = pos.y + r, z = pos.z + r},
			{"protector:protect_hidden"})

		local meta, owner

		for _, row in pairs(a) do

			meta = minetest.get_meta(row)
			owner = meta:get_string("owner") or ""

			if owner == name
			or minetest.check_player_privs(name, {protection_bypass = true}) then
				minetest.swap_node(row, {name = "protector:protect"})
			end
		end
	end
})

minetest.register_chatcommand("protector_hide", {
	params = "",
	description = S("Hide your nearby protection blocks"),
	privs = {interact = true},

	func = function(name, param)

		local player = minetest.get_player_by_name(name)

		if not player then
			return false, "Player not found"
		end

		local pos = player:get_pos()

		local a = minetest.find_nodes_in_area(
			{x = pos.x - r, y = pos.y - r, z = pos.z - r},
			{x = pos.x + r, y = pos.y + r, z = pos.z + r},
			{"protector:protect", "protector:protect2"})

		local meta, owner

		for _, row in pairs(a) do

			meta = minetest.get_meta(row)
			owner = meta:get_string("owner") or ""

			if owner == name
			or minetest.check_player_privs(name, {protection_bypass = true}) then
				minetest.swap_node(row, {name = "protector:protect_hidden"})
			end
		end
	end
})
