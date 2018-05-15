function! s:initialize_highlights() "{{{2
  " 未选中区域
  execute 'highlight TabLine cterm=NONE ctermfg=244 ctermbg=235 gui=NONE guifg=#AFAE89 guibg=#5F5F5F'
  " 选中区域
  execute 'highlight TabLineSel cterm=reverse ctermfg=239 ctermbg=187 gui=reverse guifg=#618AFC guibg=#FFFFFF'
  " 整个区域颜色
  execute 'highlight TabLineFill cterm=NONE ctermfg=244 ctermbg=235 gui=NONE guifg=#FF0000 guibg=NONE'
  " 序号颜色
  execute 'highlight TabLineTabNumber ctermbg=235 ctermfg=33 guibg=#5F5F5F guifg=#AFAE89'
  execute 'highlight TabLineTabNumberSel ctermbg=239 ctermfg=33 guibg=#618AFC guifg=#FFFFFF'
  " 窗口数量提示
  execute 'highlight TabLineWindowCount ctermbg=235 ctermfg=33 guibg=#5F5F5F guifg=#AFAE89'
  execute 'highlight TabLineWindowCountSel ctermbg=239 ctermfg=33 guibg=#618AFC guifg=#FFFFFF'
  " 未保存提示
  execute 'highlight TabLineModifiedFlag ctermbg=235 ctermfg=red guibg=#5F5F5F guifg=#FC3B50'
  execute 'highlight TabLineModifiedFlagSel ctermbg=239 ctermfg=red guibg=#618AFC guifg=#FC3B50'
  "区块的箭头
  execute 'highlight TabLineDivider cterm=reverse ctermfg=239 ctermbg=235 guibg=#618AFC guifg=#5F5F5F'
  execute 'highlight TabLineDividerSel ctermbg=235 ctermfg=239 guibg=#5F5F5F guifg=#618AFC'
  "最后一个区块的箭头
  execute 'highlight TabLineDividerLast  guibg=NONE guifg=#5F5F5F'
  execute 'highlight TabLineDividerLastSel guibg=NONE guifg=#618AFC'
  " 用户自定义
  execute 'highlight TabLineUserLabel ctermfg=173 ctermbg=235 guifg=#FD8C25 guibg=#5F5F5F'
  execute 'highlight TabLineUserLabelSel ctermfg=173 ctermbg=239 guifg=#FFFFFF guibg=#618AFC'
endfunction
function! s:initialize_dividers() "{{{2
  let s:divider_characters = [[0xe0b0], [0xe0b1], [0xe0b2], [0xe0b3]]
  let s:divider_character_hard = s:ParseChars(deepcopy(s:divider_characters[0]))
  let s:divider_character_soft = s:ParseChars(deepcopy(s:divider_characters[1]))
endfunction
function! s:initialize_commands() "{{{2
  command! -range=0 -nargs=? TabberLabel              call <SID>TabberLabel(<count>, <line1>, <f-args>)
endfunction

" 处理箭头符号
function! s:ParseChars(arg) "{{{22
  "Copied from Powerline.
  let arg = a:arg
  if type(arg) == type([])
    call map(arg, 'nr2char(v:val)')
    return join(arg, '')
  endif
  return arg
endfunction

" 展示内容
function! tabber#TabLine() "{{{2
  let tabline = ''
  for tab in range(1, s:last_tab())
    let is_active_tab = tab == s:active_tab()
    let tab_highlight = s:highlighted_text('TabLine', '', is_active_tab)

    let tabline .= tab_highlight
    let tabline .= s:highlighted_text('TabLineTabNumber', ' ' . tab, is_active_tab) . tab_highlight

    let properties = s:properties_for_tab(tab)
    if !empty(properties['label'])
      if properties['tab_of_predefined_label'] > 0
        let highlight = 'TabLineDefaultLabel'
      else
        let highlight = 'TabLineUserLabel'
      endif
      let tab_label = s:highlighted_text(highlight, properties['label'], is_active_tab) . tab_highlight
    else
      let tab_label = s:normal_label_for_tab(tab)
    endif

    let tabline .= ' ' . tab_label . ' '

    if tab != s:last_tab()
      if ((s:active_tab() == tab) || (s:active_tab() == (tab + 1)))
        let tabline .= s:highlighted_text('TabLineDivider', s:divider_character_hard, is_active_tab)
      elseif tab != s:last_tab()
        let tabline .= s:divider_character_soft
      endif
    else
      let tabline .= s:last_highlighted_text('TabLineDivider', s:divider_character_hard, is_active_tab)
    endif
  endfor
  let tabline .= '%#TabLineFill#%T'
  return tabline
endfunction

" 设置tab文字
function! s:set_label_for_tab(tab, label) "{{{2
  let properties = s:properties_for_tab(a:tab)
  let properties.label = a:label
  let properties.tab_of_predefined_label = 0
  call s:save_properties_for_tab(a:tab, properties)
endfunction

function! s:properties_for_tab(tab) "{{{2
  let properties = gettabvar(a:tab, 'tabber_properties')
  if empty(properties)
    return s:create_properties_for_tab(a:tab)
  endif
  return properties
endfunction

function! s:save_properties_for_tab(tab, properties) "{{{2
  call settabvar(a:tab, 'tabber_properties', a:properties)
endfunction

function! s:create_properties_for_tab(tab) "{{{2
  let properties = { 'label': '', 'tab_of_predefined_label': 0 }
  call s:save_properties_for_tab(a:tab, properties)
  return properties
endfunction


" 定义两个小方法
function! s:last_tab() "{{{2
  return tabpagenr('$')
endfunction
function! s:active_tab() "{{{2
  return tabpagenr()
endfunction

" 渲染非最后一行
function! s:highlighted_text(highlight_name, text, is_active_tab) "{{{2
  return '%#' . a:highlight_name . (a:is_active_tab ? 'Sel' : '') . '#' . a:text
endfunction
" 渲染最后一行
function! s:last_highlighted_text(highlight_name, text, is_active_tab) "{{{2
  return '%#' . a:highlight_name . (a:is_active_tab ? 'LastSel' : 'Last') . '#' . a:text
endfunction

" 设置文件名称
function! s:normal_label_for_tab(tab) "{{{2
  let tab_buffer_list = tabpagebuflist(a:tab)
  let window_number = tabpagewinnr(a:tab)
  let active_window_buffer_name = bufname(tab_buffer_list[window_number - 1])
  if !empty(active_window_buffer_name)
    let label = fnamemodify(active_window_buffer_name, ':t')
  else
    let label = 'New File'
  endif
  return label
endfunction

" 更改tab标签
function! s:TabberLabel(count, line1, ...) "{{{2
  let tab = s:active_tab()
  if a:0 == 1
    let new_tab_label = a:1
  else
    let new_tab_label = ''
  endif
  call s:set_label_for_tab(tab, new_tab_label)
  redraw!
endfunction

call s:initialize_commands()
call s:initialize_highlights()
call s:initialize_dividers()
