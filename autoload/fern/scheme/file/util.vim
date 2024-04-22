let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:is_windows = has('win32')

  function! fern#scheme#file#util#list_entries_find(path, token) abort
    let l:Profile = fern#profile#start('fern#scheme#file#util#list_entries_find')
    " return s:Process.start(['find', a:path, '-follow', '-maxdepth', '1'], { 'token': a:token, 'reject_on_failure': 1 })
    return s:Process.start(['fnodes', a:path], { 'token': a:token, 'reject_on_failure': 1 })
          \.catch({ v -> s:Promise.reject(join(v.stderr, "\n")) })
          \.then({ v -> v.stdout })
          \.then(s:AsyncLambda.filter_f({ v -> !empty(v) && v !=# a:path }))
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
