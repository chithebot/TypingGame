INCLUDE external.inc

.code

; --------------------------------------------------------------------
; ReadFileIntoBuffer
;
; This function will read a file, containing strings, and return a
; buffer, allocated in the heap, containing the contents of the file.
; WARNING: The buffer MUST be deallocated after use.
; RECEIVES: EAX, ESI
; RETURNS:  EAX contains an address to unprocessed buffer of strings
; REQUIRES: EAX contains address to string containing file handle
; --------------------------------------------------------------------
ReadFileIntoBuffer PROC USES ecx edx
	.data
	bufferPointer DWORD ?			; will hold address of buffer

	.code
	PUSH eax			; storing file handle

	; allocating memory in heap for buffer
	MOV ecx, BUFFER_SIZE
	CALL AllocateMemory
	MOV bufferPointer, eax

	; reading file into buffer
	MOV edx, eax
	POP eax				; loading file handle into EAX
	CALL ReadFromFile
	JC showErrorMsg
	JMP return

	; handles case if there is an error in reading file
	showErrorMsg:
	CALL WriteWindowsMsg

	return:
	MOV eax, bufferPointer
	RET
ReadFileIntoBuffer ENDP

; --------------------------------------------------------------------
; DeallocateBuffer
;
; This function deallocates memory that was allocated for a buffer.
; If the memory was successfully freed, true is returned; false,
; otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating whether memory was freed
; REQUIRES: ESI contains the address to the buffer
; --------------------------------------------------------------------
DeallocateBuffer PROC
    .code
	CALL FreeMemory
    RET
DeallocateBuffer ENDP

END
