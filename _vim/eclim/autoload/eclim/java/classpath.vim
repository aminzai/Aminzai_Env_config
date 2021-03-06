" Author:  Eric Van Dewoestine
"
" Description: {{{
"   see http://eclim.org/vim/java/classpath.html
"
" License:
"
" Copyright (C) 2005 - 2009  Eric Van Dewoestine
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" Script Variables {{{
  let s:command_variables = '-command java_classpath_variables'
  let s:command_variable_create =
    \ '-command java_classpath_variable_create -n "<name>" -p "<path>"'
  let s:command_variable_delete =
    \ '-command java_classpath_variable_delete -n "<name>"'
" }}}

" NewClasspathEntry(template) {{{
" Adds a new entry to the current .classpath file.
function! eclim#java#classpath#NewClasspathEntry(arg, template)
  let args = split(a:arg)
  let cline = line('.')
  let ccol = col('.')
  for arg in args
    call s:MoveToInsertPosition()
    let line = line('.')
    call append(line, split(substitute(a:template, '<arg>', arg, 'g'), '\n'))
    call cursor(line + 1, 1)
  endfor
  call cursor(cline + 1, ccol)
endfunction " }}}

" MoveToInsertPosition() {{{
" If necessary moves the cursor to a valid insert position.
function! s:MoveToInsertPosition()
  let start = search('<classpath\s*>', 'wn')
  let end = search('</classpath\s*>', 'wn')
  if line('.') < start || line('.') >= end
    call cursor(end - 1, 1)
  endif
endfunction " }}}

" GetVariableNames() {{{
" Gets a list of all variable names.
function! eclim#java#classpath#GetVariableNames()
  let variables = split(eclim#ExecuteEclim(s:command_variables), '\n')
  return map(variables, "substitute(v:val, '\\(.\\{-}\\)\\s.*', '\\1', '')")
endfunction " }}}

" VariableList() {{{
" Lists all the variables currently available.
function! eclim#java#classpath#VariableList()
  let variables = split(eclim#ExecuteEclim(s:command_variables), '\n')
  if len(variables) == 0
    call eclim#util#Echo("No variables.")
  endif
  if len(variables) == 1 && variables[0] == '0'
    return
  endif
  exec "echohl " . g:EclimInfoHighlight
  redraw
  for variable in variables
    echom variable
  endfor
 echohl None
endfunction " }}}

" VariableCreate(name, path) {{{
" Create or update a variable.
function! eclim#java#classpath#VariableCreate(name, path)
  let command = s:command_variable_create
  let command = substitute(command, '<name>', a:name, '')
  let command = substitute(command, '<path>', fnamemodify(a:path, ':p'), '')

  let result = eclim#ExecuteEclim(command)
  if result != '0'
    call eclim#util#Echo(result)
  endif
endfunction " }}}

" VariableDelete(name) {{{
" Delete a variable.
function! eclim#java#classpath#VariableDelete(name)
  let command = s:command_variable_delete
  let command = substitute(command, '<name>', a:name, '')

  let result = eclim#ExecuteEclim(command)
  if result != '0'
    call eclim#util#Echo(result)
  endif
endfunction " }}}

" CommandCompleteVar(argLead, cmdLine, cursorPos) {{{
" Custom command completion for classpath var relative files.
function! eclim#java#classpath#CommandCompleteVar(argLead, cmdLine, cursorPos)
  let cmdTail = strpart(a:cmdLine, a:cursorPos)
  let argLead = substitute(a:argLead, cmdTail . '$', '', '')

  let vars = eclim#java#classpath#GetVariableNames()
  call filter(vars, 'v:val =~ "^' . argLead . '"')

  return vars
endfunction " }}}

" CommandCompleteVarPath(argLead, cmdLine, cursorPos) {{{
" Custom command completion for classpath var relative files.
function! eclim#java#classpath#CommandCompleteVarPath(argLead, cmdLine, cursorPos)
  let vars = split(eclim#ExecuteEclim(s:command_variables), '\n')

  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let args = eclim#util#ParseCmdLine(cmdLine)
  let argLead = cmdLine =~ '\s$' ? '' : args[len(args) - 1]

  let var_names = deepcopy(vars)
  call filter(var_names, 'v:val =~ "^' . argLead . '"')
  if len(var_names) > 0
    call map(var_names,
      \ "isdirectory(substitute(v:val, '.\\{-}\\s\\+- \\(.*\\)', '\\1', '')) ? " .
      \ "substitute(v:val, '\\(.\\{-}\\)\\s\\+-.*', '\\1', '') . '/' : " .
      \ "substitute(v:val, '\\(.\\{-}\\)\\s\\+-.*', '\\1', '')")
    return var_names
  endif

  let var = substitute(argLead, '\(.\{-}\)/.*', '\1', '')
  let var_dir = ""
  for cv in vars
    if cv =~ '^' . var
      let var_dir = substitute(cv, '.\{-}\s\+- \(.*\)', '\1', '')
      break
    endif
  endfor
  let argLead = substitute(argLead, var, var_dir, '')
  let files = eclim#util#CommandCompleteFile(argLead, a:cmdLine, a:cursorPos)
  call map(files, "substitute(v:val, '" . var_dir . "', '" . var . "', '')")

  return files
endfunction " }}}

" CommandCompleteVarAndDir(argLead, cmdLine, cursorPos) {{{
" Custom command completion for classpath var relative files.
function! eclim#java#classpath#CommandCompleteVarAndDir(argLead, cmdLine, cursorPos)
  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let args = eclim#util#ParseCmdLine(cmdLine)
  let argLead = cmdLine =~ '\s$' ? '' : args[len(args) - 1]

  " complete dirs for first arg
  if cmdLine =~ '^' . args[0] . '\s*' . escape(argLead, '~.\') . '$'
    return eclim#java#classpath#CommandCompleteVar(argLead, a:cmdLine, a:cursorPos)
  endif

  return eclim#util#CommandCompleteDir(argLead, a:cmdLine, a:cursorPos)
endfunction " }}}

" vim:ft=vim:fdm=marker
