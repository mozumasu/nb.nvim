-- [[notebook:name]] 形式の wiki リンクの解決と、Marksman の誤検知フィルタ
local M = {}

-- カーソル下の [[notebook:name]] リンクを返す（リンク上にカーソルがなければ nil）
-- コロンを含むリンクのみ対象（通常の [[wiki-link]] は Marksman 等に任せる）
function M.link_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local search_start = 1
  while true do
    local start_pos, end_pos, link = line:find("%[%[([^%]]+:[^%]]+)%]%]", search_start)
    if not start_pos then
      return nil
    end
    if col >= start_pos and col <= end_pos then
      return link
    end
    search_start = end_pos + 1
  end
end

-- カーソル下の nb リンク先ノートを開く
-- 戻り値: カーソルが nb リンク上にあれば true（解決失敗時は警告表示のうえ true）、
-- リンク上になければ false。false のときのフォールバック（LSP definition 等）は呼び出し側で選ぶ
function M.follow_link()
  local link = M.link_at_cursor()
  if not link then
    return false
  end
  local path = require("nb.core").get_note_path(link)
  if not path or path == "" then
    vim.notify("nb: note not found: " .. link, vim.log.levels.WARN)
    return true
  end
  vim.cmd.edit(path)
  return true
end

-- nb リンク（notebook:note）への「Link to non-existent document」警告を除外する
local function drop_nb_link_diagnostics(diagnostics)
  return vim.tbl_filter(function(diagnostic)
    local msg = diagnostic.message or ""
    return not msg:match("Link to non%-existent document '[%w_%-]+:")
  end, diagnostics)
end

-- ラップ済み client id の記録（バッファごとの LspAttach で二重ラップしない）
local wrapped_clients = {}

-- Marksman の診断から nb リンクへの誤検知を除外するフィルタを有効化する
-- ハンドラ差し替えは marksman client に限定し、他の LSP には影響しない
function M.enable_marksman_filter()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("nb_marksman_filter", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= "marksman" or wrapped_clients[client.id] then
        return
      end
      wrapped_clients[client.id] = true
      local original = client.handlers["textDocument/publishDiagnostics"]
        or vim.lsp.handlers["textDocument/publishDiagnostics"]
      client.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, cfg)
        if result and result.diagnostics then
          result.diagnostics = drop_nb_link_diagnostics(result.diagnostics)
        end
        return original(err, result, ctx, cfg)
      end
    end,
  })
end

return M
