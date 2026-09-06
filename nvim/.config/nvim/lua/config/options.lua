vim.g.lazyvim_picker = "telescope"

local opt = vim.opt

local ssh_connection = vim.env.SSH_CONNECTION or ""
local ssh_client, ssh_server = ssh_connection:match("^(%S+)%s+%d+%s+(%S+)%s+%d+$")
local function is_loopback(host)
	return host == "localhost" or host == "::1" or host:match("^127%.") ~= nil
end
local is_local_tunnel = ssh_client ~= nil and is_loopback(ssh_client) and is_loopback(ssh_server)
local is_real_ssh = not is_local_tunnel and (vim.env.SSH_TTY ~= nil or ssh_client ~= nil)

if is_real_ssh then
	vim.g.clipboard = "osc52"
elseif vim.fn.has("mac") == 1 then
	vim.g.clipboard = "pbcopy"
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
opt.wrap = true
