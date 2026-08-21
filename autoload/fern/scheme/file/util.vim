let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:is_windows = has('win32')

let s:SEP = nr2char(31)

" format a byte count as iec units (e.g. 1536 -> 1.5K)
function! s:iec(bytes) abort
  let n = a:bytes < 0 ? 0 : a:bytes
  let units = ['', 'K', 'M', 'G', 'T', 'P']
  let i = 0
  let f = n * 1.0
  while f >= 1024.0 && i < len(units) - 1
    let f = f / 1024.0
    let i += 1
  endwhile
  if i == 0
    return string(n)
  elseif f < 10.0
    return printf('%.1f%s', ceil(f * 10.0) / 10.0, units[i])
  endif
  return printf('%.0f%s', ceil(f), units[i])
endfunction

function! s:tilde(path) abort
  return substitute(a:path, '/home/[^/]\+', '~', '')
endfunction

" first find lists the immediate children (type, followed-type, size, perms,
" path, link target); second find descends one more level (following symlinks)
" so each grandchild reports its parent, giving us per-directory child counts
let s:CMD = 'p="$1"; find "$p" -mindepth 1 -maxdepth 1 -printf "E\t%y\t%Y\t%s\t%m\t%p\t%l\n" && { find -L "$p" -mindepth 2 -maxdepth 2 -printf "C\t%h\n" 2>/dev/null; :; }'

function! s:build(lines) abort
  let counts = {}
  let entries = []
  for line in a:lines
    if empty(line)
      continue
    endif
    let parts = split(line, "\t", 1)
    if parts[0] ==# 'C'
      let counts[parts[1]] = get(counts, parts[1], 0) + 1
    else
      call add(entries, parts)
    endif
  endfor
  let result = []
  for e in entries
    let [type, xtype, size, perm, path] = e[1:5]
    let link = get(e, 6, '')
    if type ==# 'd'
      call add(result, path . s:SEP . get(counts, path, 0) . s:SEP . 'd')
    elseif type ==# 'l' && xtype ==# 'd'
      call add(result, path . s:SEP . get(counts, path, 0) . s:SEP . 'dl' . s:SEP . s:tilde(link))
    elseif type ==# 'l'
      call add(result, path . s:SEP . s:iec(str2nr(size)) . s:SEP . 'l' . s:SEP . s:tilde(link))
    elseif type ==# 'f'
      let ft = and(str2nr(perm, 8), 73) ? 'x' : 'f'
      call add(result, path . s:SEP . s:iec(str2nr(size)) . s:SEP . ft)
    endif
  endfor
  return result
endfunction

  function! fern#scheme#file#util#list_entries_find(path, token) abort
    let l:Profile = fern#profile#start('fern#scheme#file#util#list_entries_find')
    return s:Process.start(['sh', '-c', s:CMD, 'sh', a:path], { 'token': a:token, 'reject_on_failure': 1 })
          \.catch({ v -> s:Promise.reject(join(v.stderr, "\n")) })
          \.then({ v -> s:build(v.stdout) })
          \.finally({ -> Profile() })
  endfunction

function! fern#scheme#file#util#list_entries_glob(path, ...) abort
  let l:Profile = fern#profile#start('fern#scheme#file#util#list_entries_glob')
  let s = s:is_windows ? '\' : '/'
  let a = s:Promise.resolve(glob(a:path . s . '*', 1, 1, 1))
  let b = s:Promise.resolve(glob(a:path . s . '.*', 1, 1, 1))
        \.then(s:AsyncLambda.filter_f({ v -> v[-2:] !=# s . '.' && v[-3:] !=# s . '..' }))
  return s:Promise.all([a, b])
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.finally({ -> Profile() })
endfunction

if s:is_windows
  function! fern#scheme#file#util#list_drives(token) abort
    let l:Profile = fern#profile#start('fern#scheme#file#util#list_drives')
    return s:Process.start(['wmic', 'logicaldisk', 'get', 'name'], { 'token': a:token, 'reject_on_failure': 1 })
          \.catch({ v -> s:Promise.reject(join(v.stderr, "\n")) })
          \.then({ v -> v.stdout })
          \.then(s:AsyncLambda.filter_f({ v -> v =~# '^\w:' }))
          \.then(s:AsyncLambda.map_f({ v -> v:val[:1] . '\' }))
          \.finally({ -> Profile() })
  endfunction
endif
