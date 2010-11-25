" Vim syntax file for Tcl/tk language
" Language:	Tcl - extension sqlite
" Maintained:	SM Smithfield <m_smithfield@yahoo.com>
" Last Change:	11-19-06
" Filenames:    *.tcl
" Version:      0.1

" NOTE:
" the use of eval as a secondary command here overrides the use
" of eval as a secondary command for a slave interp

syn keyword tclSecondary contained close copy complete timeout busy last_insert_rowid nullvalue onecolumn
syn keyword tclSecondary contained changes total_changes authorizer progress collate commit_hook errorcode trace

syn keyword tclSecondary contained eval exists skipwhite nextgroup=tclSQLBraces,tclSQLQuotes
syn keyword tclSecondary contained transaction skipwhite nextgroup=tclSQLTransactionType
syn keyword tclSQLTransactionType contained deferred exclusive immediate skipwhite nextgroup=tclSQLBraces,tclSQLQuotes
hi link tclSQLTransactionType tclEnsemble

syn keyword tclSecondary contained cache skipwhite nextgroup=tclSQLCacheCmds
syn keyword tclSQLCacheCmds contained flush size
hi link tclSQLCacheCmds tclEnsemble

syn keyword tclSecondary contained function skipwhite nextgroup=tclProcDef

" Link To Sql:
if exists("b:current_syntax")
    unlet b:current_syntax
endif
syn include @tclSQLCode syntax/sql.vim
syn region tclSQLBraces contained extend keepend matchgroup=tclBookends start=+{+ end=+}+ contains=@tclSQLCode
syn region tclSQLQuotes contained extend keepend matchgroup=tclBookends start=+"+ end=+"+ contains=@tclSQLCode,@tclLContinue
" TODO add tclVariable to sqlString contains=...
