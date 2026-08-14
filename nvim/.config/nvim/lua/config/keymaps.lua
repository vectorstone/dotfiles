local map = vim.keymap.set

map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>co", "<cmd>Codex<CR>", { desc = "Open Codex terminal" })

map({ "n", "x" }, "d", '"_d', { desc = "Delete without copying" })
map({ "n", "x" }, "x", '"_x', { desc = "Delete character without copying" })
map({ "n", "x" }, "c", '"_c', { desc = "Change without copying" })
map({ "n", "x" }, "s", '"_s', { desc = "Substitute without copying" })

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
