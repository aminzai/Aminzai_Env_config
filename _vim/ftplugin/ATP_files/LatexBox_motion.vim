" Language:	tex
" Maintainer:	Marcin Szamotulski
" Author:	David Mnuger
" Comment:	This is a part of ATP plugin borrowed from LatexBox plugin 
" URL:		
" Email:	mszamot [AT] gmail [DOT] com

" Some things is enough to source once
let s:did_script = exists("s:did_script") ? 1 : 0

" HasSyntax {{{
" s:HasSyntax(syntaxName, [line], [col])
function! s:HasSyntax(syntaxName, ...)
	let line	= a:0 >= 1 ? a:1 : line('.')
	let col		= a:0 >= 2 ? a:2 : col('.')
	return index(map(synstack(line, col), 'synIDattr(v:val, "name") == "' . a:syntaxName . '"'), 1) >= 0
endfunction
" }}}

" Search and Skip Comments {{{
" s:SearchAndSkipComments(pattern, [flags], [stopline])
function! s:SearchAndSkipComments(pat, ...)
	let flags	= a:0 >= 1 ? a:1 : ''
	let stopline	= a:0 >= 2 ? a:2 : 0
	let saved_pos 	= getpos('.')

	" search once
	let ret = search(a:pat, flags, stopline)

	if ret
		" do not match at current position if inside comment
		let flags = substitute(flags, 'c', '', 'g')

		" keep searching while in comment
		while LatexBox_InComment()
			let ret = search(a:pat, flags, stopline)
			if !ret
				break
			endif
		endwhile
	endif

	if !ret
		" if no match found, restore position
		keepjumps call setpos('.', saved_pos)
	endif

	return ret
endfunction
" }}}

" begin/end pairs {{{
"
" s:JumpToMatch(mode, [backward])
" - search backwards if backward is given and nonzero
" - search forward otherwise
"
function! s:JumpToMatch(mode, ...)

    	if a:0 >= 1
	    let backward = a:1
	else
	    let backward = 0
	endif

	let sflags = backward ? 'cbW' : 'cW'

	" selection is lost upon function call, reselect
	if a:mode == 'v'
		normal! gv
	endif

	" open/close pairs (dollars signs are treated apart)
	let open_pats 		= ['{', '\[', '(', '\\begin\>', '\\left\>']
	let close_pats 		= ['}', '\]', ')', '\\end\>', '\\right\>']
	let dollar_pat 		= '\\\@<!\$'
	let two_dollar_pat 	= '\\\@<!\$\$'

	let saved_pos = getpos('.')

	" move to the left until not on alphabetic characters
	call search('\A', 'cbW', line('.'))

	" go to next opening/closing pattern on same line
	if !s:SearchAndSkipComments(
				\	'\m\C\%(' . join(open_pats + close_pats + [dollar_pat], '\|') . '\)',
				\	sflags, line('.'))
		" abort if no match or if match is inside a comment
		keepjumps call setpos('.', saved_pos)
		return
	endif

	let rest_of_line = strpart(getline('.'), col('.') - 1)

	" match for '$' pairs
	if rest_of_line =~ '^\$'

		" check if next character is in inline math
		let [lnum, cnum] = searchpos('.', 'nW')
		if lnum && s:HasSyntax('texMathZoneX', lnum, cnum)
			call s:SearchAndSkipComments(dollar_pat, 'W')
		elseif !s:HasSyntax('texMathZoneY', lnum, cnum)
			call s:SearchAndSkipComments(dollar_pat, 'bW')
		endif

		if lnum && s:HasSyntax('texMathZoneY', lnum, cnum)
			call s:SearchAndSkipComments(two_dollar_pat, 'W')
		else 
			call s:SearchAndSkipComments(two_dollar_pat, 'bW')
		endif
	else

	" match other pairs
	for i in range(len(open_pats))
		let open_pat = open_pats[i]
		let close_pat = close_pats[i]

			if rest_of_line =~ '^\C\%(' . open_pat . '\)'
			" if on opening pattern, go to closing pattern
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'W', 'LatexBox_InComment()')
			return
			elseif rest_of_line =~ '^\C\%(' . close_pat . '\)'
			" if on closing pattern, go to opening pattern
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'bW', 'LatexBox_InComment()')
			return
		endif

	endfor
    endif

endfunction

nnoremap <silent> <Plug>LatexBox_JumpToMatch 		:call <SID>JumpToMatch('n')<CR>
vnoremap <silent> <Plug>LatexBox_JumpToMatch 		:<C-U>call <SID>JumpToMatch('v')<CR>
nnoremap <silent> <Plug>LatexBox_BackJumpToMatch 	:call <SID>JumpToMatch('n', 1)<CR>
vnoremap <silent> <Plug>LatexBox_BackJumpToMatch 	:<C-U>call <SID>JumpToMatch('v', 1)<CR>
" }}}

" select inline math {{{
" s:SelectInlineMath(seltype)
" where seltype is either 'inner' or 'outer'
function! s:SelectInlineMath(seltype)

    	let saved_pos		= getpos('.')

	let synstack		= map(synstack(line("."),col(".")), 'synIDattr(v:val, "name")')

	if len(filter(synstack, "v:val =~ '^texMathZone[A-L]S\\?'"))
	    call s:SelectCurrentEnv(a:seltype)
	    return
	endif

	let ZoneX_pat_O 	= '\\\@<!\$'
	let ZoneX_pat_C 	= '\\\@<!\$'
	let ZoneY_pat_O 	= '\\\@<!\$\$'
	let ZoneY_pat_C 	= a:seltype == 'inner' ? '\\\@<!\$\$' 	: '\\\@<!\$\$'
	let ZoneV_pat_O		= '\\\@<!\\('
	let ZoneV_pat_C		= a:seltype == 'inner' ? '\\\@<!\\)' 	: '\\\@<!\\\zs)' 
	let ZoneW_pat_O		= '\\\@<!\\\['
	let ZoneW_pat_C		= a:seltype == 'inner' ? '\\\@<!\\\]'	: '\\\@<!\\\zs\]'

	if 	( s:HasSyntax('texMathZoneV', line("."), max([1,col(".")-1])) ||
		\ s:HasSyntax('texMathZoneW', line("."), max([1,col(".")-1])) ||
		\ s:HasSyntax('texMathZoneX', line("."), max([1,col(".")-1])) ||
		\ s:HasSyntax('texMathZoneY', line("."), max([1,col(".")-1])) && b:atp_TexFlavor == 'plaintex' )  && 
		\ col(".") > 1
	    normal! h
	elseif 	( s:HasSyntax('texMathZoneV', line("."), max([1,col(".")-2])) ||
		\ s:HasSyntax('texMathZoneW', line("."), max([1,col(".")-2])) ||
		\ s:HasSyntax('texMathZoneY', line("."), max([1,col(".")-2])) && b:atp_TexFlavor == 'plaintex' )  && 
		\ col(".") > 2
	    normal! 2h
	endif

	let return 		= 1 
	let math_zones		= ( b:atp_TexFlavor == 'plaintex' ? [ 'V', 'W', 'X', 'Y'] : [ 'V', 'W', 'X'] )
	for L in math_zones
	    if s:HasSyntax('texMathZone'. L, line(".")) ||
			\ s:HasSyntax('texMathZone'. L, line("."), max([1, col(".")-1]))
		    call s:SearchAndSkipComments(Zone{L}_pat_O, 'cbW')
		    let zone 	= L
		    let return 	= 0
	    endif
	endfor

	if return
	    call cursor(saved_pos[1], saved_pos[2])
	    return
	endif

	if a:seltype == 'inner'
	    if zone =~ '^V\|W$' || zone == 'Y' && b:atp_TexFlavor == 'plaintex'
		normal! 2l
	    elseif zone == 'X'
		normal! l
	    endif
	    if getline(".")[col(".")-1] == ' '
		normal! w
	    endif
	endif

	if visualmode() ==# 'V'
		normal! V
	else
		normal! v
	endif

	call s:SearchAndSkipComments(Zone{zone}_pat_C, 'W')

	if a:seltype == 'inner'
	    if getline(".")[col(".")-2] == ' '
		normal! ge
	    else
		if col(".") > 1
		    call cursor(line("."),col(".")-1)
		else
		    call cursor(line(".")-1, len(getline(line(".")-1)))
		endif
	    endif
	endif

	if a:seltype == 'outer' && zone == 'Y'
	    call cursor(line("."),col(".")+1)
	endif
endfunction


vnoremap <silent> <Plug>LatexBox_SelectInlineMathInner :<C-U>call <SID>SelectInlineMath('inner')<CR>
vnoremap <silent> <Plug>LatexBox_SelectInlineMathOuter :<C-U>call <SID>SelectInlineMath('outer')<CR>
" }}}

" {{{ select syntax
" syntax groups 'texDocZone' and 'texSectionZone' need to be synchronized
" before ':syntax sync fromstart' which is quite slow. It is better to provide
" other method of doing this. (If s:SelectSyntax is not syncing the syntax
" then the behaviour is unpredictable).
function! s:SelectSyntax(syntax)

    " mark the current position
    normal! m'

    let synstack	= map(synstack(line("."),col(".")), 'synIDattr(v:val, "name")')
    " there are better method for texDocZone and texSectionZone: 
    call filter(synstack, "v:val != 'texDocZone' && v:val != 'texSectionZone'")
    if  synstack == []
	return

    endif

    if a:syntax == 'inner'

	let len		= len(synstack)
	let syntax	= synstack[max([0, len-1])]

    elseif a:syntax == 'outer'
	let syntax	= synstack[0]

    else
	let syntax	= a:syntax

    endif

    let save_ww		= &l:ww
    set ww		+=b,l
    let save_pos	= getpos(".")	 


    if !count(map(synstack(line("."),col(".")), 'synIDattr(v:val, "name")'), syntax)
	return

    endif

    while count(map(synstack(line("."),col(".")), 'synIDattr(v:val, "name")'), syntax)
	normal! h
	" for some syntax groups do not move to previous line
	if col(".") == 1 && count(['texStatement', 'texTypeSize'], syntax)
	    keepjumps normal! h
	    break
	endif

    endwhile

    " begin offset
    if getpos(".")[2] < len(getline("."))
	call cursor(line("."),col(".")+1)

    else
	call cursor(line(".")+1, 1)

    endif

    if visualmode() ==# 'V'
	normal! V

    else
	normal! v

    endif

    call cursor(save_pos[1], save_pos[2]) 
    while count(map(synstack(line("."),max([1, min([col("."), len(getline("."))])])), 'synIDattr(v:val, "name")'), syntax) || len(getline(".")) == 0 
	keepjumps normal! l
	" for some syntax groups do not move to next line
	if col(".") == len(getline(".")) && count(['texStatement', 'texTypeSize'], syntax)
	    keepjumps normal! l
	    break
	endif
    endwhile

    " end offset
    if len(getline(".")) == 0
	call cursor(line(".")-1,len(getline(line(".")-1)))
    endif
    if count(['texParen', 'texLength', 'Delimiter', 'texStatement', 'texTypeSize', 'texRefZone', 'texSectionMarker', 'texTypeStyle'], syntax)
	if col(".") > 1
	    call cursor(line("."),col(".")-1)

	else
	    call cursor(line(".")-1,len(getline(line(".")-1)))

	endif
    elseif count(['texMathZoneV', 'texMathZoneW', 'texMathZoneY'], syntax)
	    call cursor(line("."),col(".")+1)

    endif

    let &l:ww	= save_ww
endfunction
vnoremap <silent> <buffer> <Plug>SelectInnerSyntax 	<ESC>:<C-U>call <SID>SelectSyntax('inner')<CR>
vnoremap <silent> <buffer> <Plug>SelectOuterSyntax 	<ESC>:<C-U>call <SID>SelectSyntax('outer')<CR>
" }}}

" select current environment {{{
function! s:SelectCurrentEnv(seltype)
	let [env, lnum, cnum, lnum2, cnum2] = LatexBox_GetCurrentEnvironment(1)
	call cursor(lnum, cnum)
	if a:seltype == 'inner'
		if env =~ '^\'
			call search('\\.\_\s*\S', 'eW')
		else
" 			call search('}\%(\_\s*\[\_[^]]*\]\)\?\%(\_\s*\\label\s*{[^}]*}\)\?\_\s*\S', 'eW')
			call search('}\%(\_\s*\[\_[^]]*\]\)\?\_\s*\S', 'eW')
		endif
	endif
	if visualmode() ==# 'V'
		normal! V
	else
		normal! v
	endif
	call cursor(lnum2, cnum2)
	if a:seltype == 'inner'
		call search('\S\_\s*', 'bW')
	else
		if env =~ '^\'
			normal! l
		else
			call search('}', 'eW')
		endif
	endif
endfunction

function! s:SelectCurrentEnV()
	call s:SelectCurrentEnv('inner')
	execute 'normal o'
	call s:JumpToMatch('n', 1)
	execute 'normal o'
endfunction

vnoremap <silent> <Plug>LatexBox_SelectCurrentEnvInner :<C-U>call <SID>SelectCurrentEnv('inner')<CR>
vnoremap <silent> <Plug>LatexBox_SelectCurrentEnVInner :<C-U>call <SID>SelectCurrentEnV()<CR>
vnoremap <silent> <Plug>LatexBox_SelectCurrentEnvOuter :<C-U>call <SID>SelectCurrentEnv('outer')<CR>
" }}}

" Jump to the next braces {{{
"
function! LatexBox_JumpToNextBraces(backward)
	let flags = ''
	if a:backward
		normal h
		let flags .= 'b'
	else
		let flags .= 'c'
	endif
	if search('[][}{]', flags) > 0
		normal l
	endif
	let prev = strpart(getline('.'), col('.') - 2, 1)
	let next = strpart(getline('.'), col('.') - 1, 1)
	if next =~ '[]}]' && prev !~ '[][{}]'
		return "\<Right>"
	else
		return ''
	endif
endfunction
" }}}

" Highlight Matching Pair {{{
" TODO: Redefine NoMatchParen and DoMatchParen functions to handle
" s:HighlightMatchingPair function.
" TODO: do not match for \begin{document}:\end{document}
" 	or limit matches to the window (anyway it is done every time the
" 	cursor moves).
" 	winheight(0)			returns window height
" 	winsaveview()['topline'] 	returns the top line
function! s:HighlightMatchingPair()

	2match none

	if LatexBox_InComment()
		return
	endif

" 	let open_pats 		= ['\\begin\>\ze\%(\s*{\s*document\s*}\)\@!', '\\left\>', '\c\\bigg\=\>\%((\|{\|\\{\|\[\)' ]
" 	let close_pats 		= ['\\end\>\ze\%(\s*{\s*document\s*}\)\@!', '\\right\>', '\c\\bigg\=\>\%()\|}\|\\}\|\]\)' ]
	let open_pats 		= ['\\begin\>\ze', '\\left\>', '\c\\bigg\=l\=\>\%((\|{\|\\{\|\[\)' ]
	let close_pats 		= ['\\end\>\ze', '\\right\>', '\c\\bigg\=r\=\>\%()\|}\|\\}\|\]\)' ]
	let dollar_pat 		= '\\\@<!\$'
	let two_dollar_pat 	= '\\\@<!\$\$'

	let saved_pos = getpos('.')

	if getline('.')[col('.') - 1] == '$'

	   if strpart(getline('.'), col('.') - 2, 1) == '\'
		   return
	   endif

		" match $-pairs
		let lnum = line('.')
		let cnum = col('.')

		" check if next or previous character is \$
		let two_dollars = ( getline('.')[col('.') - 2] == '$' ? 'p' : 
			    			\ ( getline('.')[col('.') ] == '$' ? 'n' : '0' ) )

		if two_dollars == '0' || b:atp_TexFlavor == 'tex'

		    " check if next character is in inline math
		    let [lnum2, cnum2] = searchpos('.', 'nW')
		    if lnum2 && s:HasSyntax('texMathZoneX', lnum2, cnum2)
			    call s:SearchAndSkipComments(dollar_pat, 'W')
		    else
			    call s:SearchAndSkipComments(dollar_pat, 'bW')
		    endif

		    execute '2match MatchParen /\%(\%' . lnum . 'l\%' . cnum . 'c\$'
					    \	. '\|\%' . line('.') . 'l\%' . col('.') . 'c\$\)/'

		elseif b:atp_TexFlavor == 'plaintex'
		    
		    " check if next character is in inline math
		    if two_dollars == 'n'
			call cursor(line('.'), col('.')+1)
		    endif
		    " position of the openning \$\$
		    let cnum = col('.')-1
		    let [lnum2, cnum2] = searchpos( '.' , 'nW')
		    if lnum2 && s:HasSyntax('texMathZoneY', lnum2, cnum2)
			    call s:SearchAndSkipComments(two_dollar_pat, 'W')
		    else
			" searching backward needs the cursor to be placed
			" before closing $$.
			if col(".") - 2 >= 1
			    call cursor(line("."), col(".")-2)
			else
			    call cursor(line(".")-1, 1) 
			    call cursor(line("."), col("$"))
			endif
			call s:SearchAndSkipComments(two_dollar_pat, 'bW')
		    endif
		    let cnum_e	= cnum+1
		    let cnum_E	= col('.')
		    let cnum_Ee	= cnum_E+1
		    execute '2match MatchParen /\%(\%' . lnum . 'l\%' . cnum . 'c\$'
					    \	. '\|\%' . lnum . 'l\%' . cnum_e . 'c\$'
					    \	. '\|\%' . line('.') . 'l\%' . cnum_E . 'c\$'
					    \	. '\|\%' . line('.') . 'l\%' . cnum_Ee . 'c\$\)/'

		endif

	else
		" match other pairs

		" find first non-alpha character to the left on the same line
		let [lnum, cnum] = searchpos('\A', 'cbW', line('.'))
		if strpart(getline(lnum), 0, cnum)  =~ '\\\%(begin\|end\){[^}]*}\=$'
		    let [lnum, cnum] = searchpos('\\', 'cbW', line('.'))
		endif

		let delim = matchstr(getline(lnum), '^\m\(' . join(open_pats + close_pats, '\|') . '\)', cnum - 1)

		if empty(delim)
			call setpos('.', saved_pos)
			return
		endif

		for i in range(len(open_pats))
			let open_pat = open_pats[i]
			let close_pat = close_pats[i]

			if delim =~# '^' . open_pat
				" if on opening pattern, go to closing pattern
				let stop_line=winheight(0)+winsaveview()['topline']
				call searchpair('\C' . open_pat, '', '\C' . close_pat, 'W', 'LatexBox_InComment()', stop_line)
				execute '2match MatchParen /\%(\%' . lnum . 'l\%' . cnum . 'c' . open_pats[i]
							\	. '\|\%' . line('.') . 'l\%' . col('.') . 'c' . close_pats[i] . '\)/'
				break
			elseif delim =~# '^' . close_pat
				" if on closing pattern, go to opening pattern
				let stop_line=winsaveview()['topline']
				if close_pat =~ '\\end'
				    call searchpair('\C\\begin\>', '', '\C\\end\>\zs'  , 'bW', 'LatexBox_InComment()', stop_line)
				else
				    call searchpair('\C' . open_pat, '', '\C' . close_pat, 'bW', 'LatexBox_InComment()', stop_line)
				endif
				execute '2match MatchParen /\%(\%' . line('.') . 'l\%' . col('.') . 'c' . open_pats[i]
							\	. '\|\%' . lnum . 'l\%' . cnum . 'c' . close_pats[i] . '\)/'
				break
			endif
		endfor
	endif

	call setpos('.', saved_pos)
endfunction
" }}}

" select current paragraph {{{
function! s:SelectCurrentParagraph(seltype) 
    if a:seltype == "inner"
	let [ bline, bcol ] = searchpos('\%(^\s*$\|^[^%]*\%(\ze\\par\>\|\\end\s*{[^}]*}\s*\|\\begin\s*{[^}]*}\s*\%(\%({\|\[\)[^]}]*\%(\]\|}\)\)\=\s*\%({[^}]*}\)\=\s*\%(\%(\\label\s*{[^}]*}\)\s*\%(\\footnote\s*\%(\n\|[^}]\)*}\)\=\|\s*\%(\\footnote\s*\%(\n\|[^}]\)*}\)\s*\%(\\label\s*{[^}]*}\)\=\)\=\)\|\\item\%(\s*\[[^\]]*\]\)\=\|\\\%(part\*\=\|chapter\*\=\|section\*\=\|subsection\*\=\|subsubsection\*\=\|paragraph\*\=\|subparagraph\*\=\)\s*\%(\[[^]]*\]\)\=\s*{[^}]*}\s*\%({^}]*}\)\=\|\\\@<!\\\]\s*$\|\\\@<!\$\$\s*$\|\\\\\*\=\)', 'ebcnW')
	let [ eline, ecol ] = searchpos('\%(^\s*$\|^[^%]*\%(\zs\\par\>\|\\end\s*{\|\\begin\s*{[^}]*}\s*\%(\[[^]]*\]\)\=\)\|\\item\|\\\%(part\*\=\|chapter\*\=\|section\*\=\|subsection\*\=\|\<subsubsection\*\=\|\<paragraph\*\=\|\<subparagraph\*\=\){[^}]*}\s*\%(\[[^]]*\]\)\=\s*\%({^}]*}\)\=\|^\s*\\\@<!\\\[\|^\s*\\\@<!\$\$\|\\\\\*\=\)', 'nW')
	" inner type ends and start with \[:\] if \[ is at the begining of
	" line (possibly with white spaces) and \] is at the end of line
	" (possibly with white spaces, aswell).
	" This can cause some asymetry. So I prefer the simpler solution: \[:\]
	" alwasy ends inner paragraph. But how I use tex it is 'gantz egal'
	" but this solution can make a difference for some users, so I keep
	" the first way.
	let emove	= "ge"
    else
	let [ bline, bcol ] = searchpos('^\s*$\|^[^%]*\zs\\par\>', 'bcnW')
	let [ eline, ecol ] = searchpos('^\s*$\|^[^%]*\zs\\par\>', 'nW')
    endif
"     let [ g:bline, g:bcol]	= deepcopy([ bline, bcol])
"     let [ g:eline, g:ecol]	= deepcopy([ eline, ecol])
    if getline(bline) =~ '\\par'
	" move to the beginning of \par
	let bmove	= ''
    else
	" or to the begining of line 
	let bmove 	=  "w"
    endif

    if getline(eline) =~ '\\par'
	let emove	= 'gE'
    else
	let emove	= 'gE'
    endif

    call cursor(bline, bcol)
    if bmove != ''
	execute "normal " . bmove
    endif

    if mode() !~ 'v'  
	if visualmode() ==# 'V'
		normal! V
	else
		normal! v
	endif
    endif

    call cursor(eline, ecol)
    execute "normal " . emove
endfunction
vnoremap <silent> <Plug>ATP_SelectCurrentParagraphInner :<C-U>call <SID>SelectCurrentParagraph('inner')<CR>
vnoremap <silent> <Plug>ATP_SelectCurrentParagraphOuter :<C-U>call <SID>SelectCurrentParagraph('outer')<CR>
" }}}

if !s:did_script
    augroup LatexBox_HighlightPairs
      " Replace all matchparen autocommands
      autocmd! CursorMoved *.tex call s:HighlightMatchingPair()
    augroup END
endif

" Highlight bold and italic, by M. Szamotulski
" (to add: optionaly only in gui) 
" this function should do that for every \texbf on the screen
" {{{
" THIS IS TOO SLOW:
function! HighlightEmphText()

     let saved_pos	= getpos('.')
     
     let top_line	= winsaveview()['topline']
     let end_line	= top_line + winheight(0)

     call cursor(top_line, 1)

     keepjumps let [start_lnum, start_cnum] = searchpos('\\\%(textbf{\|bf\)\zs', 'W', end_line)
     let [lnum, cnum] = copy([ start_lnum, start_cnum])

     " if there are no matches, return. 
     if [ lnum, cnum] == [0, 0]
	 return
     endif

     while start_lnum <= end_line && [lnum, cnum] != [0, 0]
     
	 let [lnum, cnum] = copy([ start_lnum, start_cnum])

	 if [lnum, cnum] == [ 0, 0]
	     keepjumps call setpos( '.', saved_pos)
	     return
	 endif

" 	 echomsg lnum . " " . cnum
	 while s:HasSyntax('texMatcher', lnum, cnum)
	     if cnum < len(getline(lnum))
		 let cnum += 1
	     else
		 let lnum += 1
		 let cnum  = 1
	     endif
	 endwhile

	 if cnum == 1
	     let stop_lnum = lnum-1
	     let stop_cnum = len(getline(stop_lnum))
	 else
	     let stop_lnum = lnum
	     let stop_cnum = cnum
	 endif


	 let start_lnum 	-= 1
	 let start_cnum		-= 1
	 let stop_lnum  	+= 1

	 call matchadd( 'textBold', '\%>' . start_lnum . 'l\%>' . start_cnum . 'c' . '\%<' . stop_lnum . 'l\%<' . stop_cnum . 'c')

	 let [start_lnum, start_cnum] = searchpos('\\\%(textbf{\|bf\)\zs', 'W', end_line)

     endwhile

     keepjumps call setpos( '.', saved_pos)

"      return [start_lnum, start_cnum, stop_lnum, stop_cnum]
 endfunction
" the 2match function can be run once:
" call s:HighlightEmphText()
" if !s:did_script
"     augroup HighlightEmphText
"       " Replace all matchparen autocommands
"       autocmd CursorMoved *.tex call HighlightEmphText()
"     augroup END
" endif
" }}}
