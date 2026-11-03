-- Catppuccin Mocha, matching the terminal theme
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true, -- let the Ghostty transparency show through
      integrations = { blink_cmp = true, gitsigns = true, neotree = true, treesitter = true, which_key = true },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
