local utils = require'tex.utils'
local config = require'tex.config'

local M = {}

M.state = {
  index = nil,
  engine = nil,
  jobid = nil,
  viewer_jobid = nil,
  watchlist = {}
}

-- local vim_events = {'BufFilePost', 'InsertChange', 'InsertLeave', 'TextChanged', 'TextChangedI', 'BufReadPost', 'BufWritePost'}


-- Enable autocommands
-- @return nil
local function autocommands()

  if #M.opts.compile.events == 0 then
    return
  end

  local events = table.concat(M.opts.compile.events, ',')

  local autocmd = ('autocmd %s <buffer=%d> lua require"tex".compile()')

  vim.cmd [[augroup texcompile]]
  vim.cmd [[autocmd!]]

  if M.state.index ~= nil then
    vim.cmd(autocmd:format(events, utils.buffer_id(M.state.index)))
  end

  if M.opts.compile.watchlist and #M.state.watchlist > 0 then
    for _, value in ipairs(M.state.watchlist) do
      vim.cmd(autocmd:format(events, utils.buffer_id(value)))
    end
  end

  vim.cmd [[augroup END]]

end

-- Remove file from watch list
-- @param value: string
--  string is file name
--  @return nil
local function watch_remove(value)
  for index, v in ipairs(M.state.watchlist) do
    if value == v then
      table.remove(M.state.watchlist, index)
      break
    end
  end
  autocommands()
end

-- Add file to watch list
-- @param value: string
--  string if file name.
--  @return nil
local function watch_add(value)
  if not vim.tbl_contains(M.state.watchlist, value) then
    table.insert(M.state.watchlist, value)
  end
  autocommands()
end


M.completion = {
  engines = function ()
    return vim.tbl_keys(config.engines)
  end,
  watchlist_remove = function ()
    return M.state.watchlist
  end,
  watchlist_add = function ()
    return vim.tbl_filter(function (file)
      return file ~= M.state.index and not vim.tbl_contains(M.state.watchlist, file)
    end, utils.files_get_files({'tex', 'bib'}))
  end,
  tex_files = function ()
    return utils.files_get_files({'tex'})
  end
}

-- Setup Tex
-- @param user_opts: table
--  user_opts.engine (string): tex engine name
--  user_opts.viewer (string): pdf viewer
--  @return nil
function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', {}, config, opts or {})
  M.state.engine = M.opts.engine

  vim.cmd [[
    command! -nargs=? -complete=customlist,v:lua.require'tex'.completion.tex_files TexCompile lua require'tex'.compile('<f-args>')
    command! -nargs=? -complete=customlist,v:lua.require'tex'.completion.tex_files TexSwitchIndex lua require'tex'.switch_index('<f-args>')
    command! -nargs=1 -complete=customlist,v:lua.require'tex'.completion.engines TexSwitchEngine lua require'tex'.switch_engine('<f-args>')
    command! -nargs=? -complete=customlist,v:lua.require'tex'.completion.watchlist_add TexAdd lua require'tex'.add_to_watchlist('<f-args>')
    command! -nargs=? -complete=customlist,v:lua.require'tex'.completion.watchlist_remove TexRemove lua require'tex'.remove_from_watchlist('<f-args>')
    command! -nargs=? -complete=file TexViewer lua require'tex'.viewer('<f-args>')
    command! TexWatching lua require'tex'.watching()
    command! TexCurrentIndex lua print(require'tex'.state.index)
  ]]

end


-- Print the watch list
-- @return nil
function M.watching()
  return utils.echo(table.concat(M.state.watchlist, ', '))
end

-- Switch Index File
-- @param input: string
--  string is a file path
--  if input is nil or a empty string then get current buffer
--  @return nil
function M.switch_index(input)

  local _, index = utils.input_name(input, 1)

  if not utils.file_is_valid(index, {'tex'}) then
    utils.echo('Invalid filetype', 'Error')
    return
  end

  -- remove the new index file from watchlist
  if vim.tbl_contains(M.state.watchlist, index) then
    watch_remove(index)
  end

  M.state.index = index
  utils.echo(M.state.index .. ' is index file', 'Title')

  autocommands()
end

-- Switch Tex Engine
-- @param engine: string, tex engine name
-- @return nil
function M.switch_engine(engine)

  local engines = vim.tbl_keys(config.engines)

  local new_engine = engine:gsub('\"', '')

  if not vim.tbl_contains(engines, new_engine) then
    utils.echo('Invalid engine. Available engines: ' .. table.concat(engines, ', '), 'Error')
    return
  end
  M.state.engine = new_engine
  utils.echo('Engine now is ' .. M.state.engine, 'Title')
end

-- Add to Watch List
-- @param input: string
--  string is a file path
--  if input is nil or a empty string then get current buffer
--  @return nil
function M.add_to_watchlist(input)

  local one_file, add = utils.input_name(input)

  if one_file then
    watch_add(add)
    return
  end

  local valid_files = vim.tbl_filter(function (file)
    return utils.file_is_valid(file, {'tex', 'bib'}) and not vim.tbl_contains(M.state.watchlist, file)
  end, add)

  -- if not vim.tbl_contains({'tex', 'bib'}, vim.api.nvim_buf_get_option(0, 'filetype')) then
  --   vim.api.nvim_err_writeln('Select a tex or bib file type')
  --   return
  -- end

  -- local bufnr = vim.api.nvim_get_current_buf()

  if vim.tbl_contains(valid_files, M.state.index) then
    utils.echo(M.state.index .. ' is the index file')
  end


  -- if M.state.index == bufnr then
  --   echo(vim.api.nvim_buf_get_name(bufnr) .. ' is the current index', 'Error')
  --   return
  -- end

  -- if vim.tbl_contains(M.state.watchlist, bufnr) then
    -- return
  -- end

  -- table.insert(M.state.watchlist, valid_files)
  --
  for _, file in ipairs(valid_files) do
    watch_add(file)
  end
end

-- Remove file from watch list
-- @param input: string or nil
--  if string is empty or nil the get current buffer
-- @preturn nil
function M.remove_from_watchlist(input)

  local one_file, remove = utils.input_name(input)

  if one_file then
    watch_remove(remove)
    return
  end

  for _, file in ipairs(remove) do
    watch_remove(file)
  end

  -- local bufnr = buffer_id ~= nil and vim.api.nvim_get_current_buf() or buffer_id



  -- if not vim.tbl_contains(M.state.watchlist, bufnr) then
    -- return
  -- end



  -- local pos = nil

  -- for index, value in ipairs(M.state.watchlist) do
  --   if value == bufnr then
  --     pos = index
  --     break
  --   end
  -- end



  -- echo(vim.api.nvim_buf_get_name(bufnr) .. ' removed from wacth list', 'Title')
  -- autocommands()
end

--- Build Command
-- @param file: string, file path
-- @return tuple, command and directory
local function build_command(file)
  local o = { M.state.engine }

  local engine_opts = config.engines[M.state.engine]

  if engine_opts.args ~= nil then
    for key, value in pairs(engine_opts.args) do
      local named = type(key) ~= 'number'
      table.insert(o, named and string.format('%s=%s', key, value) or value)
    end
  end

  table.insert(o, file)

  local cwd = vim.fn.fnamemodify(file, ':p:h'):gsub('\"', '')

  return table.concat(o, ' '), cwd
end

-- Compile Tex file
-- @param input: string or nil
--  if string is empty or nil then get current buffer
-- @return nll
function M.compile(input)

  local empty_input = (input == nil or (type(input) == 'string' and input:len() == 0))

  local _, entrypoint = utils.input_name(input, 1)
  local file_compile = empty_input and M.state.index or entrypoint

  if not utils.file_is_valid(file_compile, {'tex'}) then
    utils.echo('Compile only tex files', 'Error')
    return
  end


  -- local is_file = file ~= nil and string.len(file) > 0
  -- local input = is_file and file or vim.api.nvim_buf_get_name(0)

  -- if M.state.index ~= nil and not vim.api.nvim_buf_is_valid(M.state.index) then
  --   echo('Buffer not valid. Set index file with :TexSwitchIndex', 'Error')
  --   return
  -- end

  -- local filetype = is_file and vim.fn.fnamemodify(input, ':e'):gsub('\"', '') or vim.api.nvim_buf_get_option(input, 'filetype')

  -- if not vim.tbl_contains({'tex'}, filetype) then
  --   vim.api.nvim_err_writeln('Invalid filetype')
  --   return
  -- end

  -- local file = M.state.index == nil and input or vim.api.nvim_buf_get_name(M.state.index)
  local cmd, cwd = build_command(file_compile)

  M.state.jobid = vim.fn.jobstart(cmd, {
    cwd = cwd,
    on_stdout = function (_, out)
      print(table.concat(out))
    end,
    on_exit = function (id, exit_code, _)
      if exit_code == 0 then
        utils.echo('Finished ' .. file_compile, 'Title')
      else
        utils.echo('Failed ' .. file_compile, 'ErrorMsg')
      end
      M.kill()
    end
  })
end

-- Kill Compile Job
-- @return nil
function M.kill()
  if M.state.jobid ~= nil then
    vim.fn.jobstop(M.state.jobid)
    M.state.jobid = nil
  end
end

-- Open PDF viewer
-- @param input: string or nil
-- @return nil
function M.viewer(input)

  if M.opts.viewer == nil then
    utils.echo('viewer option not configured', 'Error')
    return
  end

  if vim.fn.executable(M.opts.viewer) == 0 then
    utils.echo(M.opts.viewer .. ' is not executable', 'Error')
    return
  end


  local empty_input = (input == nil or (type(input) == 'string' and input:len() == 0))

  local _, entrypoint = utils.input_name(input, 1)
  local file_open = empty_input and M.state.index or entrypoint


  -- if M.state.index == nil or not vim.api.nvim_buf_is_valid(M.state.index) then
  --   echo('Index file not found. Use :TexSwitchIndex', 'Error')
  --   return
  -- end

  -- if viewer is open then make nothing
  if M.state.viewer_jobid ~= nil then
    return
  end

  local pdf = vim.fn.fnamemodify(file_open, ':r') .. '.pdf'

  if vim.fn.filereadable(pdf) == 0 then
    utils.echo(pdf .. ' no exists', 'Error')
    return
  end

  M.state.viewer_jobid = vim.fn.jobstart(M.opts.viewer .. ' ' .. pdf, {
    on_exit = function()
      vim.fn.jobstop(M.state.viewer_jobid)
      M.state.viewer_jobid = nil
    end
  })

end

return M
