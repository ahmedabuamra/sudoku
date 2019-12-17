
INCLUDE Irvine32.inc
.DATA
; files paths
gamePath BYTE "level1.txt",0 ;this will point to sudoku folder
solvedGamePath BYTE "solution1.txt", 0
tmpPath BYTE "tmp.txt", 0

currentGame BYTE 81 dup(?) ; should filled initialy with the game numbers.   
solvedGame  BYTE 81 dup(?) ; should have solved game numbers.
gameStatus BYTE 81 dup(0)  ; each cell have number 0,1 or 2 - 0 indecates an empty cell, 1 matched cell with the solved cell and 2 for not matched cell.     
boolEqual BYTE 1   	   ; 1 if all currentGame matched with solvedGame and 0 if not.  

; gets value after calling OpenGameFile procedure
gamePlayFileHandle DWORD ?
solvedGamePlayFileHandle DWORD ?
tmpPlayFileHandle DWORD ?


; boards variables
BOARD_SIZE = 81
board BYTE BOARD_SIZE dup(?), 0
solvedBoard BYTE BOARD_SIZE dup(?), 0


; console menu options
continue_game BYTE "1 -  Continue previous game.", 0
new_game BYTE "2 -  New game.", 0
username BYTE "Please enter your name.", 0
user_name BYTE 10 dup(?)
level_selection BYTE "Please Select Difficulty [1-3] (Note: 1 is easy).", 0
difficulty BYTE 0
random_board BYTE 0

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


; @TODO: check the error "Error 5: Access is denied."
; writes the content of board in tmp.txt file
SaveGame PROC
	mov edx, OFFSET tmpPath ; filename should be path to level file
	call _OpenInputFile
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

;Ahmed & Omar area

random proc
	call Randomize            
	mov  eax,3		;always from 0 to n-1           
	call RandomRange	;return in eax
	add eax, 1
	mov random_board,ah
    ret
random endp

menu proc
	mov edx,offset continue_game
	call writestring
	call crlf
	mov edx, offset new_game
	call writestring
	call crlf
	call readdec
	cmp eax, 1
	;
	; call continue previos game function here
	;
	mov edx,offset username
	call writestring
	call crlf
	mov edx,offset user_name
	mov ecx,10
	call readstring
	call crlf
	mov edx,offset level_selection
	call writestring
	call crlf
	call readdec
	mov difficulty, ah
	call game
	ret 
menu endp

;Ahmed & Omar area


main PROC
	call OpenGameFiles ; assigns gamePlayFileHandle

	call ReadGameFiles ; read the board and store it in board variable
	
	;============================
	; print the file content
	mov edx, OFFSET solvedBoard ;mov edx to the beginning of string
	call WriteString
	call crlf


	mov edx, OFFSET board ;mov edx to the beginning of string
	call WriteString
	call crlf
	;============================

	call SaveGame ;saves board
	exit
main ENDP

END main
