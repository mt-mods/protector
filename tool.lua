
-- protector placement tool (thanks to Shara for code and idea)

local S = protector.intllib

-- get protection radius
local r = tonumber(minetest.settings:get("protector_radius")) or 5

protector.tool = {

	registered_protectors = {},

	register_protector = function(self, nodename, data)
		if not data.on_place then 
			print(S('[MOD] Protector Redo Tool: Error registering protector @1 missing on_place method', nodename))
		end

		data.nodes = data.nodes or {}
		table.insert(data.nodes, nodename)

		-- Collect parameters droppping anything that is not used
		self.registered_protectors[nodename] = {
			radius = data.radius or r,
			param2 = data.param2 or 0,
			nodes = data.nodes,
			on_place = data.on_place,
			after_place = data.after_place,
		}
		print(S('[MOD] Protector Redo Tool: registered protector:tool for @1', nodename))
		if data.nodes ~= nil then
			if type(data.nodes) == 'table' then
				for i,name in ipairs(data.nodes) do
					-- create links for nodes for fast and straightforward lookup
					if name ~= nodename then
						print(S('[MOD] Protector Redo Tool: registering alternative @1 for @2', name, nodename))
					end
					self.registered_protectors[name] = self.registered_protectors[nodename]
				end
			else
				print(S('[MOD] Protector Redo Tool: invalid data.nodes in register_protector @1', nodename))
			end
		end
	end,

	get_protector_data = function(self, nodename)
		return self.registered_protectors[nodename]
	end,

	get_registered_alternatives = function(self, nodename)
		if self.registered_protectors[nodename] then
			return self.registered_protectors[nodename].nodes
		end
		return {}
	end,

	get_registered_protectors = function(self)
		if self.registered_protectors_cache == nil then
			self.registered_protectors_cache = {}
			for nodename,_ in pairs(self.registered_protectors) do
				table.insert(self.registered_protectors_cache, nodename)
			end
		end
		return self.registered_protectors_cache
	end,

	find_protector = function(self, pos, radius)
		local pp = minetest.find_nodes_in_area(
			vector.subtract(pos, radius), vector.add(pos, radius),
			self:get_registered_protectors())
		return #pp > 0 and pp[1] or nil -- take position of first protector found
	end,

	take_from_inventory = function(self, user, node)
		-- do we have protectors to use?
		local available_node = nil
		local inv = user:get_inventory()

		-- first look for specified node (normally one user is standing on) and then any compatible nodes
		if inv:contains_item("main", node.name) then
			available_node = node.name
		elseif self.registered_protectors[node.name].nodes then
			for i,nodename in ipairs(self.registered_protectors[node.name].nodes) do
				if nodename ~= node.name and inv:contains_item("main", nodename) then
					available_node = nodename
					break
				end
			end
		end

		if not available_node then
			return
		end

		-- take protector from inventory and return node name that was actually used
		inv:remove_item("main", available_node)
		return available_node
	end,

	place_protector = function(self, user, pos, nodename, source_pos, source_node)
		local p = self:get_protector_data(source_node)

		if p.on_place then
			-- on_place event, callback should place nodes to world
			p.on_place(user, pos, source_pos, nodename)
		elseif user:get_player_control().sneak then
			-- default on_place while sneaking, place node to world with param2 copied
			local param2 = minetest.get_node(source_pos).param2
			minetest.set_node(pos, {name = nodename, param2 = param2})
		else
			-- default on_place, place node to world
			minetest.set_node(pos, {name = nodename, param2 = p.param2})
		end

		local meta = minetest.get_meta(pos)
		local name = user:get_player_name()
		meta:set_string("owner", name)

		if p.after_place then
			-- execute after_place event where metadata can be changed easily
			local src_meta = minetest.get_meta(source_pos)
			p.after_place(user, meta, src_meta, nodename)
		end
	end,
}

minetest.register_craftitem("protector:tool", {
	description = S("Protector Placer Tool (stand near protector, face direction and use)"),
	inventory_image = "protector_display.png^protector_logo.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)

		local name = user:get_player_name()
		local pos = user:get_pos()

		-- check for protector near player (2 block radius), abort if not found
		local source_pos = protector.tool:find_protector(pos, 2)
		if source_pos == nil then return end
		local source_node = minetest.get_node(source_pos)
		local radius = protector.tool:get_protector_data(source_node.name).radius

		-- get direction player is facing
		local dir = minetest.dir_to_facedir( user:get_look_dir() )
		local vec = {x = 0, y = 0, z = 0}
		local gap = (radius * 2) + 1
		local pit =  user:get_look_vertical()

		-- set placement coords
		if pit > 1.2 then
			vec.y = -gap -- up
		elseif pit < -1.2 then
			vec.y = gap -- down
		elseif dir == 0 then
			vec.z = gap -- north
		elseif dir == 1 then
			vec.x = gap -- east
		elseif dir == 2 then
			vec.z = -gap -- south
		elseif dir == 3 then
			vec.x = -gap -- west
		end

		-- new position
		pos.x = source_pos.x + vec.x
		pos.y = source_pos.y + vec.y
		pos.z = source_pos.z + vec.z

		-- does placing a protector overlap existing area
		if not protector.can_dig(radius * 2, pos, user:get_player_name(), true, 3) then

			minetest.chat_send_player(name,
				S("Overlaps into above players protected area"))

			return
		end

		-- does a protector already exist ?
		if #minetest.find_nodes_in_area(
			vector.subtract(pos, 1), vector.add(pos, 1),
			protector.tool:get_registered_alternatives(source_node.name)) > 0 then

			minetest.chat_send_player(name, S("Protector already in place!"))

			return
		end

		local protector_node = protector.tool:take_from_inventory(user, source_node)
		if not protector_node then
			-- cannot take compatible ndoe from inventory
			minetest.chat_send_player(name, S("No protectors available to place!"))
			return
		end

		-- do not replace containers with inventory space
		local inv = minetest.get_inventory({type = "node", pos = pos})
		if inv then
			minetest.chat_send_player(name,
				S("Cannot place protector, container at") ..
					" " .. minetest.pos_to_string(pos))
			return
		end

		-- protection check for other mods like Areas
		if minetest.is_protected(pos, name) then
			minetest.chat_send_player(name,
				S("Cannot place protector, already protected at") ..
				" " .. minetest.pos_to_string(pos))
			return
		end

		protector.tool:place_protector(user, pos, protector_node, source_pos, source_node.name)

		minetest.chat_send_player(name,
				S("Protector placed at") ..
				" " ..  minetest.pos_to_string(pos))

	end,
})

-- tool recipe
local df = "default:steel_ingot"
if not minetest.registered_items[df] then
	df = "mcl_core:iron_ingot"
end


minetest.register_craft({
	output = "protector:tool",
	recipe = {
		{df, df, df},
		{df, "protector:protect", df},
		{df, df, df},
	}
})
