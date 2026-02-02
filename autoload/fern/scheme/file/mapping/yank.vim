function! fern#scheme#file#mapping#yank#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-yank:path) :<C-u>call <SID>call('yank_path')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-yank:cursor:path:cb) :<C-u>call <SID>call('yank_cursor_path_to_cb')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-yank:root:path:cb) :<C-u>call <SID>call('yank_root_path_to_cb')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-yank:cursor:abspath:cb) :<C-u>call <SID>call('yank_cursor_abspath_to_cb')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-yank:root:abspath:cb) :<C-u>call <SID>call('yank_root_abspath_to_cb')<CR>

  nmap <buffer> <Plug>(fern-action-yank) <Plug>(fern-action-yank:path)
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_yank_path(helper) abort
  let node = a:helper.sync.get_cursor_node()
  let value = node._path
  call setreg(v:register, value)
  redraw | echo "The node 'path' has yanked."
endfunction

function! s:map_yank_cursor_path_to_cb(helper) abort
  let node = a:helper.sync.get_cursor_node()
  let value = fnamemodify(node._path, ':.')
  echo value
  let cmd = 'echo "' . value . '" | xclip -selection clipboard'
  call system(cmd)
endfunction

function! s:map_yank_root_path_to_cb(helper) abort
  let node = a:helper.sync.get_root_node()
  let value = fnamemodify(node._path, ':.')
  echo value
  let cmd = 'echo "' . value . '" | xclip -selection clipboard'
  call system(cmd)
endfunction

function! s:map_yank_cursor_abspath_to_cb(helper) abort
  let node = a:helper.sync.get_cursor_node()
  let value = node._path
  echo value
  let cmd = 'echo "' . value . '" | xclip -selection clipboard'
  call system(cmd)
endfunction

function! s:map_yank_root_abspath_to_cb(helper) abort
  let node = a:helper.sync.get_root_node()
  let value = node._path
  echo value
  let cmd = 'echo "' . value . '" | xclip -selection clipboard'
  call system(cmd)
endfunction

