_G.path_separator = vim.loop.os_uname().sysname:match('Windows') and '\\' or '/'

function _G.join_paths(...)
  return table.concat({ ... }, _G.path_separator)
end

function _G.has(what)
  return vim.fn.has(what) ~= 0
end

function _G.executable(what)
  return vim.fn.executable(what) ~= 0
end

function _G.is_ssh()
  local res = false

  if has('unix') then
    local function has_ip(str)
      local ip = require('ip')

      for m in str:gmatch('%((.+)%)') do
        if ip.parse(m) then
          return true
        end
      end

      return false
    end
    res = has_ip(vim.fn.system('who'))
  end

  ---@diagnostic disable-next-line
  _G.is_ssh = loadstring('return ' .. vim.inspect(res))
  return res
end

vim.cmd('colorscheme slate')

vim.opt.number = true
vim.opt.relativenumber = true
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
vim.opt.listchars = 'tab: ·,trail:×,nbsp:%,eol:·,extends:»,precedes:«'
vim.opt.laststatus = 3
vim.opt.shortmess:append('c')
vim.opt.fillchars:append('eob: ')
vim.opt.colorcolumn = '80'
vim.opt.showmode = false
vim.g.mapleader = ','
vim.g.maplocalleader = ','

if has('termguicolors') then
  vim.opt.termguicolors = true
end

local K = vim.keymap.set

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
    K(modes, left, right, options)
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
  -- Search for text in visual selection
  ['*'] = {
    '"zy/\\<\\V<C-r>=escape(@z, \'/\\\')<CR>\\><CR>',
    'Search for selected text',
  },
}) do
  K('v', k, v[1], { silent = true, noremap = true, desc = v[2] })
end

vim.cmd([[
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
]])

for k, v in pairs({
  -- Make Y behave like the other capitals
  Y = { 'y$', 'Yank untill the end of the line' },
  ['<C-h>'] = { '<cmd>wincmd h<CR>' },
  ['<C-j>'] = { '<cmd>wincmd j<CR>' },
  ['<C-k>'] = { '<cmd>wincmd k<CR>' },
  ['<C-l>'] = { '<cmd>wincmd l<CR>' },
  ['<C-n>'] = { '<cmd>bnext<CR>' },
  ['<C-p>'] = { '<cmd>bprevious<CR>' },
}) do
  K('n', k, v[1], { silent = true, noremap = true, desc = v[2] })
end

local function git_clone(url, dir, callback)
  local install_path =
    join_paths(vim.fn.stdpath('data'), 'site', 'pack', 'packer', 'start', dir)

  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    callback(vim.fn.system({
      'git',
      'clone',
      '--depth',
      '1',
      url,
      install_path,
    }))
  end
end

git_clone(
  'https://github.com/lewis6991/impatient.nvim',
  'impatient.nvim',
  function(_)
    vim.cmd([[packadd impatient.nvim]])
    require('impatient')
  end
)

git_clone(
  'https://github.com/wbthomason/packer.nvim',
  'packer.nvim',
  function(res)
    vim.g.packer_bootstrap = res
    vim.cmd([[packadd packer.nvim]])
  end
)

local function packer_setup()
  local status_ok, packer = pcall(require, 'packer')
  if not status_ok then
    return
  end

  packer.init({
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
    { 'ojroques/nvim-osc52',
        config = function()
          if is_ssh() then
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
          end
      end,
    },
    { 'shurizzle/nvim-surround',
      config = function()
          require('nvim-surround.config').default_opts.aliases = {}
          require('nvim-surround').setup()
      end,
    },
    { 'windwp/nvim-autopairs',
      config = function()
          require('nvim-autopairs').setup()
      end,
    },
    { 'numToStr/Comment.nvim',
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
    { 'nvim-telescope/telescope.nvim',
      config = function()
        local ts = require('telescope')

        ts.setup({
          defaults = {
            prompt_prefix = '❯ ',
            selection_caret = '❯ ',
            winblend = 20,
          },
          extensions = {
            ['ui-select'] = {
              require('telescope.themes').get_dropdown(),
            },
          },
        })

        for k, v in pairs({
          f = { '<cmd>Telescope find_files<CR>', 'Telescope find files' },
          g = { '<cmd>Telescope live_grep<CR>', 'Telescope live grep' },
          b = { '<cmd>Telescope buffer<CR>', 'Telescope show buffers' },
          h = { '<cmd>Telescope help_tags<CR>', 'Telescope help tags' },
          s = {
            '<cmd>Telescope lsp_document_symbols<CR>',
            'Telescope shopw workspace symbols',
          },
        }) do
          vim.keymap.set(
            'n',
            '<leader>f' .. k,
            v[1],
            { silent = true, noremap = true, desc = v[2] }
          )
        end
      end,
      requires = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
      },
    },
  })

  if vim.g.packer_bootstrap then
    packer.sync()
  end
end

packer_setup()
