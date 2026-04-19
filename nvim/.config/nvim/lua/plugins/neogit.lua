return {
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      {
        "<leader>gg",
        function()
          require("neogit").open({ kind = "split" })
        end,
        desc = "Open Neogit",
      },
    },
    opts = {
      kind = "split",
      integrations = {
        telescope = true,
      },
    },
  },
}
