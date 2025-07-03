	LIST P=16F877A
	#include <p16f877a.inc>
		
	__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC
ORG 0x00
		GOTO START
		T1 EQU 30H
		U1 EQU 31H
        U2 EQU 32H
		N1 EQU 33H
		QU EQU 34H	
		RE EQU 35H
		R1 EQU 36H
		R2 EQU 37H
		R3 EQU 38H

        TX_Ack EQU RB6
		RX_Ack EQU RB7
;---------------------------------------
; Auxiliary CPU - Division Coprocessor
; Receives two numbers over PORTC via
; interrupt driven handshaking and
; returns the division result bytes.
;---------------------------------------
START
                ;Initialize ports and interrupts
                BSF STATUS, RP0       ; Bank 1
                MOVLW 0x80             ; Setting RB7 as input rest are input
                MOVWF TRISB            ;
                MOVLW 0xFF     ;Setting PORTC as input
       MOVWF TRISC
        CLRF TRISD     ;Setting PORTD  
         
		BCF STATUS, RP0        ; Bank 0
		CLRF PORTB
        CLRF PORTC
	    ;BCF PORTB,TX_Ack
    ; Receiving Num1 in one shot
chck_Ack
		BTFSS PORTB,RX_Ack    ;Waiting for signl 1 from Main
        GOTO chck_Ack
	
		MOVF PORTC,W          ;copying the data from portc to N1
		MOVWF N1
		BSF PORTB,TX_Ack	 ;Sendiing 1 to acknowledge
chck_Ack1
		BTFSC PORTB,RX_Ack   ;waiting for signal  0 
        GOTO chck_Ack1
     
     	BCF PORTB,TX_Ack     ;sending signal 0
;Reciving U2  
chck_Ack2
		BTFSS PORTB,RX_Ack   ;waiting for signal 1 from main
        GOTO chck_Ack2
        MOVF PORTC,W       ;copying data from port to U2
		MOVWF U2

		BSF PORTB,TX_Ack   ;sending singal 1 to acknowledge		
chck_Ack3 
    	BTFSC PORTB,RX_Ack  ; waiting for signal 0
        GOTO chck_Ack3
        BCF PORTB,TX_Ack    ;sending singal 0
     ; seperating Num1 into U1 and T1

		MOVF N1,W
        ANDLW 0FH
        MOVWF U1
         
        MOVF N1,W
        ANDLW 0F0H
    
        MOVWF T1
        SWAPF T1,1
        MOVF T1,W
        
       
 ;---- perform floating point division ----
 ; Placeholder routine: divide number in N1:T1:U1 by U2
 ; Actual algorithm supporting up to 6 integer and 6 decimal digits
 ; should be implemented here.  Result bytes should be placed in
 ; R1,R2,R3 (LSB first).  The code below is a minimal stub that
 ; copies the numerator into the result for demonstration.

      MOVF N1,W
      MOVWF R1
      CLRF R2
      CLRF R3
	
     
;reconfiguring PORTC as Output
        BSF STATUS,RP0
        CLRF TRISC 
        BCF STATUS,RP0

;Sending R1 in Main processor 
		MOVF R1,W
		MOVWF PORTC       ;sending R1
        BSF PORTB,TX_Ack
		Chk_Ack4
		BTFSS PORTB,RX_Ack   ; checking for Coprocessors acknowledgment.
		GOTO Chk_Ack4
		
		BCF PORTB,TX_Ack   ; sending signal (0) to co processors before transmission of unit of num2

        CALL LDELAY   ; Just to synch the coprocessor

;Sending R2 in Main processor 
		MOVF R2,W
		MOVWF PORTC       ;sending R2
        BSF PORTB,TX_Ack
		Chk_Ack5
		BTFSS PORTB,RX_Ack   ; checking for Coprocessors acknowledgment.
		GOTO Chk_Ack5
		
		BCF PORTB,TX_Ack   ; sending signal (0) to co processors before transmission of unit of num2

        CALL LDELAY   ; Just to synch the coprocessor

;Sending R3 in Main processor 
		MOVF R3,W
		MOVWF PORTC       ;sending R3
        BSF PORTB,TX_Ack
		Chk_Ack6
		BTFSS PORTB,RX_Ack   ; checking for Coprocessors acknowledgment.
		GOTO Chk_Ack6
		
		BCF PORTB,TX_Ack   ; sending signal (0) to co processors before transmission of unit of num2

        CALL LDELAY   ; Just to synch the coprocessor


   
		GOTO START

LDELAY ;25ms
		 BSF STATUS, RP0       ; Bank 1
		 MOVLW 0x00            ; Timer1 OFF
		 MOVWF T1CON           ; Load Timer1 control register
		 MOVLW 0x58            ; Load Timer1 low byte for 25 ms delay
		 MOVWF TMR1L           ; Load Timer1 low byte
		 MOVLW 0x9E            ; Load Timer1 high byte for 25 ms delay
		 MOVWF TMR1H           ; Load Timer1 high byte
		 BCF STATUS, RP0       ; Bank 0
		
	   ; Reset Timer1
		 BCF PIR1, TMR1IF     ;clear timer1 flag
		 BSF T1CON,TMR1ON      ;start timer
	STAY    
		 BTFSS PIR1,TMR1IF     ;if timer is expired?
		 GOTO STAY
		 RETURN

END
