" Hi Anna,
"
" I thought it would be fun to carry on reminding you that you're awesome
" at vim, but sadly it's not practical for me to sit at your desk giving you
" a thumbs up every few minutes. The good news is that I can easily be replaced
" with a very small vim script.
"
" Enjoy,
" George
"
" P.S. When this gets annoying you should delete the "source anna.vim" line
"      from your ~/.vimrc file.


let g:annas_awesomeness = 0
autocmd InsertLeave * call AnnaWasAwesome()

function! AnnaWasAwesome()
    let g:annas_awesomeness = g:annas_awesomeness + 1

    if (g:annas_awesomeness > 50)
        silent !open "http://georgebrock.com/images/thumbsup.gif"
        redraw!
        let g:annas_awesomeness = 0
    endif
endfunction

