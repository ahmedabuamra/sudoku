
INCLUDE Irvine32.inc
.DATA
gamePath BYTE "level1.txt",0 ;this will point to sudoku folder

currentGame BYTE 81 dup(?) ; should filled initialy with the game numbers.   
solvedGame  BYTE 81 dup(?) ; should have solved game numbers.
gameStatus BYTE 81 dup(0)  ; each cell have number 0,1 or 2 - 0 indecates an empty cell, 1 matched cell with the solved cell and 2 for not matched cell.     
boolEqual BYTE 1   	   ; 1 if all currentGame matched with solvedGame and 0 if not.  

; gets value after calling OpenGameFile procedure
gamePlayFileHandle DWORD ?

BOARD_SIZE = 81
board BYTE BOARD_SIZE dup(0)

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
OpenGameFile PROC
	mov edx, OFFSET gamePath ; filename should be path to level file
	call _OpenInputFile
	mov gamePlayFileHandle, eax
	ret
OpenGameFile ENDP


; @TODO: check the error "Error 5: Access is denied."
; writes the content of board in the level path. e.g. gamePlayFileHandle
SaveGame PROC
	mov ecx, BOARD_SIZE
	mov eax, gamePlayFileHandle
	mov edx, OFFSET board
	call WriteToFile

	; check for error (source: page 170 from the book).
	cmp eax, 0
	ja SUCCESS 
	call WriteWindowsMsg
	SUCCESS:
	ret
SaveGame ENDP

ReadGameFile PROC
	mov edx, OFFSET board ; points to buffer
	mov ecx, BOARD_SIZE ; max bytes to read
	call _ReadFromFile 
	ret
ReadGameFile ENDP

; compare proc work with currentGame and solvedGame "Char Arrays".
; gameStatus will be affected after the proc finised.
; each index will have one of three *integer value* 0 for empty cell, 1 for mathced and 2 for unmatched. 

compare PROC uses ebx edx ebp ecx eax

	mov ebx, offset currentGame
	mov edx, offset solvedGame
	mov ebp, offset gameStatus
	mov ecx, 81

   	L:
		mov al, [edx]
		cmp al, [ebx]
		je equal

		mov al, '0'
		cmp al, [ebx]
		je free
		jmp wrong

		free :
		mov al, 0
		mov[ebp], al
		jmp cont

		equal :
		mov al, 1
		mov[ebp], al
		jmp cont

		wrong :
		mov al, 2
		mov[ebp], al
		jmp cont

		cont :
		inc ebx
		inc edx
		inc ebp

	loop L
	ret
compare endp

;finalcheck work with currentGame and solvedGame array *char Arrays*.
;return 1 in boolEqual if all currentGame cells matched with solvedGame and 0 if not.  

finalcheck PROC uses ebx edx ecx eax

	mov ebx, offset currentGame
	mov edx, offset solvedGame
	mov ecx, 81

	L:
			mov al, [ebx]
			cmp al, [edx]
			jne wr

			inc ebx
			inc edx
	loop L
		
			jmp finish
			wr :
			mov boolEqual, 0
			finish :
	ret
finalCheck endp



main PROC
	call OpenGameFile ; assigns gamePlayFileHandle

	call ReadGameFile ; read the board and store it in board variable
	
	;============================
	; print the file content
	mov edx, OFFSET board ;mov edx to the beginning of string
	call WriteString
	; new line
	call crlf
	;============================

	call SaveGame ;saves board
	exit
main ENDP

END main
