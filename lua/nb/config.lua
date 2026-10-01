local M = {}

M.defaults = {
  -- nb のデータディレクトリ（nil なら $NB_DIR → `nb env` の NB_DIR → ~/.nb の順で解決）
  dir = nil,
  -- `nb browse` のポート番号（別 notebook の画像リンク生成・解決に使用）
  browse_port = 6789,
  -- 保存したノートをバッファを閉じたときに自動コミット & リモート同期
  autosync = true,
  -- 新規ノートのファイル名に使うタイムスタンプ形式
  timestamp_format = "%Y%m%d%H%M%S",
  -- Marksman の診断から [[notebook:name]] リンクへの誤検知を除外する
  marksman_filter = true,
  -- picker のカスタムプレビュー関数 function(ctx) （nil なら snacks のファイルプレビュー）
  preview = nil,
}

M.options = vim.deepcopy(M.defaults)

-- `nb env` から解決した NB_DIR のキャッシュ（false は解決失敗）
local nb_env_dir = nil

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  nb_env_dir = nil
end

-- nb 本体が実際に使う NB_DIR を取得する
-- NB_DIR を ~/.nbrc の中で設定している場合、Neovim の環境変数には現れないため nb に問い合わせる
local function dir_from_nb()
  if nb_env_dir == nil then
    nb_env_dir = false
    if vim.fn.executable("nb") == 1 then
      local ok, result = pcall(function()
        return vim.system({ "nb", "env" }, { text = true, timeout = 5000 }):wait()
      end)
      if ok and result.code == 0 and result.stdout then
        local dir = ("\n" .. result.stdout):match("\nNB_DIR=([^\n]*)")
        if dir and dir ~= "" then
          nb_env_dir = dir
        end
      end
    end
  end
  return nb_env_dir or nil
end

function M.dir()
  local dir = M.options.dir or vim.env.NB_DIR or dir_from_nb() or "~/.nb"
  return (vim.fn.expand(dir):gsub("/$", ""))
end

return M
