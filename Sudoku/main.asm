INCLUDE Irvine32.inc
.DATA
;===================================================================================================================================================
;																File paths

gamePath BYTE "Sudoku Boards\diff_0_0.txt",0 ;this will point to sudoku folder
solvedGamePath BYTE "Sudoku Boards\diff_0_0_solved.txt",0
tmpPath BYTE "tmp.txt", 0
GamesPlayedPath BYTE "Games Played\0.txt", 0
GamesPlayedCount BYTE "Games Played\Number Of Games.txt", 0
continuePath BYTE "continue.txt", 0
GamesCount BYTE 6 dup(?),0
GamesCountInt BYTE 0
;===================================================================================================================================================
;												Getting value after calling OpenGameFile procedure
gamePlayFileHandle DWORD ?
solvedGamePlayFileHandle DWORD ?
tmpPlayFileHandle DWORD ?
GamesPlayedFileHandle DWORD ?
GamesPlayedCountFileHandle DWORD ?
continueFileHandle DWORD ?
savedFileHandle DWORD ?
;===================================================================================================================================================
;																	Sizes
BOARD_SIZE = 81
ZERO	    = 0
four	    = 4
ONE 	    = 1
TWO 	    = 2
ONE_HUNDRED = 100 
continue_size= 113
;===================================================================================================================================================
;																Normal Variables
board BYTE BOARD_SIZE dup(?), 0					;Array containing original unsolved board
solvedBoard BYTE BOARD_SIZE dup(?), 0			;Array containing solved board
difficulty BYTE 0                               ;The difficulty the user selects
randomBoard BYTE 0								;The random board generated
currentBoard BYTE  BOARD_SIZE dup(?)             ;The Board that gets updated
boardStatus  BYTE  BOARD_SIZE dup(?)			;each cell have 0,1,2 or 4 - 0 indecates an empty cell, 1 matched cell with the solved cell, 2 for not matched cell and 4 for the cell which already esxist in the original board .     
boolEqual    BYTE  1   							;1 if all currentGame matched with solvedGame and 0 if not.  
score	     sword 0					        ; this will have the user final score. 
user_name BYTE 10 dup(?),0
user_name_size BYTE ?
initialTime DWORD ?
continueTime BYTE 0
finalTime DWORD ?
time BYTE "00000000",0
ContinueString BYTE continue_size dup ('0')
;===================================================================================================================================================
;																	Counters

printingCounter DWORD 0
wrongCounter word  0							; count the number of cells which matched with the solved board.
rightCounter word  0							; count the number of cells which dosen't matched with the solved board.
rowCounter DWORD 0
colCounter DWORD 1
correctCounter BYTE 0
incorrectCounter BYTE 0
stepsCount BYTE 0
selectedRow BYTE ?
selectedCol BYTE ?
selectedVal BYTE ?
index Byte ?

;===================================================================================================================================================
;																  Game Strings

level_selection BYTE "Please Select Difficulty [1-3] (Note: 1 is easy).", 0	
continue_game BYTE "1 -  Continue previous game.", 0
new_game BYTE "2 -  New game.", 0
username BYTE "Please enter your name.", 0
selectionString BYTE "1- Change a number in the board", 0
selectionString2 BYTE "2- Restart the board", 0
selectionString3 BYTE "3- Submit your board", 0
selectionString4 BYTE "4- Save game", 0
choice BYTE "Enter you choice: ",0
selectRow BYTE "Select the desired Row: ", 0
selectCol BYTE "Select the desired Column: ", 0
selectValue BYTE "Select the desired Value: ", 0
FailMsg BYTE "Please Enter a correct index",0
FailMsg2 BYTE "Please Enter a correct choice",0
redMsgString BYTE "Wrong answer, try again",0
greenMsgString BYTE "Correct!",0
correctStr BYTE "Number of correct attempts: ",0
incorrectStr BYTE "Number of incorrect attempts: ",0
stepsStr BYTE "Number of steps needed to complete the board: ",0
timeStr BYTE "Total time is : ",0
timeStrCont BYTE " seconds"
;===================================================================================================================================================

.CODE
;###################################################################################################################################################
;																	Main Menu
;The main menu of the game where the player chooses to continue previous game or start a new game
menu PROC uses eax ecx edx esi
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
	mov user_name_size,al
	movzx ecx,al
	mov edx,offset user_name
	mov esi,10
	sub esi,ecx
	add edx,ecx
	mov ecx,esi
	;dec ecx
	L1:						;filling rest of name withe spaces
		mov al,' '
		mov [edx],al
		inc edx
	loop L1

	mov edx,offset level_selection
	call writestring
	call crlf

	call readdec
	mov difficulty, al

	call random

	EndMe:
	call LevelFill
	;ret 
menu ENDP

;Procedure returns a random number in a range from 1 to EAX
random PROC uses eax
	call Randomize		;sets seed         
	mov  eax,3		    ;RandomRange pick random number from 0 to EAX-1           
	call RandomRange	;return in EAX
	add eax, 1
	mov randomBoard,al
    ret
random ENDP

;Loads all the saved variables and previous game details
;Input is the saved file location
;Output is all the variables loaded
Load PROC uses eax ebx ecx edx esi

	mov edx,offset continuePath              ;Opening the file path
	call OpenInputFile
	mov edx, OFFSET ContinueString ; points to buffer
	mov ecx, continue_size ; max bytes to read
	call ReadFromFile ; read the file
	mov edx, offset continueString
	mov ebx, offset currentBoard
	mov savedFileHandle, eax

	mov ecx,9

	_currentboardLoop:
	mov esi,ecx
	mov ecx,9

	_CurrentRows:
	mov al,[edx]
	mov [ebx],al
	inc edx
	inc ebx    
	Loop _CurrentRows

	inc edx
	mov ecx,esi
	LOOP _currentboardLoop

	inc edx 
	
	mov edx, offset continueString
	add edx,90
	mov ebx, offset username
	mov ecx,10
	
	_username:
	mov al,[edx]
	mov [ebx],eax
	inc edx
	inc ebx    
	Loop _username

	mov edx, offset continueString
	add edx,101

	mov al,[edx]
	sub al,'0'
	mov randomBoard,al

	add edx,2
	
	mov al,[edx]
	sub al,'0'
	mov difficulty,al


	mov esi, offset continueString
	add esi,105
	mov ecx,8
	mov al,0
	_time:
	mov dl,10
	MUL dl
	mov dl,[esi]
	sub dl,'0'
	add al,dl
	inc esi 
	Loop _time
	mov continueTime,al
	mov eax, savedFileHandle
	call CloseFile
	call LevelLoading
	ret
Load ENDP

;Loads the boards from the previous game into this game
;Input takes difficulty and randomBoard
;Output The boards are ready to be printed
LevelLoading PROC
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
	
	INVOKE GetTickCount
	mov initialTime, eax
	call Game
	ret
LevelLoading ENDP

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


ReadGameFiles PROC uses edx ecx eax
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

;###################################################################################################################################################
;																	Main Game

;Loads the boards from the files into the variables at the start of the game
;Input takes difficulty and randomBoard
;Output The boards are ready to be printed
LevelFill PROC uses eax ebx edx
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
	INVOKE GetTickCount
	mov initialTime, eax
	call Game
LevelFill endp

;Game starts and the player picks his choices to play, restart,submit or save and exit the game
Game PROC uses eax edx edi
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


;Print: Prints an array in the form of a Sudoku board
;Recieves edx contains offset of an array and
;Returns: That array printed in the Sudoku form

Print PROC uses edx edi ecx eax ebx
	mov ecx, 9
	mov al, ' '
	call writechar
	call writechar
	call writechar
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

;Users inserts a number in a cell
;Takes Row index ,Column index and the assigned Value
;Checks if the input is correct or false according to the solved board then prints the new board if correct
InsertProc PROC uses eax ebx ecx edx esi
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
	mov esi, offset solvedBoard		;for checking if the solution is correct
	add esi, eax
	add ebx,eax
	mov cl,[ebx]
	mov dl, '0'
	cmp cl,dl
	jne Failled
	mov edx, offset currentBoard
	add edx , eax
	mov al, selectedVal
	mov bl,[esi]
	add al , '0'
	cmp al,bl
	jne RedMessage       ;If the answer is wrong
	mov [edx], al
	mov edx,offset greenMsgString
	mov eax,2           ; make color Green
	call setTextColor
	call crlf
	call writestring
	call crlf
	mov eax,7           ; make color White
	call setTextColor
	inc correctCounter
	jmp EndProc
	RedMessage:
		mov edx, offset redMsgString
		mov eax,12           ; make color red
		call setTextColor
		call crlf
		call writestring
		call crlf
		mov eax,7           ; make color White
		call setTextColor
		inc incorrectCounter
		jmp EndProc
	Failled:
		mov edx, offset FailMsg
		call writestring
		call crlf
		jmp RestartProc
	EndProc:	
		ret
InsertProc endp

;Clears the current board and restarts it
;Assigns currentBoard into board
Restart PROC uses eax ebx ecx
	mov ecx, 81
	mov eax, offset board
	mov ebx, offset currentBoard
	L1:									;Copying board into currentBoard
		mov esi, [eax]
		mov [ebx],esi
		inc ebx
		inc eax
	loop L1
	ret
Restart endp

;Ending the game and getting the results
;Prints the solved board with the number of steps needed to be completed,time taken to complete it and the number of correct and incorrect choices
Submit PROC uses eax ebx ecx edx edi esi
	call compare	   ; statusBoard now has the values which will represent the color in the console.
	mov esi, offset boardStatus
	mov ebx, offset solvedBoard
	mov ecx, 81
	mov edi,0
	PrintFinal:
		mov al,[ebx]
		mov dl,[esi]
		cmp dl,0
		je WriteBlue
		call writecharGreen
		jmp EndLoop
		WriteBlue:
			call writecharBlue
			inc stepsCount
		EndLoop:
		mov al,' '
		call writechar
		call writechar
		call writechar
		inc edi
		cmp edi,9
		je EndLine
		jmp Ending
		EndLine:
			call crlf
			call crlf
			mov edi,0
		Ending:
		inc esi
		inc ebx
	loop PrintFinal

	;call finalcheck    ; boolEqaul now has 1 if the player board matched with the solved.

	mov edx,offset stepsStr
	call writestring
	mov al,stepsCount
	call writedec
	call crlf
	mov edx,offset correctStr
	call writestring
	mov al,correctCounter
	call writedec
	call crlf
	mov edx,offset incorrectStr
	call writestring
	mov al,incorrectCounter
	call writedec
	call crlf
	INVOKE GetTickCount
	sub eax,initialTime
	mov ebx, 1000
	mov edx, 0
	div ebx
	add al,continueTime
	mov edx, offset timeStr
	call writestring
	call writedec
	mov edx, offset timeStrCont
	call writestring
	call crlf
	ret
Submit ENDP

;Saves the content of the variables used in the game in a file to be loaded later
;Saves currentBoard, user_name, difficulty and randomBoard
SaveGame PROC uses edx ecx eax esi edi ebx

	mov edx, offset currentBoard
	mov ecx,9
	mov eax,offset ContinueString
		
	currentboardLoop:
	mov esi,ecx
	mov ecx,9

	CurrentRows:
	mov edi,[edx]
	mov [eax],edi
	inc edx
	inc eax    
	Loop CurrentRows
	
	mov byte ptr[eax],0Dh
	inc eax
	mov ecx,esi
	LOOP currentboardLoop

	mov eax,offset ContinueString
	add eax,90

	mov edx,offset user_name
	mov ecx,10
	usernameContLoop:
	mov edi,[edx]
	mov [eax],edi
	inc edx
	inc eax    
	LOOP usernameContLoop
	
	mov byte ptr[eax],0Dh
	inc eax
	mov bl,randomBoard
	mov [eax],bl

	inc eax
	mov bl,0dh
	mov [eax],bl
	
	inc eax
	mov bl,difficulty
	mov [eax],bl

	inc eax
	mov byte ptr[eax],0Dh
	
	call CalculateTimeString
	mov ecx,8
	mov edx,offset time
	mov eax, offset ContinueString
	add eax,105

	TimeLoop:
	mov edi,[edx]
	mov [eax],edi
	inc edx
	inc eax    
	LOOP TimeLoop
	
	mov edx, OFFSET continuePath ; filename should be path to level file
	call CreateOutputFile
	mov continueFileHandle, eax

	mov edx, OFFSET ContinueString
	call writestring
	mov ecx, continue_size
	mov eax, continueFileHandle
	call WriteToFile

	; check for error (source: page 170 from the book).
	cmp eax, 0
	ja SUCCESS 
	call WriteWindowsMsg

	SUCCESS:
	mov eax, continueFileHandle
	call CloseFile
	ret
SaveGame ENDP

; compare proc work with currentBoard and solvedBoard "Char Arrays".
; boardStatus will be affected after the proc finised.
; each index will have one of three *integer value* 0 for empty cell, 1 for mathced , 2 for unmatched and 4 for the cell which already exist in the original board . 
compare PROC uses ebx edx esi ecx eax

	mov ebx, offset currentBoard
	mov edx, offset solvedBoard
	mov esi, offset boardStatus
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
		mov[esi], al
		jmp cont

		equal :
		mov al, [edi]
		cmp al,'0'
		jne alreadyExist
		mov al, one
		mov[esi], al
		jmp cont

		wrong :
		mov al, two
		mov[esi], al
		jmp cont

		alreadyExist:
		mov al,four
		mov[esi], al
		jmp cont

		cont :
		inc ebx
		inc edx
		inc esi
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
		jmp continuee
		
		wrong:
		inc wrongCounter

		continuee:
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

writecharBlue PROC uses edx eax
	
	mov edx,eax
	mov eax,9           ; make color Black
	call setTextColor

	mov eax,edx       
	call writechar
	
	mov eax,7           
	call setTextColor    ; make color White again 
	 
	ret
writecharBlue ENDP

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

;Calculates the total time to be saved in a file
;Uses GetTickCount Function
;returns a string value of the total time in seconds in variable time
CalculateTimeString PROC uses eax ebx ecx edi esi
	INVOKE GetTickCount
	sub eax,initialTime
	mov ebx, 1000
	mov edx, 0
	div ebx
	cmp eax,10
	jl onee
	cmp eax,100
	jl twoo
	cmp eax,1000
	jl three
	cmp eax,10000
	jl fourr
	cmp eax,100000
	jl five
	cmp eax,1000000
	jl six
	cmp eax,10000000
	jl seven
	cmp eax,100000000
	jl eight

	onee:
		mov ebx,1
		mov ecx,7
		jmp looping
	twoo:
		mov ebx,2
		mov ecx,6
		jmp looping
	three:
		mov ebx,3
		mov ecx,5
		jmp looping
	fourr:
		mov ebx,4
		mov ecx,4
		jmp looping
	five:
		mov ebx,5
		mov ecx,3
		jmp looping
	six:
		mov ebx,6
		mov ecx,2
		jmp looping
	seven:
		mov ebx,7
		mov ecx,1
		jmp looping
	eight:
		mov ebx,8
		mov ecx,0

	looping:
		mov edi,offset time
		add edi,ecx
		mov ecx,ebx
		L2:
			mov edx,0
			mov esi,10
			DIV esi
			add edx,'0'
			mov [edi],dl
			inc edi
		loop L2
	ret
CalculateTimeString ENDP


TopPlayers PROC
	mov edx, OFFSET GamesPlayedCount ; filename should be path to level file
	call _OpenInputFile
	mov GamesPlayedCountFileHandle, eax

	mov edx, OFFSET GamesCount ; points to buffer
	mov ecx,  6; max bytes to read
	mov eax, GamesPlayedCountFileHandle
	call _ReadFromFile

	mov esi, OFFSET GamesCount
	mov al, 0
	mov ecx,6
	L1:
		mov bl,10
		mul bl
		mov bl,[esi]
		sub bl,'0'
		add al,bl
		inc esi
	LOOP L1
	inc al
	mov GamesCountInt,al
	movzx eax,GamesCountInt
	call writedec
	cmp eax,10
	jl onee
	cmp eax,100
	jl twoo
	cmp eax,1000
	jl three
	cmp eax,10000
	jl fourr
	cmp eax,100000
	jl five
	cmp eax,1000000
	jl six
	cmp eax,10000000

	onee:
		mov ebx,1
		mov ecx,7
		jmp looping
	twoo:
		mov ebx,2
		mov ecx,6
		jmp looping
	three:
		mov ebx,3
		mov ecx,5
		jmp looping
	fourr:
		mov ebx,4
		mov ecx,4
		jmp looping
	five:
		mov ebx,5
		mov ecx,3
		jmp looping
	six:
		mov ebx,6
		mov ecx,2
		jmp looping

	looping:
		mov edi,offset GamesCount
		add edi,ecx
		mov ecx,ebx
		L2:
			mov edx,0
			mov esi,10
			DIV esi
			add edx,'0'
			mov [edi],dl
			inc edi
		loop L2
		mov edx, offset GamesCount
		call writestring
	ret
TopPlayers ENDP


main PROC
	call menu
	exit
main ENDP

END main