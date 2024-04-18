PORTB = $6000
DATADIRECTIONB = $6002

PORTA = $6001
DATADIRECTIONA = $6003

DISP_E  = %10000000
DISP_RW = %01000000
DISP_RS = %00100000
 
 .org $8000

reset:
 lda #%11111111 ; Set all pins on port B to output
 sta DATADIRECTIONB

 lda #%11100000 ; Set first 3 pins on port A to outputs
 sta DATADIRECTIONA

 lda #%00111000 ; Initialize display size, comm mode, and font
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00001110 ; Display on, cursor on, blinking off
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0
 sta PORTA

 lda #%00000111 ; Cursor moves forward; don't shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00000001 ; Clr display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 ; next we will try to shift the cursor right 8 times... very very inefficiently...

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

 lda #%00011100 ; shift display
 sta PORTB

 lda #0
 sta PORTA

 lda #DISP_E
 sta PORTA

 lda #0;
 sta PORTA

loop:
 lda #"J"
 sta PORTB

 lda #DISP_RS
 sta PORTA

 lda #(DISP_E | DISP_RS)
 sta PORTA

 lda #DISP_RS
 sta PORTA

 lda #"O"
 sta PORTB

 lda #DISP_RS
 sta PORTA

 lda #(DISP_E | DISP_RS)
 sta PORTA

 lda #DISP_RS
 sta PORTA

 lda #"E"
 sta PORTB

 lda #DISP_RS
 sta PORTA

 lda #(DISP_E | DISP_RS)
 sta PORTA

 lda #DISP_RS
 sta PORTA

 lda #"!"
 sta PORTB

 lda #DISP_RS
 sta PORTA

 lda #(DISP_E | DISP_RS)
 sta PORTA

 lda #DISP_RS
 sta PORTA

 lda #" "
 sta PORTB

 lda #DISP_RS
 sta PORTA

 lda #(DISP_E | DISP_RS)
 sta PORTA

 lda #DISP_RS
 sta PORTA

 jmp loop

 .org $fffc
 .word reset
 .word $0000