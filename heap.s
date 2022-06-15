		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _kinit( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_kinit
_kinit
		; you must correctly set the value of each MCB block
		; complete your code
		
		LDR     r0, =MCB_TOP
        LDR     R1, =MCB_BOT
		MOV 	R2, #0
_loop
		CMP		r0,r1
		BEQ 	_stop
		STRB 	R2, [R1]
		SUB 	R1, R1, #1
		B 		_loop
		
_stop
		LDR 	R2 , =MAX_SIZE
		STRH 	R2, [R0]
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size ) Size is R0
		EXPORT	_kalloc	
_kalloc
		;Start by calling ralloc
		; complete your code 
		; return value should be saved into r0
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		
		LDR		r3, = _ralloc ; address of ralloc	
		
		PUSH 	{lr}		; save lr
		BLX		r3			; call the _ralloc function 
		POP 	{lr}		; resume lr
		MOV 	R0, R6		; return value back to R0
		
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _r_alloc( int size, left_mcb, right_mcb ) Size is R0, left is R1, right is R2
		EXPORT	_ralloc	
_ralloc		
	LDR		R4, =MCB_ENT_SZ ; Can use R4 later
	SUB 	R3, R2, R1
	ADD		R3, R4 ;R3 = entire_mcb_addr_space
	SDIV	R4, R3, R4; R4 = half_mcb_addr_space
	ADD 	R5, R1, R4; R5 = midpoint
	MOV 	R6, #0 ; R6 = headp_addr
	LSL		R7, R3, #4 ; R7 = act_entire_heap_size
	LSL		R8, R4, #4 ; R8 = act_half_heap_size
	
	CMP		R0, R8
	BGT 	_more_than_half
	
	;call ralloc left
	PUSH 	{R0-R5, R7-R11, LR}		; save lr
	LDR		r11, =_ralloc ; address of ralloc
	LDR		R9, =MCB_ENT_SZ ; R9 = entity size
	SUB		r2, r5,r9 	;update parameters. Size, and left are same
	BLX		r11			; call the _ralloc function 
	POP 	{R0-R5, R7-R11, LR}		; resume lr ;R6 is our return value, so don't push/pop it.
	
	
	;call ralloc right if address still 0
	CMP		R6, #0
	BNE		_skip_alloc_right
	
	PUSH 	{R0-R5, R7-R11, LR}		; save lr
	LDR		r11, =_ralloc ; address of ralloc
	
	
	MOV		r1, r5	;update parameters. Size, and right are same
	BLX		r11			; call the _ralloc function 
	POP 	{R0-R5, R7-R11, LR}		; resume lr
	B		_skip_more_than_half	;return / branch to end
	
_skip_alloc_right
	
	
	AND 	r9,r5, #01
	CMP		r9, #0
	BNE 	_skip_split_parent_MCB
	
	LDR 	R9, [R5]
	AND		R9, R9, #01 
	CMP 	r9, #0
	MOV		r9, r8
	BEQ		_not_in_use
	ADD 	r9, r8, #1
	
_not_in_use
	STRH 	R9, [R5]
	;return heap_address
_skip_split_parent_MCB	
	B _skip_more_than_half
		
_more_than_half
	LDRH	r10, [r1]
	AND 	r9,r10, #01	
	CMP 	r9, #0
	BEQ		_skip_return_in_use;
	MOV 	R6, #0
	B		_skip_more_than_half
	
_skip_return_in_use
	LDRH	r10, [r1]
	CMP 	r10, r7 
	BGE		_set_MCB_value	
	MOV 	R6, #0
	B		_skip_more_than_half ; return 0

_set_MCB_value	
	ORR		R7, R7, #01
	STRH	R7, [R1]
	
	;return correct heap address
	
	LDR 	R9, =HEAP_TOP
	LDR 	R10, =HEAP_BOT
	LDR		R11, =MCB_TOP
	SUB 	R11, r1, R11
	LSL		R11, R11,#4
	ADD		R6, R9, R11 ;return value stored in R6
	
_skip_more_than_half
	BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )	
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		MOV		R12, #0
		
				LDR 	r1, =HEAP_TOP
		LDR 	r2, =HEAP_BOT
		LDR		r4, =MCB_TOP
		
		CMP 	r0,r1
		BLT		_return_null		
		
		CMP 	r0,r2
		BGT		_return_null
		
		SUB 	r3, r0,r1
		LSR		r3, r3,#4
		ADD		r0,r3,r4  ; R0 = mcb_addr
		
		;Call rfree
		LDR		r3, = _rfree ; address of _rfree	
		PUSH 	{lr}		; save lr
		BLX		r3			; call the _rfree function 
		POP 	{lr}		; resume lr
		
		;return value in R0
		MOV		R0, R12
		
		B 		_end
	
_return_null
		MOV 	r0, #0 ;I'm not sure how to return null, so I just return 0, I believe that is the same thing.
		
_end
		BX		lr		
		
; void* _rfree( int mcb_addr) ptr is R0
		EXPORT	_rfree	
_rfree		
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		LDRH	R3, [R0] ;R3 stores mcb contents
		SUB		R4, r0, r1 ;R4 = mcb_index
		LSR		R3, R3, #4
		MOV		R5, R3 ; R5 = mcb_disp
		LSL		R3,R3, #4
		MOV 	R6, R3	; R6 = my_size
		MOV 	R12, R0	;add return value to R12. I will return this unless null is returned

		
		STRH	R3, [R0] ; store after clearing bit
		
		MOV		R8, #2
		SDIV 	R7, R4, R5
		SDIV	R9,R7,R8
		MLS		R7,R8,R9,R7	;Pretty sure this is doing mod correctly.
		CMP		R7, #0
		BNE		_right

		ADD		R8, r0,r5 	;mcb_addr + mcb_disp
		CMP 	R8, R2
		BLT		_no_return_for_beyond
		MOV		R12, #0
		B		_ends
_no_return_for_beyond

		LDR		R9, [R8] ; R9 = Buddy's value
		AND		R10, R9, #0001
		CMP 	R10, #0
		BNE		_ends
		LSR		R9,R9, #5				;Buddy not used, continue
		LSL		R9,R9, #5
		
		CMP		R9, R6
		BNE		_ends
		
		MOV 	R11, #0
		;buddy is unused and same size
		STRH	R11, [r8]	;clear buddy
		LSL		R6, #1
		STRH	R6, [R0]
		
		;Recursive
		PUSH 	{R0-R11, LR}		; save lr , dont push R12, it is our return value
		LDR		r11, =_rfree ; address of ralloc
							;Parameters don't need update
		BLX		r11			; call the _rfree function 
		POP 	{R0-R11, LR}		; resume lr, don't pop R12 it is our return value
		B		_ends
		
_right
		SUB		R8, r0,r5 	;mcb_addr - mcb_disp
		CMP		R8, R1
		BGE		_no_return_for_below
		MOV		R12, #0
		B		_ends
_no_return_for_below		
		LDR		R9, [R8] ; R9 = Buddy's value
		AND		R10, R9, #0001
		CMP 	R10, #0
		BNE		_ends			;buddy in use
		LSR		R9,R9, #5		;Buddy not used, continue
		LSL		R9,R9, #5		;clear bits 0-4
		
		CMP		R9, R6
		BNE		_ends

		MOV 	R11, #0
		;buddy is unused and same size
		STRH	R11, [r0]	;clear slelf
		LSL		R6, #1
		STRH	R6, [R8]
		
		;Recursive
		PUSH 	{R0-R11, LR}		; save lr , dont push R12, it is our return value
		LDR		r11, =_rfree ; address of ralloc
							
		SUB		R0, R0, R5 
		BLX		r11			; call the _rfree function 
		POP 	{R0-R11, LR}		; resume lr, don't pop R12 it is our return value
		MOV 	R12, R0	;add return value to R12
		B		_ends

_ends
		
		BX		lr
		
		
		END