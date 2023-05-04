INCLUDE external.inc

.code

; --------------------------------------------------------------------
; ConstructString
;
; This function will allocate memory in the heap and copy, a given
; string, into the allocated memory location. The heap handle and
; and a pointer to the allocated memory is returned.
; RECEIVES: ESI
; RETURNS:  EAX contains the string address
; REQUIRES:	ESI contains the address of source string (array) to copy
; --------------------------------------------------------------------
ConstructString PROC USES esi ecx edx
	.code
	; determining size to allocate
	MOV edx, esi
	CALL StrLength
	INC eax					; increasing length of memory to allocate by 1 to account for null character
	MOV ecx, eax

	; allocating memory in heap
	CALL AllocateMemory
	
	; copies string into the allocated memory
	INVOKE Str_copy, esi, eax
	RET
ConstructString ENDP

; --------------------------------------------------------------------
; DestroyString
;
; This function will destroy the string object. True is returned if
; string was sucessfully destroyed; false, otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating if memory was freed
; REQUIRES: ESI contains the array address
; --------------------------------------------------------------------
DestroyString PROC
	.code
	CALL FreeMemory
	RET
DestroyString ENDP

; --------------------------------------------------------------------
; GetStringLength
;
; This function will return the length of the string.
; RECEIVES: ESI
; RETURNS:  EAX contains the length of the string
; REQUIRES: ESI contains the address to the string
; --------------------------------------------------------------------
GetStringLength PROC USES edx
    .code
    MOV edx, esi
    CALL StrLength
    RET
GetStringLength ENDP

; --------------------------------------------------------------------
; GetCharacterAt
;
; This function will return the character at the given index. If the
; passed in index is invalid, 0xFFh is returned into the AL register.
; RECEIVES: ESI, EAX
; RETURNS:  AL contains the character of interest
; REQUIRES: ESI contains the address to the string;
;           EAX contains the index of the character
; --------------------------------------------------------------------
GetCharacterAt PROC USES ebx esi
    .code
    ; check if index is valid
    MOV ebx, eax            ; storing index of character
    CALL GetStringLength
    CMP ebx, eax
    JAE invalidIndex

    ; handles case for valid index
    ADD esi, ebx
    MOV al, [esi]
    JMP return

    ; handles case for invalid index
    invalidIndex:
    MOV al, 0FFh

    return:
    RET
GetCharacterAt ENDP

END
