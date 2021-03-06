#include "msp430.h"
;*******************POLYNOMIAL RANDOM GAME**************************
;* HARDWARE NEEDED FOR PLAYING THE GAME:
;* 	1) BREADBOARD
;* 	2) WIRES
;* 	3) 8 LEDS
;*	4) 8 RESITORS 15 Ohms
;* LEDS WILL BE CONNECTED FROM PORT 2.0 TO 2.5 AND THE LAST TWO IN XOUT AND XIN (For each port one LED and one resitor in series) 
;* Layout of leds from right to left(2.0-2.5,Xin-Xout). LSB=2.0
;* 
;* About game:
;*	Polynomials:
;*		P0(x) = 25x3 − 2x2 + 102x + 5
;*		P1(x) = −9x3 + 6x2 − 13x + 15
;*		P2(x) = x3 + 25x2 − 6x + 7
;*		P3(x) = 4x3 + 106x2 − 110x + 87
;*	Values:
;*		x0 = 12, x1 = −10, x2 = −15, and x3 = −30
;* The LEDs are ﬂashing together. When the player pushes-and-releases the push button,
;* the LED’s turn oﬀ and the microcontroller evaluates the polynomial value Ph(xj), where h
;* and j are randomly selected. The polynomial evaluation is done using synthetic division. 
;* The result should be within −32,768 and 32,767. If it falls outside this range, then the red LED 
;* of the PCB is turned on and the player eliminated. If the evaluation is correct, then the green LED of
;* the PCB is turned on and the hex result will be read with the LED’s you added.
;* Since only eight LEDs are being used, ﬁrst show the LSB. Then show the MSB and complete the evaluation.
;* Push the button again, and all LEDs should be turned oﬀ, including that in the launchpad PCB. Another game 
;* can be started by pressing the RESET push button.
;*******************POLYNOMIAL RANDOM GAME**************************

Delay2	MACRO	dato
	LOCAL	Loop1
	mov.w	dato,R10
Loop1:	dec	R10
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	jnz	Loop1
	ENDM
	
Mult	MACRO	dato1, dato2
	LOCAL	Par, Finish, Over, Loop, end, Neg,Pos,Return
	mov.w	#0,R11			; (Boolean) Check if the value overpass range		
	mov.w	#0,R12			; "boolean" (use for checking the number of negatives)
	mov.w	#0,R15			; Result
	mov.w	dato1,R13		; M
	mov.w	dato2,R14		; N   (M x N)
	call	#Helper			; Helper method for negatives
Loop:	tst	R13			; checking if M=0
	jz	Finish			; Finish if M=0
	bit.b	#1,R13			; Testing if M is odd or even
	jz	Par			; if even jump
	add.w	R14,R15			; if odd Result= Result + N
	jc	Over			; if carry the value is out of range
Par:	clrc				; make sure that the rrc roll zeros
	rrc	R13			; M/2
	rla	R14			; N*2
	jc	Over			; if carry the value is out of range
	jmp	Loop			; Continue Loop	
Finish:	cmp	#1,R12			; Loop finised, if there was one negative invert 
	jnz	end			; else finish
	inv	R15			; Result needs to be negative
	add.w	#1,R15			; 2's complement of R4		
end:	bit.w	#08000h,R15		; testing the result for overflow
	jn	Neg		
	jz	Pos
Neg:	cmp.w	#1,R12			; if the result is negative and N or M where not negatives result has overflow
	jnz	Over				
	jmp	Return
Pos:	cmp.w	#0,R12			; if result is positive and N or M where not both positive or negative result has overflow
	jnz	Over		
	jmp	Return
Over:	mov	#1,R11			; (Boolean) Result Overflow=True		
Return:	ENDM
;---------------------------------------------------------------
		ORG	0F800h			; Program Start
;---------------------------------------------------------------
P0		DW	25,-2,102,5		; P0 Polynomial
X0		DW	12			; X0 Value
P1		DW	-9,6,-13,15		; P1 Polynomial
X1		DW	-10			; X1 Value
P2		DW	1,25,-6,7		; P2 Polynomial
X2		DW	-15			; X2 Value
P3		DW	4,106,-110,87		; P3 Polynomial
X3		DW	-30			; X3 Value
		EVEN				; To ensure that addresses are even
RESET		mov.w	#0280h,SP		; Initialize Stack-Pointer
StopWDT 	mov.w	#WDTPW+WDTHOLD,&WDTCTL	; StopWDT
		bic.b	#11000000b,P2SEL	; Selecting pins for output
						; P2.7 and P2.6, their default operation is set for module operation.
		bis.b	#11111111b,P2DIR	; P2.0-P2.7 as output ports
LOW		bic.b	#0xFF,P2OUT		; P2.0-P2.7 as low output
		bis.b	#11110111b,P1DIR	; P1.0-P1.7 as output ports
		bic.b	#11110111b,P1OUT	; Clear output in P1
		bis.b	#00001000b,P1REN	; Select Internal Resistor
		bis.b	#00001000b,P1OUT	; Make it Pull-Up	
		bis.b	#00001000b,P1IE		; Enable P1.3 interrupt
		eint				; global interrupt enable	
		mov.w	#0,R7			; Interrupt Counter	
;--------------------Loop Waiting for player------------------------
Loop		mov	#30000,R4		; Delay for flashing LEDs
		xor.b	#0xFF,P2OUT		; Toggle LEDs
DELAY		cmp	#1,R7			; Check if the player pressed button in P1.3
		jz	OutOfInterrupt		; Start Game
		add.w	#1,0200h		; Value use for choosing random polynomial 
		add.w	#1,0202h		; Value use for choosing random X value
		dec	R4			; Decrement Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		nop				; 1 Clock Cycle Delay
		jnz	DELAY			; if not zero, repeate DELAY again
		jmp	Loop			; else, repeate Loop again
OutOfInterrupt	bic.b	#0xFF,P2OUT		; Turn off LEDs		
;----------------Chossing the polynomial------------ Check which polynomial was chosen randomly
		cmp	#0,R8			; Check if random number is 0
		jnz	Next			; If not zero keep checking
		mov.w	#P0,R5			;  Save the address of the first coeficient in R5
		jmp	Out			
Next		cmp	#1,R8			; Check if random number is 1
		jnz	Next1
		mov.w	#P1,R5			; Save the address of the first coeficient 
		jmp	Out
Next1		cmp	#2,R8			; Check if random number is 2
		jnz	Next2
		mov.w	#P2,R5			; Save the address of the first coeficient 
		jmp	Out
Next2		mov.w	#P3,R5			; by default is P3,  Address of P is located in R5
;-----------------Chossing the X Value-------------- Check wich X value was chosen randomly
Out		cmp	#0,R6			; Check if random number is 0
		jnz	Next3			; If not zero keep checking
		mov.w	X0,R9			; Save the address of the first coeficient in R9
		jmp	Out1
Next3		cmp	#1,R6			; Check if random number is 1
		jnz	Next4
		mov.w	X1,R9			; Save the address of the first coeficient 
		jmp	Out1
Next4		cmp	#2,R6			; Check if random number is 2
		jnz	Next5
		mov.w	X2,R9			; Save the address of the first coeficient 
		jmp	Out1
Next5		mov.w	X3,R9			; by default is X3   

;---X value is located in R9 and the address of the polynomial in R5----
;-------------------------------------------------------------------------
;			Syntethic Division
;-------------------------------------------------------------------------
Out1		mov.w	@R5+,R4			; Initialize the first coeficient and update address of the next coeficient (in R5)
Continue	Mult	R4,R9			; Mult the first coeficient with X
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose			; If out of range, lose
		mov.w	R15,R4			; Move the Result of the Mult in R4
		add.w	@R5+,R4			; add the next coeficient to x	
		Mult 	R4,R9			; Mult the result with x
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose			; If out of range, lose
		mov.w	R15,R4			; Move the Result of the Mult in R4
		add.w	@R5+,R4			; add the next coeficient to x
		Mult	R4,R9			; Mult the result with x
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose			; If out of range, lose
		mov.w	R15,R4			; Move the Result of the Mult in R4
		add.w	@R5+,R4			; add the last coeficient to x
		
;----------------Player Wins-----------------------------------
		bis.b	#01000000b,P1OUT	; Player Wins, green LED on
		mov	#0,R6			; Initialize R6
		mov.w	R4,R5			; Copy result in R5
		mov.w	#0,R8
Roll		cmp	#8,R8			; Roll the most significant bit of R5 to R6
		jz	OrganizeR5		; This will extract MSB from R5 to R6
		clrc
		rla	R5		
		rlc	R6
		inc	R8
		jmp	Roll
OrganizeR5	mov 	#0,R8
Again		cmp	#8,R8			; Reorganize R5 with LSB 
		jz	FlashMSB
		clrc
		rra	R5	
		inc	R8
		jmp	Again		
FlashMSB	bis.b	R5,P2OUT		; Copy LSB in Port 2, LEDs in BreadBoard will show the LSB
		Delay2	#50000			; Delay 
		Delay2	#50000			; This delay will give us time to write down the LSB
		Delay2	#50000
		Delay2	#50000
		Delay2	#50000
		Delay2	#50000
		Delay2	#50000
		bic.b	#0xFF,P2OUT		; Turn off LEDs
		Delay2	#30000			; Delay
		bis.b	R6,P2OUT		; Copy MSB in Port 2, LEDs in BreadBoard will show the MSB
		jmp	$
		
;---------------------Player Loses------------------------------
Lose		bis.b	#00000001b,P1OUT	; Player Loses, red LED on
		jmp	$

;---------------------------------------------------------------
;		Helper Method For Negatives
;---------------------------------------------------------------
Helper		bit.w	#1000000000000000b,R13	; Checking sign of R13
		jz	Check2			; if postive R13 check other number
		inv	R13			; else invert
		add.w	#1,R13			; 2's complement of R13
		add.w	#1,R12			; Counter for negatives
Check2		bit.w	#1000000000000000b,R14	; Checking sign of R9
		jz	Return			; if positive return from subroutine
		inv	R14			
		add.w	#1,R14			; 2's complement of R9
		add.w	#1,R12			; Counter for negatives
Return		cmp.w	#2,R12			; Two negative is the same as no negatives
		jnz	Return1	
		mov.w	#0,R12			; Easier to compare later in the Mult MACRO
Return1		ret
;-------------------------------------------------------------
;		P1.3 Interrupt Service Routine
;-------------------------------------------------------------
PBISR		bic.b	#00001000b,P1IFG	; clear int. flag
		cmp	#1,R7			; Check if it was the second time to press the button in P1.3
		jz	Restart			; If true jump 
		mov.w	#1,R7			; (True) Use for checking how many pushes have been made
		mov.w	#0,R4			; initialize random selection counter
		mov.w	#0,R8			; Random number for Polynomial selection
		mov.w	#0,R6			; Random number for value selection
;------------------Random Algorithm----------------------------------------------------------------------------
First		cmp	#2,R4			; if loop done twice
		jz	Exit			; exit
		rra	&0200h			; else, Move least significant bit to carry
		rlc	R8			; Roll left the carry to R8
		inc	R4			; increment R4 by one, R8 will have the posibility of having a number from 0 to 3
		jmp	First			; repeat again
Exit		mov.w	#0,R4			; initialize random selection counter
Second		cmp	#2,R4			; if loop done twice
		jz	Exit2			; Exit
		rra	&0202h			; else, Move least significant bit to carry
		rlc	R6			; Roll left the carry to R6
		inc	R4			; increment R4 by one, R6 will have the posibility of having a number from 0 to 3	
		jmp	Second			; repeat loop
Restart		bic.b	#11111111b,P2OUT	; Turn off all Port 2 LEDs 
		bic.b	#11111111b,P1OUT	; Turn off all Port 1 LEDs
		bis.w	#CPUOFF +GIE,SR		; Sleep CPU
Exit2		reti 				; return from ISR
;---------------------------------------------------------------------------------------------------------------
;	Interrrupt Vectors
;---------------------------------------------------------------------------------------------------------------
		ORG	0FFFEh			; MSP430 Reset Vector
		DW	RESET			;
		ORG	0FFE4h			; interrupt vector 2
		DW	PBISR			; address of label PBISR
		END
