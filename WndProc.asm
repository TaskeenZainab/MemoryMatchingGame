; ============================================================
;  wndproc.asm  -  the window procedure
;
;  Windows calls WndProc every time something happens (window
;  created, button clicked, timer ticked, button needs painting).
;  This file only decides WHICH procedure handles each message:
;
;    WM_CREATE          -> CreateControls   (gui.asm)
;    WM_SIZE            -> LayoutControls   (gui.asm) keeps game centred
;    WM_GETMINMAXINFO   -> minimum window size
;    WM_COMMAND         -> StartGame / CardClicked   (game.asm)
;    WM_DRAWITEM        -> DrawItem         (gui.asm)
;    WM_CTLCOLORSTATIC  -> text colours for labels
;    WM_TIMER           -> UpdateStatus (clock) / FlipBack (mismatch)
;    WM_DESTROY         -> PostQuitMessage
; ============================================================
INCLUDE defs.inc

.code

WndProc PROC USES ebx esi edi, hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg
    cmp eax, WM_CREATE
    je on_create
    cmp eax, WM_SIZE
    je on_size
    cmp eax, WM_GETMINMAXINFO
    je on_minmax
    cmp eax, WM_COMMAND
    je on_command
    cmp eax, WM_DRAWITEM
    je on_drawitem
    cmp eax, WM_CTLCOLORSTATIC
    je on_ctlcolor
    cmp eax, WM_TIMER
    je on_timer
    cmp eax, WM_DESTROY
    je on_destroy
    INVOKE DefWindowProcA, hWnd, uMsg, wParam, lParam
    ret

; ---------- WM_CREATE: build all controls ----------
on_create:
    mov eax, hWnd
    mov hMain, eax
    INVOKE CreateControls, hWnd
    xor eax, eax
    ret

; ---------- WM_SIZE: window resized / maximized / restored ----------
on_size:
    cmp wParam, 1                   ; SIZE_MINIMIZED: nothing to lay out
    je sz_done
    cmp hStart, 0                   ; controls not created yet
    je sz_done
    mov eax, lParam
    and eax, 0FFFFh                 ; low word  = client width
    mov edx, lParam
    shr edx, 16                     ; high word = client height
    INVOKE LayoutControls, eax, edx
sz_done:
    xor eax, eax
    ret

; ---------- WM_GETMINMAXINFO: do not allow a window smaller than the board ----------
on_minmax:
    mov eax, lParam                 ; points to a MINMAXINFO structure
    mov DWORD PTR [eax + 24], 410   ; ptMinTrackSize.x
    mov DWORD PTR [eax + 28], 520   ; ptMinTrackSize.y
    xor eax, eax
    ret

; ---------- WM_COMMAND: a button was pressed ----------
on_command:
    mov eax, wParam
    and eax, 0FFFFh                 ; low word = control ID
    cmp eax, ID_START
    je do_start
    cmp eax, ID_RESTART
    je do_restart
    cmp eax, ID_CARD0
    jb cmd_done
    cmp eax, ID_CARD0 + 15
    ja cmd_done
    sub eax, ID_CARD0               ; card index 0..15
    INVOKE CardClicked, eax
    jmp cmd_done
do_start:
    INVOKE ShowWelcomeGroup, SW_HIDE
    INVOKE ShowGameGroup, SW_SHOW
    call StartGame
    jmp cmd_done
do_restart:
    call StartGame
cmd_done:
    xor eax, eax
    ret

; ---------- WM_DRAWITEM: paint an owner-draw button ----------
on_drawitem:
    INVOKE DrawItem, lParam
    mov eax, 1
    ret

; ---------- WM_CTLCOLORSTATIC: label colours on the cream background ----------
on_ctlcolor:
    mov eax, lParam                 ; the static control being painted
    mov edx, COL_TEXT
    cmp eax, hTitle
    jne cc_set
    mov edx, COL_TITLE              ; welcome title colour
cc_set:
    INVOKE SetTextColor, wParam, edx
    INVOKE SetBkMode, wParam, 1     ; TRANSPARENT
    mov eax, brBg
    ret

; ---------- WM_TIMER ----------
on_timer:
    mov eax, wParam
    cmp eax, ID_TIMER_CLOCK
    je t_clock
    cmp eax, ID_TIMER_FLIP
    jne t_done
    call FlipBack                   ; mismatch delay finished
    jmp t_done
t_clock:
    call UpdateStatus               ; refresh the time display
t_done:
    xor eax, eax
    ret

; ---------- WM_DESTROY ----------
on_destroy:
    INVOKE PostQuitMessage, 0
    xor eax, eax
    ret
WndProc ENDP

END