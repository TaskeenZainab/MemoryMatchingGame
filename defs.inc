; ============================================================
;  defs.inc  -  shared by every .asm file in the project
;  Contains: processor/model setup, libraries, Win32 + Irvine32
;  prototypes, constants, and the list of procedures/variables
;  that are shared between files.
; ============================================================
.386
.model flat, stdcall
option casemap:none

INCLUDELIB kernel32.lib
INCLUDELIB user32.lib
INCLUDELIB gdi32.lib
INCLUDELIB Irvine32.lib

; ---------------- Irvine32 ----------------
Randomize   PROTO                       ; seeds the generator
RandomRange PROTO                       ; EAX = n  ->  EAX = 0..n-1

; ---------------- Win32 prototypes ----------------
ExitProcess      PROTO :DWORD
GetModuleHandleA PROTO :DWORD
GetTickCount     PROTO
LoadCursorA      PROTO :DWORD, :DWORD
RegisterClassExA PROTO :DWORD
CreateWindowExA  PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ShowWindow       PROTO :DWORD, :DWORD
UpdateWindow     PROTO :DWORD
GetMessageA      PROTO :DWORD, :DWORD, :DWORD, :DWORD
TranslateMessage PROTO :DWORD
DispatchMessageA PROTO :DWORD
DefWindowProcA   PROTO :DWORD, :DWORD, :DWORD, :DWORD
PostQuitMessage  PROTO :DWORD
DestroyWindow    PROTO :DWORD
SetWindowTextA   PROTO :DWORD, :DWORD
SetTimer         PROTO :DWORD, :DWORD, :DWORD, :DWORD
KillTimer        PROTO :DWORD, :DWORD
MessageBoxA      PROTO :DWORD, :DWORD, :DWORD, :DWORD
SendMessageA     PROTO :DWORD, :DWORD, :DWORD, :DWORD
InvalidateRect   PROTO :DWORD, :DWORD, :DWORD
FillRect         PROTO :DWORD, :DWORD, :DWORD
DrawTextA        PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CreateFontA      PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CreateSolidBrush PROTO :DWORD
GetStockObject   PROTO :DWORD
SelectObject     PROTO :DWORD, :DWORD
SetBkMode        PROTO :DWORD, :DWORD
SetTextColor     PROTO :DWORD, :DWORD
MoveWindow       PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
RoundRect        PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
wsprintfA        PROTO C :DWORD, :DWORD, :VARARG

; ---------------- Constants ----------------
WM_CREATE         EQU 0001h
WM_DESTROY        EQU 0002h
WM_SIZE           EQU 0005h
WM_GETMINMAXINFO  EQU 0024h
WM_SETFONT        EQU 0030h
WM_DRAWITEM       EQU 002Bh
WM_COMMAND        EQU 0111h
WM_TIMER          EQU 0113h
WM_CTLCOLORSTATIC EQU 0138h

WS_OVERLAPPED   EQU 00000000h
WS_CAPTION      EQU 00C00000h
WS_SYSMENU      EQU 00080000h
WS_MINIMIZEBOX  EQU 00020000h
WS_MAXIMIZEBOX  EQU 00010000h
WS_THICKFRAME   EQU 00040000h
WS_VISIBLE      EQU 10000000h
WS_CHILD        EQU 40000000h
SS_CENTER       EQU 1
BS_OWNERDRAW    EQU 0Bh

CW_USEDEFAULT   EQU 80000000h
SW_HIDE         EQU 0
SW_SHOW         EQU 5
IDC_ARROW       EQU 32512
NULL_PEN        EQU 8
MB_YESNO_QUEST  EQU 24h             ; MB_YESNO + MB_ICONQUESTION
IDYES           EQU 6

; DRAWITEMSTRUCT offsets
DIS_ID          EQU 4
DIS_STATE       EQU 16
DIS_HDC         EQU 24
DIS_RECT        EQU 28              ; left, top, right, bottom (4 DWORDs)

; colours (COLORREF = 00BBGGRR)  -- soft purple theme
COL_BG          EQU 00F0F8FFh       ; cream window background
COL_HIDDEN      EQU 00FA8BA7h       ; medium soft violet card back
COL_HIDDEN_TXT  EQU 00FFFFFFh       ; white "?" on hidden card
COL_FLIP        EQU 00FFE8F3h       ; very light lilac flipped card
COL_FLIP_TXT    EQU 00871C58h       ; deep purple letter on flipped card
COL_MATCH       EQU 00FEB4D8h       ; soft orchid matched card
COL_MATCH_TXT   EQU 0064073Bh       ; darkest purple letter on matched card
COL_BTN         EQU 00FDB5C4h       ; lavender Start / Restart buttons
COL_BTN_TXT     EQU 00951D4Ch       ; plum button text
COL_TEXT        EQU 00871C58h       ; status line and instructions
COL_TITLE       EQU 00A8216Bh       ; welcome-screen title

; control / timer IDs
ID_CARD0        EQU 100             ; cards use IDs 100..115
ID_RESTART      EQU 200
ID_START        EQU 201
ID_STATUS       EQU 300
ID_TITLE        EQU 301
ID_INFO         EQU 302
ID_TIMER_CLOCK  EQU 1
ID_TIMER_FLIP   EQU 2

; layout (pixels)
CARD_SIZE       EQU 80
CARD_STEP       EQU 90              ; size + 10 gap
GRID_X          EQU 20
GRID_Y          EQU 60
GAME_W          EQU 350             ; size of the whole game block
GAME_H          EQU 450
WEL_H           EQU 375             ; height of the welcome block

; ---------------- Procedures shared between files ----------------
; game.asm
StartGame        PROTO
CardClicked      PROTO :DWORD
FlipBack         PROTO
ComputeTime      PROTO
; gui.asm
InitGdi          PROTO
CreateControls   PROTO :DWORD
LayoutControls   PROTO :DWORD, :DWORD
RedrawCard       PROTO :DWORD
ShowGameGroup    PROTO :DWORD
ShowWelcomeGroup PROTO :DWORD
UpdateStatus     PROTO
ShowResult       PROTO
DrawItem         PROTO :DWORD
; wndproc.asm
WndProc          PROTO :DWORD, :DWORD, :DWORD, :DWORD

; ---------------- Variables shared between files (defined in data.asm) ----
; game data
EXTERNDEF cards:BYTE
EXTERNDEF state:BYTE
EXTERNDEF symBuf:BYTE
EXTERNDEF hCards:DWORD
EXTERNDEF firstPick:DWORD
EXTERNDEF secondPick:DWORD
EXTERNDEF moves:DWORD
EXTERNDEF score:DWORD
EXTERNDEF pairsFound:DWORD
EXTERNDEF startTime:DWORD
EXTERNDEF endTime:DWORD
EXTERNDEF busy:DWORD
EXTERNDEF gameOver:DWORD
; window and GDI handles
EXTERNDEF hInst:DWORD
EXTERNDEF hMain:DWORD
EXTERNDEF hStatus:DWORD
EXTERNDEF hRestart:DWORD
EXTERNDEF hTitle:DWORD
EXTERNDEF hInfo:DWORD
EXTERNDEF hStart:DWORD
EXTERNDEF brBg:DWORD
EXTERNDEF brHidden:DWORD
EXTERNDEF brFlip:DWORD
EXTERNDEF brMatch:DWORD
EXTERNDEF brBtn:DWORD
EXTERNDEF hFontTitle:DWORD
EXTERNDEF hFontCard:DWORD
EXTERNDEF hFontMid:DWORD
EXTERNDEF hFontSm:DWORD
; text
EXTERNDEF buf:BYTE
EXTERNDEF className:BYTE
EXTERNDEF winTitle:BYTE
EXTERNDEF clsButton:BYTE
EXTERNDEF clsStatic:BYTE
EXTERNDEF txtHidden:BYTE
EXTERNDEF txtRestart:BYTE
EXTERNDEF txtStart:BYTE
EXTERNDEF txtTitle:BYTE
EXTERNDEF txtInfo:BYTE
EXTERNDEF txtStatusInit:BYTE
EXTERNDEF fmtStatus:BYTE
EXTERNDEF fmtWin:BYTE
EXTERNDEF msgTitle:BYTE
EXTERNDEF fontName:BYTE