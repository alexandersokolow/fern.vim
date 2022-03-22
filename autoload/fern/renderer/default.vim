let s:Config = vital#fern#import('Config')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:ESCAPE_PATTERN = '^$~.*[]\'
let s:STATUS_NONE = g:fern#STATUS_NONE
let s:STATUS_COLLAPSED = g:fern#STATUS_COLLAPSED

function! fern#renderer#default#new() abort
  return {
        \ 'render': funcref('s:render'),
        \ 'index': funcref('s:index'),
        \ 'lnum': funcref('s:lnum'),
        \ 'syntax': funcref('s:syntax'),
        \ 'highlight': funcref('s:highlight'),
        \}
endfunction

function! s:render(nodes) abort
  let options = {
        \ 'leading': g:fern#renderer#default#leading,
        \ 'root_symbol': g:fern#renderer#default#root_symbol,
        \ 'leaf_symbol': g:fern#renderer#default#leaf_symbol,
        \ 'expanded_symbol': g:fern#renderer#default#expanded_symbol,
        \ 'collapsed_symbol': g:fern#renderer#default#collapsed_symbol,
        \}
  let base = len(a:nodes[0].__key)
  let l:Profile = fern#profile#start('fern#renderer#default#s:render')
  return s:AsyncLambda.map(copy(a:nodes), { v, -> s:render_node(v, base, options) })
        \.finally({ -> Profile() })
endfunction

function! s:index(lnum) abort
  return a:lnum - 1
endfunction

function! s:lnum(index) abort
  return a:index + 1
endfunction

function! s:syntax() abort
  syntax match FernRoot /^.*$/
  syntax match FernLink /^.*/ contains=FernWallChar
  syntax match FernExecutable /^.*.*$/ contains=ExecutableChar
  syntax match FernBranch /^.*[].*$/ contains=FernBranchLink,FernWallChar
  syntax match FernBranchLink /.*$/ contains=FernWallChar

  " syntax match FernLeaf   /^.*[^/].*$/ transparent contains=FernLeafSymbol
  " syntax match FernBranch /^[ ]*[] .*.*$/   transparent contains=FernBranchSymbol
  " syntax match FernRoot   /\%1l.*/       transparent contains=FernRootText
  " execute printf(
  "       \ 'syntax match FernRootSymbol /%s/ contained nextgroup=FernRootText',
  "       \ escape(g:fern#renderer#default#root_symbol, s:ESCAPE_PATTERN),
  "       \)
  " execute printf(
  "       \ 'syntax match FernLeafSymbol /^\%%(%s\)*%s/ contained nextgroup=FernLeafText',
  "       \ escape(g:fern#renderer#default#leading, s:ESCAPE_PATTERN),
  "       \ escape(g:fern#renderer#default#leaf_symbol, s:ESCAPE_PATTERN),
  "       \)
  " execute printf(
  "       \ 'syntax match FernBranchSymbol /^\%%(%s\)*\%%(%s\|%s\)/ contained nextgroup=FernBranchText',
  "       \ escape(g:fern#renderer#default#leading, s:ESCAPE_PATTERN),
  "       \ escape(g:fern#renderer#default#collapsed_symbol, s:ESCAPE_PATTERN),
  "       \ escape(g:fern#renderer#default#expanded_symbol, s:ESCAPE_PATTERN),
  "       \)
  " syntax match FernRootText   /.*\ze.*$/ contained nextgroup=FernBadgeSep
  " syntax match FernLeafText   /.*\ze.*$/ contained nextgroup=FernBadgeSep
  " syntax match FernBranchText /.*\ze.*$/ contained nextgroup=FernBadgeSep
  " syntax match FernBadge      /.*/         contained
  syntax match FernWallChar /│/ contained
  syntax match FernWallCharAlone /│/
  syntax match ExecutableChar   //         contained conceal
  setlocal concealcursor=nvic conceallevel=2
endfunction

function! s:highlight() abort
  highlight default link FernRootSymbol   Directory
  highlight default link FernRootText     Directory
  highlight default link FernLeafSymbol   Directory
  highlight default link FernLeafText     None
  highlight default link FernBranchSymbol Directory
  highlight default link FernBranchText   Directory
endfunction

function! s:get_node_suffix(node) abort
  let filetype = a:node._filetype
  let linkto = a:node._linkto
  if filetype == "f"
    return ""
  endif
  if filetype == "x"
    return ""
  endif
  if filetype == 'l'
    return "   " .linkto
  endif
  return ""
endfunction

function! s:get_node_prefix(node) abort
  let filetype = a:node._filetype
  let size = a:node._size
  let linkto = a:node._linkto
  if filetype == "f"
    return ""
  endif
  if filetype == "x"
    return ""
  endif
  if filetype == 'l'
    return ""
  endif
  return ""
endfunction

function! s:get_formatted_size(size) abort
  let last_char = a:size[len(a:size)-1]
  if last_char == 'K'
    return a:size[0:len(a:size)-2] . " " . last_char
  endif
  if last_char == 'M'
    return a:size[0:len(a:size)-2] . " " . last_char
  endif
  if last_char == 'G'
    return a:size[0:len(a:size)-2] . " " . last_char
  endif
  return a:size . " B"
endfunction

function! s:get_node_size(node, leading) abort
  if g:fern#hide_sizes
    return ""
  endif
  let name = a:node.label
  let filetype = a:node._filetype
  let size = a:node._size
  let formatted_size = s:get_formatted_size(size)
  let linkto = a:node._linkto
  let spaces_to_pad = 48 - len(name) - len(a:leading) - len(size)
  if filetype == "d"
    let spaces_to_pad2 = spaces_to_pad - 3
    if spaces_to_pad2 > 1
      return repeat(" ", spaces_to_pad2) . size
    endif
    return ""
  endif
  if filetype == "f"
    if spaces_to_pad > 1
      let last_formatted_char = formatted_size[len(formatted_size)-1]
      if last_formatted_char == 'B'
        return repeat(" ", spaces_to_pad - 2) . formatted_size
      endif
      return repeat(" ", spaces_to_pad - 1) . formatted_size
    endif
    return ""
  endif
  if filetype == "x"
    if spaces_to_pad > 1
      let last_formatted_char = formatted_size[len(formatted_size)-1]
      if last_formatted_char == 'B'
        return repeat(" ", spaces_to_pad - 2) . formatted_size
      endif
      return repeat(" ", spaces_to_pad - 1) . formatted_size
    endif
    return ""
  endif
  if filetype == 'l'
    return ""
  endif
  return repeat(" ", spaces_to_pad) . size
endfunction

function! s:render_node(node, base, options) abort
  let level = len(a:node.__key) - a:base
  if level is# 0
    return a:options.root_symbol . a:node.label
  endif
  let leading = repeat(a:options.leading, level - 1)
  let symbol = a:node.status is# s:STATUS_NONE
        \ ? s:get_node_prefix(a:node)
        \ : a:node.status is# s:STATUS_COLLAPSED
        \   ? a:options.collapsed_symbol
        \   : a:options.expanded_symbol
  let suffix = s:get_node_suffix(a:node)
  " return leading . symbol . a:node.label . suffix
  return leading . symbol . a:node.label . suffix . s:get_node_size(a:node, leading)
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'leading': ' ',
      \ 'root_symbol': '',
      \ 'leaf_symbol': '|  ',
      \ 'collapsed_symbol': '|+ ',
      \ 'expanded_symbol': '|- ',
      \})

" OBSOLETE:
if exists('g:fern#renderer#default#marked_symbol')
  call fern#util#obsolete(
        \ 'g:fern#renderer#default#marked_symbol',
        \ 'g:fern#mark_symbol',
        \)
endif
if exists('g:fern#renderer#default#unmarked_symbol')
  call fern#util#obsolete('g:fern#renderer#default#unmarked_symbol')
endif
