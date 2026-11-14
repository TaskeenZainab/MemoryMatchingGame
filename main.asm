; ============================================================
;  main.asm  -  program entry point
;
;  1. seed the random generator (Irvine32 Randomize)
;  2. create brushes and fonts (InitGdi)
;  3. register the window class and create the window
;  4. run the message loop until the window is closed
;
;  File overview:
;    defs.inc    shared constants, prototypes, extern declarations
;    data.asm    all variables and text
;    game.asm    game logic (deck, shuffle, match, score, timer)
;    gui.asm     drawing and screens
;    wndproc.asm message dispatcher
;    main.asm    this file
; ============================================================
INCLUDE defs.inc

; ---------------- Structures used only here ----------------
MYWNDCLASSEX STRUCT
    cbSize        DWORD ?
    style         DWORD ?
    lpfnWndProc   DWORD ?
    cbClsExtra    DWORD ?
    cbWndExtra    DWORD ?
    hInstance     DWORD ?
    hIcon         DWORD ?
    hCursor       DWORD ?
    hbrBackground DWORD ?
    lpszMenuName  DWORD ?
    lpszClassName DWORD ?
    hIconSm       DWORD ?
MYWNDCLASSEX ENDS

MYMSG STRUCT
    hwnd     DWORD ?
    message  DWORD ?
    wParam   DWORD ?
    lParam   DWORD ?
    time     DWORD ?
    ptX      DWORD ?
    ptY      DWORD ?
MYMSG ENDS

.data
wc          MYWNDCLASSEX <>
msg         MYMSG <>

.code
main PROC
    call Randomize                  ; Irvine32: seed the generator
    call InitGdi                    ; brushes and fonts (gui.asm)

    INVOKE GetModuleHandleA, 0
    mov hInst, eax

    ; ---- register the window class ----
    mov wc.cbSize, SIZEOF MYWNDCLASSEX
    mov wc.style, 0
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInst
    mov wc.hInstance, eax
    mov wc.hIcon, 0
    INVOKE LoadCursorA, 0, IDC_ARROW
    mov wc.hCursor, eax
    mov eax, brBg
    mov wc.hbrBackground, eax       ; dark window background
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, OFFSET className
    mov wc.hIconSm, 0
    INVOKE RegisterClassExA, ADDR wc

    ; ---- create and show the window ----
    INVOKE CreateWindowExA, 0, ADDR className, ADDR winTitle, \
           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_VISIBLE, \
           CW_USEDEFAULT, CW_USEDEFAULT, 410, 520, 0, 0, hInst, 0
    INVOKE ShowWindow, hMain, SW_SHOW
    INVOKE UpdateWindow, hMain

    ; ---- message loop ----
msg_loop:
    INVOKE GetMessageA, ADDR msg, 0, 0, 0
    cmp eax, 0
    jle quit                        ; 0 = WM_QUIT, -1 = error
    INVOKE TranslateMessage, ADDR msg
    INVOKE DispatchMessageA, ADDR msg
    jmp msg_loop

quit:
    INVOKE ExitProcess, 0
main ENDP

END main