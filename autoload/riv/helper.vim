"=============================================
"    Name: helper.vim
"    File: helper.vim
" Summary: helper to access file and lines
"  Author: Rykka G.Forest
"  Update: 2012-06-17
" Version: 0.5
"=============================================
let s:cpo_save = &cpo
set cpo-=C

fun! riv#helper#enter()  "{{{
    call s:helper.exit()
endfun "}}}
fun! riv#helper#exit() "{{{
    call s:helper.exit()
    wincmd p
endfun "}}}
fun! riv#helper#tab() "{{{
    call s:helper.tab()
    call s:helper.render()
endfun "}}}
fun! riv#helper#run() "{{{
    call s:helper.run()
endfun "}}}

" init "{{{
let s:helper = { 'name' : '_Helper_', 
            \}
let s:helper.maps = {
    \  '<Enter>'  : 'riv#helper#enter',
    \  '<KEnter>' : 'riv#helper#enter',
    \  'q'        : 'riv#helper#exit'  ,
    \  '<Esc>'    : 'riv#helper#exit'  ,
    \  '<Tab>'    : 'riv#helper#tab'  ,
    \  '<S-Tab>'  : 'riv#helper#tab'  ,
    \  '/'        : 'riv#helper#run'  ,
    \}
let s:helper.contents = [[]]
let s:helper.content_title = "Helper"
let s:helper.lines = []
let s:helper.clist = []
let s:helper.input = ""
let s:helper.syntax_func = ""
let s:helper.c_id = 0
"}}}
fun! s:helper.win(...) dict "{{{
    call self.new()
    call self.set()
    call self.run()
endfun "}}}
fun! s:helper.new() dict "{{{
    if !s:get_buf(self.name)
        exec 'noa keepa bot 5new  +setl\ nobl '.self.name
    endif
endfun "}}}
fun! s:helper.run() dict "{{{
    call self.render()
    let self.running = 1
    while self.running
        let n = getchar()
        let c = nr2char(n)
        if c =~ '\w\|[ \\''`_,.!?@#$%^&*()<>:"[\]+=_|{}-]'
            let self.input .= c
        elseif n=="\<BS>"
            let self.input = self.input[:-2]
        elseif c=="\<C-W>"
            let self.input = join(split(self.input)[:-2])
        elseif c=="\<C-U>"
            let self.input = ""
        elseif c=="\<Tab>" || c=="\<S-Tab>"
            call self.tab()
        else
            let self.running = 0
        endif
        call self.render()
    endwhile
endfun "}}}
fun! s:helper.map() dict "{{{
    abcl <buffer>
    mapc <buffer>
    let cmd = 'nn <buffer><silent> %s :cal %s()<CR>'
    for [lhs,rhs] in items(self.maps)
        exe printf(cmd,lhs,rhs)
    endfor
    
    " XXX we can't call the numbered dict 
    " exe 'nn <buffer><silent> <ESC> :cal function('.string(self.exit).')<CR>'
    " exe 'nn <buffer><silent> H :function {'.string(self.exit).'}<CR>'
endfun "}}}
fun! s:helper.set() dict "{{{
	setl noswf nonu nowrap nolist nospell nocuc wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
	setl noma
	setl ft=riv
	setl cul
	if v:version > 702
		setl nornu noudf cc=0
	en
    call call(self.syntax_func,[])

    call self.map()

endfun "}}}
fun! s:helper.hi() dict "{{{
    " let [row,col] = getpos('.')[1:2]
    " execute '2match' "none"
    " execute '2match' "DiffText".' /\%'.(row).'l/'
endfun "}}}
fun! s:helper.exit() dict "{{{
	cal s:get_buf(s:helper.name)
	redraw
	try 
	    noa bun!
    catch 
	    noa close! 
    endtry
endfun "}}}
fun! s:helper.tab() dict "{{{
    let self.c_id = self.c_id == len(self.contents)-1 ? 0 : self.c_id + 1
endfun "}}}
fun! s:helper.render() dict "{{{
    cal s:helper.content()
    cal s:helper.stats()
    cal s:helper.prompt()
endfun "}}}
fun! s:helper.stats() dict "{{{
    let chooser = ""
    for name in self.contents_name 
        let chooser .= name == self.contents_name[self.c_id] ? "%4*[".name."]%*" : " ".name." "
    endfor
    let title = self.content_title

    let &l:stl = "%1*".self.content_title .":%* ". chooser
                \."%=Matching Numbers : ". len(self.clist).""
endfun "}}}
fun! s:helper.prompt() dict "{{{
    redraw | echohl Comment | echo ">>" | echohl Normal | echon self.input
endfun "}}}
fun! s:helper.content() dict "{{{
    if g:riv_fuzzy_help == 1
        let fuzzyinput = join(split(self.input,'\zs'),'.*')
    else
        let fuzzyinput = self.input
    endif
    let fuzzyinput = escape(fuzzyinput,'\[]^$~')
    let self.clist = range(len(self.contents[self.c_id]))
    call filter(self.clist,'self.contents[self.c_id][v:val]=~?fuzzyinput')
    
    if !empty(fuzzyinput)
        let fuzzyinput = '\c'.fuzzyinput
    endif

    2match none
    exe '2match IncSearch /' . fuzzyinput.'/'

    let self.lines = map(copy(self.clist), 'self.contents[self.c_id][v:val]')
    let len = len(self.clist)
    if len==0
        resize 1
    elseif len <=4
        exe "resize " len
    elseif winheight(0)<=5
        resize 5
    endif
    setl ma
    1,$d_
    if len==0
        call setline(1,"=== No Match ===")
    else
        call setline(1,self.lines)
    endif
    setl noma
endfun "}}}

fun! s:get_buf(name) "{{{
    """ if buffer exists , go to buffer and return 1
    """ else return 0
    let n = bufwinnr(bufnr(a:name))
    if  n != -1
        exe  n . "wincmd w"
        return n
    else
        return 0
    endif
endfun "}}}

fun! riv#helper#new() "{{{
    return s:helper
endfun "}}}
let &cpo = s:cpo_save
unlet s:cpo_save
