vim.g.lazyvim_picker = "telescope"

local opt = vim.opt

if vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
  vim.g.clipboard = "osc52"
end

opt.clipboard = "unnamedplus"
opt.number = true
opt.relativenumber = true
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true
opt.scrolloff = 10
opt.list = true
opt.confirm = true
opt.spelllang = { "en", "cjk" }
