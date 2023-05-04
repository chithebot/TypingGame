INCLUDE external.inc

.code

; --------------------------------------------------------------------
; RandomInt32Range
;
; This function will generate a random integer at a specified range.
; Max integer range is [-2147483648, 2147483647]. Returns a positive
; or negative integer.
; RECEIVES: EAX
; RETURNS:  EAX contains the random integer
; REQUIRES: EAX contains the upper bound
; --------------------------------------------------------------------
RandomInt32Range PROC
    .code
    CALL RandomRange
    PUSH eax            ; storing random integer

    ; determining whether or not random integer is positive
    MOV eax, 2
    CALL RandomRange
    CMP eax, TRUE       ; checks whether it is true that the number is positive
    POP eax             ; loading random integer back into EAX
    JZ positive
    NEG eax             ; handles negative cases

    ; handles the positive case
    positive:
    RET
RandomInt32Range ENDP

; --------------------------------------------------------------------
; ClearStringBuffer
;
; This function will fill a byte array with 0's.
; RECEIVES: ESI
; RETURNS:  None
; REQUIRES: ESI contains address to the array;
;           ECX contains the size of the array
; --------------------------------------------------------------------
ClearStringBuffer PROC USES ecx esi eax
    .code
    MOV al, 0
    fillLoop:
        MOV [esi], al
        INC esi
        LOOP fillLoop
    RET
ClearStringBuffer ENDP

; --------------------------------------------------------------------
; ConvertIndexToDWORDIndex
;
; This function converts an index into a DWORD index. The index
; value's maximum is the maximum for a 32-bit unsigned integer.
; RECEIVES: EAX
; RETURNS:  EAX contains result of multiplication (lower half);
;           EDX contains result of multiplication (upper half)
; REQUIRES: EAX contains the index to be converted
; --------------------------------------------------------------------
ConvertIndexToDWORDIndex PROC USES ebx
    .code
    MOV ebx, TYPE DWORD          ; storing DWORD type size into EBX
    MUL ebx
    RET
ConvertIndexToDWORDIndex ENDP

; --------------------------------------------------------------------
; GetMiddleOfConsole
;
; This function will get the middle coordinates of the console screen.
; The lower bound, in the x and y-direction, are assumed to be 0.
; Positions must be a 32-bit number.
; RECEIVES: EAX, EBX
; RETURNS:  EAX contains the middle x-coordinate on console;
;           EBX contains the middle y-coordinate on console
; REQUIRES: EAX contains the upper x-bounds of console;
;           EBX contains the upper y-bounds of console
; --------------------------------------------------------------------
GetMiddleOfConsole PROC USES edx esi
    .code
    ; determining midpoint on x-axis
    PUSH ebx        ; storing upper y-bounds
    MOV edx, 0      ; initializing EDX for 64-bit division 
    MOV ebx, 2
    DIV ebx         ; determining midpoint on x-axis
    MOV esi, eax    ; storing midpoint on x-axis in ESI

    ; determining midpoint on y-axis
    POP eax         ; loading upper y-bounds into EAX
    MOV edx, 0      ; initializing EDX for 64-bit division
    DIV ebx         ; determining midpoint on x-axis

    ; returning values
    MOV ebx, eax    ; moving midpoint of y-axis into EBX
    MOV eax, esi    ; moving midpoint of x-axis into EAX
    RET
GetMiddleOfConsole ENDP

; --------------------------------------------------------------------
; GetMidpoint
;
; This function will return the midpoint from 0 to the given positive
; upper bound value.
; RECEIVES: EAX
; RETURNS:  EAX contains the midpoint
; REQUIRES: EAX contains the upper bound value
; --------------------------------------------------------------------
GetMidpoint PROC USES edx ebx
    .code
    MOV edx, 0
    MOV ebx, 2
    DIV ebx
    RET
GetMidpoint ENDP

; --------------------------------------------------------------------
; GetMidpointOfString
;
; This function will return the length of the string up to its
; midpoint.
; RECEIVES: ESI
; RETURNS:  EAX contains the length to the midpoint of the string
; REQUIRES: ESI contains the address to the string
; --------------------------------------------------------------------
GetMidpointOfString PROC USES esi edx
    .code
    ; determining the length to the middle of the string
    MOV edx, esi
    CALL StrLength
    CALL GetMidpoint
    RET
GetMidpointOfString ENDP

; --------------------------------------------------------------------
; IsValidChar
;
; This function checks if a byte-sized data is a valid ASCII
; character. Returns true, or 1, if data is a valid character;
; false, otherwise.
; RECEIVES: AL
; RETURNS:  AH contains indicator whether or not the data is a
;			character
; REQUIRES: AL contains the character being checked
; --------------------------------------------------------------------
IsValidChar PROC
	.data
	UPPER_CASE_UB = 90		; ASCII decimal upper bound for upper case letter
	UPPER_CASE_LB = 65		; ASCII decimal lower bound for upper case letter
	LOWER_CASE_UB = 122		; ASCII decimal upper bound for lower case letter
	LOWER_CASE_LB = 97		; ASCII decimal lower bound for lower case letter

	.code
    MOV ah, FALSE           ; assumes char is invalid

	; checks if AL is a character in ['A', 'Z']
	condition1:
		CMP al, UPPER_CASE_LB
		JB condition2
		CMP al, UPPER_CASE_UB
		JA condition2
		JMP validChar

	; checks if AL is a character in ['a', 'z']
	condition2:
		CMP al, LOWER_CASE_LB
		JB return
		CMP al, LOWER_CASE_UB
		JA return
	
	validChar:
		MOV ah, TRUE
		
	return:
		RET
IsValidChar ENDP

; --------------------------------------------------------------------
; DisplayStringAtMiddle
;
; This function will display a given string at the center of the
; console offset from the middle by a given amount
; RECEIVES: ESI, ECX
; RETURNS:  None
; REQUIRES: ESI contains the address to the string;
;			ECX contains the offset, in y-direction, from middle
; --------------------------------------------------------------------
DisplayStringAtMiddle PROC USES eax ebx esi edx
    .code		
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
	MOV edx, esi
	CALL WriteString					; displaying level header
	CALL Crlf
    RET
DisplayStringAtMiddle ENDP

END
