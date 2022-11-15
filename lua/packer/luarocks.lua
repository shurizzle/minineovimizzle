local function noop() end

return {
  handle_command = noop,
  install_commands = noop,
  list = noop,
  install_hererocks = noop,
  setup_paths = noop,
  uninstall = noop,
  clean = noop,
  install = noop,
  ensure = noop,
  generate_path_setup = function()
    return ''
  end,
  cfg = function() end,
}
