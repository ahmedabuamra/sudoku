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
ONE 	    = 1
TWO 	    = 2
ONE_HUNDRED = 100 
board BYTE BOARD_SIZE dup(?), 0					;Array containing original unsolved board
solvedBoard BYTE BOARD_SIZE dup(?), 0				;Array containing solved board
difficulty BYTE '2'                                   		;The difficulty the user selects
randomBoard BYTE '2'						;The random board generated
currentBoard BYTE BOARD_SIZE dup(?)                 		;The Board that gets updated
boardStatus  BYTE  BOARD_SIZE dup(?)				;each cell have 0,1 or 2 - 0 indecates an empty cell, 1 matched cell with the solved cell and 2 for not matched cell.     
boolEqual    BYTE  1   						;1 if all currentGame matched with solvedGame and 0 if not.  
wrongCounter word  0						; count the number of cells which matched with the solved board.
rightCounter word  0						; count the number of cells which dosen't matched with the solved board.
score	     sword 0					        ; this will have the user final score. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
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
; each index will have one of three *integer value* 0 for empty cell, 1 for mathced and 2 for unmatched. 

compare PROC uses ebx edx ebp ecx eax

	mov ebx, offset currentBoard
	mov edx, offset solvedBoard
	mov ebp, offset boardStatus
	mov ecx, BOARD_SIZE 

   	beginToEnd: 

		mov al, [edx]
		cmp al, [ebx]
		je equal		; if the cell in currentBoard equal the one in the solved, jump to the equal label which will put 1 in statusGame. 

		mov al, '0'
		cmp al, [ebx]
		je free		    ; if the cell in currentBoard equal zero, jump to free label which will put 0 in statusGame.  
		jmp wrong		; else will jump to wrong label which will put 2 in statusGame.

		free :
		mov al, zero
		mov[ebp], al
		jmp cont

		equal :
		mov al, one
		mov[ebp], al
		jmp cont

		wrong :
		mov al, two
		mov[ebp], al
		jmp cont

		cont :
		inc ebx
		inc edx
		inc ebp

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

Print PROC uses edx 

	mov ecx,81
	mov ebx,0     ;counter
	L1:
		mov al , [edx]
		call writechar 
		mov al, ' '
		call writechar
		inc edx
		inc ebx
		cmp ebx,9
		je LeaveLine
		jmp EndLoop
		LeaveLine:
			mov ebx,0
			call crlf
		EndLoop:
	loop L1

	ret
Print endp


LevelFill PROC
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
	
	ret
Game endp


main PROC
	;call OpenGameFiles ; assigns gamePlayFileHandle

	;call ReadGameFiles ; read the board and store it in board variable
	call LevelFill
	;============================
	; print the file content
	mov edx, OFFSET solvedBoard ;mov edx to the beginning of string
	;call WriteString
	;call crlf


	mov edx, OFFSET board ;mov edx to the beginning of string
	;call WriteString
	;call crlf
	;============================

	mov edx,offset currentboard
	call Print

	;call SaveGame ;saves board
	exit
main ENDP

END main
