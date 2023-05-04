INCLUDE external.inc

.data
pHeap DWORD ?						; contains the pointer to the memory allocated
dwByte DWORD ?						; contains the number of bytes to allocate

.code

; --------------------------------------------------------------------
; ConstructRandomWord
;
; This function will create a random word object which contains:
;       - a pointer to a string object
;       - x-position (int)
;       - y-position (int)
;       - x-velocity (int)
;       - y-velocity (int)
;       - correct characters typed (unsigned)
;       - spawned indicator (bool)
;       - hidden indicator (bool)
;       - frames per movement (unsigned)
; RECEIVES: ESI
; RETURNS:  EAX contains the random word object address
; REQUIRES:	ESI contains the address of the string to construct the
;           random word object with
; --------------------------------------------------------------------
ConstructRandomWord PROC USES ecx esi
    .code
    ; determining memory size to allocate for a RandomWord object
    MOV dwByte, TYPE DWORD * 9          ; contains 8 DWORD-sized member variables
    MOV ecx, dwByte
    CALL AllocateMemory

    ; storing heap pointer
    MOV pHeap, eax

    ; constructing string object to be used as member for random word object
    CALL ConstructString
    MOV esi, pHeap
    MOV [esi], eax

    ; returning heap pointer
    MOV eax, pHeap
    RET
ConstructRandomWord ENDP

; --------------------------------------------------------------------
; DestroyRandomWord
;
; This function destroys a given RandomWord object. It deallocates
; memory that was allocated for the object. True is returned if object
; was successfully destroyed; false, otherwise
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating if object was destroyed
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
DestroyRandomWord PROC USES esi ecx
    .code
    PUSH esi                ; saving address to random word object

    ; deallocating memory for string
    CALL GetString          ; getting string of random word object
    MOV esi, eax
    CALL DestroyString
    
    ; deallocating memory for random word object
    POP esi                 ; loading address of random word object
    CALL FreeMemory
    RET
DestroyRandomWord ENDP

; --------------------------------------------------------------------
; GetString
;
; This function will return address to the string object.
; RECEIVES: ESI
; RETURNS:  EAX contains string address of random word object
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetString PROC USES esi
    .code
    MOV eax, [esi]
    RET
GetString ENDP

; --------------------------------------------------------------------
; GetXPosition
;
; This function will return the x-position of the random word object
; on the console.
; RECEIVES: ESI
; RETURNS:  EAX contains x-position of random word object
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetXPosition PROC USES esi
    .code
    ADD esi, TYPE DWORD * 1
    MOV eax, [esi]
    RET
GetXPosition ENDP

; --------------------------------------------------------------------
; GetYPosition
;
; This function will return the y-position of the random word object
; on the console.
; RECEIVES: ESI
; RETURNS:  EAX contains y-position of random word object
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetYPosition PROC USES esi
    .code
    ADD esi, TYPE DWORD * 2
    MOV eax, [esi]
    RET
GetYPosition ENDP

; --------------------------------------------------------------------
; GetXVelocity
;
; This function will return the x-velocity of the random word object.
; RECEIVES: ESI
; RETURNS:  EAX contains x-velocity of random word object
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetXVelocity PROC USES esi
    .code
    ADD esi, TYPE DWORD * 3
    MOV eax, [esi]
    RET
GetXVelocity ENDP

; --------------------------------------------------------------------
; GetYVelocity
;
; This function will return the y-velocity of the random word object.
; RECEIVES: ESI
; RETURNS:  EAX contains y-velocity of random word object
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetYVelocity PROC USES esi
    .code
    ADD esi, TYPE DWORD * 4
    MOV eax, [esi]
    RET
GetYVelocity ENDP

; --------------------------------------------------------------------
; GetCorrectCharacters
;
; This function will return the correct characters typed for the 
; random word object.
; RECEIVES: ESI
; RETURNS:  EAX contains the number of correct characters, in the
;           random word object, that has been typed
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetCorrectCharacters PROC USES esi
    .code
    ADD esi, TYPE DWORD * 5
    MOV eax, [esi]
    RET
GetCorrectCharacters ENDP

; --------------------------------------------------------------------
; IsSpawned
;
; This function indicates whether or not the random word object has
; been spawned. True is returned if it has been spawned; false,
; otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating if object spawned
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
IsSpawned PROC USES esi
    .code
    ADD esi, TYPE DWORD * 6
    MOV eax, [esi]
    RET
IsSpawned ENDP

; --------------------------------------------------------------------
; IsHidden
;
; This function indicates whether or not the random word object is
; hidden. True is returned if it is hidden; false, otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating if object is hidden
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
IsHidden PROC USES esi
    .code
    ADD esi, TYPE DWORD * 7
    MOV eax, [esi]
    RET
IsHidden ENDP

; --------------------------------------------------------------------
; GetFramesPerMovement
;
; This function will return the number of frames until the object
; moves.
; RECEIVES: ESI
; RETURNS:  EAX contains the number of frames until the object moves
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetFramesPerMovement PROC USES esi
    .code
    ADD esi, TYPE DWORD * 8
    MOV eax, [esi]
    RET
GetFramesPerMovement ENDP

; --------------------------------------------------------------------
; IsCompleted
;
; This function indicates whether or not the random word object was
; fully typed and completed. True is returned if it is hidden; false,
; otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating if object is typed
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
IsCompleted PROC USES esi ebx
    .code
    ; checking if correct characters value is equal to length of word
    CALL GetLength
    MOV ebx, eax
    CALL GetCorrectCharacters
    CMP eax, ebx
    JB incomplete

    ; handles case where word is completed
    MOV eax, TRUE
    JMP return

    ; handles case where word is not completed
    incomplete:
    MOV eax, FALSE

    return:
    RET
IsCompleted ENDP

; --------------------------------------------------------------------
; IsOutOfYBounds
;
; This function indicates whether or not the random word object is out
; of bounds, in the y-direction, in the console.
; RECEIVES: ESI, EAX
; RETURNS:  EAX contains a boolean indicating if object is out of 
;           bounds
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the upper bound
; --------------------------------------------------------------------
IsOutOfYBounds PROC USES esi ebx
    .code
    MOV ebx, eax            ; storing upper bound in EBX
    CALL GetYPosition

    ; comparing random word object's position with upper and lower bounds
    CMP eax, 0
    JL outOfBounds
    CMP eax, ebx
    JG outOfBounds

    ; handles case where object is within bounds
    MOV eax, FALSE
    JMP return

    ; handles case where object is out of bounds
    outOfBounds:
    MOV eax, TRUE

    return:
    RET
IsOutOfYBounds ENDP

; --------------------------------------------------------------------
; GetLength
;
; This function will return the length of the string of the random
; word object.
; RECEIVES: ESI
; RETURNS:  EAX contains the length of the string
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetLength PROC USES esi edx
    .code
    CALL GetString
    MOV esi, eax
    CALL GetStringLength
    RET
GetLength ENDP

; --------------------------------------------------------------------
; GetCurrentCharacter
;
; This function will return the currently focused character of the
; random word object. The focused character is first character that
; has not been typed yet. Returns -1 if word is fully typed; false,
; otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains the character of interest
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetCurrentCharacter PROC USES esi
    .code
    ; check if word is completed
    CALL IsCompleted
    CMP eax, TRUE
    JE completed

    ; handles case where random word object has not yet been fully typed by user
    CALL GetString                  ; getting address of string in random word object
    PUSH eax                        ; storing address of string object
    CALL GetCorrectCharacters       ; getting the index of next character that needs to be typed
    POP esi                         ; popping address of string object into ESI
    ADD esi, eax                    ; moving to appropriate index
    MOV al, [esi]
    JMP return

    ; handles case where random word object is already fully typed by user
    completed:
    MOV eax, -1

    return:
    RET
GetCurrentCharacter ENDP

; --------------------------------------------------------------------
; GetRightCorner
;
; This function will return the coordinate of the top-right of the 
; random word object on the console.
; RECEIVES: ESI
; RETURNS:  EAX contains x-position of random word object
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
GetRightCorner PROC USES esi ebx
    .code
    CALL GetLength
    MOV ebx, eax
    CALL GetXPosition
    ADD eax, ebx
    RET
GetRightCorner ENDP

; --------------------------------------------------------------------
; SetXPosition
;
; This function will set the x-position to the given value.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new x-position value
; --------------------------------------------------------------------
SetXPosition PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 1
    MOV [esi], eax
    RET
SetXPosition ENDP

; --------------------------------------------------------------------
; SetYPosition
;
; This function will set the y-position to the given value.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new y-position value
; --------------------------------------------------------------------
SetYPosition PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 2
    MOV [esi], eax
    RET
SetYPosition ENDP

; --------------------------------------------------------------------
; SetXVelocity
;
; This function will set the x-velocity to the given value.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new x-velocity value
; --------------------------------------------------------------------
SetXVelocity PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 3
    MOV [esi], eax
    RET
SetXVelocity ENDP

; --------------------------------------------------------------------
; SetYVelocity
;
; This function will set the y-velocity to the given value.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new y-velocity value
; --------------------------------------------------------------------
SetYVelocity PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 4
    MOV [esi], eax
    RET
SetYVelocity ENDP

; --------------------------------------------------------------------
; SetCorrectCharacters
;
; This function will set the number of correct characters, typed, to
; the given value.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new correct character value
; --------------------------------------------------------------------
SetCorrectCharacters PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 5
    MOV [esi], eax
    RET
SetCorrectCharacters ENDP

; --------------------------------------------------------------------
; SetSpawnedState
;
; This function will set the spawned state to the given boolean.
; the given value.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new boolean value
; --------------------------------------------------------------------
SetSpawnedState PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 6
    MOV [esi], eax
    RET
SetSpawnedState ENDP

; --------------------------------------------------------------------
; SetHiddenState
;
; This function will set the hidden state to the given boolean.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new boolean value
; --------------------------------------------------------------------
SetHiddenState PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 7
    MOV [esi], eax
    RET
SetHiddenState ENDP

; --------------------------------------------------------------------
; SetFramesPerMovement
;
; This function will set the frames per movement value of the random
; word object. Frames per movement is the object's speed tied to the
; frame speed at which the program is running at.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the new frames per movement value
; --------------------------------------------------------------------
SetFramesPerMovement PROC USES esi eax
    .code
    ADD esi, TYPE DWORD * 8
    MOV [esi], eax
    RET
SetFramesPerMovement ENDP

; --------------------------------------------------------------------
; AddXPosition
;
; This function will add the given value to the x-position.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the value to add
; --------------------------------------------------------------------
AddXPosition PROC USES eax ebx esi
    .code
    MOV ebx, eax            ; storing the value to be added into EBX
    CALL GetXPosition
    ADD eax, ebx
    CALL SetXPosition
    RET
AddXPosition ENDP

; --------------------------------------------------------------------
; AddYPosition
;
; This function will add the given value to the y-position.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the value to add
; --------------------------------------------------------------------
AddYPosition PROC USES eax ebx esi
    .code
    MOV ebx, eax            ; storing the value to be added into EBX
    CALL GetYPosition
    ADD eax, ebx
    CALL SetYPosition
    RET
AddYPosition ENDP

; --------------------------------------------------------------------
; IncrementCorrectCharacters
;
; This function will increment the number of correct characters typed
; for the random word object
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
; --------------------------------------------------------------------
IncrementCorrectCharacters PROC USES eax esi
    .code
    CALL GetCorrectCharacters
    INC eax
    CALL SetCorrectCharacters
    RET
IncrementCorrectCharacters ENDP

; --------------------------------------------------------------------
; ToggleSpawned
;
; This function will toggle the spawned state.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
; --------------------------------------------------------------------
ToggleSpawned PROC USES eax esi
    .code
    CALL IsSpawned
    XOR eax, 1          ; mask for toggling the boolean
    CALL SetSpawnedState
    RET
ToggleSpawned ENDP

; --------------------------------------------------------------------
; ToggleHidden
;
; This function will toggle the hidden state.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
ToggleHidden PROC USES eax esi
    .code
    CALL IsHidden
    XOR eax, 1          ; mask for toggling the boolean
    CALL SetHiddenState
    RET
ToggleHidden ENDP

; --------------------------------------------------------------------
; OutOfXBounds
;
; This function checks if the random word object's position is out of
; bounds, in the x-direction. If it is, the random object's position
; is corrected and x-velocity is negated to simulate a bouncing
; effect.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the upper bound
; --------------------------------------------------------------------
OutOfXBounds PROC USES eax ebx esi
    .code
    MOV ebx, eax            ; storing upper bound in EBX
    CALL GetXPosition

    ; comparing random word object's position with upper and lower bounds
    CMP eax, 0
    JLE outOfBounds
    CALL GetRightCorner
    CMP eax, ebx
    JGE outOfBounds
    JMP return

    ; handles case where object is out of either bounds
    outOfBounds:
    CALL Bounce

    return:
    RET
OutOfXBounds ENDP

; --------------------------------------------------------------------
; Bounce
;
; This function will negate the x-velocity of the object to simulate
; it bouncing off a surface.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
Bounce PROC USES eax esi
    .code
    CALL GetXVelocity
    NEG eax
    CALL SetXVelocity
    RET
Bounce ENDP

; --------------------------------------------------------------------
; UpdateRandomWord
;
; This function updates the position of the random word object by its
; velocity. It also updates the state of the random word object,
; accordingly.
; RECEIVES: ESI, EAX
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object;
;           EAX contains the current frame the program is running at
; --------------------------------------------------------------------
UpdateRandomWord PROC USES eax ebx esi
    .code
    MOV ebx, eax                            ; storing program frame count

    ; checks if random word object is hidden
    CALL IsHidden
    CMP eax, TRUE
    JE return

    ; checks if object is completed, or fully typed by user
    CALL IsCompleted
    CMP eax, TRUE
    JE hide

    ; checks if object is out of x-bounds
    MOV eax, CONSOLE_WINDOW_MAX_X
    CALL OutOfXBounds

    ; checks if object is out of y-bound
	MOV eax, CONSOLE_WINDOW_MAX_Y
	CALL IsOutOfYBounds
	CMP eax, TRUE
    JE hide

    ; checks if current frame is divisible by frame value of random word object
    MOV eax, ebx                            ; loading program frame count back into EAX
    CALL ShouldMove
    CMP eax, TRUE
    JNE return

    ; updating x-position
    CALL GetXVelocity
    CALL AddXPosition

    ; updating y-position
    CALL GetYVelocity
    CALL AddYPosition
    JMP return

    ; updates the state of object to hidden
    hide:
    MOV eax, TRUE
    CALL SetHiddenState

    return:
    RET
UpdateRandomWord ENDP

; --------------------------------------------------------------------
; ClearRandomWord
;
; This function will draw the random word object onto the console.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
ClearRandomWord PROC USES esi eax edx
    .code
    ; checks if random word object is hidden
    CALL IsHidden
    CMP eax, TRUE
    JE hidden

    ; getting x, y position of random word object
    CALL GetXPosition
    MOV dl, al
    CALL GetYPosition
    MOV dh, al
    
    ; getting string address associated with random word object
    CALL GetString
    MOV esi, eax
    CALL ClearTextAt

    ; handles case where object is hidden
    hidden:
    RET
ClearRandomWord ENDP

; --------------------------------------------------------------------
; DrawRandomWord
;
; This function will draw the random word object onto the console.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains the address to the random word object
; --------------------------------------------------------------------
DrawRandomWord PROC USES esi eax edx
    .code
    ; checks if random word object is hidden
    CALL IsHidden
    CMP eax, TRUE
    JE hidden

    ; getting x, y position of random word object
    CALL GetXPosition
    MOV dl, al
    CALL GetYPosition
    MOV dh, al
    
    ; getting correct numbers of letters typed for random word object
    CALL GetCorrectCharacters
    MOV ebx, eax

    ; getting string address associated with random word object
    CALL GetString
    MOV esi, eax
    CALL DisplayTextAt

    ; handles case where object is hidden
    hidden:
    RET
DrawRandomWord ENDP

; --------------------------------------------------------------------
; ShouldMove
;
; This function will return a boolean value indicating whether or not
; it is the appropriate time to move the random object given the
; program's current frame count. True is returned if the random word
; object is to move; false, otherwise.
; RECEIVES: ESI, EAX
; RETURNS:  EAX contains a boolean indicating if object should move
; REQUIRES: ESI contains a random word object array's address;
;           EAX contains the program's current frame count
; --------------------------------------------------------------------
ShouldMove PROC USES esi ebx edx
    .code
    MOV edx, 0                  ; initializing EDX for division
    PUSH eax                    ; storing current frame count program is running at
    CALL GetFramesPerMovement
    MOV ebx, eax                ; storing frames per movement value into EBX
    POP eax                     ; loading current program frame into EAX
    DIV ebx                     ; divides current program frame by frames per movement of object
    CMP edx, 0                  ; checks if there is a remainder in EDX
    JNE noMove

    ; handles the case where it is the appropriate frame to move
    MOV eax, TRUE
    JMP return

    ; handles the case where it is not the appropriate frame to move
    noMove:
    MOV eax, FALSE

    return:
    RET
ShouldMove ENDP

END
