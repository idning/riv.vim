"=============================================
"    Name: publish.vim
"    File: publish.vim
" Summary: publish to html/pdf.
"  Author: Rykka G.Forest
"  Update: 2012-07-07
"=============================================
let s:cpo_save = &cpo
set cpo-=C
fun! s:repl_file_link(line) "{{{
    " File              Title   Path
    " index.rst     => `index <index.html>`_
    " test.rst      => `test <test.html>`_
    " test.py       => `test.py <test.py>`_
    " Html/         => `Html/   <Html/index.html>`_
    " /home/a.rst   => `/home/a.rst  </home/a.rst>`_    ?
    " ~/a.rst       => `~/a.rst  <~/a.rst>`_            ?
    " ./index.rst   => `./index  <./index.html>`_
    " ../           => `../      <../index.html>`_
    " index.rst#RIV => `index#RIV <index.html#RIV>`_     ToDo
    " [index]       => `[index] <index.html>`_
    " [index.rst]   => `[index] <index.html>`_
    " [index.vim]   => `[index.vim] <index.vim>`_
    " [index/]      => `[index/] <index/index.rst>`_
    " [/home/a.rst] => `[/home/a.rst]  </home/a.rst>`_    ?
    
    " Dont' convert links in table. which will made table malformed.
    "
    " Also links in same line of explicit mark are not converted.
    
    
    let line = a:line
    
    if line =~ g:_riv_p.table || line =~ g:_riv_p.exp_mark
        return line
    endif

    let file = matchstr(line, g:_riv_p.link_file)
    let idx = matchend(line, g:_riv_p.link_file)
    while !empty(file)
        if g:riv_localfile_linktype == 2
            let file = matchstr(file, '^\[\zs.*\ze\]$')
        endif
        let file = s:escape(file)
        if !riv#path#is_relative(file)
                let title = file
                let path = file
        elseif riv#path#is_directory(file)
            let title = file
            let path = title . 'index.html'
        else
            let f = s:get_rst_file(file)
            if !empty(f)
                let title = f
                let path = title.'.html'
            elseif g:riv_localfile_linktype == 2 && fnamemodify(file, ':e') == ''
                let title = file
                let path = title.'.html'
            else
                let title = file
                let path = file
            endif
        endif
        let line = substitute(line, s:escape_file_ptn(file), 
                    \s:gen_embed_link(title, path), 'g')
        let file = matchstr(line, g:_riv_p.link_file,idx)
        let idx = matchend(line, g:_riv_p.link_file,idx)
    endwhile
    return line
endfun "}}}

fun! s:get_rst_file(file) "{{{
    return matchstr(a:file, '.*\ze\.rst$')
endfun "}}}
fun! s:escape_file_ptn(file) "{{{
    if g:riv_localfile_linktype == 2
        return   '\%(^\|\s\)\zs\[' . a:file . '\]\ze\%(\s\|$\)'
    else
        return   '\%(^\|\s\)\zs' . a:file . '\ze\%(\s\|$\)'
    endif
endfun "}}}
fun! s:escape(txt) "{{{
    return escape(a:txt, '~.*\[]^$')
endfun "}}}
fun! s:gen_embed_link(title, path) "{{{
    if g:riv_localfile_linktype == 2
        return  '`['.a:title.'] <'.a:path.'>`_'
    else
        return  '`'.a:title.' <'.a:path.'>`_'
    endif
endfun "}}}

fun! s:rst_args(ft) "{{{
    return exists("g:riv_rst2".a:ft."_args") ? !empty(g:riv_rst2{a:ft}_args)
                \ ? g:riv_rst2{a:ft}_args : '' : ''
endfun "}}}
fun! s:auto_mkdir(path) "{{{
    if !isdirectory(fnamemodify(a:path,':h')) 
        call mkdir(fnamemodify(a:path,':h'),'p')
    endif
endfun "}}}

let s:tempfile = tempname()
let s:tempdir = riv#path#directory(fnamemodify(s:tempfile,':h'))
fun! s:create_tmp(file) "{{{
    update
    let lines = map(readfile(a:file),'s:repl_file_link(v:val)')
    call writefile(lines, s:tempfile)       " not all system can pipe
    return s:tempfile
endfun "}}}

fun! riv#publish#copy2proj(file,html_path) abort "{{{
    let out_path = a:html_path . riv#path#rel_to_root(expand(a:file))
    call s:auto_mkdir(out_path)
    call s:sys( 'cp -f '. a:file. ' '.  fnamemodify(out_path, ':h'))
endfun "}}}
fun! riv#publish#proj2(ft) abort "{{{
    let ft_path = riv#path#build_ft(a:ft)
    let root = riv#path#root()
    let files = filter(split(glob(root.'**/*.rst')), 'v:val !~ ''_build''')
    echohl Function
    echon 'Convert: '
    for file in files
        call riv#publish#2(a:ft,file, ft_path, 0)
        echon '>'
    endfor
    let copy_ext = '{'.join(g:_riv_t.file_ext_lst,',').'}'
    if a:ft == "html" 
        \ && input("Copy all file of extension: ".copy_ext."\n(Y/n):")!~?'n'
        let files = filter(split(glob(root.'**/*'.copy_ext)), 'v:val !~ ''_build''')
        for file in files
            call riv#publish#copy2proj(file, ft_path)
            echon '>'
        endfor
    endif
    echon ' Done.'
    echohl Normal
endfun "}}}

" ['s5', 'latex', 'odt', 'xml' , 'pseudoxml', 'html' ]
fun! riv#publish#file2(ft, browse) "{{{
    let file = expand('%:p')
    if riv#path#is_rel_to_root(file)
        call riv#publish#2(a:ft , file, riv#path#build_ft(a:ft), a:browse)
    else
        call s:single2(a:ft, file, a:browse)
    endif
endfun "}}}
fun! s:single2(ft, file, browse) "{{{
    " A file that is not in a project
    let file = expand(a:file)
    if empty(g:riv_temp_path)
        let out_path = riv#path#ext_to(file, a:ft)
    elseif g:riv_temp_path == 1
        let temp_path = s:tempdir
        let out_path = temp_path . riv#path#ext_tail(file, a:ft)
    else
        let temp_path = riv#path#directory(g:riv_temp_path)  
        let out_path = temp_path . riv#path#ext_tail(file, a:ft)
    endif

    call s:convert(a:ft, file, out_path, s:rst_args(a:ft))

    if a:browse
        if a:ft == "latex"
            exe 'sp ' out_path
        elseif a:ft == "odt"
            call s:sys(g:riv_ft_browser . ' '. shellescape(out_path) . ' &')
        else
            call s:sys(g:riv_web_browser . ' '. shellescape(out_path) . ' &')
        endif
    endif
endfun "}}}
fun! riv#publish#2(ft, file, path, browse) "{{{
    let file = expand(a:file)
    let out_path = a:path . riv#path#rel_to_root(file)
    let file_path = riv#path#ext_to(out_path, a:ft)
    call s:auto_mkdir(out_path)
    call s:convert(a:ft, s:create_tmp(file), file_path, s:rst_args(a:ft))
    if a:browse
        if a:ft == "latex"
            exe 'sp ' file_path
        elseif a:ft == "odt"
            call s:sys(g:riv_ft_browser . ' '. file_path . ' &')
        else
            call s:sys(g:riv_web_browser . ' '. file_path . ' &')
        endif
    endif
endfun "}}}
fun! s:convert(ft, input, output, ...) "{{{
    " try 2 first , for py3 version should decode to 'bytes'.
    let exe = 'rst2'.a:ft.'2.py'
    if !executable(exe)
        let exe = 'rst2'.a:ft.'.py'
        if !executable(exe)
            call riv#error('Could not find '.exe)
            return -1
        endif
    endif
    let args = a:0 ? a:1 : ''
    call s:sys( exe." ". args .' '. shellescape(a:input) . " > " . shellescape(a:output) )
endfun "}}}

fun! riv#publish#browse() "{{{
    let path = riv#path#build_ft('html') .  'index.html'
    call s:sys(g:riv_web_browser . ' '. shellescape(path) . ' &')
endfun "}}}
fun! riv#publish#open_path() "{{{
    exe 'sp ' riv#path#build_path()
endfun "}}}

fun! s:sys(arg) abort "{{{
    return system(a:arg)
endfun "}}}
fun! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun "}}}
fun! riv#publish#SID() "{{{
    return '<SNR>'.s:SID().'_'
endfun "}}}
let &cpo = s:cpo_save
unlet s:cpo_save
