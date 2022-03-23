let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#system#init(disable_default_mappings) abort

  nnoremap <buffer><silent> <Plug>(fern-action-open:system) :<C-u>call <SID>call('open_system')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:system:detached) :<C-u>call <SID>call('open_system_detached')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv) :<C-u>call <SID>call('open_sxiv')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv:tile) :<C-u>call <SID>call('open_sxiv_tile')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv:root) :<C-u>call <SID>call('open_sxiv_root')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:mpv) :<C-u>call <SID>call('open_mpv')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:mpv:loop) :<C-u>call <SID>call('open_mpv_loop')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-ext:here) :<C-u>call <SID>call('extract_here')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-ext:directory) :<C-u>call <SID>call('extract_directory')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-cb:copy) :<C-u>call <SID>call('copy_from_clipboard')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cb:move) :<C-u>call <SID>call('move_from_clipboard')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cb:link) :<C-u>call <SID>call('link_from_clipboard')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cb:select) :<C-u>call <SID>call('selection_to_clipboard')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-ftrash) :<C-u>call <SID>call('trash_nodes')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-wallpaper) :<C-u>call <SID>call('set_wallpaper')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-bash:cursor) :<C-u>call <SID>call('bash_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-bash:root) :<C-u>call <SID>call('bash_root')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-fzf:cursor) :<C-u>call <SID>call('fzf_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-fzf:root) :<C-u>call <SID>call('fzf_root')<CR>

  " if !a:disable_default_mappings
  "   nmap <buffer><nowait> x <Plug>(fern-action-open:system)
  " endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_open_system(helper) abort
  let node = a:helper.sync.get_cursor_node()
  let l:Done = a:helper.sync.process_node(node)
  return fern#scheme#file#shutil#open(node._path, a:helper.fern.source.token)
        \.then({ -> a:helper.sync.echo(printf('%s has opened', node._path)) })
        \.finally({ -> Done() })
endfunction

function! s:map_open_system_detached(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'nohup xdg-open "' . path . '" >/dev/null 2>&1  &'
  echo cmd
  call system(cmd)
  return 
endfunction

function! s:map_open_sxiv(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'nohup sxiv -b "' . path . '" >/dev/null 2>&1 &'
  call system(cmd)
  return
endfunction

function! s:map_open_sxiv_tile(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'nohup sxiv -t -b "' . path . '" >/dev/null 2>&1 &'
  call system(cmd)
  return
endfunction

function! s:map_open_sxiv_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let cmd = 'nohup sxiv -t -b "' . path . '" >/dev/null 2>&1 &'
  call system(cmd)
  return
endfunction

function! s:map_open_mpv(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'nohup mpv --profile=pseudo-gui "' . path . '" >/dev/null 2>&1 &'
  call system(cmd)
  return
endfunction

function! s:map_open_mpv_loop(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'nohup mpv --profile=pseudo-gui "' . path . '" --loop=inf >/dev/null 2>&1 &'
  call system(cmd)
  return
endfunction

function! s:map_extract_here(helper) abort
  let cwd = getcwd()
  let cfd = a:helper.sync.get_root_node()._path
  let d1cmd = "cd ". cfd
  exe d1cmd
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'silent !exth "' . path . '" && fg'
  exe cmd
  exe 'redraw!'
  let d2cmd = "cd ". cwd
  exe d2cmd
  let root = a:helper.sync.get_root_node()
  return a:helper.async.reload_node(root.__key)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_extract_directory(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'silent !extd "' . path . '" && fg'
  exe cmd
  exe 'redraw!'
  let root = a:helper.sync.get_root_node()
  return a:helper.async.reload_node(root.__key)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_copy_from_clipboard(helper) abort
  let clipboard_has_nodes = system('cb-check')
  if clipboard_has_nodes
    let cursor_path = a:helper.sync.get_cursor_node()._path
    let cursor_dir = fnamemodify(cursor_path, ':p:h')
    let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Copy\ Files?\  cbc ' . cursor_dir
    exe cmd
  else
    echo "clipboard content is not a valid list of nodes"
  endif
endfunction

function! s:map_move_from_clipboard(helper) abort
  let clipboard_has_nodes = system('cb-check')
  if clipboard_has_nodes
    let cursor_path = a:helper.sync.get_cursor_node()._path
    let cursor_dir = fnamemodify(cursor_path, ':p:h')
    let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Move\ Files?\  cbm ' . cursor_dir
    exe cmd
  else
    echo "clipboard content is not a valid list of nodes"
  endif
endfunction

function! s:map_link_from_clipboard(helper) abort
  let clipboard_has_nodes = system('cb-check')
  if clipboard_has_nodes
    let cursor_path = a:helper.sync.get_cursor_node()._path
    let cursor_dir = fnamemodify(cursor_path, ':p:h')
    let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Create\ Symlinks?\  cbl ' . cursor_dir
    exe cmd
  else
    echo "clipboard content is not a valid list of nodes"
  endif
endfunction

function! s:map_selection_to_clipboard(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> substitute(v._path, " ", "", "g") })
  let length = len(paths)
  let args = join(paths, " ")
  let cmd = "echo '" . args . "' | xclip -sel clip"
  call system(cmd)
  echo "successfully copied " . length . " nodes to clipboard"
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:map_trash_nodes(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> substitute(v._path, " ", "", "g") })
  let args = join(paths, " ")
  let cmd = "echo '" . args . "' | xclip -sel clip"
  call system(cmd)
  let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Trash\ Files?\  ftrash'
  exe cmd
endfunction

function! s:map_set_wallpaper(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'feh --bg-scale "' . path . '"'
  let cmd2 = 'echo "' . path . '" > ~/.cur/wallpaper'
  call system(cmd)
  call system(cmd2)
  return 
endfunction

function! s:map_bash_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=Bash --cwd=' . path
  exe cmd
endfunction

function! s:map_bash_cursor(helper) abort
  let cursor_path = a:helper.sync.get_cursor_node()._path
  let cursor_dir = fnamemodify(cursor_path, ':p:h')
  let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=Bash --cwd=' . cursor_dir
  exe cmd
endfunction

function! s:map_fzf_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let sink_cmd = 'FzfCursorAfter ' . path
  call fzf#run({'source': '~/dot/scripts/fzf/fzf-vim-invim-here ' . path, 'sink': sink_cmd, 'window': {'width': 0.8, 'height': 0.8}})
endfunction

function! s:map_fzf_cursor(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let sink_cmd = 'FzfCursorAfter ' . path
  call fzf#run({'source': '~/dot/scripts/fzf/fzf-vim-invim-here ' . path, 'sink': sink_cmd, 'window': {'width': 0.8, 'height': 0.8}})
endfunction

function! s:fzf_cursor_after(cursor, selection)
  let path = a:cursor . "/" . a:selection
  execute 'edit' l:path
endfunction
command! -nargs=* FzfCursorAfter :call s:fzf_cursor_after(<f-args>)
