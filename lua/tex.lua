local M = {}

M.state = {
  index = nil,
  engine = nil,
  jobid = nil,
  viewer_job_id = nil,
  watchlist = {}
}

M.engines = {'pdflatex', 'xelatex', 'latexmk', 'lualatex', 'tectonic'}


-- local vim_events = {'BufFilePost', 'InsertChange', 'InsertLeave', 'TextChanged', 'TextChangedI', 'BufReadPost', 'BufWritePost'}


local default_opts = {
  engine = 'latexmk',
  compile = {
    events = { 'BufWritePost' },
    watchlist = true
  },
  viewer = nil,
  engines = {
    tectonic = {},
    latexmk = {
      args = {
        '-pdf', -- generate pdf
        ['-interaction'] = 'nonstopmode'
      }
    },
    pdflatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    },
    xelatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    },
    lualatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    }
  }
}

local function echo(msm, hl)
  return vim.api.nvim_echo({{ msm, hl or "" }}, false, {})
end

local function autocommands()

  if #M.opts.compile.events == 0 then
    return
  end

  local events = table.concat(M.opts.compile.events, ',')

  local autocmd = ('autocmd %s <buffer=%d> lua require"tex".compile()')

  vim.cmd [[augroup texcompile]]
  vim.cmd [[autocmd!]]

  vim.cmd(autocmd:format(events, M.state.index))

  if M.opts.compile.watchlist and #M.state.watchlist > 0 then
    for _, value in ipairs(M.state.watchlist) do
      vim.cmd(autocmd:format(events, value))
    end
  end

  vim.cmd [[augroup END]]

end

function M.setup(user_opts)
  M.opts = vim.tbl_deep_extend('force', {}, default_opts, user_opts or {})
  M.state.engine = M.opts.engine

  vim.cmd [[
    command! -nargs=? -complete=file TexCompile lua require'tex'.compile('<f-args>')
    command! TexSwitchIndex lua require'tex'.switch_index()
    command! -nargs=+ TexSwitchEngine lua require'tex'.switch_engine('<args>')
    command! TexAdd lua require'tex'.add_to_watchlist()
    command! TexRemove lua require'tex'.remove_from_watchlist()
    command! TexViewer lua require'tex'.viewer()
  ]]

end

function M.switch_index()
  if vim.api.nvim_buf_get_option(0, 'filetype') ~= 'tex' then
    vim.api.nvim_err_writeln('Select a tex file type')
    return
  end
  M.state.index = vim.api.nvim_get_current_buf()
  echo(vim.api.nvim_buf_get_name(M.state.index) .. ' is index file', 'Title')
  autocommands()
end

function M.switch_engine(engine)
  if not vim.tbl_contains(M.engines, engine) then
    vim.api.nvim_err_writeln('Invalid engine. Available engines: ' .. table.concat(M.engines, ', '))
    return
  end
  M.state.engine = engine
  echo('Engine now is ' .. engine, 'Title')
end

function M.add_to_watchlist()
  if not vim.tbl_contains({'tex', 'bib'}, vim.api.nvim_buf_get_option(0, 'filetype')) then
    vim.api.nvim_err_writeln('Select a tex or bib file type')
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if M.state.index == bufnr then
    echo(vim.api.nvim_buf_get_name(bufnr) .. ' is the current index', 'Error')
    return
  end

  if vim.tbl_contains(M.state.watchlist, bufnr) then
    return
  end

  table.insert(M.state.watchlist, vim.api.nvim_get_current_buf())
  echo(vim.api.nvim_buf_get_name(0) .. ' add to wachlist', 'Title')
  autocommands()
end

function M.remove_from_watchlist()

  local bufnr = vim.api.nvim_get_current_buf()

  if not vim.tbl_contains(M.state.watchlist, bufnr) then
    return
  end

  local pos = nil

  for index, value in ipairs(M.state.watchlist) do
    if value == bufnr then
      pos = index
      break
    end
  end

  table.remove(M.state.watchlist, pos)
  echo(vim.api.nvim_buf_get_name(bufnr) .. ' removed from wacth list', 'Title')
  autocommands()
end

local function build_cmd(file)

  local o = { M.state.engine }

  local engine_opts = M.opts.engines[M.state.engine]

  if engine_opts.args ~= nil then
    for key, value in pairs(engine_opts.args) do
      local named = type(key) ~= 'number'
      table.insert(o, named and string.format('%s=%s', key, value) or value)
    end
  end

  table.insert(o, file)

  return table.concat(o, " ")
end

function M.compile(file)

  local is_file = file ~= nil and string.len(file) > 0
  local input = is_file and file or vim.api.nvim_buf_get_name(0)

  if M.state.index ~= nil and not vim.api.nvim_buf_is_valid(M.state.index) then
    echo('Buffer not valid. Set index file with :TexSwitchIndex', 'Error')
    return
  end

  local filetype = is_file and vim.fn.fnamemodify(input, ':e'):gsub('\"', '') or vim.api.nvim_buf_get_option(input, 'filetype')

  if not vim.tbl_contains({'tex'}, filetype) then
    vim.api.nvim_err_writeln('Invalid filetype')
    return
  end

  local main_tex_file = M.state.index == nil and input or vim.api.nvim_buf_get_name(M.state.index)

  local cmd = build_cmd(main_tex_file)
  local cwd = vim.fn.fnamemodify(main_tex_file, ':p:h'):gsub('\"', '')

  M.state.jobid = vim.fn.jobstart(cmd, {
    cwd = cwd,
    on_stdout = function (_, out)
      print(table.concat(out))
    end,
    on_exit = function (id, exit_code, _)
      if exit_code == 0 then
        echo("Finished", "Title")
      else
        echo("Failed", "ErrorMsg")
      end
      M.kill()
    end
  })
end

function M.kill()
  if M.state.jobid ~= nil then
    vim.fn.jobstop(M.state.jobid)
    M.state.jobid = nil
  end
end

function M.viewer()

  if M.opts.viewer == nil then
    return
  end

  if vim.fn.executable(M.opts.viewer) == 0 then
    echo(M.opts.viewer .. ' is not executable', 'Error')
    return
  end

  if M.state.index == nil or not vim.api.nvim_buf_is_valid(M.state.index) then
    echo('Index file not found. Use :TexSwitchIndex', 'Error')
    return
  end

  -- running
  if M.state.viewer_job_id ~= nil then
    return
  end

  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(M.state.index), ':r') .. '.pdf'

  if vim.fn.filereadable(file) == 0 then
    echo(file .. ' no exists', 'Error')
    return
  end

  M.state.viewer = vim.fn.jobstart(M.opts.viewer .. ' ' .. file, {
    on_exit = function()
      vim.fn.jobstop(M.state.viewer)
      M.state.viewer_job_id = nil
    end
  })

end

return M
