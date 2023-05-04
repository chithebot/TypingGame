INCLUDE external.inc

.code

; --------------------------------------------------------------------
; DisplayTextAt
;
; This function will display the random word with correct characters
; displayed as gray text and characters that are not correct displayed
; as white. The text will be displayed, starting, at a given position.
; RECEIVES: ESI, EBX, DH, DL
; RETURNS:  None
; REQUIRES: ESI contains address to string;
;			EBX contains the numbers of correct characters typed;
;			DH contains the x-position, or column, to display text at;
;			DL contains the y-position, or row, to display text at;
;			String passed in must be an array of BYTES
; --------------------------------------------------------------------
DisplayTextAt PROC USES esi edx
	.code
	; moving to position on the console to display text
	CALL Gotoxy
	MOV edx, esi
	CALL DisplayText
	RET
DisplayTextAt ENDP

; --------------------------------------------------------------------
; ClearTextAt
;
; This function will clear the text at a given position.
; RECEIVES: ESI, DH, DL
; RETURNS:  None
; REQUIRES: ESI contains address to string;
;			DH contains the x-position, or column, to display text at;
;			DL contains the y-position, or row, to display text at;
;			String passed in must be an array of BYTES
; --------------------------------------------------------------------
ClearTextAt PROC USES esi edx
	.code
	; clearing the position on the console
	CALL Gotoxy
	MOV edx, esi
	CALL ClearText
	RET
ClearTextAt ENDP

; --------------------------------------------------------------------
; DisplayText
;
; This function will display the random word with correct characters
; displayed as gray text and characters that are not correct displayed
; as white.
; RECEIVES: EDX, EBX
; RETURNS:  None
; REQUIRES: EDX contains address to string;
;			EBX contains the numbers of correct characters typed;
;			String passed in must be an array of BYTES
; --------------------------------------------------------------------
DisplayText PROC USES eax edx ecx ebx esi
	.code
	; getting the length of the string
	CALL StrLength
	MOV ecx, eax

	; loop that displays the word
	MOV esi, 0							; keeps track of index

	; displays text
	displayTextLoop:
		MOV al, [edx]					; moving character into AL for display
		CMP esi, ebx					; checking whether or not character at index, esi, is a correct character
		JAE done

		; handling case for correct letters typed
		CALL CorrectTextColor		; sets text color to black BG and gray text

		done:
			CALL WriteChar
			CALL DefaultTextColor			; sets text color to black background and white text
			INC esi
			INC edx
		LOOP displayTextLoop
	RET
DisplayText ENDP

; --------------------------------------------------------------------
; ClearText
;
; This function will display the random word with correct characters
; displayed as gray text and characters that are not correct displayed
; as white.
; RECEIVES: EDX
; RETURNS:  None
; REQUIRES: EDX contains address to string;
;			String passed in must be an array of BYTES
; --------------------------------------------------------------------
ClearText PROC USES eax edx
	.code
	CALL EmptyTextColor
	CALL WriteString
	CALL DefaultTextColor
	RET
ClearText ENDP

; --------------------------------------------------------------------
; CorrectTextColor
;
; This function displays a character in black background and gray
; white foreground.
; RECEIVES: None
; RETURNS:  None
; REQUIRES: None
; --------------------------------------------------------------------
CorrectTextColor PROC USES eax
	.code
	; setting text color to gray
	MOV eax, lightGreen + (black * 16)
	CALL SetTextColor
	RET
CorrectTextColor ENDP

; --------------------------------------------------------------------
; DefaultTextColor
;
; This function sets the text color to black background and white 
; foreground.
; RECEIVES: None
; RETURNS:  None
; REQUIRES: None
; --------------------------------------------------------------------
DefaultTextColor PROC USES eax
	.code
	; sets text color to default console color
	MOV eax, white + (black * 16)
	CALL SetTextColor
	RET
DefaultTextColor ENDP

; --------------------------------------------------------------------
; EmptyTextColor
;
; This function sets the text color to black background and white 
; foreground.
; RECEIVES: None
; RETURNS:  None
; REQUIRES: None
; --------------------------------------------------------------------
EmptyTextColor PROC USES eax
	.code
	; sets text colors to black to simulate an empty space
	MOV eax, black + (black * 16)
	CALL SetTextColor
	RET
EmptyTextColor ENDP

END
