; ============================================================
;  gui.asm  -  everything the player sees
;
;  InitGdi          create brushes (colours) and fonts
;  CreateControls   create the label, 16 cards, buttons, welcome screen
;  LayoutControls   keep both screens centred when the window is resized
;  DrawItem         paint one owner-draw button (card / Restart / Start)
;  RedrawCard       repaint one card after its state changes
;  ShowGameGroup / ShowWelcomeGroup   switch between the two screens
;  UpdateStatus     refresh "Moves / Score / Time"
;  ShowResult       "You found all pairs - play again?" box
; ============================================================
INCLUDE defs.inc

.code

; ------------------------------------------------------------
; InitGdi: create brushes and fonts once, at start-up
; ------------------------------------------------------------
InitGdi PROC
    INVOKE CreateSolidBrush, COL_BG
    mov brBg, eax
    INVOKE CreateSolidBrush, COL_HIDDEN
    mov brHidden, eax
    INVOKE CreateSolidBrush, COL_FLIP
    mov brFlip, eax
    INVOKE CreateSolidBrush, COL_MATCH
    mov brMatch, eax
    INVOKE CreateSolidBrush, COL_BTN
    mov brBtn, eax

    INVOKE CreateFontA, 44, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, ADDR fontName
    mov hFontTitle, eax
    INVOKE CreateFontA, 38, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, ADDR fontName
    mov hFontCard, eax
    INVOKE CreateFontA, 22, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, ADDR fontName
    mov hFontMid, eax
    INVOKE CreateFontA, 20, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 0, 0, ADDR fontName
    mov hFontSm, eax
    ret
InitGdi ENDP

; ------------------------------------------------------------
; CreateControls: called from WM_CREATE
; ------------------------------------------------------------
CreateControls PROC USES ebx esi, hWnd:DWORD
    ; ---- game screen: status label ----
    INVOKE CreateWindowExA, 0, ADDR clsStatic, ADDR txtStatusInit, \
           WS_CHILD or WS_VISIBLE or SS_CENTER, 20, 15, 350, 30, \
           hWnd, ID_STATUS, hInst, 0
    mov hStatus, eax
    INVOKE SendMessageA, eax, WM_SETFONT, hFontMid, 1

    ; ---- game screen: 16 owner-draw cards in a 4x4 grid ----
    xor esi, esi
card_loop:
    mov eax, esi
    shr eax, 2                      ; row = index / 4
    imul eax, CARD_STEP
    add eax, GRID_Y
    mov ebx, eax                    ; y
    mov eax, esi
    and eax, 3                      ; column = index mod 4
    imul eax, CARD_STEP
    add eax, GRID_X                 ; x
    lea ecx, [esi + ID_CARD0]       ; control ID = 100 + index
    INVOKE CreateWindowExA, 0, ADDR clsButton, ADDR txtHidden, \
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, eax, ebx, CARD_SIZE, CARD_SIZE, \
           hWnd, ecx, hInst, 0
    mov hCards[esi*4], eax
    inc esi
    cmp esi, 16
    jb card_loop

    ; ---- game screen: restart button ----
    INVOKE CreateWindowExA, 0, ADDR clsButton, ADDR txtRestart, \
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, 20, 425, 350, 40, \
           hWnd, ID_RESTART, hInst, 0
    mov hRestart, eax

    ; ---- welcome screen: title, instructions, Start button ----
    INVOKE CreateWindowExA, 0, ADDR clsStatic, ADDR txtTitle, \
           WS_CHILD or WS_VISIBLE or SS_CENTER, 10, 70, 370, 60, \
           hWnd, ID_TITLE, hInst, 0
    mov hTitle, eax
    INVOKE SendMessageA, eax, WM_SETFONT, hFontTitle, 1

    INVOKE CreateWindowExA, 0, ADDR clsStatic, ADDR txtInfo, \
           WS_CHILD or WS_VISIBLE or SS_CENTER, 20, 150, 350, 210, \
           hWnd, ID_INFO, hInst, 0
    mov hInfo, eax
    INVOKE SendMessageA, eax, WM_SETFONT, hFontSm, 1

    INVOKE CreateWindowExA, 0, ADDR clsButton, ADDR txtStart, \
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, 95, 390, 200, 55, \
           hWnd, ID_START, hInst, 0
    mov hStart, eax

    INVOKE ShowGameGroup, SW_HIDE   ; start on the welcome screen
    ret
CreateControls ENDP

; ------------------------------------------------------------
; LayoutControls: keep the game block and the welcome block centred
; in the client area (winW x winH). Called from WM_SIZE, so it runs
; at start-up, on maximize, on restore and while resizing.
; Game block = GAME_W x GAME_H, welcome block = 370 x WEL_H.
; ------------------------------------------------------------
LayoutControls PROC USES ebx esi edi, winW:DWORD, winH:DWORD
    LOCAL baseX:DWORD, baseY:DWORD

    ; ---- top-left corner of the game block, never negative ----
    mov eax, winW
    sub eax, GAME_W
    sar eax, 1                      ; (width - blockWidth) / 2
    jge lx_ok
    xor eax, eax
lx_ok:
    mov baseX, eax
    mov eax, winH
    sub eax, GAME_H
    sar eax, 1                      ; (height - blockHeight) / 2
    jge ly_ok
    xor eax, eax
ly_ok:
    mov baseY, eax

    ; ---- status label ----
    INVOKE MoveWindow, hStatus, baseX, baseY, GAME_W, 30, 1

    ; ---- 16 cards ----
    xor esi, esi
lc_loop:
    mov eax, esi
    shr eax, 2                      ; row
    imul eax, CARD_STEP
    add eax, baseY
    add eax, 45                     ; cards start 45 px below block top
    mov ebx, eax                    ; y
    mov eax, esi
    and eax, 3                      ; column
    imul eax, CARD_STEP
    add eax, baseX                  ; x
    INVOKE MoveWindow, hCards[esi*4], eax, ebx, CARD_SIZE, CARD_SIZE, 1
    inc esi
    cmp esi, 16
    jb lc_loop

    ; ---- restart button ----
    mov eax, baseY
    add eax, 410
    INVOKE MoveWindow, hRestart, baseX, eax, GAME_W, 40, 1

    ; ---- welcome screen: centred horizontally and vertically ----
    mov eax, winW
    sar eax, 1
    mov edi, eax                    ; edi = horizontal centre
    mov eax, winH
    sub eax, WEL_H
    sar eax, 1
    jge lw_ok
    xor eax, eax
lw_ok:
    mov esi, eax                    ; esi = top of welcome block

    mov eax, edi
    sub eax, 185
    INVOKE MoveWindow, hTitle, eax, esi, 370, 60, 1

    mov eax, edi
    sub eax, 175
    mov ebx, esi
    add ebx, 80
    INVOKE MoveWindow, hInfo, eax, ebx, 350, 210, 1

    mov eax, edi
    sub eax, 100
    mov ebx, esi
    add ebx, 320
    INVOKE MoveWindow, hStart, eax, ebx, 200, 55, 1
    ret
LayoutControls ENDP

; ------------------------------------------------------------
; RedrawCard: repaint one card button (index 0..15) immediately
; ------------------------------------------------------------
RedrawCard PROC, idx:DWORD
    mov eax, idx
    INVOKE InvalidateRect, hCards[eax*4], 0, 0
    mov eax, idx
    INVOKE UpdateWindow, hCards[eax*4]
    ret
RedrawCard ENDP

; ------------------------------------------------------------
; Show / hide the two screens (mode = SW_SHOW or SW_HIDE)
; ------------------------------------------------------------
ShowGameGroup PROC USES esi, mode:DWORD
    INVOKE ShowWindow, hStatus, mode
    INVOKE ShowWindow, hRestart, mode
    xor esi, esi
sg_loop:
    INVOKE ShowWindow, hCards[esi*4], mode
    inc esi
    cmp esi, 16
    jb sg_loop
    ret
ShowGameGroup ENDP

ShowWelcomeGroup PROC, mode:DWORD
    INVOKE ShowWindow, hTitle, mode
    INVOKE ShowWindow, hInfo, mode
    INVOKE ShowWindow, hStart, mode
    ret
ShowWelcomeGroup ENDP

; ------------------------------------------------------------
; UpdateStatus: refresh the "Moves / Score / Time" label
; ------------------------------------------------------------
UpdateStatus PROC
    call ComputeTime                ; eax = minutes, edx = seconds
    INVOKE wsprintfA, ADDR buf, ADDR fmtStatus, moves, score, eax, edx
    INVOKE SetWindowTextA, hStatus, ADDR buf
    ret
UpdateStatus ENDP

; ------------------------------------------------------------
; ShowResult: Yes/No box with score, moves, time. EAX = IDYES / IDNO
; ------------------------------------------------------------
ShowResult PROC
    call ComputeTime
    INVOKE wsprintfA, ADDR buf, ADDR fmtWin, score, moves, eax, edx
    INVOKE MessageBoxA, hMain, ADDR buf, ADDR msgTitle, MB_YESNO_QUEST
    ret
ShowResult ENDP

; ------------------------------------------------------------
; DrawItem: paints one owner-draw button (card, Restart, Start)
; ------------------------------------------------------------
DrawItem PROC USES ebx esi edi, pDis:DWORD
    LOCAL txtClr:DWORD, txtPtr:DWORD, hF:DWORD
    LOCAL oldB:DWORD, oldP:DWORD, oldF:DWORD

    mov esi, pDis
    mov edi, [esi + DIS_HDC]
    mov eax, [esi + DIS_ID]
    cmp eax, ID_CARD0
    jb di_button
    cmp eax, ID_CARD0 + 15
    ja di_button

    ; ----- a card: look at its state -----
    sub eax, ID_CARD0               ; eax = card index
    movzx edx, state[eax]
    mov ecx, hFontCard
    mov hF, ecx
    cmp edx, 0
    je di_hidden
    cmp edx, 1
    je di_flipped
    mov ebx, brMatch                ; state 2 = matched (soft orchid)
    mov txtClr, COL_MATCH_TXT
    jmp di_symbol
di_flipped:
    mov ebx, brFlip                 ; state 1 = flipped (light lilac)
    mov txtClr, COL_FLIP_TXT
di_symbol:
    mov dl, cards[eax]
    mov symBuf, dl
    mov txtPtr, OFFSET symBuf
    jmp di_paint
di_hidden:
    mov ebx, brHidden               ; state 0 = hidden (violet "?")
    mov txtClr, COL_HIDDEN_TXT
    mov txtPtr, OFFSET txtHidden
    jmp di_paint

    ; ----- Restart / Start button -----
di_button:
    mov ebx, brBtn
    mov txtClr, COL_BTN_TXT
    mov ecx, hFontMid
    mov hF, ecx
    mov txtPtr, OFFSET txtRestart
    cmp eax, ID_START
    jne di_pressed
    mov txtPtr, OFFSET txtStart
di_pressed:
    test DWORD PTR [esi + DIS_STATE], 1     ; ODS_SELECTED = pressed
    jz di_paint
    mov ebx, brHidden                       ; darker lavender while pressed

    ; ----- common painting -----
di_paint:
    lea ecx, [esi + DIS_RECT]
    INVOKE FillRect, edi, ecx, brBg         ; clear corners to background
    INVOKE SelectObject, edi, ebx
    mov oldB, eax
    INVOKE GetStockObject, NULL_PEN
    INVOKE SelectObject, edi, eax
    mov oldP, eax
    INVOKE RoundRect, edi, DWORD PTR [esi + DIS_RECT], DWORD PTR [esi + DIS_RECT + 4], \
           DWORD PTR [esi + DIS_RECT + 8], DWORD PTR [esi + DIS_RECT + 12], 18, 18
    INVOKE SetBkMode, edi, 1                ; TRANSPARENT
    INVOKE SetTextColor, edi, txtClr
    INVOKE SelectObject, edi, hF
    mov oldF, eax
    lea ecx, [esi + DIS_RECT]
    INVOKE DrawTextA, edi, txtPtr, -1, ecx, 25h   ; centre, vcentre, single line
    INVOKE SelectObject, edi, oldF
    INVOKE SelectObject, edi, oldP
    INVOKE SelectObject, edi, oldB
    mov eax, 1
    ret
DrawItem ENDP

END