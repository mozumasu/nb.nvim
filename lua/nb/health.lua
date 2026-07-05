local M = {}

function M.check()
  local health = vim.health

  health.start("nb.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    health.ok("Neovim >= 0.10")
  else
    health.error("Neovim >= 0.10 is required (vim.uv / vim.system)")
  end

  if vim.fn.executable("nb") == 1 then
    local result = vim.system({ "nb", "--version" }, { text = true, timeout = 5000 }):wait()
    local version = result.code == 0 and vim.trim(result.stdout) or "unknown version"
    health.ok("nb CLI found (" .. version .. ")")
  else
    health.error("nb CLI not found", "Install nb: https://github.com/xwmx/nb#installation")
  end

  if vim.fn.executable("git") == 1 then
    health.ok("git found")
  else
    health.error("git not found (required for commit & sync)")
  end

  local dir = require("nb.config").dir()
  if vim.uv.fs_stat(dir) then
    health.ok("data directory: " .. dir)
  else
    health.warn(
      "data directory not found: " .. dir,
      "Set opts.dir, $NB_DIR, or create ~/.nb (e.g. by running `nb` once)"
    )
  end

  if pcall(require, "snacks") then
    health.ok("snacks.nvim found")
  else
    health.error("snacks.nvim not found (required for pickers)", "https://github.com/folke/snacks.nvim")
  end

  if pcall(require, "img-clip.clipboard") then
    health.ok("img-clip.nvim found (clipboard image import enabled)")
  else
    health.warn("img-clip.nvim not found (optional: clipboard image import is disabled)")
  end
end

return M
