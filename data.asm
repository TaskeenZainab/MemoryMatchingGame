; ============================================================
;  data.asm  -  all global variables and text strings
;  (declared as EXTERNDEF in defs.inc so other files can use them)
; ============================================================
INCLUDE defs.inc

.data

; ---------------- text ----------------
className     BYTE "MemoryMatchWnd", 0
winTitle      BYTE "Memory Matching Game", 0
clsButton     BYTE "BUTTON", 0
clsStatic     BYTE "STATIC", 0
txtHidden     BYTE "?", 0
txtRestart    BYTE "Restart", 0
txtStart      BYTE "Start Game", 0
txtTitle      BYTE "Memory Match", 0
txtInfo       BYTE "Find all 8 pairs of matching cards.", 13, 10, 13, 10
              BYTE "Flip two cards per turn.", 13, 10
              BYTE "Match: +10 points", 13, 10
              BYTE "Mismatch: -1 point", 13, 10, 13, 10
              BYTE "Fewer moves and a faster time is better!", 0
txtStatusInit BYTE "Moves: 0   Score: 0   Time: 00:00", 0
fmtStatus     BYTE "Moves: %d   Score: %d   Time: %02d:%02d", 0
fmtWin        BYTE "You found all 8 pairs!", 13, 10, 13, 10
              BYTE "Score: %d", 13, 10
              BYTE "Moves: %d", 13, 10
              BYTE "Time: %02d:%02d", 13, 10, 13, 10
              BYTE "Play again?", 0
msgTitle      BYTE "Memory Matching Game", 0
fontName      BYTE "Segoe UI", 0
buf           BYTE 160 DUP(0)           ; scratch buffer for wsprintf

; ---------------- game data (same design as the proposal) ----------------
cards       BYTE 16 DUP(0)          ; shuffled symbols
state       BYTE 16 DUP(0)          ; 0 = hidden, 1 = flipped, 2 = matched
hCards      DWORD 16 DUP(0)         ; window handle of each card button
symBuf      BYTE 0, 0               ; one-character string for DrawText

firstPick   DWORD -1                ; index of first card this turn (-1 = none)
secondPick  DWORD -1
moves       DWORD 0
score       DWORD 0
pairsFound  DWORD 0
startTime   DWORD 0                 ; GetTickCount at game start
endTime     DWORD 0                 ; GetTickCount when last pair found
busy        DWORD 0                 ; 1 while a mismatch is on screen
gameOver    DWORD 0

; ---------------- window / GDI handles ----------------
hInst       DWORD 0
hMain       DWORD 0
hStatus     DWORD 0
hRestart    DWORD 0
hTitle      DWORD 0
hInfo       DWORD 0
hStart      DWORD 0
brBg        DWORD 0
brHidden    DWORD 0
brFlip      DWORD 0
brMatch     DWORD 0
brBtn       DWORD 0
hFontTitle  DWORD 0
hFontCard   DWORD 0
hFontMid    DWORD 0
hFontSm     DWORD 0

END