"=============================================
"    Name: create.vim
"    File: riv/create.vim
" Summary: Create miscellaneous things.
"  Author: Rykka G.Forest
"  Update: 2012-06-27
" Version: 0.5
"=============================================
let s:cpo_save = &cpo
set cpo-=C

" link "{{{
fun! s:is_relative(name) "{{{
    return a:name !~ '^\~\|^/\|^[a-zA-Z]:'
endfun "}}}
fun! s:is_directory(name) "{{{
    return a:name =~ '/$' 
endfun "}}}

fun! s:expand_file_link(file) "{{{
    " all with ``
    " when localfile_linktype = 1
    " the name with rst and is relative will be sub to .html
    " the rel directory will add index.html
    " other's unchanged
    " when localfile_linktype =2
    " the name with [xx] and is relative will be sub to .html
    " the rel directory with [] will add index.html
    " other unchanged.
    let file = a:file
    let str = matchstr(file, '^\[\zs.*\ze\]$')
    if g:riv_localfile_linktype == 2 && !empty(str)
        let file = str
    endif
    if !s:is_relative(file)
            let ref = '`'.file.'`_'
            let tar = '.. _`'.file.'`: '.file
    elseif s:is_directory(file)
        let ref = '`'.file.'`_'
        let tar = '.. _`'.file.'`: '.file.'index.html'
    else
        if file =~ '\.rst$'
            let ref = '`'.file.'`_'
            let tar = '.. _`'.file.'`: '. fnamemodify(file, ':r').'.html'
        elseif fnamemodify(file, ':e') == '' && g:riv_localfile_linktype == 2
            let ref = '`'.file.'`_'
            let tar = '.. _`'.file.'`: '.file.'.html'
        else
            let ref = '`'.file.'`_'
            let tar = '.. _`'.file.'`: '.file
        endif
    endif
    return [ref, tar]
endfun "}}}
fun! s:expand_link(word) "{{{
    " expand file, and let the refname expand
    let word = a:word
    if word=~ g:_riv_p.link_file
        return s:expand_file_link(word)
    else
        if word =~ '\v^'.g:_riv_p.ref_name.'$'
            if word =~ '^[[:alnum:]]\{40}$'
                let [ref, tar] = [word[:7].'_', '.. _' . word[:7].': '.word]
            else
                let ref = word.'_'
                let tar = '.. _'.word.': '.word
            endif
        elseif word =~ g:_riv_p.link_ref_footnote
            " footnote
            let trim = strpart(word,  0 , len(word)-1)
            let ref = word
            let tar = '.. '.trim.' '.trim
        elseif word =~ g:_riv_p.link_ref_normal
            let trim = strpart(word,  0 , len(word)-1)
            let ref = word
            let tar = '.. _'.trim.': '.trim
        elseif word =~ g:_riv_p.link_ref_anonymous
            " anonymous link
            let ref = word
            let tar = '__ '.s:normal_phase(word)
        elseif word =~ g:_riv_p.link_ref_phase
            let trim = s:normal_phase(word)
            let ref = word
            let tar = '.. _'.trim.': '.trim
        else
            let ref = '`'.word.'`_'
            let tar = '.. _`'.word.'`: '.word
        endif
        return [ref, tar]
    endif
endfun "}}}

fun! s:normal_phase(text) "{{{
    let text = substitute(a:text ,'\v(^__=|_=_$)','','g')
    let text = substitute(text ,'\v(^`|`$)','','g')
    let text = substitute(text ,'\v(^\[|\]$)','','g')
    return text
endfun "}}}
fun! s:get_cWORD_obj() "{{{
    let line = getline('.')
    let ptn = printf('\%%%dc.', col('.'))
    let obj = {}
    if matchstr(line, ptn)=~'\S'
        let ptn = '\S*'.ptn.'\S*'
        let obj.str = matchstr(line, ptn)
        let obj.start = match(line, ptn)
        let obj.end  = matchend(line, ptn)
    endif
    return obj
endfun "}}}
fun! s:get_phase_obj() "{{{
    " if cursor is in a phase ,return it's idx , else return -1
    let line = getline('.')
    let col = col('.')
    let ptn = printf('`[^`]*\%%%dc[^`]*`__\?\|\%%%dc`[^`]*`__\?', col, col)
    let obj = {}
    let start = match(line, ptn)
    if start != -1
        let obj.start = start
        let obj.str = matchstr(line, ptn)
        let obj.end  = matchend(line, ptn)
    endif
    return obj
endfun "}}}
fun! riv#create#link() "{{{
    let [row, col] = [line('.'), col('.')]
    let line = getline(row)

    let obj = s:get_phase_obj()
    if empty(obj)
        let obj = s:get_cWORD_obj()
    endif
    if !empty(obj)
        let word = obj.str
        let idx  = obj.start + 1
        let end  = obj.end + 1
    else
        let word = input("Input a link name:")
        if word =~ '^\s*$'
            return
        endif
        let idx = col
        let end = col
    endif

    let [ref, tar] = s:expand_link(word)

    let line = substitute(line, '\%'.idx.'c.\{'.(end-idx).'}', ref, '')

    call setline(row , line)
    call append(row, ["",tar])
    exe "normal! jj0f:2lv$\<C-G>"
endfun "}}}
"}}}
" section title "{{{
fun! riv#create#title(level) "{{{
    " Create a title of level.
    " If it's empty line, ask the title
    "     append line
    " If it's non empty , use it. 
    "     and if prev line is nonblank. append a blank line
    " append title 
    let row = line('.')
    let lines = []
    let pre = []
    let line = getline(row)
    let shift = 3
    if line =~ '^\s*$'
        let title = input("Create Level ".a:level." Title.\nInput The Title Name:")
        if title == ''
            return
        endif
        call add(lines, title)
    else
        let title = line
        if row-1!=0 && getline(row-1)!~'^\s*$'
            call add(pre, '')
        endif
    endif
    if len(title) >= 60
        call riv#warning("This line Seems too long to be a title."
                    \."\nYou can use block quote Instead.")
        return
    endif

    if exists("g:_riv_c.sect_lvs[a:level-1]")
        let t = g:_riv_c.sect_lvs[a:level-1]
    else
        let t = s:sect_lv_b[ a:level - len(g:_riv_c.sect_lvs) - 1 ]
    endif
    
    let t = repeat(t, len(title))
    call add(lines, t)
    call add(lines, '')

    call append(row,lines)
    call append(row-1,pre)
    call cursor(row+shift,col('.'))
    
endfun "}}}

fun! s:get_sect_txt() "{{{
    " get the section text of the row
    let row = line('.')
    if !exists('b:riv_obj')
        call riv#error('No buf object found.')
        return 0
    endif
    let sect = b:riv_obj['sect_root']
    while !empty(sect.child)
        for child in sect.child
            if child <= row && b:riv_obj[child].end >= row
                let sect = b:riv_obj[child]
                break
            endif
        endfor
        if child > row
            break       " if last child > row , then no match,
                        " put it here , cause we can not break twice inside
        endif
    endwhile
    if sect.bgn =='sect_root'
        return 0
    else
        return sect.txt
    endif
endfun "}}}
fun! riv#create#rel_title(rel) "{{{
    let sect = s:get_sect_txt()
    if !empty(sect)
        let level = len(split(sect, g:riv_fold_section_mark)) + a:rel
    else
        let level = 1
    endif
    let level = level<=0 ? 1 : level

    call riv#create#title(level)
    
endfun "}}}
fun! riv#create#show_sect() "{{{
    let sect = s:get_sect_txt()
    if !empty(sect)
        echo 'You are in section: '.sect
    else
        echo 'You are not in any section.'
    endif
endfun "}}}
"}}}
" scratch "{{{
fun! riv#create#scratch() "{{{
    let scr = g:_riv_c.p[s:id()]._scratch_path . strftime("%Y-%m-%d") . '.rst'
    call s:split(scr)
endfun "}}}
let s:months = g:_riv_t.month_names
fun! s:format_src_index() "{{{
    " category scratch by month and format it 4 items a line
    let path = g:_riv_c.p[s:id()]._scratch_path
    if !isdirectory(path)
        return -1
    endif
    let files = split(glob(path.'*.rst'),'\n')
    "
    let dates = filter(map(copy(files), 'fnamemodify(v:val,'':t:r'')'),'v:val=~''[[:digit:]_-]\+'' ')

    " create a years dictionary contains year dict, 
    " which contains month dict, which contains days list
    let years = {}
    for date in dates
        let [_,year,month,day;rest] = matchlist(date, '\(\d\{4}\)-\(\d\{2}\)-\(\d\{2}\)')
        if !has_key(years, year)
            let years[year] = {}
        endif
        if !has_key(years[year], month)
            let years[year][month] = []
        endif
        call add(years[year][month], date)
    endfor
    
    let lines = []
    for year in keys(years)
        call add(lines, "Year ".year)
        call add(lines, "=========")
        for month in keys(years[year])
            call add(lines, "")
            call add(lines, s:months[month-1])
            call add(lines, repeat('-', strwidth(s:months[month-1])))
            let line_lst = [] 
            for day in years[year][month]
                if g:riv_localfile_linktype ==2 
                    let f = printf("[%s]",day)
                else
                    let f = printf("%s.rst",day)
                endif
                call add(line_lst, f)
                if len(line_lst) == 4
                    call add(lines, join(line_lst,"    "))
                    let line_lst = [] 
                endif
            endfor
            call add(lines, join(line_lst,"    "))
        endfor
        call add(lines, "")
    endfor

    let file = path.'index.rst'
    call writefile(lines , file)
endfun "}}}

fun! riv#create#view_scr() "{{{
    call s:format_src_index()
    let path = g:_riv_c.p[s:id()]._scratch_path
 
    call s:split(path.'index.rst')
endfun "}}}
fun! s:escape_file_ptn(file) "{{{
    if g:riv_localfile_linktype == 2
        return   '\%(^\|\s\)\zs\[' . fnamemodify(a:file, ':t:r') 
                    \ . '\]\ze\%(\s\|$\)'
    else
        return   '\%(^\|\s\)\zs' . fnamemodify(a:file, ':t') . '\ze\%(\s\|$\)'
    endif
endfun "}}}
fun! riv#create#delete() "{{{
    let file = expand('%:p')
    if input("Deleting '".file."'\n Continue? (y/N)?") !~?"y"
        return 
    endif
    let ptn = s:escape_file_ptn(file)
    call delete(file)

    exe 'edit ' expand('%:p:h').'/index.rst'
    let b:riv_p_id = s:id()

    let f_idx = filter(range(1,line('$')),'getline(v:val)=~ptn')
    for i in f_idx
        call setline(i, substitute(getline(i), ptn ,'','g'))
    endfor
    update
    redraw
    echo len(f_idx) ' relative link in index deleted.'
endfun "}}}
"}}}
" todo helper "{{{
let s:slash = has('win32') || has('win64') ? '\' : '/'
fun! s:get_rel_to(dir,path) "{{{
    if a:dir == 'root'
        let root = s:get_root_path()
    else
        " use fnamemodify ':gs?\\?/?' ?
        let root = s:get_root_path().a:dir . s:slash
    endif
    if match(a:path, root) == -1
        throw 'Riv: Not Same Path with Project'
    endif
    let r_path = substitute(a:path, root , '' , '')
    let r_path = substitute(r_path, '^/', '' , '')
    return r_path
endfun "}}}
fun! s:cache_todo(force) "{{{
    " TODO: we should cache once for the first time or manually
    " and update them with editing buffer only.
    let root = s:get_root_path()
    let cache = root.'.rst_cache'
    if filereadable(cache) && a:force==0
        return
    endif
    let files = split(glob(root.'**/*.rst'))
    let files = filter(files, ' v:val !~ ''_build''')
    let todos = []
    echo 'Caching...'
    let lines = []
    for file in files
        let lines += s:file2lines(readfile(file),file)
    endfor
    echon 'Done'
    
    call writefile(lines , cache)
endfun "}}}
fun! s:file2list(filelines,filename) "{{{
    " setup a qflist dict list
    let lines = a:filelines
    let list  = range(len(lines))
    call filter(list, 'lines[v:val]=~g:_riv_p.todo_all && lines[v:val] !~ g:_riv_p.todo_done_list_ptn ')
    let dictlist = map(list,
        \'{"filename": a:filename ,"bufnr":0 , "lnum":v:val+1 , "line":lines[v:val] }')
    return dictlist
endfun "}}}
fun! s:strip(line) "{{{
    return substitute(a:line,'^\s*\(.\{-}\)\s*$','\1','')
endfun "}}}

fun! s:file2lines(filelines,filename) "{{{
    let lines = a:filelines
    let list  = range(len(lines))
    call filter(list, 'lines[v:val]=~g:_riv_p.todo_all  ')
    let f = s:get_rel_to('root',a:filename)
    call map(list , 'printf("%-20s %4d | ",f,(v:val+1)). s:strip(lines[v:val])')
    return list
endfun "}}}

fun! s:get_root_path() "{{{
    return g:_riv_c.p[s:id()]._root_path
endfun "}}}

fun! s:list2lines(list) "{{{
    let lines = []
    for [file, todos] in a:list
        call add(lines , "F: ".file)
        for [lnum, item] in todos
            call add(lines, lnum.":\t".item)
        endfor
    endfor
    return lines
endfun "}}}
fun! s:lines2list(lines) "{{{
    let list = []
    let todos = []
    for line in a:lines
        let str=matchstr(line, '^F: \zs.*')
        if !empty(str) "{{{
            if !empty(todos)
                call add(list,todos)
            endif
            let tds = []
            let todos = [str, tds]
        endif "}}}
        let td= matchstr(line, '^\d\+:\t.*')
        if !empty(td)
            call add(tds , td)
        endif
    endfor
    return list
endfun "}}}
fun! s:lines2helper(lines) "{{{
    let list = []
    let todos = []
    let path = []
    let lines = []
    let g:_riv_td_path = [path, lines]
    for line in a:lines
        let file=matchstr(line, '^F: \zs.*')
        if !empty(file) "{{{
            if !empty(todos)
                call extend(list,todos)
            endif
            let f = file
            let todos = []
        endif "}}}
        let td= matchstr(line, '^\d\+:\t\zs.*')
        if !empty(td)
            let lnum= matchstr(line, '^\d\+\ze:\t.*')
            call add(path, [f, lnum])
            call add(lines, td)
            call add(todos, td)
        endif
    endfor
    return list
endfun "}}}
fun! s:load_todo() "{{{
    call s:cache_todo(0)
    " return s:lines2helper(readfile(s:get_root_path().'.rst_cache'))
    return readfile(s:get_root_path().'.rst_cache')
endfun "}}}
fun! riv#create#force_update() "{{{
    call s:cache_todo(1)
endfun "}}}
fun! riv#create#update_todo() "{{{
    " every time writing buffer.
    " parse the buffer. find the todo item.
    " then parse the cache , remove lines match the buffer filename
    " add with the buffer's new todo-item
    let file = expand('%:p')
    " windows use '\' as directory delimiter
    if file =~ escape(g:_riv_c.p[s:id()]._build_path,'\')
        return
    endif
    try
        let lines = s:file2lines(getline(1,line('$')), file)
        let cache = s:get_root_path() .'.rst_cache'
        let f = s:get_rel_to('root',file)
    catch /Riv: Not Same Path with Project/
        return
    endtry
    if filereadable(cache)
        let c_lines = filter(readfile(cache), ' v:val!~escape(f,''\'')')
    else
        let c_lines = []
    endif
    call writefile(c_lines+lines , cache)
endfun "}}}
fun! riv#create#enter() "{{{
    let [all,file,lnum;rest] = matchlist(getline('.'),  '\v^(\S*)\s+(\d+)\ze |')
    call s:todo.exit()
    " exe 'sp ' s:get_root_path().file
    call s:split(s:get_root_path().file)
    call cursor(lnum, 1)
    normal! zv
endfun "}}}
fun! s:split(file) "{{{
    exe 'sp ' a:file
    let b:riv_p_id = s:id()
endfun "}}}
fun! s:edit(file) "{{{
    exe 'edit ' a:file
    let b:riv_p_id = s:id()
endfun "}}}
let s:td_keywords = g:_riv_p.td_keywords
fun! riv#create#syn_hi() "{{{
    syn match rivHelperFile  '^\S*' 
    syn match rivHelperLNum  '\s\+\d\+ |'
    exe 'syn match rivHelperTodo '
            \.'`\v\c%(^\S*\s+\d+ |)@<=\s*%([-*+]|%(\d+|[#a-z]|[imlcxvd]+)[.)])\s+'
            \.'%(\[.\]|'. s:td_keywords .')'
            \.'%(\s\d{4}-\d{2}-\d{2})='.'%(\s\~ \d{4}-\d{2}-\d{2})='
            \.'\ze%(\s|$)` transparent contains=@rivTodoBoxGroup'

    exe 'syn match rivHelperTodoDone '
            \.'`\v\c%(^\S*\s+\d+ |)@<=\s*%([-*+]|%(\d+|[#a-z]|[imlcxvd]+)[.)])\s+'
            \. g:_riv_p.todo_done_ptn
            \.'%(\s\d{4}-\d{2}-\d{2})='.'%(\s\~ \d{4}-\d{2}-\d{2})='
            \.'\ze%(\s|$)` '
    syn cluster rivTodoBoxGroup contains=rivTodoList,rivTodoBoxList,rivTodoTmsList,rivTodoTmsEnd
    syn match rivTodoList `\v\c\s*%([-*+]|%(\d+|[#a-z]|[imlcxvd]+)[.)])\s+`
                \ contained nextgroup=rivTodoBoxList
    exe 'syn match rivTodoBoxList '
                \.'`\v%(\[.\]|'. s:td_keywords .')`'
                \.' nextgroup=rivTodoTmsList contained'
    syn match rivTodoTmsList `\v\d{4}-\d{2}-\d{2}` contained nextgroup=rivTodoTmsEnd
    syn match rivTodoTmsEnd  `\v\~ \zs\d{4}-\d{2}-\d{2}` contained
    hi def link rivTodoList    Function
    hi def link rivTodoBoxList Include
    hi def link rivTodoTmsList Number
    hi def link rivTodoTmsEnd  Number
    hi def link rivHelperTodoDone Comment

    hi link rivHelperLNum SpecialComment
    hi link rivHelperFile Function
endfun "}}}
fun! riv#create#tab() "{{{
    " call s:helper.tab()
    echom string(s:todo.c_id)
    let s:todo.c_id = s:todo.c_id == len(s:todo.contents)-1 ? 0 : s:todo.c_id + 1
    call s:todo.render()
endfun "}}}
fun! riv#create#todo_helper() "{{{
    " TODO: Create more actions.
    let s:todo = riv#helper#new()
    let All = s:load_todo()
    let Todo = filter(copy(All),'v:val!~''\v''.g:_riv_p.todo_done_ptn ')
    let Done = filter(copy(All),'v:val=~''\v''.g:_riv_p.todo_done_ptn ') 
    let s:todo.contents = [All,Todo,Done]
    let s:todo.contents_name = ['All', 'Todo', 'Done']
    let s:todo.content_title = "Todo Helper"

    let s:todo.maps['<Enter>'] = 'riv#create#enter'
    let s:todo.maps['<KEnter>'] = 'riv#create#enter'
    let s:todo.maps['<2-leftmouse>'] = 'riv#create#enter'
    " let s:todo.maps['<Tab>'] = 'riv#create#tab'
    let s:todo.syntax_func  = "riv#create#syn_hi"
    let s:todo.input=""
    cal s:todo.win()
endfun "}}}
"}}}

" misc "{{{
fun! riv#create#foot() "{{{
    " return a link target and ref def.
    " DONE: 2012-06-10 get buf last footnote.
    " DONE: 2012-06-10 they should add at different position.
    "       current and last.
    "   
    " put cursor in last line and start backward search.
    " get the last footnote and return.

    let id = riv#link#get_last_foot()[1] + 1
    let line = getline('.') 

    if line =~ g:_riv_p.table
        let tar = substitute(line,'\%' . col(".") . 'c' , ' ['.id.']_ ', '')
    elseif line =~ '\S\@<!$'
    " have \s before eol.
        let tar = line."[".id."]_"
    else
        let tar = line." [".id."]_"
    endif
    let footnote = input("[".id."]: Your footnote message is?\n")
    if empty(footnote) | return | endif
    let def = ".. [".id."] ".footnote
    call setline(line('.'),tar)
    call append(line('$'),def)
    
endfun "}}}
fun! riv#create#date(...) "{{{
    if a:0 && a:1 == 1
        exe "normal! a" . strftime('%Y-%m-%d %H:%M:%S') . "\<ESC>"
    else
        exe "normal! a" . strftime('%Y-%m-%d') . "\<ESC>"
    endif
endfun "}}}
fun! riv#create#auto_mkdir() "{{{
    let dir = expand('%:p:h')
    if !isdirectory(dir)
        call mkdir(dir,'p')
    endif
endfun "}}}
"}}}

" cmd helper "{{{
fun! s:load_cmd() "{{{
    let list = items(g:riv_default.buf_maps)
    return map(list, 'string(v:val[0]).string(v:val[1])')
endfun "}}}
fun! riv#create#cmd_helper() "{{{
    " showing all cmds
    
    let s:cmd = riv#helper#new()
    " let s:cmd.contents = s:load_cmd()
    let s:cmd.maps['<Enter>'] = 'riv#create#enter'
    " let s:cmd.maps['<KEnter>'] = 'riv#create#enter'
    " let s:cmd.maps['<2-leftmouse>'] = 'riv#create#enter'
    " let s:cmd.syntax_func  = "riv#create#syn_hi"
    let s:cmd.contents = [s:load_cmd(),
                \filter(copy(s:cmd.contents[0]),'v:val=~g:_riv_p.todo_done_list_ptn '),
                \filter(copy(s:cmd.contents[0]),'v:val!~g:_riv_p.todo_done_list_ptn '),
                \]
    let s:cmd.input=""
    cal s:cmd.win()
endfun "}}}
"}}}

fun! s:id() "{{{
    return exists("b:riv_p_id") ? b:riv_p_id : g:riv_p_id
endfun "}}}
fun! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun "}}}
fun! riv#create#SID() "{{{
    return '<SNR>'.s:SID().'_'
endfun "}}}

let &cpo = s:cpo_save
unlet s:cpo_save
