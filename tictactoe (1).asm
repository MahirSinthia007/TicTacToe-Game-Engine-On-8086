; feature MAP:
;   feature 1 - Main Menu & Mode Selection Interface
;   feature 2 - Board Rendering & Move Input/Validation 
;   feature 3 - Win / Draw Condition Checker              
;   feature 4 - Player vs Player Turn Handling
;   feature 5 - AI Opponent Logic                         
;   feature 6 - Score Tracking & Game Reset
;
;
; Board cell numbering shown to the user:
;      1 | 2 | 3
;      4 | 5 | 6
;      7 | 8 | 9

; board value meaning: 0 = empty, 1 = X (player 1), 2 = O (player 2 / AI)
; ==================================================================

.MODEL SMALL
.STACK 200h


PRINT_STR MACRO msg
    PUSH AX
    PUSH DX
    LEA  DX, msg
    MOV  AH, 09h
    INT  21h
    POP  DX
    POP  AX
ENDM


; PRINT_CHAR  --  Prints a single ASCII character
; Input:  ch  = character to print

PRINT_CHAR MACRO ch
    PUSH AX
    PUSH DX
    MOV  DL, ch
    MOV  AH, 02h
    INT  21h
    POP  DX
    POP  AX
ENDM


AI_MOVE MACRO
    LOCAL try_win, win_next, win_taken
    LOCAL try_block, block_next, block_taken, block_skip_lbl
    LOCAL first_empty, first_next, ai_finished_place, ai_finished

    ;can AI win
    MOV BX, 0
try_win:
    CMP BOARD[BX], 0
    JNE win_next
    MOV BOARD[BX], 2          ; temporarily O
    CALL WinCheck
    CMP AL, 2
    JE  win_taken             
    MOV BOARD[BX], 0          
win_next:
    INC BX
    CMP BX, 9
    JL  try_win
    JMP try_block

win_taken:
    JMP ai_finished

try_block:
    MOV BX, 0
    
block_next:
    CMP BOARD[BX], 0
    JNE block_skip_lbl
    MOV BOARD[BX], 1          ; temporarily place X
    CALL WinCheck
    CMP AL, 1
    JE  block_taken           
    MOV BOARD[BX], 0  

block_skip_lbl:
    INC BX
    CMP BX, 9
    JL  block_next
    JMP first_empty

block_taken:
    MOV BOARD[BX], 2          ; placing O to block
    JMP ai_finished

    
first_empty:
    MOV SI, 0
first_next:
    MOV BL, [AI_PRIORITY + SI]
    MOV BH, 0
    CMP BOARD[BX], 0
    JE  ai_finished_place
    INC SI
    CMP SI, 9
    JL  first_next
    JMP ai_finished

ai_finished_place:
    MOV BOARD[BX], 2

ai_finished:
ENDM



.DATA
    
    ; Index:  0  1  2  3  4  5  6  7  8
    ;         ---------------------------
    ; Cell:   1  2  3  4  5  6  7  8  9
    ; 0=empty, 1=X, 2=O
    BOARD       DB 9 DUP(0)

    
    WINLINES    DB 0,1,2,  3,4,5,  6,7,8         ; rows
                DB 0,3,6,  1,4,7,  2,5,8         ; cols
                DB 0,4,8,  2,4,6                 ; diagonals

   -
    MODE    DB 0      ; 1 = Player vs Player, 2 = Player vs AI

    
    CURRENT_PLAYER  DB 1      ; 1 = X's turn, 2 = O's turn

    ; score counters
    SCORE_X     DB 0
    SCORE_O     DB 0
    SCORE_DRAW  DB 0

    
    ; Priority: center, corners edges
    AI_PRIORITY  DB 4, 0, 2, 6, 8, 1, 3, 5, 7

    ; text 
    NEWLINE     DB 13,10,'$'
    DASHLINE    DB '-----------',13,10,'$'

    MSG_TITLE   DB 13,10,'=== TIC-TAC-TOE ===',13,10,'$'
    MSG_MENU    DB 13,10,'1. Player vs Player',13,10
                DB '2. Player vs AI',13,10
                DB 'Choose mode (1 or 2): $'
    MSG_INVALID_MODE DB 13,10,'Invalid choice, try again: $'

    MSG_PROMPT_X  DB 13,10,"Player X, enter your cell (1-9): $"
    MSG_PROMPT_O  DB 13,10,"Player O, enter your cell (1-9): $"
    MSG_AI_TURN   DB 13,10,'AI (O) is thinking...',13,10,'$'
    MSG_AI_PICKED DB 'AI chose cell: $'

    MSG_INVALID   DB 13,10,'Invalid input, must be 1-9. $'
    MSG_OCCUPIED  DB 13,10,'That cell is already taken. $'

    MSG_WIN_X     DB 13,10,'*** Player X WINS! ***',13,10,'$'
    MSG_WIN_O_PVP DB 13,10,'*** Player O WINS! ***',13,10,'$'
    MSG_WIN_O_AI  DB 13,10,'*** AI (O) WINS! ***',13,10,'$'
    MSG_DRAW      DB 13,10,'*** Game is a DRAW! ***',13,10,'$'

    MSG_BYE        DB 13,10,'Thanks for playing!',13,10,'$'
    MSG_SCORE   DB 13,10,'Score: X=$'
    MSG_SCORE_O DB '  O=$'
    MSG_SCORE_D DB '  Draw=$'
    MSG_AGAIN   DB 13,10,'Play again? (Y/N): $'



.CODE


ResetGame PROC
    ; Clear all 9 board cells to 0
    MOV CX, 9
    XOR BX, BX
rg_loop:
    MOV BOARD[BX], 0
    INC BX
    LOOP rg_loop

    MOV CURRENT_PLAYER, 1     ; X always starts
    RET
ResetGame ENDP


WinCheck PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV SI, 0         
    MOV CX, 8

check_line:
    
    MOV DI, SI
    MOV BL, WINLINES[DI]
    MOV BH, 0
    MOV DL, BOARD[BX]        
    CMP DL, 0
    JE  next_line              

    
    MOV DI, SI
    INC DI
    MOV BL, WINLINES[DI]
    MOV BH, 0
    MOV DH, BOARD[BX]       
    CMP DH, DL
    JNE next_line

    
    MOV DI, SI
    ADD DI, 2
    MOV BL, WINLINES[DI]
    MOV BH, 0
    MOV AH, BOARD[BX]       
    CMP AH, DL
    JNE next_line

    
    MOV AL, DL
    JMP wc_exit

next_line:
    ADD SI, 3               
    LOOP check_line

    MOV AL, 0                  

wc_exit:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
WinCheck ENDP



IsBoardFull PROC
    PUSH BX
    PUSH CX
    MOV BX, 0
    MOV CX, 9
ibf_loop:
    CMP BOARD[BX], 0
    JE  ibf_not_full
    INC BX
    LOOP ibf_loop
    MOV AL, 1
    JMP ibf_exit
ibf_not_full:
    MOV AL, 0
ibf_exit:
    POP CX
    POP BX
    RET
IsBoardFull ENDP



PrintCell PROC
    PUSH AX
    PUSH DX
    MOV AL, BOARD[BX]
    CMP AL, 1
    JE  pc_x
    CMP AL, 2
    JE  pc_o
    MOV DL, ' '
    JMP pc_print
pc_x:
    MOV DL, 'X'
    JMP pc_print
pc_o:
    MOV DL, 'O'
pc_print:
    MOV AH, 02h
    INT 21h
    POP DX
    POP AX
    RET
PrintCell ENDP



DisplayBoard PROC
    PUSH AX
    PUSH BX
    PUSH DX

    PRINT_STR NEWLINE

    
    MOV BX, 0
    CALL PrintCell
    PRINT_CHAR '|'
    MOV BX, 1
    CALL PrintCell
    PRINT_CHAR '|'
    MOV BX, 2
    CALL PrintCell
    PRINT_STR NEWLINE
    PRINT_STR DASHLINE

    
    MOV BX, 3
    CALL PrintCell
    PRINT_CHAR '|'
    MOV BX, 4
    CALL PrintCell
    PRINT_CHAR '|'
    MOV BX, 5
    CALL PrintCell
    PRINT_STR NEWLINE
    PRINT_STR DASHLINE

    
    MOV BX, 6
    CALL PrintCell
    PRINT_CHAR '|'
    MOV BX, 7
    CALL PrintCell
    PRINT_CHAR '|'
    MOV BX, 8
    CALL PrintCell
    PRINT_STR NEWLINE

    POP DX
    POP BX
    POP AX
    RET
DisplayBoard ENDP



GetMove PROC
    PUSH AX

gm_retry:
    MOV AH, 01h            
    INT 21h                

    CMP AL, '1'
    JB  gm_bad_range
    CMP AL, '9'
    JA  gm_bad_range

    SUB AL, '1'              
    MOV BL, AL
    MOV BH, 0
    CMP BOARD[BX], 0
    JNE gm_bad_taken
    JMP gm_ok

gm_bad_range:
    PRINT_STR MSG_INVALID
    JMP gm_retry
gm_bad_taken:
    PRINT_STR MSG_OCCUPIED
    JMP gm_retry

gm_ok:
    POP AX
    RET
GetMove ENDP


ShowMenu PROC
    PUSH AX

    PRINT_STR MSG_TITLE
sm_retry:
    PRINT_STR MSG_MENU
    MOV AH, 01h
    INT 21h                  

    CMP AL, '1'
    JE  sm_pvp
    CMP AL, '2'
    JE  sm_ai
    PRINT_STR MSG_INVALID_MODE
    JMP sm_retry

sm_pvp:
    MOV MODE, 1
    JMP sm_done
sm_ai:
    MOV MODE, 2
sm_done:
    POP AX
    RET
ShowMenu ENDP



PromptTurn PROC
    CMP CURRENT_PLAYER, 1
    JE  pt_x
    PRINT_STR MSG_PROMPT_O
    RET
pt_x:
    PRINT_STR MSG_PROMPT_X
    RET
PromptTurn ENDP



main PROC
    MOV AX, @DATA
    MOV DS, AX

    
    CALL ShowMenu

    MOV CURRENT_PLAYER, 1

game_loop:
    CALL DisplayBoard

    CMP CURRENT_PLAYER, 1
    JE  do_human_turn
    CMP MODE, 2
    JE  do_ai_turn
    
do_human_turn:
    
    CALL PromptTurn
    CALL GetMove              
    JMP place_move

do_ai_turn:
    
    PRINT_STR MSG_AI_TURN
    AI_MOVE                    
    PUSH AX
    PRINT_STR MSG_AI_PICKED
    MOV AL, BL
    ADD AL, '1'
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    PRINT_STR NEWLINE
    POP AX

place_move:
    
    CMP CURRENT_PLAYER, 2
    JNE record_move
    CMP MODE, 2
    JE  skip_board_write        
record_move:
    MOV AL, CURRENT_PLAYER
    MOV BOARD[BX], AL
skip_board_write:

    
    CALL WinCheck
    CMP AL, 0
    JNE announce_win

    CALL IsBoardFull
    CMP AL, 1
    JE  announce_draw

    
    CMP CURRENT_PLAYER, 1
    JE  switch_to_o
    MOV CURRENT_PLAYER, 1
    JMP game_loop
switch_to_o:
    MOV CURRENT_PLAYER, 2
    JMP game_loop

announce_win:
    CALL DisplayBoard
    CMP AL, 1
    JE  win_is_x
   
    CMP MODE, 2
    JE  win_is_ai
    PRINT_STR MSG_WIN_O_PVP
    JMP after_win_msg
win_is_ai:
    PRINT_STR MSG_WIN_O_AI
    JMP after_win_msg
win_is_x:
    PRINT_STR MSG_WIN_X
after_win_msg:
    JMP end_game

announce_draw:
    CALL DisplayBoard
    PRINT_STR MSG_DRAW
    XOR AL, AL              
end_game:
    
    CMP AL, 1
    JE  score_x_win
    CMP AL, 2
    JE  score_o_win
    INC SCORE_DRAW       
    JMP show_score

score_x_win:
    INC SCORE_X
    JMP show_score
score_o_win:
    INC SCORE_O

show_score:
   
    PRINT_STR NEWLINE
    PRINT_STR MSG_SCORE
    MOV DL, SCORE_X
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    PRINT_STR MSG_SCORE_O
    MOV DL, SCORE_O
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    PRINT_STR MSG_SCORE_D
    MOV DL, SCORE_DRAW
    ADD DL, '0'
    MOV AH, 02h
    INT 21h

    
    PRINT_STR MSG_AGAIN
    MOV AH, 01h
    INT 21h
    CMP AL, 'Y'
    JE  do_reset
    CMP AL, 'y'
    JE  do_reset
    

    PRINT_STR MSG_BYE
    MOV AH, 4Ch
    INT 21h

do_reset:
    CALL ResetGame
    JMP game_loop
main ENDP

END main
