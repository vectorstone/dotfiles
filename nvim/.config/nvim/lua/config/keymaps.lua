local map = vim.keymap.set

map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>co", "<cmd>Codex<CR>", { desc = "Open Codex terminal" })

local directions = {
  h = "left",
  j = "down",
  k = "up",
  l = "right",
}

for key, direction in pairs(directions) do
  map("n", "<A-" .. key .. ">", "<C-w>" .. key, { desc = "Focus window " .. direction })
  map({ "i", "t" }, "<A-" .. key .. ">", "<C-\\><C-n><C-w>" .. key, { desc = "Focus window " .. direction })
end
