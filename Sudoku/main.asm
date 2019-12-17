
INCLUDE Irvine32.inc
.DATA
; files paths
gamePath BYTE "level1.txt",0 ;this will point to sudoku folder
solvedGamePath BYTE "solution1.txt", 0
tmpPath BYTE "tmp.txt", 0

; gets value after calling OpenGameFile procedure
gamePlayFileHandle DWORD ?
solvedGamePlayFileHandle DWORD ?
tmpPlayFileHandle DWORD ?


; boards variables
BOARD_SIZE = 81
board BYTE BOARD_SIZE dup(?), 0
solvedBoard BYTE BOARD_SIZE dup(?), 0

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