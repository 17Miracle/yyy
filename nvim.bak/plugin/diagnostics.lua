vim.diagnostic.config({
	-- Виртуальный текст справа от строки
	virtual_text = {
		enabled = true,
		spacing = 4, -- отступ от кода
		prefix = "  ", -- иконка перед сообщением
		suffix = "", -- текст после сообщения
		source = false, -- показывать источник (eslint, lua_ls...)
		severity = nil, -- фильтр: vim.diagnostic.severity.ERROR — только ошибки
		format = nil, -- function(diag) return diag.message end
	},

	-- Виртуальные строки (каждая ошибка на отдельной строке под кодом)
	-- Требует Neovim >= 0.10
	virtual_lines = false,

	-- Знаки в signcolumn (E W I H)
	signs = {
		enabled = true,
		severity = { min = vim.diagnostic.severity.HINT },
		-- Кастомные иконки:
		-- text = {
		--     [vim.diagnostic.severity.ERROR] = "",
		--     [vim.diagnostic.severity.WARN]  = "",
		--     [vim.diagnostic.severity.INFO]  = "",
		--     [vim.diagnostic.severity.HINT]  = "",
		-- },
	},

	-- Подчёркивание проблемных мест
	underline = {
		severity = { min = vim.diagnostic.severity.HINT },
	},

	-- Обновлять диагностику пока пишешь в insert mode
	update_in_insert = false,

	-- Сортировать по severity (ERROR > WARN > INFO > HINT)
	severity_sort = true,

	-- Всплывающее окно (открывается через vim.diagnostic.open_float)
	float = {
		enabled = true,
		border = "single", -- "single" | "double" | "rounded" | "shadow" | "none"
		source = true, -- показывать источник диагностики
		header = "", -- заголовок окна
		prefix = "", -- префикс каждой строки
		suffix = "", -- суффикс каждой строки
		focus = false, -- фокусировать курсор во float окне
		scope = "line", -- "line" | "buffer" | "cursor"
		pos = nil, -- позиция: nil = авто
		severity_sort = true,
	},

	-- Переход между ошибками (используется в vim.diagnostic.goto_next/prev)
	jump = {
		float = true, -- открывать float при прыжке
		wrap = true, -- переходить с конца в начало
		severity = nil, -- фильтр severity при прыжке
	},
})
