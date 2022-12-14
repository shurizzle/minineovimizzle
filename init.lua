-- Directory setup {{{
_G.INIT_DIR = vim.fn.fnamemodify(
  vim.loop.fs_realpath(({ debug.getinfo(1,"S").source:gsub('^@', '') })[1]),
  ':h'
)

if not vim.tbl_contains(vim.opt.rtp:get(), INIT_DIR) then
  vim.opt.rtp:append(INIT_DIR)
end
-- }}}

-- Basic util {{{
_G.PATH_SEPARATOR = vim.loop.os_uname().sysname:match('Windows') and '\\' or '/'

function _G.join_paths(...)
  return table.concat({ ... }, _G.PATH_SEPARATOR)
end

function _G.has(what)
  return vim.fn.has(what) ~= 0
end

function _G.executable(what)
  return vim.fn.executable(what) ~= 0
end

function _G.ssh_remote()
  local function extract(env)
    if env then
      local i = env:find('%s')

      if i then
        local remote = require('ip').parse(env:sub(0, i - 1))
        if remote then
          return remote
        end
      end
    end
  end

  local function coalesce_map(map, ...)
    for _, name in ipairs({ ... }) do
      local res = map(name)
      if res then
        return res
      end
    end
  end

  local res = coalesce_map(function(name)
    return extract(vim.loop.os_getenv(name))
  end, 'SSH_CLIENT', 'SSH_CONNECTION')

  ---@diagnostic disable-next-line
  _G.ssh_remote = loadstring('return ' .. vim.inspect(res))
  return res
end

function _G.is_ssh()
  return _G.ssh_remote() ~= nil
end
-- }}}

-- Options {{{
vim.g.mapleader = ','
vim.g.maplocalleader = ','

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.autoread = true
vim.opt.mouse = 'a'
vim.opt.smartindent = true
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.list = true
vim.opt.listchars = {
  tab = ' ·',
  trail = '×',
  nbsp = '%',
  eol = '·',
  extends = '»',
  precedes = '«',
}
vim.opt.laststatus = 3
vim.opt.shortmess:append('c')
vim.opt.fillchars:append('eob: ')
vim.opt.colorcolumn = '80'
vim.opt.showmode = false
vim.opt.foldmethod = 'marker'
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0

if has('termguicolors') then
  vim.opt.termguicolors = true
end
-- }}}

-- Statusline {{{
vim.opt.statusline = "%{%v:lua.Mode.status()%} %f %h%w%m%r%=%{&ft} :%l:%v/%L %P"

-- Mode {{{
_G.Mode = {
  map = {
    ['n']      = 'NORMAL',
    ['no']     = 'O-PENDING',
    ['nov']    = 'O-PENDING',
    ['noV']    = 'O-PENDING',
    ['no\22']  = 'O-PENDING',
    ['niI']    = 'NORMAL',
    ['niR']    = 'NORMAL',
    ['niV']    = 'NORMAL',
    ['nt']     = 'NORMAL',
    ['ntT']    = 'NORMAL',
    ['v']      = 'VISUAL',
    ['vs']     = 'VISUAL',
    ['V']      = 'V-LINE',
    ['Vs']     = 'V-LINE',
    ['\22']    = 'V-BLOCK',
    ['\22s']   = 'V-BLOCK',
    ['s']      = 'SELECT',
    ['S']      = 'S-LINE',
    ['\19']    = 'S-BLOCK',
    ['i']      = 'INSERT',
    ['ic']     = 'INSERT',
    ['ix']     = 'INSERT',
    ['R']      = 'REPLACE',
    ['Rc']     = 'REPLACE',
    ['Rx']     = 'REPLACE',
    ['Rv']     = 'V-REPLACE',
    ['Rvc']    = 'V-REPLACE',
    ['Rvx']    = 'V-REPLACE',
    ['c']      = 'COMMAND',
    ['cv']     = 'EX',
    ['ce']     = 'EX',
    ['r']      = 'REPLACE',
    ['rm']     = 'MORE',
    ['r?']     = 'CONFIRM',
    ['!']      = 'SHELL',
    ['t']      = 'TERMINAL',
  },
  colors = {
    ['NORMAL']    = { fg = '#000000', bg = '#ffffff' },
    ['O-PENDING'] = 'Normal',
    ['VISUAL']    = { fg = '#000000', bg = '#ffff99' },
    ['V-LINE']    = 'Visual',
    ['V-BLOCK']   = 'Visual',
    ['INSERT']    = { fg = '#000000', bg = '#d7e8d2' },
    ['REPLACE']   = { fg = '#000000', bg = '#fa979a' },
    ['V-REPLACE'] = 'Replace',
    ['SELECT']    = 'Replace',
    ['S-LINE']    = 'Select',
    ['S-BLOCK']   = 'Select',
    ['COMMAND']   = 'Insert',
    ['EX']        = 'Insert',
    ['MORE']      = 'Insert',
    ['CONFIRM']   = 'Replace',
    ['SHELL']     = 'Replace',
    ['TERMINAL']  = 'Insert',
  },
  status = function()
    local mode = _G.Mode.map[vim.fn.mode()] or 'NORMAL'
    return '%#' .. _G.Mode.colors[mode] .. '# ' .. mode .. ' %*'
  end,
}

-- Colors setup {{{
;(function()
  local colors = {}

  for _, key in ipairs(vim.tbl_keys(_G.Mode.colors)) do
    local v = _G.Mode.colors[key]
    local k = key:lower():gsub('-', '')
    k = 'SBM' .. k:sub(1, 1):upper() .. k:sub(2)
    if type(v) == 'table' then
      v = vim.tbl_extend('error', v, { bold = true })
    else
      v = { link = 'SBM' .. v }
    end
    v.default = true

    vim.api.nvim_set_hl(0, k, v)
    _G.Mode.colors[key] = k
    colors[k] = v
  end

  local group = vim.api.nvim_create_augroup(
    'set_mode_highlight_colors',
    { clear = true }
  )
  vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
    group = group,
    callback = function()
      for k, v in pairs(colors) do
        vim.api.nvim_set_hl(0, k, v)
      end
    end,
  })
end)()
-- }}}
-- }}}
-- }}}

-- Colorscheme {{{
vim.cmd('colorscheme bluesky')
-- }}}

-- Disable some not-so-vim-like keymaps {{{
for name, key in pairs({
  'Left',
  'Right',
  'Up',
  'Down',
  'PageUp',
  'PageDown',
  'End',
  'Home',
  Delete = 'Del',
}) do
  if type(name) == 'number' then
    name = key
  end

  local keymap = function(modes, left, right, options)
    options =
      vim.tbl_extend('force', { noremap = true, silent = true }, options or {})
    vim.keymap.set(modes, left, right, options)
  end

  keymap(
    'n',
    '<' .. key .. '>',
    '<cmd>echo "No ' .. name .. ' for you!"<CR>',
    { noremap = false }
  )
  keymap(
    'v',
    '<' .. key .. '>',
    '<cmd><C-u>echo "No ' .. name .. ' for you!"<CR>',
    { noremap = false }
  )
  keymap(
    'i',
    '<' .. key .. '>',
    '<C-o><cmd>echo "No ' .. name .. ' for you!"<CR>',
    { noremap = false }
  )
end
-- }}}

-- function buf_kill() {{{
local function buf_kill(range, behaviour, wipeout)
  local function buf_needs_deletion(bufnr, wipeout)
      if wipeout then
          return vim.api.nvim_buf_is_valid(bufnr)
      else
          return vim.api.nvim_buf_is_loaded(bufnr)
      end
  end

  if range == nil or range == 0 then
    range = 0
  end

  if type(range) == 'number' then
    range = { range, range }
  end

  if range[1] == 0 then
    range[1] = vim.api.nvim_get_current_buf()
    range[2] = range[1]
  end

  behaviour = behaviour or 'interactive'

  vim.validate({
    range = { range, 't' },
    ['range[1]'] = { range[1], 'n' },
    ['range[2]'] = { range[2], 'n' },
    behaviour = { behaviour, function(v)
      return v == 'interactive' or v == 'force' or v == 'save'
    end, "valid values are 'interactive', 'force', 'save'" },
    wipeout = { wipeout, 'b' },
  })

  local function cmd(str)
    local ok, err = pcall(vim.api.nvim_command, str)
    if not ok then
      vim.api.nvim_echo({ { err, 'ErrorMsg' } }, true, {})
    end
    return ok
  end

  local target_buffers = {}
  for bufnr=range[1], range[2] do
    if buf_needs_deletion(bufnr, wipeout) then
      target_buffers[bufnr] = true
    end
  end

  if behaviour ~= 'force' then
    for bufnr, _ in pairs(target_buffers) do
      if vim.bo[bufnr].modified then
        if behaviour == 'interactive' then
          vim.api.nvim_echo({{
            string.format(
              'No write since last change for buffer %d (%s). Would you like to:\n' ..
              '(s)ave and close\n(i)gnore changes and close\n(c)ancel',
              bufnr, vim.api.nvim_buf_get_name(bufnr)
            )
          }}, false, {})

          local choice = string.char(vim.fn.getchar())

          if choice == 's' or choice == 'S' then  -- Save changes to the buffer.
            if not vim.api.nvim_buf_call(bufnr, function() return cmd('write') end) then
              return
            end
          elseif choice == 'c' or choice == 'C' then  -- Cancel, remove buffer from targets.
            target_buffers[bufnr] = nil
          else
            vim.api.nvim_err_writeln("Invalid choice")
            return
          end

          cmd('echo')
          cmd('redraw')
        else
          if not vim.api.nvim_buf_call(bufnr, function() return cmd('update') end) then
            return
          end
        end
      end
    end
  end

  if next(target_buffers) == nil then
    api.nvim_err_writeln("bufdelete.nvim: No buffers were deleted")
    return
  end

  local windows = vim.tbl_filter(
      function(win)
          return target_buffers[vim.api.nvim_win_get_buf(win)] ~= nil
      end,
      vim.api.nvim_list_wins()
  )

  local buffers_outside_range = vim.tbl_filter(
    function(buf)
      return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
        and (buf < range[1] or buf > range[2])
    end,
    vim.api.nvim_list_bufs()
  )

  local switch_bufnr
  if #buffers_outside_range > 0 then
    local buffer_before_range
    for _, v in ipairs(buffers_outside_range) do
      if v < range[1] then
        buffer_before_range = v
      end
      if v > range[2] then
        switch_bufnr = v
        break
      end
    end
    if switch_bufnr == nil then
      switch_bufnr = buffer_before_range
    end
  else
    switch_bufnr = vim.api.nvim_create_buf(true, false)

    if switch_bufnr == 0 then
      vim.api.nvim_err_writeln("bufdelete.nvim: Failed to create buffer")
    end
  end

  for _, win in ipairs(windows) do
    vim.api.nvim_win_set_buf(win, switch_bufnr)
  end

  for bufnr, _ in pairs(target_buffers) do
    if buf_needs_deletion(bufnr, wipeout) then
      local bang = ''
      if behaviour == 'force' or vim.bo[bufnr].modified then
        bang = '!'
      end

      if not cmd(bufnr .. (wipeout and 'bwipeout' or 'bdelete') .. bang) then
        return
      end
    end
  end
end
-- }}}

-- Keymaps {{{
for k, v in pairs({
  -- Reselect visual selection after indenting
  ['<'] = { '<gv', 'Indent back' },
  ['>'] = { '>gv', 'Indent' },
  -- Maintain the cursor position when yanking a visual selection
  -- http://ddrscott.github.io/blog/2016/yank-without-jank/
  ['y'] = { 'myy`y', 'yank text' },
  ['Y'] = { 'myY`y', 'yank text until the end of the line' },
  -- Paste replace visual selection without copying it
  ['<leader>p'] = { '"_dP', 'Replace visual selection' },
  -- Replace visual selection without copying it
  ['<leader>c'] = { '"_c', 'Replace visual selection' },
  -- Search for text in visual selection
  ['*'] = {
    '"zy/\\<\\V<C-r>=escape(@z, \'/\\\')<CR>\\><CR>',
    'Search for selected text',
  },
}) do
  vim.keymap.set('v', k, v[1], { silent = true, noremap = true, desc = v[2] })
end

vim.cmd([[
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! SynGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun
nnoremap gm <cmd>call SynGroup()<CR>
]])

vim.cmd('autocmd BufWritePre * :%s/\\s\\+$//e')

for k, v in pairs({
  -- Make Y behave like the other capitals
  Y         = { 'y$', 'Yank untill the end of the line' },
  ['<C-h>'] = { '<cmd>wincmd h<CR>' },
  ['<C-j>'] = { '<cmd>wincmd j<CR>' },
  ['<C-k>'] = { '<cmd>wincmd k<CR>' },
  ['<C-l>'] = { '<cmd>wincmd l<CR>' },
  ['<C-n>'] = { '<cmd>bnext<CR>' },
  ['<C-p>'] = { '<cmd>bprevious<CR>' },
  ZZ        = {
    function() buf_kill(0, 'save', true) end,
    'Close current buffer',
  },
  ZQ        = {
    function() buf_kill(0, 'force', true) end,
    'Close current buffer without saving',
  },
}) do
  vim.keymap.set('n', k, v[1], { silent = true, noremap = true, desc = v[2] })
end
-- }}}

-- Bootstrap {{{
;(function()
  local function git_clone(url, dir, callback)
    local install_path =
      join_paths(vim.fn.stdpath('data'), 'site', 'pack', 'packer', 'start', dir)

    if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
      vim.fn.system({
        'git',
        'clone',
        '--depth',
        '1',
        url,
        install_path,
      })
      callback(vim.v.shell_error)
    end
  end

  git_clone(
    'https://github.com/lewis6991/impatient.nvim',
    'impatient.nvim',
    function(res) if res == 0 then vim.cmd([[packadd impatient.nvim]]) end end
  )

  xpcall(
    function() require('impatient') end,
    function(_)
      vim.api.nvim_echo(
        { { 'Error while loading impatient', 'ErrorMsg' } },
        true, {}
      )
    end
  )

  git_clone(
    'https://github.com/wbthomason/packer.nvim',
    'packer.nvim',
    function(res)
      if res == 0 then
        vim.g.packer_bootstrap = true
        vim.cmd([[packadd packer.nvim]])
      end
    end
  )
end)()
-- }}}

-- Packer config {{{
;(function()
  local status_ok, packer = pcall(require, 'packer')
  if not status_ok then
    return
  end

  local compiled = join_paths(vim.fn.stdpath('data'), 'packer_compiled.lua')

  local after_load = nil
  local loaded = false
  local function _after_load()
    if not loaded then
      loaded = true
      if after_load then after_load() end
    end
  end

  packer.on_complete = vim.schedule_wrap(function()
    _after_load()
    vim.cmd([[doautocmd User PackerComplete]])
  end)

  packer.init({
    compile_path = compiled,
    display = {
      open_fn = function()
        return require('packer.util').float({ border = 'rounded' })
      end,
    },
  })

  packer.reset()
  packer.use({
    { 'wbthomason/packer.nvim' },
    { 'lewis6991/impatient.nvim' },
    { 'nvim-lua/plenary.nvim',
      module_pattern = {
        '^plenary$',
        '^plenary%.',
        '^luassert$',
        '^luassert%.',
        '^say$',
      },
    },
    { 'ojroques/nvim-osc52',
        config = function()
          local function copy(lines, _)
            require('osc52').copy(table.concat(lines, '\n'))
          end

          local function paste()
            return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
          end

          vim.g.clipboard = {
            name = 'osc52',
            copy = { ['+'] = copy, ['*'] = copy },
            paste = { ['+'] = paste, ['*'] = paste },
          }
      end,
      cond = function()
        return is_ssh()
      end,
    },
    { 'kylechui/nvim-surround',
      keys = {
        { 'n', 'ys' },
        { 'n', 'yss' },
        { 'n', 'yS' },
        { 'n', 'ySS' },
        { 'x', 'S' },
        { 'x', 'gS' },
        { 'n', 'ds' },
        { 'n', 'cs' },
      },
      config = function()
        local opts = require('nvim-surround.config').default_opts
        opts.keymaps.insert = nil
        opts.keymaps.insert_line = nil
        opts.aliases = {}
        require('nvim-surround').setup()
      end,
    },
    { 'windwp/nvim-autopairs',
      config = function()
        require('nvim-autopairs').setup()
      end,
    },
    { 'numToStr/Comment.nvim',
      keys = {
        { 'n', '<leader>c/' },
        { 'x', '<leader>c/' },
      },
      config = function()
        require('Comment').setup({
          mappings = {
            basic = false,
            extra = false,
            extended = false,
          },
        })

        vim.keymap.set(
          'n',
          '<leader>c/',
          '<Plug>(comment_toggle_linewise_current)',
          { silent = true, noremap = true, desc = 'Toggle comments' }
        )
        vim.keymap.set(
          'x',
          '<leader>c/',
          '<Plug>(comment_toggle_linewise_visual)',
          { silent = true, noremap = true, desc = 'Toggle comments' }
        )
      end,
    },
    { 'junegunn/fzf',
      run = function()
        vim.fn['fzf#install']()
      end,
      disable = not not _G.jit,
    },
    { 'junegunn/fzf.vim',
      after = 'fzf',
      setup = function()
        for k, v in pairs({
          f = { '<cmd>Files<CR>', 'fzf find files' },
          g = { '<cmd>Rg<CR>', 'fzf live grep' },
          b = { '<cmd>Buffers<CR>', 'fzf show buffers' },
          h = { '<cmd>Helptags<CR>', 'fzf help tags' },
        }) do
          vim.keymap.set(
            'n',
            '<leader>f' .. k,
            v[1],
            { silent = true, noremap = true, desc = v[2] }
          )
        end
      end,
      disable = not not _G.jit,
    },
    { 'nvim-telescope/telescope-fzf-native.nvim',
      run = 'make',
      opt = true,
      disable = not _G.jit,
    },
    { 'nvim-telescope/telescope-ui-select.nvim',
      opt = true,
      disable = not _G.jit,
    },
    { 'nvim-telescope/telescope.nvim',
      keys = {
        { 'n', '<leader>ff' },
        { 'n', '<leader>fg' },
        { 'n', '<leader>fb' },
        { 'n', '<leader>fh' },
        { 'n', '<leader>fs' },
      },
      setup = function()
        if not vim.api.nvim_get_commands({})['Telescope'] then
          vim.api.nvim_create_user_command('Telescope', function(opts)
            require('packer.load')({ 'telescope.nvim' }, {
              cmd = 'Telescope',
              l1 = opts.line1,
              l2 = opts.line2,
              bang = opts.bang and '!' or '',
              args = opts.args,
              ---@diagnostic disable-next-line
            }, _G.packer_plugins)
          end, {
            nargs = '*',
            range = true,
            bang = true,
            complete = 'file',
          })
        end
      end,
      config = function()
        require('packer.load')({
          'telescope-fzf-native.nvim',
          'telescope-ui-select.nvim',
        }, { module = 'telescope.nvim' }, packer_plugins)

        local ts = require('telescope')

        ts.setup({
          defaults = {
            prompt_prefix = '❯ ',
            selection_caret = '❯ ',
            winblend = 20,
          },
          extensions = {
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
              case_mode = 'smart_case',
            },
            ['ui-select'] = {
              require('telescope.themes').get_dropdown(),
            },
          },
        })

        ts.load_extension('fzf')
        ts.load_extension('ui-select')

        for k, v in pairs({
          f = { '<cmd>Telescope find_files<CR>', 'Telescope find files' },
          g = { '<cmd>Telescope live_grep<CR>', 'Telescope live grep' },
          b = { '<cmd>Telescope buffers<CR>', 'Telescope show buffers' },
          h = { '<cmd>Telescope help_tags<CR>', 'Telescope help tags' },
        }) do
          vim.keymap.set(
            'n',
            '<leader>f' .. k,
            v[1],
            { noremap = true, silent = true, desc = v[2] }
          )
        end
      end,
      disable = not _G.jit,
    },
  })

  -- Sync Packer if it's running for the first time
  if vim.g.packer_bootstrap then
    packer.sync()
  elseif vim.loop.fs_stat(compiled) then
    dofile(compiled)
    _after_load()
  end
end)()
-- }}}
