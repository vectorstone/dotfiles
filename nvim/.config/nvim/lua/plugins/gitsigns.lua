return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
    keys = {
      {
        "]c",
        function()
          require("gitsigns").nav_hunk("next")
        end,
        desc = "Next git hunk",
      },
      {
        "[c",
        function()
          require("gitsigns").nav_hunk("prev")
        end,
        desc = "Previous git hunk",
      },
      {
        "<leader>gp",
        function()
          require("gitsigns").preview_hunk()
        end,
        desc = "Preview git hunk",
      },
      {
        "<leader>gb",
        function()
          require("gitsigns").blame_line()
        end,
        desc = "Blame current line",
      },
      {
        "<leader>gs",
        function()
          require("gitsigns").stage_hunk()
        end,
        desc = "Stage git hunk",
      },
      {
        "<leader>gr",
        function()
          require("gitsigns").reset_hunk()
        end,
        desc = "Reset git hunk",
      },
    },
  },
}
