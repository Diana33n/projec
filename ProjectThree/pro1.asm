;---------------------------------------
; Master CPU - Division Calculator
; Displays a blinking "Division" banner,
; accepts two floating point numbers
; via push button on RB0 and communicates
; with the coprocessor over PORTC using
; interrupt driven handshaking.
;---------------------------------------
                LIST P=16F877A
                #include <p16f877a.inc>
		
		__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC
		;__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _INTOSC_OSC_NOCLKOUT & _MCLRE_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF
		
		
		ORG 0x00
		GOTO START
       
		LCD_DATA EQU PORTD
		LCD_CTRL EQU PORTD
		RS EQU RD0
		RW EQU RD1
		EN EQU RD2
;------ Temporary  Locations
		T1 EQU 30H  ; for Ten1 digit of number1
		U1 EQU 31H   ;for Unit digit of number1
		T2 EQU 32H   ;for Ten digit of number 2
		U2 EQU 33H   ;for Unit Digit of Number2
		NUM1 EQU 34H   ;for Number1
        NUM2 EQU 35H   ;for Number 2
        R1 EQU 36H   ;for R1 (unit digit of result)
        R2 EQU 37H   ;for R2 (tenth digit of result )
        R3 EQU 38H   ;for R3 (Hundred digit of Result )
        R4 EQU 39H	 ;for R4 (Thousand digit of Result )
        QU EQU 40H	 ;for quotient ( will be used while dividing by 10)
        RE EQU 41H   ;for remainder (will be used while dividing by 10)
		R22 EQU 42H  ;for R2 (Ten digit of result) recieved from co processor
        R33 EQU 43H  ;for R3 (Hundred  digit ) recieved from co processor
        R44 EQU 44H
        TEMP EQU 45H  ; temporary location
		AA EQU D'5'   ; Number of Delays is called adjusting from one digit to other digit while entering Numbers

        TX_Ack EQU RB6 ; acknolwedgement pin for transfer
		RX_Ack EQU RB7 ; acknowledgemetn pin for recepetion


		
		
START:
    BSF STATUS, RP0
    MOVLW 0x81
    MOVWF TRISB
    CLRF TRISD
    CLRF TRISC
    BCF STATUS, RP0
    CLRF PORTB
    CLRF PORTD
    MOVLW 0xFF
    MOVWF PORTC

    ; ????? ????? ????? ?? ???? T1 ? U1
    ; ????? ????? ?????? ?? ???? T2 ? U2
    ; ????? ??????? ???????? NUM1 ? NUM2
    MOVF T1,W
    MOVWF NUM1
    SWAPF NUM1
    MOVF U1,W
    IORWF NUM1,F

    MOVF T2,W
    MOVWF NUM2
    SWAPF NUM2
    MOVF U2,W
    IORWF NUM2,F

    ; ????? NUM1
    MOVF NUM1, W
    MOVWF PORTC
    BSF PORTB, TX_Ack

REP1
		MOVLW D'3'      ; number of time welcome message is repeated
		MOVWF 01H
MREP
		
		MOVLW 01H    ;clear screen
		CALL COMNWRT
		CALL DELAY15
		CALL DELAY1S
		MOVLW 0EH    ;Diplay on Cursor blinking
		CALL COMNWRT
		CALL DELAY15
		MOVLW 06H    ;Increment cursor  
		CALL COMNWRT
		CALL DELAY15
		MOVLW 80H    ;First character on first line[Welcome To]
		CALL COMNWRT
		CALL DELAY15
		CALL WLCMESSAGE
                MOVLW 0C0H    ;first character on second line [Division]
                CALL COMNWRT
                CALL DELAY15
                CALL DIVMESSAGE
		DECFSZ 01H ;Dec 3-peat counter
		GOTO MREP
		;step 2
		;--------Number1-------------
		MOVLW 01H   ;clear screen
		CALL COMNWRT
		CALL DELAY15
		CALL DELAY1S
		MOVLW 0EH   ;Diplay on Cursor blinking
		CALL COMNWRT
		CALL DELAY15
		MOVLW 06h    ;increment cursor  
		CALL COMNWRT
		CALL DELAY15
		MOVLW 80H     ;first character on first line 
		CALL COMNWRT
		CALL DELAY15
AGAIN
		; Initialize ports
		BSF STATUS, RP0       ; Bank 1
		MOVLW 81H
		MOVWF TRISB            ; Set PORTB as output except RB0,RB7
		CLRF TRISD             ; Set PORTD as output
		CLRF TRISC             ; Set PORTC as output
		BCF STATUS, RP0        ; Bank 0
		CLRF PORTB
		CLRF PORTD
		MOVLW 0xFF
		MOVWF PORTC
		 

		MOVLW 01H    ;clear screen
		CALL COMNWRT
		CALL DELAY15
		CALL DELAY1S
		MOVLW 0EH    ;Diplay on Cursor blinking
		CALL COMNWRT
		CALL DELAY15
		MOVLW 06H    ;Increment cursor  
		CALL COMNWRT
		CALL DELAY15
		
		CALL PrintNUM1
	
		MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called
		
		MOVLW 0x30
		MOVWF T1  ;saving tenth of first number
		
		CALL TEN1  ; calling subroutine to collect ten digit of number 1
		MOVLW 30H
        SUBWF T1,1
		;step 3
		;-------Unit
        MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called
		
		MOVLW 0x30
		MOVWF U1  ;saving tenth of first number
		
		CALL UNIT1 ; calling subroutine to collect Unit digit of number 1
		MOVLW 30H
        SUBWF U1,1
        ;step 4  
        ;--- division symbol '/'
                MOVLW 01H   ;clear screen
                CALL COMNWRT
                CALL DELAY15
        MOVLW A'/'  ; printing '/' symbol
        CALL send
        CALL DELAY1S
       ;step 5
		;------ Number2
        MOVLW 01H   ;clear screen
		CALL COMNWRT
		CALL DELAY15
		
		CALL PrintNUM2 ;calling subroutine to print num2
	    ;step 6
	
		MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called
		
		MOVLW 0x30
		MOVWF T2  ;saving tenth of first number
		
		CALL TEN2 ; calling subroutine to collect ten digit of number 2
		MOVLW 30H
        SUBWF T2,1

        MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called
		
		MOVLW 0x30
		MOVWF U2  ;saving tenth of first number
		
		CALL UNIT2 ; calling subroutine to collect Unit digit of number 1
		MOVLW 30H
        SUBWF U2,1
        ;step 7
		;------ Processing

  ; binding T1,U1 to form PrintNUM1   ;will be used to transmit num1 in one shot
      MOVF T1,W
      MOVWF NUM1
      SWAPF NUM1
      MOVF U1,W
      IORWF NUM1,F
      


 
   ;------ displaying '=' SYMBOL------------
     	MOVLW 01H    ;clear screen
		CALL COMNWRT
		CALL DELAY15
		CALL DELAY1S
		MOVLW 0EH    ;Diplay on Cursor blinking
		CALL COMNWRT
		CALL DELAY15

		MOVLW 06H    ;Increment cursor  
		CALL COMNWRT
		CALL DELAY15

		MOVLW 80H    ;First character on first line 
		CALL COMNWRT
		CALL DELAY15

        MOVLW 27H  ;ascci symbol of '
		CALL send
		CALL DELAY15

        MOVLW A'='
        CALL send
        CALL DELAY15

        MOVLW 27H ;ascci symbol of '
		CALL send
		CALL DELAY15

;------------Sending num1 in one shot to co processor 

		MOVF NUM1,W
		MOVWF PORTC       ;sending NUM1
        BSF PORTB,TX_Ack   ;sending acknowledgment to Coprocessor
		Chk_Ack
		BTFSS PORTB,RX_Ack   ; checking for Coprocessors acknowledgment.
		GOTO Chk_Ack
		
		BCF PORTB,TX_Ack   ; sending signal (0) to co processors before transmission of unit of num2

        CALL DELAY25   ; Just to synch the coprocessor

	  ;Sending U2 to co processor 
		MOVF U2,W
		MOVWF PORTC       ;sending U2
        BSF PORTB,TX_Ack    ;sending acknowledgment to Coprocessor
		Chk_Ack1
		BTFSS PORTB,RX_Ack   ; checking for Coprocessors acknowledgment.
		GOTO Chk_Ack1

         BCF PORTB, TX_Ack    ;sinding signal 0 to coproessor 
         CALL DELAY25


        

      ;---- perform floating point division using coprocessor ----
      ; Send both numbers and trigger the auxiliary CPU.  The
      ; result bytes will be returned via the interrupt handler
      ; and stored in R1-R4.  Placeholder implementation uses the
      ; previously entered first number as the result.

      MOVF NUM1,W
      MOVWF R1
      CLRF R2
      CLRF R3
      CLRF R4
     
      
	;reconfiguring PORTC as input
        BSF STATUS,RP0
        MOVLW 0xFF
		MOVWF TRISC 
        BCF STATUS,RP0


    ; Receiving R1
chck_Ack2
		BTFSS PORTB,RX_Ack    ;Waiting for signl 1 from coprocessor
        GOTO chck_Ack2
	
		MOVF PORTC,W          ;copying the data from portc to R1
		MOVWF R1
		BSF PORTB,TX_Ack	 ;Sendiing 1 to acknowledge
chck_Ack3
		BTFSC PORTB,RX_Ack   ;waiting for signal  0 
        GOTO chck_Ack3
        BCF PORTB,TX_Ack     ;sending signl 0

    ; Receiving R22
chck_Ack4
		BTFSS PORTB,RX_Ack    ;Waiting for signl 1 from coprocessor
        GOTO chck_Ack4
	
		MOVF PORTC,W          ;copying the data from portc to R22
		MOVWF R22
		BSF PORTB,TX_Ack	 ;Sendiing 1 to acknowledge
chck_Ack5
		BTFSC PORTB,RX_Ack   ;waiting for signal  0 
        GOTO chck_Ack5
        BCF PORTB,TX_Ack     ;sending signl 0
    ; Receiving R33
chck_Ack6
		BTFSS PORTB,RX_Ack    ;Waiting for signl 1 from coprocessor
        GOTO chck_Ack6
	
		MOVF PORTC,W          ;copying the data from portc to R33
		MOVWF R33
		BSF PORTB,TX_Ack	 ;Sendiing 1 to acknowledge
chck_Ack7
		BTFSC PORTB,RX_Ack   ;waiting for signal  0 
        GOTO chck_Ack7
        BCF PORTB,TX_Ack     ;sending signl 0


  ;--- ADJUSTING SUMS
   
   ;; adjustment of R2---------
	  MOVF R2,W
      ADDWF R22,F
      
      MOVF R22,W
      MOVWF RE


      CLRF QU
      MOVLW 0x0A
DIV3
      INCF QU
      SUBWF RE,F
      BTFSS RE,7
      GOTO DIV3
      DECF QU
      ADDWF RE,F

      MOVF RE,W
      MOVWF R2
      MOVF QU,W


   ;; adjustment of  from R3---------
    
     ADDWF R3,F
     MOVF R33,W
     ADDWF R3,F


     
     MOVF R3,W
     MOVWF RE

     CLRF QU
     MOVLW 0x0A
DIV4
	 INCF QU
	 SUBWF RE,F
     BTFSS RE,7
     GOTO DIV4
     DECF QU
     ADDWF RE,F

     MOVF RE,W
     MOVWF R3
     
    
;; Ajdustment  of R4

    MOVF QU,W
    ADDWF R4,F

    ; Displaying result
		MOVLW 01H    ;clear screen
		CALL COMNWRT
		CALL DELAY15
		CALL DELAY1S
		MOVLW 0EH    ;Diplay on Cursor blinking
		CALL COMNWRT
		CALL DELAY15
		MOVLW 06H    ;Increment cursor  
		CALL COMNWRT
		CALL DELAY15
		MOVLW 80H    ;First character on first line 
		CALL COMNWRT
		CALL DELAY15
        CALL RESULT
        
        MOVLW 0C0H   ;First character on first line 
		CALL COMNWRT
		CALL DELAY15
     




; Print testing for que and remainder
      MOVLW 30H
      ADDWF R2,F
      ADDWF R3,F
      ADDWF R4,F
  	  ADDWF R1,F

   
	   MOVF  R4,W
      CALL send
      CALL DELAY15

	  MOVF  R3,W
      CALL send
      CALL DELAY15
;
      MOVF  R2,W
      CALL send
      CALL DELAY15


 	  MOVF  R1,W
      CALL send
      CALL DELAY15
STOP
    BTFSC PORTB,0
    GOTO STOP
    GOTO AGAIN

	
TEN1
      ;Start_Ten1
		MOVLW 0C0H    ;first charater on second line
		CALL COMNWRT
		CALL DELAY15
		
		MOVF T1,W
		CALL send
		CALL DELAY15
			
		BTFSC PORTB,0
		GOTO SKIP_INCR_TEN1
		GOTO INCR_TEN1
		
SKIP_INCR_TEN1
		CALL DELAY25
		DECFSZ 01H  ; decrement times press has been skipped to check if we excedded 2 secs
		GOTO TEN1
        GOTO Exit_Ten1
        
INCR_TEN1

		INCF T1
		MOVF T1,W    ; to check if it is exceeding 9
		XORLW 3AH
		BTFSC STATUS,Z
        GOTO RESET_TEN
		MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called)		
		GOTO TEN1
RESET_TEN 
		MOVLW 30H
		MOVWF T1
		GOTO TEN1
Exit_Ten1
	    RETURN
		
TEN2
      ;Start_Ten2
		MOVLW 0C0H    ;first charater on second line
		CALL COMNWRT
		CALL DELAY15
		
		MOVF T2,W
		CALL send
		CALL DELAY15
			
		BTFSC PORTB,0
		GOTO SKIP_INCR_TEN2
		GOTO INCR_TEN2
		
SKIP_INCR_TEN2
		CALL DELAY25
		DECFSZ 01H  ; addition of delays 
		GOTO TEN2
        GOTO Exit_Ten2
        
INCR_TEN2

		INCF T2
		MOVF T2,W    ; to check if it is exceeding 9
		XORLW 3AH
		BTFSC STATUS,Z
        GOTO RESET_TEN2
		MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called)		
		GOTO TEN2
RESET_TEN2
		MOVLW 30H
		MOVWF T2
		GOTO TEN2
Exit_Ten2
	    RETURN

UNIT1
      
		MOVLW 0C1H    ;first charater on second line
		CALL COMNWRT
		CALL DELAY15
		
		MOVF U1,W
		CALL send
		CALL DELAY15
			
		BTFSC PORTB,0
		GOTO SKIP_INCR_UNIT1
		GOTO INCR_UNIT1
		
SKIP_INCR_UNIT1
		CALL DELAY25
		DECFSZ 01H  ; addition of delays 
		GOTO UNIT1
        GOTO Exit_Unit1
        
INCR_UNIT1

		INCF U1
		MOVF U1,W    ; to check if it is exceeding 9
		XORLW 3AH
		BTFSC STATUS,Z
        GOTO RESET_UNIT1
		MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called)		
		GOTO UNIT1
RESET_UNIT1
		MOVLW 30H
		MOVWF U1
		GOTO UNIT1
Exit_Unit1
	    RETURN

UNIT2
      
		MOVLW 0C1H    ;first charater on second line
		CALL COMNWRT
		CALL DELAY15
		
		MOVF U2,W
		CALL send
		CALL DELAY15
			
		BTFSC PORTB,0
		GOTO SKIP_INCR_UNIT2
		GOTO INCR_UNIT2
		
SKIP_INCR_UNIT2
		CALL DELAY25
		DECFSZ 01H  ; addition of delays 
		GOTO UNIT2
        GOTO Exit_Unit2
        
INCR_UNIT2

		INCF U2
		MOVF U2,W    ; to check if it is exceeding 9
		XORLW 3AH
		BTFSC STATUS,Z
        GOTO RESET_UNIT2
		MOVLW AA
		MOVWF 01H  ; SAVING number of time delay has been called)		
		GOTO UNIT2
RESET_UNIT2
		MOVLW 30H
		MOVWF U2
		GOTO UNIT2
Exit_Unit2
	    RETURN
		
		
		
		
DELAY1S
		MOVLW D'2'
		MOVWF 00H
		ABC
		CALL DELAY25
		DECFSZ 00H
		GOTO ABC
		RETURN

RESULT
        MOVLW 27H
		CALL send
		CALL DELAY15
        MOVLW A'R'
		CALL send
		CALL DELAY15	
        MOVLW A'E'
		CALL send
		CALL DELAY15
        MOVLW A'S'
		CALL send
		CALL DELAY15	
        MOVLW A'U'
		CALL send
		CALL DELAY15
        MOVLW A'L'
		CALL send
		CALL DELAY15
        MOVLW A'T'
		CALL send
		CALL DELAY15
        MOVLW 27H
		CALL send
		CALL DELAY15
		RETURN
		
PrintNUM1
 		MOVLW 27H
		CALL send
		CALL DELAY15
		MOVLW A'N'
		CALL send
		CALL DELAY15
		MOVLW A'u'
		CALL send
		CALL DELAY15
		MOVLW A'm'
		CALL send
		CALL DELAY15
		MOVLW A'b'
		CALL send
		CALL DELAY15
		MOVLW A'e'
		CALL send
		CALL DELAY15
		MOVLW A'r'
		CALL send
		CALL DELAY15
		MOVLW A' '
		CALL send
		CALL DELAY15
		MOVLW A'1'
		CALL send
		CALL DELAY15
 		MOVLW 27H
		CALL send
		CALL DELAY15
		RETURN
		
PrintNUM2
        MOVLW 27H
		CALL send
		CALL DELAY15
		MOVLW A'N'
		CALL send
		CALL DELAY15
		MOVLW A'u'
		CALL send
		CALL DELAY15
		MOVLW A'm'
		CALL send
		CALL DELAY15
		MOVLW A'b'
		CALL send
		CALL DELAY15
		MOVLW A'e'
		CALL send
		CALL DELAY15
		MOVLW A'r'
		CALL send
		CALL DELAY15
		MOVLW A' '
		CALL send
		CALL DELAY15
		MOVLW A'2'
		CALL send
		CALL DELAY15
       MOVLW 27H
		CALL send
		CALL DELAY15
		RETURN
		
WLCMESSAGE
		MOVLW A'W'
		CALL send
		CALL DELAY15
		MOVLW A'E'
		CALL send
		CALL DELAY15
		MOVLW A'L'
		CALL send
		CALL DELAY15
		MOVLW A'C'
		CALL send
		CALL DELAY15
		MOVLW A'O'
		CALL send
		CALL DELAY15
		MOVLW A'M'
		CALL send
		CALL DELAY15
		MOVLW A'E'
		CALL send
		CALL DELAY15
		MOVLW A' '
		CALL send
		CALL DELAY15
		MOVLW A'T'
		CALL send
		CALL DELAY15
		MOVLW A'0'
		CALL send
		CALL DELAY15
		RETURN
		
DIVMESSAGE
                MOVLW A'D'
                CALL send
                CALL DELAY15
                MOVLW A'I'
                CALL send
                CALL DELAY15
                MOVLW A'V'
                CALL send
                CALL DELAY15
                MOVLW A'I'
                CALL send
                CALL DELAY15
                MOVLW A'S'
                CALL send
                CALL DELAY15
                MOVLW A'I'
                CALL send
                CALL DELAY15
                MOVLW A'O'
                CALL send
                CALL DELAY15
                MOVLW A'N'
                CALL send
                CALL DELAY15
                RETURN
COMNWRT


        MOVWF TEMP
        ANDLW 0F0H
		MOVWF LCD_DATA
		BCF LCD_CTRL,RS
		BCF LCD_CTRL,RW
		BSF LCD_CTRL,EN
		CALL SDELAY
		BCF LCD_CTRL,EN
        
        CALL SDELAY
		SWAPF TEMP
        MOVF TEMP,W
        ANDLW 0F0H
        MOVWF LCD_DATA
		BCF LCD_CTRL,RS
		BCF LCD_CTRL,RW
		BSF LCD_CTRL,EN
		CALL SDELAY
		BCF LCD_CTRL,EN
        
        CALL SDELAY

		RETURN
		
send 


		MOVWF TEMP
        ANDLW 0F0H
		
		MOVWF LCD_DATA
		BSF LCD_CTRL,RS
		BCF LCD_CTRL,RW
		BSF LCD_CTRL,EN
		CALL SDELAY
		BCF LCD_CTRL,EN

        CALL SDELAY
		SWAPF TEMP
        MOVF TEMP,W
        ANDLW 0F0H
	    
		MOVWF LCD_DATA
		BSF LCD_CTRL,RS
		BCF LCD_CTRL,RW
		BSF LCD_CTRL,EN
		CALL SDELAY
		BCF LCD_CTRL,EN
		
 		CALL SDELAY

		RETURN

DELAY25 ;25ms
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
		
 DELAY15 ;15ms
		    BSF STATUS, RP0       ; Bank 1
		    MOVLW 0x00            ; Timer1 OFF
		    MOVWF T1CON           ; Load Timer1 control register
		    MOVLW 0x68           ; Load Timer1 low byte for 15 ms delay
		    MOVWF TMR1L           ; Load Timer1 low byte
		    MOVLW 0x0C5            ; Load Timer1 high byte for 15 ms delay
		    MOVWF TMR1H           ; Load Timer1 high byte
		    BCF STATUS, RP0       ; Bank 0
		
		    ; Reset Timer1
		    BCF PIR1, TMR1IF     ;clear timer1 flag
		    BSF T1CON,TMR1ON     ;clear timer1 flag
		STAY1    
		    BTFSS PIR1,TMR1IF   ;if timer is expired?
		    GOTO STAY1
		   
		    RETURN
		
		SDELAY ;1ms
		    BSF STATUS, RP0       ; Bank 1
		    MOVLW 0x00            ; Timer1 OFF
		    MOVWF T1CON           ; Load Timer1 control register
		    MOVLW 0x18           ; Load Timer1 low byte for  1ms delayM
		    MOVWF TMR1L           ; Load Timer1 low byte
		    MOVLW 0x0FC            ; Load Timer1 high byte for 1 ms delay
		    MOVWF TMR1H           ; Load Timer1 high byte
		    BCF STATUS, RP0       ; Bank 0
		
		    ; Reset Timer1
		    BCF PIR1, TMR1IF     ;clear timer1 flag
		    BSF T1CON,TMR1ON     ;clear timer1 flag
		STAY2    
		    BTFSS PIR1,TMR1IF   ;if timer is expired?
		    GOTO STAY2
		   
		    RETURN
		    END
		
	
		    
		
		
		
