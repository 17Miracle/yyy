local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

local files = {}

for name, type in vim.fs.dir(plugins_dir) do
	if type == "file" and name:match("%.lua$") then
		table.insert(files, name)
	end
end

table.sort(files)

for _, name in ipairs(files) do
	local module = "plugins." .. name:gsub("%.lua$", "")
	require(module)
end
