let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#system#init(disable_default_mappings) abort

  nnoremap <buffer><silent> <Plug>(fern-action-open:system) :<C-u>call <SID>call('open_system')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:system:detached) :<C-u>call <SID>call('open_system_detached')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv) :<C-u>call <SID>call('open_sxiv')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv:tile) :<C-u>call <SID>call('open_sxiv_tile')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:sxiv:root) :<C-u>call <SID>call('open_sxiv_root')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:mpv) :<C-u>call <SID>call('open_mpv')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-wallpaper) :<C-u>call <SID>call('set_wallpaper')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-fzf:cursor) :<C-u>call <SID>call('fzf_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-fzf:directory) :<C-u>call <SID>call('fzf_directory')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-fzf:root) :<C-u>call <SID>call('fzf_root')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> x <Plug>(fern-action-open:system)
  endif
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
  let cmd = 'nohup mpv "' . path . '" --loop=inf >/dev/null 2>&1 &'
  call system(cmd)
  return
endfunction

function! s:map_set_wallpaper(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'feh --bg-scale "' . path . '"'
  let cmd2 = 'echo "' . path . '" > ~/.cur/wallpaper'
  call system(cmd)
  call system(cmd2)
  return 
endfunction

function! s:map_fzf_cursor(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'silent !fvvf ' . path
  exe cmd
  let test = system('cat ~/.cur/fvvf-out')
  if test == ""
    exe 'redraw!'
    return
  endif
  try
    exe 'redraw!'
    exe 'edit ' . test
    exe 'redraw!'
  catch
    return
  endtry
endfunction

function! s:map_fzf_directory(helper) abort
  let path = a:helper.sync.get_cursor_node()._path
  let cmd = 'silent !fvdf ' . path
  exe cmd
  let test = system('cat ~/.cur/fvdf-out')
  if test == ""
    exe 'redraw!'
    return
  endif
  try
    exe 'redraw!'
    exe 'edit ' . test
    exe 'redraw!'
  catch
    return
  endtry
endfunction

function! s:map_fzf_root(helper) abort
  let path = a:helper.sync.get_root_node()._path
  let cmd = 'silent !fvvf ' . path
  exe cmd
  let test = system('cat ~/.cur/fvvf-out')
  if test == ""
    exe 'redraw!'
    return
  endif
  try
    exe 'redraw!'
    exe 'edit ' . test
    exe 'redraw!'
  catch
    return
  endtry
endfunction
