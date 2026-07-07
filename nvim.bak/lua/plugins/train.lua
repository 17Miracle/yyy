vim.pack.add({
	"https://github.com/Weyaaron/nvim-training",
})

-- require("nvim-training").setup()
local training = require("nvim-training")
training.configure({ -- All of these options work for 'opts' of lazy as well.
	audio_feedback = true, -- Enables/Disables audio feedback, if enabled, requires the 'sox' package providing the 'play' command.
	counter_bounds = { 1, 5 }, --The outer bounds for counters used in some tasks. WARNING: A high value may result in glitchy behaviour.
	custom_collections = {}, -- A table of tables containing names of tasks, for details read on.
	enable_counters = true, -- Enables/Disables counters in tasks that support counters.
	enable_events = true, -- Enables/Disables events.
	-- enable_registers = false, -- Enables/Disables registers. Since this option complicates a lot of tasks, it is disabled by default.
	-- enable_repeat_on_failure = false, -- Enables/Disables wether the current task will be repeated (exactly) if it failed. Failures will be counted regardless.
	enable_highlights = true, --Enables/Disables highlights. Care is taken to ensure that tasks are possible without them.
	event_storage_directory_path = vim.fn.stdpath("data") .. "/nvim-training/", -- The path used to store events.
	-- logging_args = {
	-- 	enable_logging = true, --Enables/Disables logging entirely.
	-- 	log_directory_path = vim.fn.stdpath("log") .. "/nvim-training/",
	-- 	log_file_path = os.date("%Y-%m-%d") .. ".log",
	-- 	display_logs = false, --Enables/Disables wether messages with the level 'log' should be printed. WARNING: Enabling his produces a lot of noise, but might be usefull for developers.
	-- 	display_warnings = true, --Enables/Disables wether messages with the level 'warning' should be printed.
	-- },
	possible_marks_list = { "a", "b", "c", "r", "s", "t", "d", "n", "e" }, -- A list of possible marks.
	possible_register_list = { "a", "b", "c", "r", "s", "t", "d", "n", "e" }, -- A list of possible registers.
	scheduler_args = { repetitions = 5 }, --These args are used to configure all the available schedulers
	task_alphabet = "ABCDEFGabddefg,", -- The alphabet of targets used in tasks like f,t etc. WARNING: Chars that represent lua patterns (Including e.g. '.') are not a valid entry. This is not checked for.
})
