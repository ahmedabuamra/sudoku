INCLUDE Irvine32.inc
.DATA
; files paths
gamePath BYTE "Sudoku Boards\diff_0_0.txt",0 ;this will point to sudoku folder
solvedGamePath BYTE "Sudoku Boards\diff_0_0_solved.txt",0
tmpPath BYTE "tmp.txt", 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; gets value after calling OpenGameFile procedure
gamePlayFileHandle DWORD ?
solvedGamePlayFileHandle DWORD ?
tmpPlayFileHandle DWORD ?


; boards variables                       THESE ARE THE VARIABLES WE ARE USING IN THE PROJECT
BOARD_SIZE = 81
ZERO	    = 0
four	    = 4
ONE 	    = 1
TWO 	    = 2
ONE_HUNDRED = 100 
board BYTE BOARD_SIZE dup(?), 0					;Array containing original unsolved board
solvedBoard BYTE BOARD_SIZE dup(?), 0			;Array containing solved board
difficulty BYTE 0                               ;The difficulty the user selects
randomBoard BYTE 0								;The random board generated
printingCounter DWORD 0
currentBoard BYTE  BOARD_SIZE dup(?)             ;The Board that gets updated
boardStatus  BYTE  BOARD_SIZE dup(?)			;each cell have 0,1,2 or 4 - 0 indecates an empty cell, 1 matched cell with the solved cell, 2 for not matched cell and 4 for the cell which already esxist in teh original board .     
boolEqual    BYTE  1   							;1 if all currentGame matched with solvedGame and 0 if not.  
wrongCounter word  0							; count the number of cells which matched with the solved board.
rightCounter word  0							; count the number of cells which dosen't matched with the solved board.
score	     sword 0					        ; this will have the user final score. 
level_selection BYTE "Please Select Difficulty [1-3] (Note: 1 is easy).", 0	
continue_game BYTE "1 -  Continue previous game.", 0
new_game BYTE "2 -  New game.", 0
username BYTE "Please enter your name.", 0
user_name BYTE 10 dup(?)

rowCounter DWORD 0
colCounter DWORD 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 Game Strings
selectionString BYTE "1- Change a number in the board", 0
selectionString2 BYTE "2- Restart the board", 0
selectionString3 BYTE "3- Submit your board", 0
selectionString4 BYTE "4- Save game", 0
choice BYTE "Enter you choice: ",0

selectRow BYTE "Select the desired Row: ", 0
selectCol BYTE "Select the desired Column: ", 0
selectValue BYTE "Select the desired Value: ", 0
selectedRow BYTE ?
selectedCol BYTE ?
selectedVal BYTE ?
index Byte ?
FailMsg BYTE "Please Enter a correct index",0
FailMsg2 BYTE "Please Enter a correct choice",0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE

; yasser
random proc uses eax
	call Randomize		;sets seed         
	mov  eax,3		    ;RandomRange pick random number from 0 to EAX-1           
	call RandomRange	;return in EAX
	add eax, 1
	mov randomBoard,al
    ret
random endp

menu proc
	StartProc:
	mov edx,offset continue_game
	call writestring
	call crlf
	mov edx, offset new_game
	call writestring
	call crlf
	call readdec

	cmp eax, 1
	je ContinuePreviousGame
	cmp eax, 2
	je NewGame
	mov edx ,offset FailMsg2
	call writestring
	call crlf
	JMP StartProc

	ContinuePreviousGame:
		call Load
		jmp EndMe

	NewGame:
	mov edx,offset username
	call writestring
	call crlf

	mov edx,offset user_name
	mov ecx,10
	call readstring

	mov edx,offset level_selection
	call writestring
	call crlf

	call readdec
	mov difficulty, al

	call random

	EndMe:
	call LevelFill
	;ret 
menu endp
;

; input:
;	edx: offset of file path string, for example -> filename BYTE "myfile.txt",0
; return
;	eax: handle file
_OpenInputFile PROC
	call OpenInputFile
	ret
_OpenInputFile ENDP


; input:
;	edx: offset of file path string, for example -> filename BYTE "myfile.txt",0
; return
;	eax: handle file
_CreateOutputFile PROC
	call CreateOutputFile
	ret
_CreateOutputFile ENDP


; input:
;	edx: offset to variable array to store in it
;	ecx: max bytes to read
;	eax: handle file
; return:
;	eax: counter of already readed bytes
;	edx: last memory location after eax ^
;	edits the variable in edx
_ReadFromFile PROC
	call ReadFromFile ; read the file
	ret
_ReadFromFile ENDP


; return
;	gamePlayFileHandle: handle file of the game play, should be constant during the same game.
OpenGameFiles PROC
	;loading unsolved
	mov edx, OFFSET gamePath ; filename should be path to level file
	call _OpenInputFile
	mov gamePlayFileHandle, eax

	;loading solved
	mov edx, OFFSET solvedGamePath ; filename should be path to level file
	call _OpenInputFile
	mov solvedGamePlayFileHandle, eax
	ret
OpenGameFiles ENDP


; writes the content of board in tmp.txt file
SaveGame PROC
	mov edx, OFFSET tmpPath ; filename should be path to level file
	call CreateOutputFile
	mov tmpPlayFileHandle, eax

	mov edx, OFFSET board
	mov ecx, BOARD_SIZE
	mov eax, tmpPlayFileHandle
	call WriteToFile

	; check for error (source: page 170 from the book).
	cmp eax, 0
	ja SUCCESS 
	call WriteWindowsMsg

	SUCCESS:
	mov eax, tmpPlayFileHandle
	call CloseFile
	ret
SaveGame ENDP


ReadGameFiles PROC
	mov edx, OFFSET board ; points to buffer
	mov ecx, BOARD_SIZE ; max bytes to read
	mov eax, gamePlayFileHandle
	call _ReadFromFile
	
	mov edx, OFFSET solvedBoard ; points to buffer
	mov ecx,  BOARD_SIZE ; max bytes to read
	mov eax, solvedGamePlayFileHandle
	call _ReadFromFile 
	ret
ReadGameFiles ENDP

; compare proc work with currentBoard and solvedBoard "Char Arrays".
; boardStatus will be affected after the proc finised.
; each index will have one of three *integer value* 0 for empty cell, 1 for mathced , 2 for unmatched and 4 for the cell which already exist in the original board . 

compare PROC uses ebx edx ebp ecx eax

	mov ebx, offset currentBoard
	mov edx, offset solvedBoard
	mov ebp, offset boardStatus
	mov edi, offset board
	mov ecx, BOARD_SIZE 
	

   	beginToEnd: 

		mov al, [edx]
		cmp al, [ebx]
		je equal 		; if the cell in currentBoard equal the one in the solved, jump to the equal label which will put 1 or 4 in statusGame depinding in the original board. 

		mov al, '0'
		cmp al, [ebx]
		je free		    ; if the cell in currentBoard equal zero, jump to free label which will put 0 in statusGame.  
		jmp wrong		; else will jump to wrong label which will put 2 in statusGame.

		free :
		mov al, zero
		mov[ebp], al
		jmp cont

		equal :
		mov al, [edi]
		cmp al,'0'
		jne alreadyExist
		mov al, one
		mov[ebp], al
		jmp cont

		wrong :
		mov al, two
		mov[ebp], al
		jmp cont

		alreadyExist:
		mov al,four
		mov[ebp], al
		jmp cont

		cont :
		inc ebx
		inc edx
		inc ebp
		inc edi 
	loop beginToEnd
	
	ret
compare ENDP

;finalcheck work with currentBoard and solvedBoard array *char Arrays*.
;return 1 in boolEqual if all currentGame cells matched with solvedGame and 0 if not.  

finalcheck PROC uses ebx edx ecx eax

	mov ebx, offset currentBoard
	mov edx, offset solvedBoard
	mov ecx, BOARD_SIZE

	beginToEnd:

		mov al, [ebx]
		cmp al, [edx]
		jne wrong
		inc ebx
		inc edx
	
	loop beginToEnd
	jmp finish
	
	wrong:
		mov boolEqual, 0
	
	finish:

	ret
finalCheck ENDP


; calculateScore PROC calcuate the user score according this formula (rightCells-wrongCells)*100 and work with boardStatus
; you have to call compare PROC before using this PROC (to fill the boardStatus Array)
; to find the score you have to use this instruction "movsx eax, score"
; and also you should use "call writeint" as maybe the score be negative

calculateScore PROC uses eax ecx edx 

	mov edx, OFFSET boardStatus
	mov ecx,BOARD_SIZE
	beginToEnd:	
		movzx eax,byte ptr [edx]
		cmp eax,1
		jne wrong

		inc rightCounter 
		jmp continue
		
		wrong:
		inc wrongCounter

		continue:
		inc edx
	LOOP beginToEnd
	
		mov ax, wrongCounter
		sub rightCounter,ax
		mov ax, rightCounter
		mov cx, ONE_HUNDRED
		imul cx
		mov score,ax

	ret
calculateScore ENDP

; writecharGreen print the char which in eax register in Green color
; you have to move the char you need to print to the eax registr
writecharGreen PROC uses edx eax
	
	mov edx,eax
	mov eax,2           ; make color Green
	call setTextColor

	mov eax,edx        
	call writechar
	
	mov eax,7           
	call setTextColor    ; make color White again 
	 
	ret
writecharGreen ENDP


; writecharBlack print the char which in eax register in Black color
; you have to move the char you need to print to the eax registr

writecharBlack PROC uses edx eax
	
	mov edx,eax
	mov eax,0           ; make color Black
	call setTextColor

	mov eax,edx       
	call writechar
	
	mov eax,7           
	call setTextColor    ; make color White again 
	 
	ret
writecharBlack ENDP

; writecharRed print the char which in eax register in Red color
; you have to move the char you need to print to the eax registr

writecharRed PROC uses edx eax
	
	mov edx,eax
	mov eax,12           ; make color Red
	call setTextColor

	mov eax,edx       
	call writechar
	
	mov eax,7           
	call setTextColor    ; make color White again 
		 
	ret
writecharRed ENDP


;Print: Prints an array in the form of a Sudoku board
;Recieves edx contains offset of an array and
;Returns: That array printed in the Sudoku form

Print PROC uses edx edi
	mov ecx, 9
	mov al, ' '
	call writechar
	mov al, ' '
	call writechar
	mov al, ' '
	call writechar
	mov al, ' '
	call writechar
	L2:
		mov al, '['
		call writechar
		mov eax,rowCounter
		call writedec
		add eax,1
		mov rowCounter, eax
		mov al, ']'
		call writechar
		mov al, ' '
		call writechar

	loop L2
	call crlf
	call crlf
	mov al, '['
	call writechar
	mov al, '0'
	call writechar
	mov al, ']'
	call writechar
	mov al, ' '
	call writechar
	mov ecx,81
	mov ebx,0     ;counter
	mov printingCounter, ebx
	L1:
		mov al, ' '
		call writechar
		mov al , [edx]
		mov bl,'0'
		mov bh,[edi]
		cmp bl,bh
		je WriteNormal
		WriteGreen:
		call writecharGreen
		jmp EndWrite
		WriteNormal:
		call writechar 
		EndWrite:
		mov al, ' '
		call writechar
		mov al, ' '
		call writechar
		inc edx
		mov ebx,printingCounter
		inc ebx
		mov printingCounter,ebx
		inc edi
		cmp ebx,9
		je LeaveLine
		jmp EndProc
		LeaveLine:
			call crlf
			mov esi,colCounter
			cmp esi,9
			je EndProc
			mov ebx,0
			mov printingCounter,ebx
			call crlf
			mov al, '['
			call writechar
			mov eax,colCounter
			add eax,'0'
			call writechar
			mov al, ']'
			call writechar
			mov al, ' '
			call writechar
			inc colCounter
			EndProc:
	dec ecx
	cmp ecx,0
	jne L1
	call crlf
	mov eax,0
	mov rowCounter, eax
	mov eax,1
	mov colCounter,eax
	ret
Print endp


LevelFill PROC
	mov bl, difficulty
	add bl, '0'
	mov difficulty, bl

	mov bl, randomBoard
	add bl, '0'
	mov randomBoard, bl

	mov edx, OFFSET gamePath
	add edx,19
	mov al, difficulty
	mov [edx], al
	add edx,2
	mov al, randomBoard
	mov [edx],al

	mov edx, OFFSET solvedGamePath
	add edx,19
	mov al, difficulty
	mov [edx], al
	add edx,2
	mov al, randomBoard
	mov [edx],al
	call OpenGameFiles ; assigns gamePlayFileHandle
	call ReadGameFiles ; read the board and store it in board variable
	
	CALL Restart
LevelFill endp

Restart PROC
	mov ecx, 81
	mov eax, offset board
	mov ebx, offset currentBoard
	L1:									;Copying board into currentBoard
		mov esi, [eax]
		mov [ebx],esi
		inc ebx
		inc eax
	loop L1
Restart endp


Game PROC
	Start:
	mov edx,offset currentboard
	mov edi,offset board
	call Print
	call crlf
	mov edx, offset selectionString
	call writestring
	call crlf
	mov edx, offset selectionString2
	call writestring
	call crlf
	mov edx, offset selectionString3
	call writestring
	call crlf
	mov edx, offset selectionString4
	call writestring
	call crlf
	mov edx, offset choice
	call writestring
	call readdec

	cmp eax,1
	je choice1
	cmp eax,2
	je choice2
	cmp eax,3
	je choice3
	cmp eax,4
	je choice4

	choice1:
		call InsertProc
		jmp Start
	choice2:
		call Restart
		jmp Start
	choice3:
		call Submit                                         
		jmp Endgame
	choice4:
		call SaveGame                                        
		jmp Endgame
	Endgame:
		exit
		ret
Game endp

InsertProc PROC
	RestartProc:
	mov edx,offset selectRow
	call writestring
	call readdec
	mov selectedRow,al
	mov edx,offset selectCol
	call writestring
	call readdec
	mov selectedCol,al
	mov edx,offset selectValue
	call writestring
	call readdec
	mov selectedVal,al
	mov al , 9
	mov bl , selectedRow
	mul bl
	add al,selectedCol
	mov ebx, offset board
	add ebx,eax
	mov cl,[ebx]
	mov dl, '0'
	cmp cl,dl
	jne Failled
	mov edx, offset currentBoard
	add edx , eax
	mov al, selectedVal
	add al , '0'
	mov [edx], al
	jmp EndProc
	Failled:
		mov edx, offset FailMsg
		call writestring
		call crlf
		jmp RestartProc
	EndProc:	
		ret
InsertProc endp

Submit PROC                 ;SALEH

	call compare	   ; statusBoard now has the values which will represent the color in the console.
	call finalcheck    ; boolEqaul now has 1 if the player board matched with the solved. 

	ret
Submit ENDP

Load PROC                  ;ABUAMRA

	ret
Load ENDP

main PROC
	;call OpenGameFiles ; assigns gamePlayFileHandle

	;call ReadGameFiles ; read the board and store it in board variable
	;;;;;;;;;;call menu
	;;;;;;;;;;call game
	;============================
	; print the file content
	;mov edx, OFFSET solvedBoard ;mov edx to the beginning of string
	;call WriteString
	;call crlf


	;	mov edx, OFFSET board ;mov edx to the beginning of string
	;call WriteString
	;call crlf
	;============================

	;call SaveGame ;saves board
	
	
	exit
main ENDP

END main
