INCLUDE external.inc

; DIFFICULTY SCALING
RANDOM_WORD_MAX = 50									; max number of words the last level will have
RANDOM_WORD_BASE = 10									; base number of random word objects
DIFFICULTY_RANDOM_WORD_SCALAR = 10						; number of words increased per level
DIFFICULTY_SPAWN_RATE_SCALAR = 4						; spawn rate decreased per level

.code

; --------------------------------------------------------------------
; RunTypingGame
;
; This function runs the typing game. The typing game consists of 5
; difficulty levels that get increasingly harder.
; RECEIVES: None
; RETURNS:  None
; REQUIRES: None
; --------------------------------------------------------------------
RunTypingGame PROC USES eax ebx ecx edx esi edi
	.data
	filename BYTE "randomWords.txt", 0
	fileHandle DWORD ?
	bufferAddress DWORD ?								; address to file buffer
	randomWordAddresses DWORD RANDOM_WORD_MAX DUP(?)	; array containing random word addresses
	effectiveSize DWORD RANDOM_WORD_BASE				; effective size of random word address
	levelDifficulty DWORD 1								; contains the level difficulty
	spawnRate WORD 60									; spawn rate based on frames
	mainGameLoopInput BYTE ?							; contains the user input to navigate through main game loop

	.code
	CALL Randomize										; seeding RNG

	; opening and reading randomWord.txt into a buffer
	MOV edx, OFFSET filename
	CALL OpenInputFile
	MOV fileHandle, eax
	CALL ReadFileIntoBuffer
	MOV bufferAddress, eax
	MOV eax, fileHandle
	CALL CloseFile

	; display menu
	MOV eax, levelDifficulty
	CALL DisplayMenu
	MOV mainGameLoopInput, al 

	typingGameLoop:
		; game loop exit condition
		CMP mainGameLoopInput, 'q'
		JE typingGameLoopExit
		CMP levelDifficulty, 5
		JA typingGameLoopExit

		; generating random words into random word array
		MOV esi, bufferAddress
		MOV edi, OFFSET randomWordAddresses
		MOV ecx, effectiveSize
		CALL GenerateRandomWords

		; runs the game level
		MOV esi, OFFSET randomWordAddresses
		MOV eax, levelDifficulty
		MOV ebx, effectiveSize
		MOV dx, spawnRate
		CALL RunLevel

		; clear random word array for next level (deallocates memory for random word objects)
		MOV esi, OFFSET randomWordAddresses
		MOV ecx, effectiveSize
		CALL ClearRandomWordArray

		; handles set up for next level
		INC levelDifficulty
		ADD effectiveSize, DIFFICULTY_RANDOM_WORD_SCALAR
		SUB spawnRate, DIFFICULTY_SPAWN_RATE_SCALAR
		CMP levelDifficulty, 5
		JA typingGameLoop

		; display menu
		MOV eax, levelDifficulty
		CMP eax, 5
		CALL DisplayMenu
		MOV mainGameLoopInput, al

		JMP typingGameLoop
	typingGameLoopExit:

	; destroying file buffer
	MOV esi, bufferAddress
	CALL DeallocateBuffer

	; display credits screen
	CALL DisplayCredits
	RET
RunTypingGame ENDP

; --------------------------------------------------------------------
; RunLevel
;
; This function runs the level of the typing game.
; RECEIVES: ESI, EAX, EBX, DX
; RETURNS:  None	
; REQUIRES: ESI contains the address to the random word array;
;			EAX contains the difficulty level of the level;
;			EBX contains the effective size of the random word array;
;			DX contains the spawn rate of random word objects
; --------------------------------------------------------------------
RunLevel PROC USES eax ebx ecx edx esi edi
	.data
	lDifficultyLevel DWORD ?				; contains difficulty level
	lRandomWordArrayAddress DWORD ?			; contains random word array address
	lEffectiveSize DWORD ?					; contains effective array size
	lSpawnRate WORD ?						; contains spawn rate of random word objects
	
	; back-end tracking for game logic
	unspawnedIndex DWORD 0					; index of next word to spawn
	focusedIndex DWORD -1					; index being focused
	frameCounter DWORD 0					; counts the frames
	userInput BYTE ?

	; tracks scoring and accuracy
	score DWORD 0
	correctKeyStrokes DWORD 0
	totalKeyStrokes DWORD 0

	.code
	PUSHFD								; saving flags

	; initializing all variables for current level (previous levels overwrite these values)
	MOV unspawnedIndex, 0
	MOV focusedIndex, -1
	MOV frameCounter, 0
	MOV userInput, 0
	MOV score, 0
	MOV correctKeyStrokes, 0
	MOV totalKeyStrokes, 0

	; transferring function parameters to variables
	MOV lDifficultyLevel, eax
	MOV lRandomWordArrayAddress, esi
	MOV lEffectiveSize, ebx
	MOV lSpawnRate, dx

;**************************************************** LEVEL BEGIN ****************************************************
	; displaying level start screen
	MOV eax, lDifficultyLevel
	CALL LevelStartDisplay

	; game level loop
	levelLoopBegin:
		; game level exit conditions
		; EXIT CONDITION #1: User presses ESC
		CMP userInput, ESC_KEY			; checking if user pressed ESCAPE
		JZ levelLoopEnd
		
		; EXIT CONDITION #2: All random word objects are hidden and have been spawned
		MOV esi, lRandomWordArrayAddress
		MOV ecx, lEffectiveSize
		CALL GameLevelExitCondition
		CMP eax, TRUE
		JE levelLoopEnd

;*************************************************** INPUT CHECKING ***************************************************
		; reading user input
		CALL ReadKey
		MOV userInput, al				; storing ASCII code of user input into variable
		JZ stateChecking

		; checks if the user input is a character
		CALL IsValidChar
		CMP ah, TRUE
		JNE invalidChar
		INC totalKeyStrokes			; only adds to key stroke if the input is a valid character
		invalidChar:

		; check that focused index is valid
		CMP focusedIndex, -1
		JNE validFocusedIndex

		; searches array for a character inputted by user if focused index is invalid
		MOV esi, lRandomWordArrayAddress
		MOV ecx, lEffectiveSize
		MOV al, userInput
		CALL SearchRandomWordArray
		CMP eax, -1					; checks if a random word object was found to be focused
		JE spawner

		; handling the case where a valid replacement for focused index is found
		MOV focusedIndex, eax

		; handles case for a valid focused index
		validFocusedIndex:
		MOV esi, lRandomWordArrayAddress
		MOV eax, focusedIndex
		MOV ecx, lEffectiveSize
		CALL GetRandomWordAt

		; handles case for an input checking against focused random word object 
		MOV bl, userInput				; storing the user input into BL
		CALL GetCurrentCharacter
		CMP bl, al						; comparing user input with current character
		JNE stateChecking
		CALL IncrementCorrectCharacters
		INC correctKeyStrokes

;*************************************** RANDOM WORD OBJECT STATE CHECKING ***************************************
		stateChecking:

		; handles case where there is no focused index
		CMP focusedIndex, -1
		JE spawner

		; getting focused random word address
		MOV esi, lRandomWordArrayAddress
		MOV eax, focusedIndex
		MOV ecx, lEffectiveSize
		CALL GetRandomWordAt

		; checks if focused word is hidden
		CALL IsHidden
		CMP eax, TRUE
		JNE notHidden
		MOV focusedIndex, -1			; sets focused index to an invalid index if focused random word is hidden
		notHidden:

;***************************************************** SPAWNER *****************************************************
		spawner:

		; checks if a random word object can spawn 
		MOV eax, frameCounter
		MOV bx, lSpawnRate
		CALL SpawnNow
		CMP eax, TRUE
		JNE noSpawn

		; checks if unspawned index is valid
		MOV eax, unspawnedIndex
		CMP eax, lEffectiveSize 
		JE noSpawn

		; getting unspawned random word address
		MOV esi, lRandomWordArrayAddress
		MOV eax, unspawnedIndex
		MOV ecx, lEffectiveSize
		CALL GetRandomWordAt

		; handles the case for spawning a word
		MOV eax, unspawnedIndex
		MOV ecx, lEffectiveSize
		CALL SpawnRandomWord
		INC unspawnedIndex
		noSpawn:

;*********************************************** DRAWING AND UPDATING ***********************************************
		; drawing and updating all random word objects onto the console screen
		MOV esi, lRandomWordArrayAddress
		MOV ecx, lEffectiveSize
		CALL Draw				; draws all random word objects onto console
		MOV eax, 16				; delay in milliseconds until next frame
		CALL Delay
		CALL Clear				; clears all random word objects from console
		MOV eax, frameCounter	; moving frame counter as parameter for Update function
		CALL Update				; updates all random word object positions
		INC frameCounter		; increasing all relevant counters
		JMP levelLoopBegin
	levelLoopEnd:

;**************************************************** LEVEL END ****************************************************
	; counting score
	MOV esi, lRandomWordArrayAddress
	MOV ecx, lEffectiveSize
	CALL ScoreCounting
	MOV score, eax
	
	; displaying level end screen and user score on level
	MOV eax, score
	MOV ebx, correctKeyStrokes
	MOV ecx, totalKeyStrokes
	MOV edx, lEffectiveSize
	CALL LevelEndDisplay
	POPFD						; loading flags
	RET
RunLevel ENDP

; --------------------------------------------------------------------
; ExtractRandomWord
;
; This function will extract a random word from the passed in buffer
; and create a random word object with a random x-position, 
; x-velocity, and y-velocity.
; RECEIVES: ESI
; RETURNS:  EAX contains address to random word object
; REQUIRES: ESI contains address to buffer
; --------------------------------------------------------------------
ExtractRandomWord PROC USES esi edi ecx
	.data
	stringBuffer BYTE STRING_BUFFER_SIZE DUP(0), 0

    .code
	MOV edi, OFFSET stringBuffer	; storing address to string buffer into EDI for copying later

	; generating a random index to start from
	MOV eax, BUFFER_SIZE
	CALL RandomRange
	ADD eax, STRING_BUFFER_SIZE
	ADD esi, eax

	; this loop moves index to a line feed
	MOV al, 0Ah						; contains line feed ASCII for comparison
	beginWhile1:
		; while loop condition
		CMP [esi], al				; checks if current character is a line feed
		JE endWhile1
		DEC esi
		JMP beginWhile1
	endWhile1:
	INC esi							; moves index to first character of a word

	; this loop copies string from file buffer into string buffer until carriage return is reached
	MOV al, 0Dh						; contains carrage return ASCII for comparison
	beginWhile2:
		; while loop condition
		CMP [esi], al				; checks if current character is a carriage return
		JE endWhile2

		; copying character to buffer
		MOV ah, [esi]
		MOV [edi], ah

		; increments index to next character to copy
		INC esi
		INC edi
		JMP beginWhile2
	endWhile2:

	; creating random word object
	MOV esi, OFFSET stringBuffer
	CALL ConstructRandomWord
	MOV ecx, STRING_BUFFER_SIZE
	CALL ClearStringBuffer
    RET
ExtractRandomWord ENDP

; --------------------------------------------------------------------
; GenerateRandomWordAttributes
;
; This function will randomize the values of the x-position. The upper 
; bound at which the x-position is randomized, up to, can be set. 
; Random values are generated within the range of [0, upperBound) 
; where the upper bound is not included. Random word objects must
; have objects that are of size 1 or greater.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;			EAX contains the x-position upper bound of randomization;
; --------------------------------------------------------------------
GenerateRandomWordAttributes PROC USES esi eax ecx
    .code
    ; randomizing the x-position of the random word object
	CALL RandomRange
	CALL SetXPosition

	; setting y-position of random word object
	MOV eax, 0
	CALL SetYPosition

	; setting number of correct characters typed
	MOV eax, 0
	CALL SetCorrectCharacters

	; setting spawned state boolean value
	MOV eax, FALSE
	CALL SetSpawnedState

	; setting hidden state boolean value
	MOV eax, TRUE
	CALL SetHiddenState

	; assigning velocity based on string sizes
	CALL GetString
	PUSH esi
	MOV esi, eax
	CALL GetStringLength
	POP esi

	; checking size and assigning attributes based on size
	CMP eax, 5
	JBE small
	CMP eax, 10
	JBE medium
	JMP large

	; SMALL WORD CASE
	small:
	; randomizing the x-velocity of the small random word object
	MOV eax, 1
	CALL RandomInt32Range
	CALL SetXVelocity

	; randomizing the y-velocity of the small random word object
	MOV eax, 1
	CALL RandomRange
	INC eax
	CALL SetYVelocity

	; sets the frames per movement value to small random word object 
	MOV eax, 5
	CALL SetFramesPerMovement
	JMP return

	; MEDIUM WORD CASE
	medium:
	; randomizing the x-velocity of the medium random word object
	MOV eax, 1
	CALL RandomInt32Range
	CALL SetXVelocity

	; setting the y-velocity of the medium random word object
	MOV eax, 1
	CALL SetYVelocity

	; sets the frames per movement value to medium random word object 
	MOV eax, 15
	CALL SetFramesPerMovement
	JMP return

	; LARGE WORD CASE
	large:
	; randomizing the x-velocity of the large random word object
	MOV eax, 0
	CALL SetXVelocity

	; randomizing the y-velocity of the large random word object
	MOV eax, 1
	CALL SetYVelocity

	; sets the frames per movement value to large random word object 
	MOV eax, 30
	CALL SetFramesPerMovement
	JMP return

	return:
    RET
GenerateRandomWordAttributes ENDP

; --------------------------------------------------------------------
; GenerateRandomWords
;
; This function will generate random words and store their addresses
; into an array of random word addresses.
; RECEIVES: ESI, EDI, ECX
; RETURNS:  None
; REQUIRES: ESI contains the address to the file buffer containing
;			random strings;
;			EDI contains the address to the random word object array;
;			ECX contains the effective size of the array
; --------------------------------------------------------------------
GenerateRandomWords PROC USES esi edi ecx ebx
	.code
	; this loop generates random word objects into a destination array
	generateLoop:
		PUSH esi							; storing address to file buffer
		CALL ExtractRandomWord				; creates a random word object from extracted word from buffer
		MOV esi, eax
		CALL GetLength
		MOV ebx, eax
		MOV eax, CONSOLE_WINDOW_MAX_X
		SUB eax, ebx
		CALL GenerateRandomWordAttributes	; generates random attributes for random word object
		MOV [edi], esi						; storing random word object address into array of random word object addresses
		ADD edi, TYPE DWORD
		POP esi								; loading address to file buffer
		LOOP generateLoop
	RET
GenerateRandomWords ENDP

; --------------------------------------------------------------------
; ClearRandomWordArray
;
; This function clears all random words from an array of random word
; addresses. The memory is deallocated for each random word in the
; array.
; RECEIVES: ESI, ECX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object array;
;			ECX contains the effective size of the array
; --------------------------------------------------------------------
ClearRandomWordArray PROC USES esi eax ecx edx
	.data
	failedMsg BYTE "Random word object array failed to fully clear."

    .code
	MOV edx, OFFSET failedMsg			; used to display a failure message in the case clearing fails

	; this loop deallocates memory for each random word objects in the array of random word object addresses
    clearArrayLoop:
		PUSH esi				; saving address to random word object array
		MOV eax, [esi]
		MOV esi, eax
		CALL DestroyRandomWord
		POP esi					; loading address to random word object array

		; checks if destruction of random word object was successful
		CMP eax, TRUE
		JNE failed

		ADD esi, TYPE DWORD
		LOOP clearArrayLoop
	JMP return

	; handles the case where a random word was not successfully cleared
	failed:
	CALL Clrscr
	CALL WriteString
	CALL Crlf

	return:
    RET
ClearRandomWordArray ENDP

; --------------------------------------------------------------------
; LevelStartDisplay
;
; This function will display the level start screen.
; RECEIVES: EAX
; RETURNS:  None
; REQUIRES: EAX contains the level number
; --------------------------------------------------------------------
LevelStartDisplay PROC USES eax ebx ecx edx edi esi
    .code
	; displaying level header at middle of screen
	MOV ecx, 0
	CALL DisplayLevelHeader

	; getting position to display countdown
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole				; getting middle coordinates of console
	INC ebx
	MOV dl, al
	MOV dh, bl

	; displays a 3 second countdown on screen
	MOV ecx, 3							; setting countdown length into ECX
	countdownLoop:
		CALL Gotoxy
		MOV eax, 1000
		CALL Delay
		MOV eax, ecx
		CALL WriteDec
		LOOP countdownLoop
	MOV eax, 1000
	CALL Delay
	CALL Clrscr
    RET
LevelStartDisplay ENDP

; --------------------------------------------------------------------
; SpawnRandomWord
;
; This function will spawn a random word object onto the console. The 
; address of the random word is given.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
SpawnRandomWord PROC USES esi eax
    .code
	; checks if word was already spawned
	CALL IsSpawned
	CMP eax, TRUE
	JE return

	; sets the state of the random word object to spawned
    MOV eax, TRUE
	CALL SetSpawnedState

	; sets the state of the random word object to not be hidden
	MOV eax, FALSE
	CALL SetHiddenState

	return:
    RET
SpawnRandomWord ENDP

; --------------------------------------------------------------------
; SpawnNow
;
; This function will determine whether or not to spawn a random word
; object given the current loop count, of the game loop, and the
; spawn rate.
; RECEIVES: EAX, BX
; RETURNS:  EAX contains a boolean indicating whether or not to spawn
;			a random word object
; REQUIRES: AX contains the loop counter;
;			BL contains the spawn rate
; --------------------------------------------------------------------
SpawnNow PROC USES ebx edx
    .code
	MOV edx, 0			; setting EDX up for division
    DIV ebx

	; checking if the loop count is divisible by the spawn rate
	CMP edx, 0			; checking remainder for divisibility
	JNE noSpawn

	; handles case for spawn occuring
	MOV eax, TRUE
	JMP return

	; handles case for no spawn occuring
	noSpawn:
	MOV eax, FALSE

	return:
    RET
SpawnNow ENDP

; --------------------------------------------------------------------
; SearchRandomWordArray
;
; This function will search a given random word array for a word that
; begins with a given character and has the largest value for its 
; y-position to resolve the possibility of multiple words beginning 
; with the same character. The index will be returned if a match is
; found; otherwise, -1 is returned.
; RECEIVES: ESI, ECX, AL
; RETURNS:  EAX
; REQUIRES: ESI contains the address to the array containing random
;			word object addresses;
;			ECX contains the effective array size;
;			AL contains the the character of interest
; --------------------------------------------------------------------
SearchRandomWordArray PROC USES esi ebx edi edx ecx ebx
	.data
	resultIndex DWORD ?			; the resultant index with the random word meeting search criterias
	resultIndexYPos DWORD ?		; the y-position of the random word at resultant index

    .code
	; initializing result tracking values
	MOV resultIndex, -1			; assumes random word object is not at an index that is valid
	MOV resultIndexYPos, 0		; initializes result y-position to 0

	MOV bl, al					; storing character to check for into BL
	MOV edi, esi				; storing random word array address into EDI
	MOV edx, 0					; storing index of current random word object being searched (index tracking)

	; searches through array for random word object containing target character and largest y-position
	searchLoop:
		; getting character of random word object at currentIndex (if it is not hidden)
		MOV esi, [edi]
		CALL IsHidden				; checks if random word object is hidden
		CMP eax, TRUE
		JE hidden
		CALL GetCurrentCharacter
		
		; comparing target character with first character in current random word
		CMP bl, al
		JNE hidden

		; handles case where target character is the first letters in current random word object
		CALL GetYPosition
		CMP eax, resultIndexYPos
		JBE hidden
		
		; handles the case where one random word object has a greater y-position than the resultant
		; random word object (both containing target character)
		MOV resultIndexYPos, eax
		MOV resultIndex, edx

		hidden:
		INC edx
		ADD edi, TYPE DWORD
		LOOP searchLoop

	; checking if result index is valid
	CMP resultIndex, -1
	JE return

	; handles case where a random word object was found and returning the index
	MOV eax, resultIndex

	return:
    RET
SearchRandomWordArray ENDP

; --------------------------------------------------------------------
; Update
;
; This function will update positions of random word objects in a 
; given array of random word objects. The effective size of the array 
; is also given.
; RECEIVES: ESI, EAX, ECX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object array;
;			EAX contains the current frame count of the program;
;			ECX contains the effective size of the array
; --------------------------------------------------------------------
Update PROC USES eax esi ecx
    .code
	; this loop will update all random word objects
	updateLoop:
		PUSH esi					; storing address to random word object array
		PUSH eax					; storing current program frame count
		MOV eax, [esi]				; storing address to random word object
		MOV esi, eax
		POP eax						; loading current program frame count
		CALL UpdateRandomWord		; updating the random word
		POP esi						; loading address to random word object array
		ADD esi, TYPE DWORD			; incrementing ESI to next random word object
		LOOP updateLoop
	RET
Update ENDP

; --------------------------------------------------------------------
; Clear
;
; This function will clear all, currently drawn, random word objects  
; in a given array of random word objects. The effective size of the  
; array is also given.
; RECEIVES: ESI, ECX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object array;
;			ECX contains the effective size of the array
; --------------------------------------------------------------------
Clear PROC USES eax esi ecx
    .code
	; this loop will clear all random word objects on the console
	clearLoop:
		PUSH esi					; storing address to random word object array
		MOV eax, [esi]				; storing address to random word object
		MOV esi, eax
		CALL ClearRandomWord		; clearing the random word from console
		POP esi						; loading address to random word object array
		ADD esi, TYPE DWORD			; incrementing ESI to next random word object
		LOOP clearLoop
	RET
Clear ENDP

; --------------------------------------------------------------------
; Draw
;
; This function will display all random word objects in a given array
; of random word objects. The effective size of the array is also
; given.
; RECEIVES: ESI, ECX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object array;
;			ECX contains the effective size of the array
; --------------------------------------------------------------------
Draw PROC USES eax esi ecx
    .code
	; this loop will draw all random word objects onto the console
	drawLoop:
		PUSH esi					; storing address to random word object array
		MOV eax, [esi]				; storing address to random word object
		MOV esi, eax
		CALL DrawRandomWord			; drawing the random word onto console
		POP esi						; loading address to random word object array
		ADD esi, TYPE DWORD			; incrementing ESI to next random word object
		LOOP drawLoop
	RET
Draw ENDP

; --------------------------------------------------------------------
; GetRandomWordAt
;
; This function will get the random word object at a given index.
; RECEIVES: ESI, EAX, ECX
; RETURNS:  ESI contains the address to the random word object
; REQUIRES: ESI contains the address to the random word object array;
;			EAX contains the index to retrieve the random word from;
;			ECX contains the effective size of array
; --------------------------------------------------------------------
GetRandomWordAt PROC USES eax ebx ecx edi
    .code
    ; check that index is valid and within range
	CMP eax, ecx
	JAE invalidIndex

	; handles the case where index is valid
	CALL ConvertIndexToDWORDIndex
	ADD esi, eax
	MOV eax, esi
	MOV esi, [eax]			; storing random word object address into ESI
	JMP return

	; handles case for invalid index
	invalidIndex:
	;MOV esi, 0

	return:
    RET
GetRandomWordAt ENDP

; --------------------------------------------------------------------
; ScoreCounting
;
; This function will count the user's score of all completed words in
; the array.
; RECEIVES: ESI, ECX
; RETURNS:  EAX contains the user's score
; REQUIRES: ESI contains the address to the random word array;
;			ECX contains the effective size of array
; --------------------------------------------------------------------
ScoreCounting PROC USES ecx esi edi edx
    .code
	MOV edx, 0				; initializing score counter, EAX, to 0
	MOV edi, esi			; storing random word array address into EDI

	; loop counts the score
    scoreCountingLoop:
		MOV esi, [edi]
		CALL IsCompleted
		CMP eax, TRUE
		JNE continue

		; handles case where word is completed
		INC edx				; adds to user score

		continue:
		ADD edi, TYPE DWORD
		LOOP scoreCountingLoop

	MOV eax, edx			; returning the score value to EAX
    RET
ScoreCounting ENDP

; --------------------------------------------------------------------
; GameLevelExitCondition
;
; This function checks if the exit condition has been met for the game
; level. True is returned if exit condition is met; false, otherwise.
; The exit condition is met when all random word objects, within a
; level, has been spawned and are hidden.
; RECEIVES: ESI, ECX
; RETURNS:  EAX contains a boolean indicating if exit condition has
;			has been met for the game level
; REQUIRES: ESI contains the address to the random word object array;
;			ECX contains the effective size of the array
; --------------------------------------------------------------------
GameLevelExitCondition PROC USES esi ebx ecx edi
    .code
	MOV ebx, FALSE			; assumes exit condition has not been met
	MOV edi, esi			; storing random word object array into EDI

	; this function checks if the exit condition has been met
    exitConditionCheckLoop:
		MOV esi, [edi]

		; checks if random word object is hidden
		CALL IsHidden
		CMP eax, TRUE
		JNE return

		; checks if random word object has been spawned
		CALL IsSpawned
		CMP eax, TRUE
		JNE return

		ADD edi, TYPE DWORD
		LOOP exitConditionCheckLoop

	MOV ebx, TRUE			; exit condition has been met

	return:
	MOV eax, ebx			; returns boolean value into EAX
    RET
GameLevelExitCondition ENDP

; --------------------------------------------------------------------
; LevelEndDisplay
;
; This function displays the end of the level and score that the user
; received.
; RECEIVES: EAX, EBX, ECX
; RETURNS:  None
; REQUIRES: EAX contains the user's score;
;			EBX contains the user's correct key strokes;
;			ECX contains the user's total key strokes;
;			EDX contains the possible score
; --------------------------------------------------------------------
LevelEndDisplay PROC USES eax
    .code
	CALL DisplayLevelEndString
    CALL DisplayUserScore
	CALL DisplayPossibleScore
	CALL DisplayUserAccuracy
	CALL Crlf

	; displaying WaitMsg (Irvine32.inc)
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole
	SUB eax, 14							; centering the wait message
	ADD ebx, 4
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy
	CALL WaitMsg
	CALL Clrscr
    RET
LevelEndDisplay ENDP

; --------------------------------------------------------------------
; DisplayLevelEndString
;
; This function will display the level ending string, centered on the
; console window.
; RECEIVES:	None
; RETURNS:  None
; REQUIRES: None
; --------------------------------------------------------------------
DisplayLevelEndString PROC USES esi eax ebx ecx edx
	.data
	levelEndString BYTE "LEVEL COMPLETED", 0

    .code
    ; determines location to print levelEndString
	MOV esi, OFFSET levelEndString
	CALL GetMidpointOfString
	MOV ecx, eax
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole
	SUB eax, ecx					; centers the text at middle of screen
	SUB ebx, 2							; moving y-coordinate to an unoccupied space for level end display

	; moving cursor to appropriate location to print string
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy

	; setting color of text to green
	MOV eax, green + (black * 16)
	CALL SetTextColor

	MOV edx, OFFSET LevelEndString
	CALL WriteString

	; setting color of text to default color
	CALL DefaultTextColor
	CALL Crlf
    RET
DisplayLevelEndString ENDP

; --------------------------------------------------------------------
; DisplayUserScore
;
; This function will display the user's score at the middle of the
; screen.
; RECEIVES: EAX
; RETURNS:  None
; REQUIRES: EAX contains the user's score
; --------------------------------------------------------------------
DisplayUserScore PROC USES esi eax ebx ecx edx
	.data
	scoreHeader BYTE "SCORE: ", 0

    .code
	PUSH eax						; saving the user's score

    ; determines location to print scoreHeader
	MOV esi, OFFSET scoreHeader
	CALL GetMidpointOfString
	INC eax							; accounts for midpoint of score number
	MOV ecx, eax
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole
	SUB eax, ecx					; centers the text at middle of screen
	DEC ebx

	; moving cursor to appropriate location to print string
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy

	; displaying score
	POP eax							; loading user's score into EAX
	MOV edx, OFFSET scoreHeader
	CALL WriteString
	CALL WriteDec
	CALL Crlf
    RET
DisplayUserScore ENDP

; --------------------------------------------------------------------
; DisplayPossibleScore
;
; This function will display the possible score at the middle of the
; screen.
; RECEIVES: EDX
; RETURNS:  None
; REQUIRES: EDX contains the possible score attainable
; --------------------------------------------------------------------
DisplayPossibleScore PROC USES eax ebx ecx edx
	.data
	possibleScoreHeader BYTE "POSSIBLE SCORE: ", 0

    .code
	PUSH edx						; saving the user's score

    ; determines location to print possibleScoreHeader
	MOV esi, OFFSET possibleScoreHeader
	CALL GetMidpointOfString
	INC eax							; accounts for midpoint of possible score number
	MOV ecx, eax
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole
	SUB eax, ecx					; centers the text at middle of screen

	; moving cursor to appropriate location to print string
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy

	; displaying possible score
	POP eax							; loading possible score into EAX
	MOV edx, OFFSET possibleScoreHeader
	CALL WriteString
	CALL WriteDec
	CALL Crlf
    RET
DisplayPossibleScore ENDP

; --------------------------------------------------------------------
; DisplayUserAccuracy
;
; This function will display the user's accuracy at the middle of the
; screen.
; RECEIVES: EBX, ECX
; RETURNS:  None
; REQUIRES: EBX contains the user's correct key strokes;
;			ECX contains the user's total key strokes
; --------------------------------------------------------------------
DisplayUserAccuracy PROC
    .code
	; displaying correct and total key strokes
	CALL DisplayCorrectKeyStrokes
	CALL DisplayTotalKeyStrokes
    RET
DisplayUserAccuracy ENDP

; --------------------------------------------------------------------
; DisplayCorrectKeyStrokes
;
; This function will display the user's total key strokes, centered,
; on the console window.
; RECEIVES: EBX
; RETURNS:  None
; REQUIRES: EBX contains the user's correct key strokes
; --------------------------------------------------------------------
DisplayCorrectKeyStrokes PROC USES esi eax ebx ecx edx
	.data
	correctKeyHeader BYTE "CORRECT KEY STROKES: ", 0

    .code
	PUSH ebx						; saving the user's correct key strokes

    ; determines location to print correctKeyHeader
	MOV esi, OFFSET correctKeyHeader
	CALL GetMidpointOfString
	INC eax							; accounts for midpoint of accuracy number
	MOV ecx, eax
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole
	SUB eax, ecx					; centers the text at middle of screen
	INC ebx							; moving y-coordinate to an unoccupied space for level end display

	; moving cursor to appropriate location to print string
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy

	; displaying correct keys pressed by user
	POP eax							; loading correct key strokes
	MOV edx, OFFSET correctKeyHeader
	CALL WriteString
	CALL WriteDec
	CALL Crlf
    RET
DisplayCorrectKeyStrokes ENDP

; --------------------------------------------------------------------
; DisplayTotalKeyStrokes
;
; This function will display the user's total key strokes, centered,
; on the console window.
; RECEIVES: ECX
; RETURNS:  None
; REQUIRES: ECX contains the user's total key strokes
; --------------------------------------------------------------------
DisplayTotalKeyStrokes PROC USES esi eax ebx ecx edx
	.data
	totalKeyHeader BYTE "TOTAL KEY STROKES: ", 0

    .code
	; move to appropriate spot on screen
	PUSH ecx						; saving the user's total key strokes

    ; determines location to print totalKeyHeader
	MOV esi, OFFSET totalKeyHeader
	CALL GetMidpointOfString
	INC eax							; accounts for midpoint of accuracy number
	MOV ecx, eax
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole
	SUB eax, ecx					; centers the text at middle of screen
	ADD ebx, 2						; moving y-coordinate to an unoccupied space for level end display

	; moving cursor to appropriate location to print string
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy

	; displaying total keys pressed by user
	POP eax							; loading total key strokes
	MOV edx, OFFSET totalKeyHeader
	CALL WriteString
	CALL WriteDec
	CALL Crlf
	RET
DisplayTotalKeyStrokes ENDP

; --------------------------------------------------------------------
; DisplayMenu
;
; This function will display the main game menu and get the user input
; on whether or not to start or quit the game.
; RECEIVES: EAX
; RETURNS:  AL contains the user's input
; REQUIRES: EAX contains the level difficulty
; --------------------------------------------------------------------
DisplayMenu PROC USES ebx esi edx
	.data
	gameTitle BYTE "TYPEROIDS - A typing game", 0
	mainMenuUserInputPrompt1 BYTE "Press [p] to play.", 0
	mainMenuUserInputPrompt2 BYTE "Press [q] to quit.", 0

    .code
	; displaying game title
	MOV esi, OFFSET gameTitle
	MOV ecx, -2
	CALL DisplayStringAtMiddle

	; displaying level header
	MOV ecx, 0					; setting offset
	CALL DisplayLevelHeader

	; displays the main menu prompts
	MOV esi, OFFSET mainMenuUserInputPrompt1
	MOV ecx, 1
	CALL DisplayStringAtMiddle

	MOV esi, OFFSET mainMenuUserInputPrompt2
	MOV ecx, 2
	CALL DisplayStringAtMiddle

	; obtaining valid user input
	MOV al, 0
	mainMenuInputLoop:
		; while loop exit conditions
		CMP al, 'p'
		JE mainMenuInputLoopExit
		CMP al, 'q'
		JE mainMenuInputLoopExit
		CMP al, 'P'
		JE mainMenuInputLoopExit
		CMP al, 'Q'
		JE mainMenuInputLoopExit
		
		; reads user input
		CALL ReadChar
		JMP mainMenuInputLoop
	mainMenuInputLoopExit:
    CALL Clrscr
    RET
DisplayMenu ENDP

; --------------------------------------------------------------------
; DisplayLevelHeader
;
; This function will display the level header at the center of the
; console given the level difficulty.
; RECEIVES: EAX, ECX
; RETURNS:  None
; REQUIRES: EAX contains the level difficulty;
;			ECX contains the offset, in y-direction, from middle
; --------------------------------------------------------------------
DisplayLevelHeader PROC USES ebx esi edx
	.data
	levelHeader BYTE "LEVEL ", 0

    .code		
	PUSH eax							; saving level number

	; displaying level header at middle of screen
	MOV esi, OFFSET levelHeader
	CALL GetMidpointOfString
	MOV edi, eax						; storing length of string to midpoint
	MOV eax, CONSOLE_WINDOW_MAX_X
	MOV ebx, CONSOLE_WINDOW_MAX_Y
	CALL GetMiddleOfConsole				; getting middle coordinates of console
	SUB eax, edi
	ADD ebx, ecx
	MOV dl, al
	MOV dh, bl
	CALL Gotoxy							; moving to middle of screen
	MOV edx, OFFSET LevelHeader
	CALL WriteString					; displaying level header
	POP eax
	CALL WriteDec
	CALL Crlf
    RET
DisplayLevelHeader ENDP

; --------------------------------------------------------------------
; DisplayCredits
;
; This function will display the credits screen.
; RECEIVES: EAX
; RETURNS:  AL contains the user's input
; REQUIRES: EAX contains the level difficulty
; --------------------------------------------------------------------
DisplayCredits PROC USES ebx esi edx
	.data
	creditsDirector BYTE "Game Director: Vincent Chi", 0
	creditsDesigner BYTE "Lead Game Designer: Vincent Chi", 0
	creditsProgrammer BYTE "Lead Gameplay Programmer: Vincent Chi", 0
	thankYouMessage BYTE "Thank you for playing Typeroids :)", 0
	creditContinueMsg BYTE "Press any key to continue.", 0

    .code
	; displaying thank you for playing message
	MOV esi, OFFSET thankYouMessage
	MOV ecx, -3
	CALL DisplayStringAtMiddle

	; displaying game title
	MOV esi, OFFSET creditsDirector
	MOV ecx, -1
	CALL DisplayStringAtMiddle

	; displaying game title
	MOV esi, OFFSET creditsDesigner
	MOV ecx, 0
	CALL DisplayStringAtMiddle

	; displaying game title
	MOV esi, OFFSET creditsProgrammer
	MOV ecx, 1
	CALL DisplayStringAtMiddle

	MOV esi, OFFSET creditContinueMsg
	MOV ecx, 4
	CALL DisplayStringAtMiddle
    CALL ReadChar
	CALL Clrscr
    RET
DisplayCredits ENDP

END
