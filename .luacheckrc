unused = false

globals = {
	"minetest",
	"default",
	"protector",
	"register_door",
	"register_trapdoor"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "VoxelArea",

	-- deps
	"intllib",
	"mesecon",
	"screwdriver",
	"lucky_block",
	"factions"
}
