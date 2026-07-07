vim.pack.add({ "https://github.com/cuducos/yaml.nvim" })

require("yaml_nvim").setup({ ft = { "yaml", "eruby.yaml" } })

local function pick(prompt)
	local ok, yaml = pcall(require, "yaml_nvim")
	if not ok then
		return
	end
	local prev = vim.fn.getqflist()
	yaml.quickfix()
	local items = vim.fn.getqflist()
	vim.fn.setqflist(prev, "r")
	if #items == 0 then
		return
	end
	local labels, lnums = {}, {}
	for _, item in ipairs(items) do
		table.insert(labels, item.text)
		table.insert(lnums, item.lnum)
	end
	vim.ui.select(labels, {
		prompt = prompt,
		format_item = function(s)
			return s
		end,
	}, function(_, idx)
		if not idx then
			return
		end
		vim.api.nvim_win_set_cursor(0, { lnums[idx], 0 })
		vim.cmd("normal! zz")
	end)
end

local function yank(cmd)
	return function()
		vim.cmd(cmd)
		vim.fn.setreg("y", vim.trim(vim.fn.getreg('"')), "c")
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "yaml" },
	group = vim.api.nvim_create_augroup("yaml_keymaps", { clear = true }),
	callback = function(ev)
		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
		end
    -- stylua: ignore start
    map("<leader>fy", function() pick("YAML Keys")     end, "YAML Full Path")
    map("<leader>yq", function() pick("YAML Quickfix") end, "YAML Quickfix")
    map("<leader>yv", "<cmd>YAMLView<cr>",                  "YAML View")
    map("<leader>yy", yank("YAMLYank"),                     "YAML Yank [KV]")
    map("<leader>yk", yank("YAMLYankKey"),                  "YAML Yank [K]")
    map("<leader>yV", yank("YAMLYankValue"),                "YAML Yank [V]")
    map("<leader>yp", '"yp',                                "YAML Paste")
		-- stylua: ignore end
	end,
})
