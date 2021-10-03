local M = {}

-- Split string
-- @param pString: string
-- @param pPattern: string, pattern
-- @return table
-- from https://stackoverflow.com/a/60172017/11439260
function M.string_split(pString, pPattern)
  local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
    end
    last_end = e+1
    s, e, cap = pString:find(fpat, last_end)
  end
  if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
  end
  return vim.tbl_map(function (t)
    return t:gsub('\"', '')
  end, Table)
end

-- @param file, string
-- @param type, table
-- @return boolean
function M.file_is_valid(file, type)
  local extension = vim.fn.fnamemodify(file, ':e')
  return vim.tbl_contains(type, extension)
end

-- Get Input Name
-- @param input: string or nil
--  if string is empty or nil and get current buffer name
-- @param n: number
-- @return tuble, boolean if is a single file and string or table
function M.input_name(input, n)

  if input == nil or (type(input) == 'string' and input:len() == 0) then
    return true, vim.api.nvim_buf_get_name(0)
  end

  local inputs = M.string_split(input, '%s')

  if n ~= nil then
    return true, inputs[n]
  end

  return false, inputs

end

-- Echo
-- @param msm: string
-- @param hl: string
-- @return nil
function M.echo(msm, hl)
  return vim.api.nvim_echo({{ msm, hl or '' }}, false, {})
end

-- Get Buffer ID
-- @param name: string
-- @return number
function M.buffer_id(name)
  local buffers = vim.tbl_filter(function (buffer)
    return vim.api.nvim_buf_get_name(buffer) == name
  end, vim.api.nvim_list_bufs())

  if #buffers == 0 then
    error('buffer id ' .. name .. ' not found')
  end

  return buffers[1]
end

-- Get files by type
-- @param types: table
-- @return array
function M.files_get_files(types)
  local valid_files = vim.tbl_filter(function (buffer)
    return M.file_is_valid(vim.api.nvim_buf_get_name(buffer), types)
    -- return vim.tbl_contains(types, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buffer_id), ':e'))
  end, vim.api.nvim_list_bufs())

  return vim.tbl_map(function(buffer)
    return vim.api.nvim_buf_get_name(buffer)
  end, valid_files)
end

return M
