let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#copy#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-copy-bulk) :<C-u>call <SID>call('copy', 'split')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> B <Plug>(fern-action-copy-bulk)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_copy(helper, opener) abort
  let root = a:helper.sync.get_root_node()
  let nodes = a:helper.sync.get_selected_nodes()
  if len(nodes) == 1
    let root_path = a:helper.sync.get_root_node()._path
    let cursor_path = a:helper.sync.get_cursor_node()._path
    if root_path == cursor_path
      return
    endif
  endif
  let l:Factory = { -> map(copy(nodes), { -> v:val._path }) }
  let options = {
        \ 'opener': a:opener,
        \ 'cursor': [1, len(root._path) + 1],
        \ 'is_drawer': a:helper.sync.is_drawer(),
        \ 'modifiers':[
        \   { r -> s:check_copy_destinations(r) },
        \ ],
        \}
  let ns = {}
  return fern#internal#replacer#start(Factory, options)
        \.then({ r -> s:_map_copy(a:helper, r) })
        \.then({ n -> s:Lambda.let(ns, 'n', n) })
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are copied', ns.n)) })
endfunction

function! s:_map_copy(helper, result) abort
  let token = a:helper.fern.source.token
  let ps = []
  for [src, dst] in a:result
    call add(ps, fern#scheme#file#shutil#copy(src, dst, token))
  endfor
  return s:Promise.all(ps)
        \.then({ -> len(ps) })
endfunction

function! s:check_copy_destinations(pairs) abort
  let seen = {}
  for [src, dst] in a:pairs
    if has_key(seen, dst)
      throw printf('Destination "%s" appears more than once', dst)
    endif
    let seen[dst] = 1
  endfor
  for [src, dst] in a:pairs
    if src !=# dst && getftype(dst) !=# ''
      throw printf('Destination "%s" already exists', dst)
    endif
  endfor
  return a:pairs
endfunction
