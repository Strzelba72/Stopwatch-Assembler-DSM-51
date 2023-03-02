;************************************************
; PRZERWANIA
;************************************************

LED	EQU	P1.7

;********* Ustawienie TIMERÓW *********
;TIMER 0
T0_G	EQU	0	;GATE
T0_C	EQU	0	;COUNTER/-TIMER
T0_M	EQU	1	;MODE (0..3)
TIM0	EQU	T0_M+T0_C*4+T0_G*8
;TIMER 1
T1_G	EQU	0	;GATE
T1_C	EQU	0	;COUNTER/-TIMER
T1_M	EQU	0	;MODE (0..3)
TIM1	EQU	T1_M+T1_C*4+T1_G*8

TMOD_SET	EQU	TIM0+TIM1*16

;50[ms] = 50 000[ms]*(11.0592[MHz]/12) =
;	= 46 080 cykli = 180 * 256
TH0_SET		EQU	256-36
TL0_SET		EQU	0

TH1_SET		EQU	256-180 
TL1_SET		EQU	0
;**************************************

	LJMP	START

;********* Przerwanie Timer 0 *********
	ORG	0BH
	MOV	TH0,#TH0_SET		;TH0 na 10ms
	LCALL SETNE_SEK			
	LCALL CURRENT_TIME
	RETI
	
;********* Przerwanie Timer 1 *********
	ORG 1BH					
	MOV TH1,#TH1_SET		;TH1 na 50ms
	DJNZ R7,NO_10SEK
	LCALL ALARM
NO_10SEK:
	RETI
;**************************************
	ORG	100H
START:
	LCALL	LCD_CLR
	MOV	TMOD,#TMOD_SET		;Timer 0 liczy czas
	MOV	TH0,#TH0_SET		;Timer 0 na 10ms
	MOV	TL0,#TL0_SET
	MOV TH1,#TH1_SET 		;Timer 1 na 50ms
	MOV TL1,#TL1_SET
	
	SETB	EA				;włącz zezwolenie ogólne
							;na przerwania
	SETB	ET0				;włącz zezwolenie na
	SETB	ET1				;przerwanie od Timera 0 i 1
	
	MOV	R7,#200				;200*50ms=10s	
	
	MOV R2,#0 				;sekunda
	MOV R3,#0 				;setna sekund
	
	LCALL CURRENT_TIME
	LCALL 	WAIT_KEY
	
	SETB TR0				;start timerów 1 i 0		
	SETB TR1 
	
LOOP:
	LCALL 	WAIT_KEY		;czekaj na klawisz	
	CPL TR0
	CPL TR1
	
	SJMP 	LOOP
	SJMP	$				;koniec pracy
							;programu głównego

ALARM:
	MOV R7,#20				;R7:20*50ms=1s	
	MOV A,R2				;przypisanie sekund do akumulatora
	MOV B,#10					
	DIV AB					;podzielenie sekund przez 10, reszta z dzielenia
	MOV A,B						

	JNZ TURN_OFF			;skok jeśli akumulator różny od zera
	MOV A,R6
	JNZ TURN_OFF
	
	CLR P1.5				;wł sygnał
	MOV R6,#1				;1*50ms=50ms
	RET

TURN_OFF:
	SETB P1.5				;wył sygnał
	MOV R6,#0				;ustaw 0
	MOV R7,#200				;200*50ms=10s	
	RET
	
SETNE_SEK:
	INC R3					;zwiekszam setna sekund
	CJNE R3,#100,SEKUNDY	;zwiekszenie liczby sek jeśli 100
	MOV R3,#0				;zerowanie liczby po przecinku
	INC R2					;inkrementacja sekundy o 1

SEKUNDY:
	CJNE R2,#100,LOOP3		;kiedy następi 100s
	MOV R2,#0
	MOV R3,#0				;wyzerowanie obu wartości

LOOP3:							
	RET	
	
CURRENT_TIME:	
					
	LCALL LCD_CLR ;wyświela bieżący czas
	MOV A,R2
	LCALL TO_BCD
	LCALL WRITE_HEX
	MOV A,#','
	LCALL WRITE_DATA
	MOV A,R3
	LCALL TO_BCD
	LCALL WRITE_HEX
	RET
	

TO_BCD:
        MOV B,#10; DZIELNIK
        DIV AB; WYDZIELAMY CYFRE DZIESIATEK
        SWAP A; PRZESUWAMY CYFRĘ DZIESIĄTEK NA WYŻSZY 4 BITY
        ORL A,B; OPERACJA LOGICZNA SUMA
        RET
        NOP
