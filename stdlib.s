		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		PUSH	{r1-r12,lr}
		MOV		r2, #0				; r2 = 0; use r2 to set memory data
_bzero_loop							; while( ) {
		CMP 	r1, #0
		BEQ		_bzero_end			; if ( n < 0 ) return; 	
		SUBS	r1, r1, #1			; 	n--;	
		STRB	r2, [r0], #1		;	[s++] = 0;
		B		_bzero_loop			; }
_bzero_end
		POP		{r1-r12,lr}
		BX lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		; r3 = a copy of original dest
		PUSH {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
_strncpy_loop						; while( ) {
		CMP 	r2, #0
		BEQ		_strncpy_return		; if ( size == 0 ) break;
		SUBS	r2, r2, #1			; 	size--;
		LDRB	r4, [r1], #1		; 	r4 = [src++];
		STRB	r4, [r0], #1		;	[dest++] = r4;
		B		_strncpy_loop		; }
_strncpy_return
		MOV		r0, r3				; copy dst (r3) to r0 (return);
		POP 	{r1-r12,lr}
		BX 		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO NOT UPDATE THIS CODE
;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc 
		PUSH 	{r1-r12,lr}		
		MOV		r7, #0x1			; r7 specifies system call number
        SVC     #0x0				; system call
		POP 	{r1-r12,lr}
		
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO NOT UPDATE THIS CODE
;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		PUSH 	{r1-r12,lr}		
		MOV		r7, #0x2			; r7 specifies system call number
        SVC     #0x0				; system call
		POP 	{r1-r12,lr}
		
		BX 		lr
		
		END