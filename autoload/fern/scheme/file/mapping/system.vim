let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#system#init(disable_default_mappings) abort

  nnoremap <buffer><silent> <Plug>(fern-action-open:system) :<C-u>call <SID>call('open_system')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:system:detached) :<C-u>call <SID>call('open_system_multi_detached')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv) :<C-u>call <SID>call('open_sxiv')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv:tile) :<C-u>call <SID>call('open_sxiv_tile')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv:root) :<C-u>call <SID>call('open_sxiv_root')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:mpv) :<C-u>call <SID>call('open_mpv')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:mpv:loop) :<C-u>call <SID>call('open_mpv_loop')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:gimp) :<C-u>call <SID>call('open_gimp')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-ext:here) :<C-u>call <SID>call('extract_here')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-ext:directory) :<C-u>call <SID>call('extract_directory')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-cb:copy) :<C-u>call <SID>call('copy_from_clipboard')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cb:move) :<C-u>call <SID>call('move_from_clipboard')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cb:link) :<C-u>call <SID>call('link_from_clipboard')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cb:select) :<C-u>call <SID>call('selection_to_clipboard')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-mark:regex) :<C-u>call <SID>call('mark_by_regex')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-ftrash) :<C-u>call <SID>call('trash_nodes')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-ftogglex) :<C-u>call <SID>call('toggle_executable')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-wallpaper) :<C-u>call <SID>call('set_wallpaper')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-echo-info) :<C-u>call <SID>call('echo_info')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-collapse-all) :<C-u>call <SID>call('collapse_all')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-expand-siblings-or-children) :<C-u>call <SID>call('expand_siblings_or_children')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-bash:cursor) :<C-u>call <SID>call('bash_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-bash:root) :<C-u>call <SID>call('bash_root')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-fzf:cursor) :<C-u>call <SID>call('fzf_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-fzf:root) :<C-u>call <SID>call('fzf_root')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-fzf-dir:cursor) :<C-u>call <SID>call('fzf_dir_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-fzf-dir:root) :<C-u>call <SID>call('fzf_dir_root')<CR>

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

function! s:map_open_system_multi_detached(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> s:give_quotes(v._path)})
  for path in paths
    let cmd = 'nohup xdg-open ' . path . ' >/dev/null 2>&1  &'
    call system(cmd)
  endfor
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:give_quotes(word) 
  return "'" . a:word . "'"
endfunction

function! s:map_open_sxiv(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> s:give_quotes(v._path)})
  let args = join(paths, " ")
  let cmd = 'nohup nsxiv -b ' . args . ' >/dev/null 2>&1 &'
  echo cmd
  call system(cmd)
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:map_open_sxiv_tile(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> s:give_quotes(v._path)})
  let args = join(paths, " ")
  let cmd = 'nohup nsxiv -t -b ' . args . ' >/dev/null 2>&1 &'
  echo cmd
  call system(cmd)
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:map_open_sxiv_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let cmd = 'nohup nsxiv -t -b "' . path . '" >/dev/null 2>&1 &'
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

function! s:map_open_gimp(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'nohup gimp "' . path . '" >/dev/null 2>&1 &'
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
    let root_path = a:helper.sync.get_root_node()._path
    let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Copy\ Files?\  cbc "' . cursor_dir . '" "' . root_path . '"'
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
    let root_path = a:helper.sync.get_root_node()._path
    let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Move\ Files?\  cbm "' . cursor_dir . '" "' . root_path . '"'

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
    let root_path = a:helper.sync.get_root_node()._path
    let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Create\ Symlinks?\  cbl "' . cursor_dir . '" "' . root_path . '"'
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

function! s:map_mark_by_regex(helper) abort
  let nodes = a:helper.fern.visible_nodes
  let regex = input(printf('Marking Regex: '))
  echo "\r\r"
  echo ""
  if len(regex) == 0
    return
  endif
  let marks = copy(a:helper.fern.marks)
  let l:count = 0
  for node in nodes
    if node.label =~ regex
      if index(marks, node.__key) == -1
        let l:count = l:count + 1
        call add(marks, node.__key)
      endif
    endif
  endfor
  if l:count > 0
    echo "Successfully marked " . l:count . " nodes"
  else
    echo "No unmarked nodes match the given regex"
  endif
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks(marks) })
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:map_trash_nodes(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> "'" . v._path . "'"})
  let args = join(paths, " ")
  let root_path = a:helper.sync.get_root_node()._path
  let cmd = 'FloatermNew --borderchars=─│─│╭╮╯╰ --title=\ Trash\ Files?\  ftrash "' . root_path . '" ' . args
  exe cmd
endfunction

function! s:map_toggle_executable(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let length = len(nodes)
  let paths = map(copy(nodes), { _, v -> substitute(v._path, " ", "", "g") })
  let args = join(paths, " ")
  let cmd = "ftogglex " . args
  let out = system(cmd)
  let root = a:helper.sync.get_root_node()
  if length == 1
    if out == 0
      echo "executability can't be toggled for this node"
    elseif out == 1
      echo "executability toggled off for " . nodes[0].label
      return a:helper.async.reload_node(root.__key)
            \.then({ -> a:helper.async.redraw() })
    elseif out == 2
      echo "executability toggled on for " . nodes[0].label
      return a:helper.async.reload_node(root.__key)
            \.then({ -> a:helper.async.redraw() })
    endif
  else
    let out_s = split(out)
    let count_on = out_s[0]
    let count_off = out_s[1]
    echo "executability toggled on for " . count_on . " nodes, off for " . count_off . " nodes."
    return a:helper.async.reload_node(root.__key)
          \.then({ -> a:helper.async.update_marks([]) })
          \.then({ -> a:helper.async.remark() })
          \.then({ -> a:helper.async.redraw() })
  endif
endfunction

function! s:map_set_wallpaper(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd1 = 'feh --bg-scale "' . path . '"'
  let cmd2 = 'echo "' . path . '" > ~/.cur/wallpaper'
  call system(cmd1)
  let cmd1_success = v:shell_error
  if !v:shell_error
    call system(cmd2)
  else
    echo path . " can't be used as a wallpaper"
  endif
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

function! s:map_echo_info(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'ls -lh ' . path
  let out = system(cmd)
  echo out
endfunction

function! s:map_collapse_all(helper) abort
  let root = a:helper.sync.get_root_node()
  let nodes = a:helper.fern.nodes
  let promises = []
  for node in nodes
    if node.status == 2 && node._path != root._path
      call add(promises, a:helper.async.collapse_node(node.__key))
    endif
  endfor
  return s:Promise.all(promises)
          \.then({ -> a:helper.async.reload_node(root.__key) })
          \.then({ -> a:helper.async.redraw() })
endfunction

function! s:get_dir_for_comparison(path, status) abort
  if a:status == 2
    return a:path
  else
    return s:get_parent_dir(a:path, a:status)
  endif
endfunction

function! s:get_parent_dir(path, status) abort
  let path_split = split(a:path, "/")
  let path_split_cut = path_split[0:(len(path_split)-2)]
  return "/" . join(path_split_cut, "/")
endfunction

" if cursor node is file or collapsed directory, expand siblings, else expand children
function! s:map_expand_siblings_or_children(helper) abort
  let fern = a:helper.fern
  let root = a:helper.sync.get_root_node()
  let cursor = a:helper.sync.get_cursor_node()
  let comparison_dir = s:get_dir_for_comparison(cursor._path, cursor.status)
  let nodes = a:helper.fern.visible_nodes
  let promises = []
  for node in nodes
    if node.status == 1
      let node_dir = s:get_parent_dir(node._path, cursor.status)
      if node_dir == comparison_dir
        call add(promises, fern#internal#node#expand(node, fern.nodes, fern.provider, fern.comparator, fern.source.token))
      endif
    endif
  endfor
  return s:Promise.all(promises)
          \.then({ -> a:helper.async.reload_node(root.__key) })
          \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_fzf_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let sink_cmd = 'FzfCursorAfter ' . path
  call fzf#run({'source': '~/dot/scripts/fzf/base/fzf-here-file.sh ' . path, 'sink': sink_cmd, 'window': {'width': 0.8, 'height': 0.8}})
endfunction

function! s:map_fzf_cursor(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let sink_cmd = 'FzfCursorAfter ' . path
  call fzf#run({'source': '~/dot/scripts/fzf/base/fzf-here-file.sh ' . path, 'sink': sink_cmd, 'window': {'width': 0.8, 'height': 0.8}})
endfunction

function! s:map_fzf_dir_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let sink_cmd = 'FzfCursorAfter ' . path
  call fzf#run({'source': '~/dot/scripts/fzf/base/fzf-here-dir.sh ' . path, 'sink': sink_cmd, 'window': {'width': 0.8, 'height': 0.8}})
endfunction

function! s:map_fzf_dir_cursor(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let sink_cmd = 'FzfCursorAfter ' . path
  call fzf#run({'source': '~/dot/scripts/fzf/base/fzf-here-dir.sh ' . path, 'sink': sink_cmd, 'window': {'width': 0.8, 'height': 0.8}})
endfunction

function! s:fzf_cursor_after(cursor, selection)
  let path = a:cursor . "/" . a:selection
  execute 'edit' l:path
endfunction
command! -nargs=* FzfCursorAfter :call s:fzf_cursor_after(<f-args>)
