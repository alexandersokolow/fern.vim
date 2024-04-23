let s:Config = vital#fern#import('Config')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:ESCAPE_PATTERN = '^$~.*[]\'
let s:STATUS_NONE = g:fern#STATUS_NONE
let s:STATUS_COLLAPSED = g:fern#STATUS_COLLAPSED

let s:LINE_LENGTH = 50

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
  syntax match FernExecutable /^.*.*$/ contains=ExecutableChar
  syntax match FernBranch /^.*[].*$/ contains=FernBranchLink,FernWallChar
  syntax match FernLink /^.* .*$/ contains=FernLinkPointedText,FernWallChar
  syntax match FernLinkPointedText /  .* / contains=FernWallChar,FernLinkFileSize
  syntax match FernLinkFileSize / [^ ]* B/ contained
  syntax match FernLinkToBranch /^.*[].* .*$/ contains=FernLinkToBranchPointedText,FernWallChar
  syntax match FernLinkToBranchPointedText /  .* / contains=FernWallChar

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
  if filetype == 'l' || filetype == 'dl'
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

function! s:get_formatted_size(size, filetype) abort
  if a:filetype == "d" || a:filetype == "dl"
    return a:size
  endif
  let last_char = a:size[len(a:size)-1]
  if last_char == 'K' || last_char == 'M' || last_char == 'G'
    return a:size[0:len(a:size)-2] . " " . last_char
  endif
  return a:size . " B"
endfunction

function! s:cut_string(s, from, to)
  try
    let a = []
    for c in a:s
      call add(a,c)
    endfor
    let cut_a = a[a:from:a:to-1]
    return join(cut_a, "")
  catch /.*/
    echo "Caught error: " . v:exception
  endtry
endfunction

function! s:get_spaces_to_pad(name, size, filetype) abort
  let spaces_to_pad = s:LINE_LENGTH - strchars(a:name) - strchars(a:size)
  if a:filetype == "x"
    return spaces_to_pad + 1
  endif
  return spaces_to_pad
endfunction

function! s:get_ending(name, filetype) abort
  let fileparts = split(a:name, "\\V.")
  let hasEnding = (a:filetype == "f" || a:filetype == "x") && len(fileparts) > 1
  if hasEnding
    let ending = fileparts[len(fileparts)-1]
    if len(ending) < 9
      return ending
    endif
  endif
  return ""
endfunction

function! s:get_node_string(node, leading, suffix, symbol) abort
    let filetype = a:node._filetype
    let name = a:leading . a:symbol . a:node.label . a:suffix
    let formatted_size = s:get_formatted_size(a:node._size, filetype)
    let spaces_to_pad = s:get_spaces_to_pad(name, formatted_size, filetype)
    let cut_name = spaces_to_pad < 3
    if cut_name
      let ending = s:get_ending(name, filetype)
      let appender = len(ending) == 0 ? "~ " : ("~." . ending . " ")
      let len_to_cut = s:LINE_LENGTH - strchars(formatted_size) - strchars(appender) + (filetype == "x" ? 1 : 0)
      let name_cut = s:cut_string(name, 0, len_to_cut)
      return name_cut . appender . formatted_size
    endif
    return name . repeat(" ", spaces_to_pad) . formatted_size
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
  let node_string = s:get_node_string(a:node, leading, suffix, symbol)
  return node_string
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
