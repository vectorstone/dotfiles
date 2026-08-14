vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_user_command("GitBlameLine", function()
  local line_number = vim.fn.line(".")
  local filename = vim.api.nvim_buf_get_name(0)
  print(vim.system({ "git", "blame", "-L", line_number .. ",+1", filename }):wait().stdout)
end, { desc = "Print the git blame for the current line" })

vim.api.nvim_create_user_command("Codex", function()
  vim.cmd("botright vsplit")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns / 2))
  vim.cmd("terminal codex")
  vim.cmd("startinsert")
end, { desc = "Open Codex terminal" })

vim.cmd("packadd! nohlsearch")
