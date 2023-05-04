INCLUDE external.inc

.data
hHeap DWORD ?						; contains the heap handle
pHeap DWORD ?						; contains the pointer to the memory allocated
dwByte DWORD ?						; contains the number of bytes to allocate

.code

; --------------------------------------------------------------------
; AllocateMemory
;
; This function will allocate memory in the heap. The heap handle and
; and a pointer to the allocated memory is returned.
; RECEIVES: ECX
; RETURNS:  EAX contains the array address
; REQUIRES: ECX contains size of memory to allocate in bytes
; --------------------------------------------------------------------
AllocateMemory PROC USES ecx
	.code
	MOV dwByte, ecx									; storing size of memory allocation

	; gets heap handle for heap allocation
	INVOKE GetProcessHeap
	MOV hHeap, eax									; storing heap handle

	; allocates memory in the heap for the string
	INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, dwByte
	MOV pHeap, eax									; storing pointer to array
	RET
AllocateMemory ENDP

; --------------------------------------------------------------------
; FreeMemory
;
; This function will free memory that was allocated. True is returned
; if the memory was successfully freed; false, otherwise.
; RECEIVES: ESI
; RETURNS:  EAX contains a boolean indicating if memory was freed
; REQUIRES: ESI contains the array address
; --------------------------------------------------------------------
FreeMemory PROC USES esi
	.code
	MOV pHeap, esi							; storing pointer to heap

	; getting heap handle
	INVOKE GetProcessHeap
	MOV hHeap, eax
	
	INVOKE HeapFree, hHeap, HEAP_NO_SERIALIZE, pHeap
	RET
FreeMemory ENDP

END
