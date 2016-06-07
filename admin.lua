
local S = protector.intllib

protector.removal_names = ""

minetest.register_chatcommand("delprot", {
	params = "",
	description = S("Remove Protectors near players with names provided (separate names with spaces)"),
	privs = {server = true},
	func = function(name, param)

		if not param or param == "" then

			minetest.chat_send_player(name,
				S("Protector Names to remove: %1",
				protector.removal_names))

			return
		end

		if param == "-" then
			minetest.chat_send_player(name,
				S("Name List Reset"))

			protector.removal_names = ""

			return
		end

		protector.removal_names = param

	end,
})

minetest.register_abm({
	nodenames = {"protector:protect", "protector:protect2"},
	interval = 8,
	chance = 1,
	catch_up = false,
	action = function(pos, node)

		if protector.removal_names == "" then
			return
		end

		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		--local members = meta:get_string("members")

		local names = protector.removal_names:split(" ")

		for _, n in pairs(names) do

			if n == owner then
				minetest.set_node(pos, {name = "air"})
			end

		end

	end
})
