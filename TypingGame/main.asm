; main.asm - [Typeroids - A typing game]
; creator: Vincent Chi

INCLUDE external.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD

.code
main PROC
	CALL RunTypingGame			; runs Typeroids

	INVOKE ExitProcess, 0
main ENDP

END main
