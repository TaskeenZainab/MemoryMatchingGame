; ============================================================
;  game.asm  -  game logic only (no drawing code)
;
;  StartGame    build deck, Fisher-Yates shuffle, reset everything
;  CardClicked  flip a card, check for a match, score, win check
;  FlipBack     hide the two mismatched cards after the 1 s delay
;  ComputeTime  elapsed time as minutes (EAX) and seconds (EDX)
; ============================================================
INCLUDE defs.inc

.code

; ------------------------------------------------------------
; ComputeTime: returns EAX = minutes, EDX = seconds
; (live clock while playing, frozen at endTime once game is over)
; ------------------------------------------------------------
ComputeTime PROC
    cmp gameOver, 0
    jne ct_end
    INVOKE GetTickCount
    jmp ct_got
ct_end:
    mov eax, endTime
ct_got:
    sub eax, startTime              ; elapsed ms
    xor edx, edx
    mov ecx, 1000
    div ecx                         ; eax = seconds
    xor edx, edx
    mov ecx, 60
    div ecx                         ; eax = minutes, edx = seconds
    ret
ComputeTime ENDP

; ------------------------------------------------------------
; StartGame: build deck, Fisher-Yates shuffle, reset board/UI
; ------------------------------------------------------------
StartGame PROC USES ebx esi
    INVOKE KillTimer, hMain, ID_TIMER_CLOCK
    INVOKE KillTimer, hMain, ID_TIMER_FLIP

    ; fill deck: 0,0,1,1,2,2... -> 'A','A','B','B',...
    xor esi, esi
fill:
    mov eax, esi
    shr eax, 1
    add al, 'A'
    mov cards[esi], al
    inc esi
    cmp esi, 16
    jb fill

    ; Fisher-Yates: for i = 15 down to 1, swap cards[i] with cards[0..i]
    mov esi, 15
shuf:
    mov eax, esi
    inc eax
    call RandomRange                ; eax = 0..esi
    mov bl, cards[esi]
    mov dl, cards[eax]
    mov cards[esi], dl
    mov cards[eax], bl
    dec esi
    jnz shuf

    ; hide every card
    xor esi, esi
reset:
    mov state[esi], 0
    INVOKE RedrawCard, esi
    inc esi
    cmp esi, 16
    jb reset

    mov firstPick, -1
    mov secondPick, -1
    mov moves, 0
    mov score, 0
    mov pairsFound, 0
    mov busy, 0
    mov gameOver, 0
    INVOKE GetTickCount
    mov startTime, eax
    INVOKE SetTimer, hMain, ID_TIMER_CLOCK, 500, 0
    call UpdateStatus
    ret
StartGame ENDP

; ------------------------------------------------------------
; CardClicked: game logic for one card press (index 0..15)
; ------------------------------------------------------------
CardClicked PROC USES ebx esi, idx:DWORD
    cmp busy, 0
    jne cc_exit                     ; mismatch still showing
    cmp gameOver, 0
    jne cc_exit
    mov esi, idx
    cmp state[esi], 0
    jne cc_exit                     ; already flipped or matched

    ; flip the card face-up
    mov state[esi], 1
    INVOKE RedrawCard, esi

    cmp firstPick, -1
    jne second_pick
    mov firstPick, esi              ; first card of the turn
    jmp cc_exit

second_pick:
    mov secondPick, esi
    inc moves
    mov ebx, firstPick
    mov al, cards[ebx]
    cmp al, cards[esi]
    jne mismatch

    ; ---- match ----
    mov state[ebx], 2
    mov state[esi], 2
    add score, 10
    inc pairsFound
    INVOKE RedrawCard, ebx
    INVOKE RedrawCard, esi
    mov firstPick, -1
    mov secondPick, -1
    cmp pairsFound, 8
    jne cc_update

    ; ---- all pairs found: stop the clock, show result ----
    mov gameOver, 1
    INVOKE GetTickCount
    mov endTime, eax
    INVOKE KillTimer, hMain, ID_TIMER_CLOCK
    call UpdateStatus
    call ShowResult                 ; returns IDYES or IDNO in EAX
    cmp eax, IDYES
    jne quit_game
    call StartGame                  ; play again
    jmp cc_exit
quit_game:
    INVOKE DestroyWindow, hMain     ; "No" ends the program
    jmp cc_exit

mismatch:
    cmp score, 0
    je no_penalty
    dec score                       ; -1, never below 0
no_penalty:
    mov busy, 1                     ; lock input
    INVOKE SetTimer, hMain, ID_TIMER_FLIP, 1000, 0   ; FlipBack runs after 1 s

cc_update:
    call UpdateStatus
cc_exit:
    ret
CardClicked ENDP

; ------------------------------------------------------------
; FlipBack: called by WM_TIMER 1 s after a mismatch
; ------------------------------------------------------------
FlipBack PROC USES esi
    INVOKE KillTimer, hMain, ID_TIMER_FLIP
    mov esi, firstPick
    mov state[esi], 0
    INVOKE RedrawCard, esi
    mov esi, secondPick
    mov state[esi], 0
    INVOKE RedrawCard, esi
    mov firstPick, -1
    mov secondPick, -1
    mov busy, 0                     ; unlock input
    ret
FlipBack ENDP

END