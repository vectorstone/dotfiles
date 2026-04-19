return {
  {
    import = "lazyvim.plugins.extras.editor.telescope",
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      opts.defaults = opts.defaults or {}
      opts.defaults.hidden = true

      opts.pickers = opts.pickers or {}
      opts.pickers.find_files = vim.tbl_deep_extend("force", opts.pickers.find_files or {}, {
        hidden = true,
      })
    end,
    keys = {
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
        desc = "Search files",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Search by grep",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Search buffers",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Search help",
      },
      {
        "<leader>fk",
        function()
          require("telescope.builtin").keymaps()
        end,
        desc = "Search keymaps",
      },
    },
  },
}
