" Vim indent file
" Language:         reStructuredText Documentation Format
" Maintainer:       Nikolai Weibull <now@bitwi.se>
" Modified By:      Rykka G.Forest <Rykka10@gmail.com>
" Latest Revision:  2012-06-05

if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetRSTIndent(v:lnum)
setlocal indentkeys=!^F,o,O
setlocal nosmartindent

if exists("*GetRSTIndent")
    finish
endif

function! GetRSTIndent(row) "{{{
    
    let pnb_num = prevnonblank(a:row - 1)
    if pnb_num == 0
        return 0
    endif

    let p_line = getline(a:row - 1)

    " Field List
    " 1:ind
    let p_ind =  matchend(p_line, g:_riv_p.field_list)
    if p_ind != -1
        return p_ind
    endif

    let pnb_line = getline(pnb_num)
    let ind = indent(pnb_num)
    
    " list
    " 1/2:fix ind
    " 3: ind
    " 4: prev ind
    let l_ind = matchend(pnb_line, g:_riv_p.list_all)
    if l_ind != -1 &&  a:row <= pnb_num+2 
        return (ind + l_ind - matchend(pnb_line, '^\s*'))
    elseif l_ind != -1 &&  a:row <= pnb_num+3 
        return ind
    elseif l_ind != -1 &&  a:row >= pnb_num+4 
        call cursor(pnb_num,1)
        let p_lnum = searchpos(g:_riv_p.list_all.'|^\S', 'bW')[0]
        let p_ind  = matchend(getline(p_lnum),g:_riv_p.list_all)
        if p_ind != -1
            return indent(p_lnum)
        endif
    endif
    
    " literal-block
    " 1/2+:ind  
    " 2:4
    let l_ind = matchend(pnb_line, '[^:]::\s*$')
    if l_ind != -1 &&  a:row == pnb_num+2
        return 4
    endif

    " exp_markup
    " 1~2: ind
    let l_ind = matchend(pnb_line, '^\s*\.\.\s')
    if l_ind != -1 &&  a:row <= pnb_num+2
        return (ind + l_ind - matchend(pnb_line, '^\s*'))
    endif
    
    " one empty without match
    " 1: ind
    " 2+ : check prev exp_mark
    if a:row > pnb_num+1
        call cursor(pnb_num,1)
        let p_line = getline(searchpos('^\s*\.\.\s\|^\S', 'bW')[0])
        let p_ind  = matchend(p_line,'^\s*\.\.\s')
        if p_ind != -1
            return p_ind
        endif
    endif

    return ind
endfunction "}}}
