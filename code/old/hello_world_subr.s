PORTB = $6000
DATADIRECTIONB = $6002

PORTA = $6001
DATADIRECTIONA = $6003

DISP_E  = %10000000
DISP_RW = %01000000
DISP_RS = %00100000
 
 .org $8000

message: .asciiz "Hello, World!                           I'm Joe!"


display_wait:
 pha ; Save whatever was on reg.a
 lda #%00000000 ; Port B as input
 sta DATADIRECTIONB

display_wait_internal_loop:
 lda #DISP_RW
 sta PORTA
 lda #(DISP_RW | DISP_E)
 sta PORTA
 lda PORTB
 and #%10000000
 bne display_wait_internal_loop

 lda #DISP_RW
 sta PORTA
 lda #%11111111
 sta DATADIRECTIONB

 pla
 rts

write_display_character:
 jsr display_wait
 sta PORTB

 lda #DISP_RS
 sta PORTA

 lda #(DISP_E | DISP_RS)
 sta PORTA

 lda #DISP_RS
 sta PORTA

 rts

write_display_settings:
 jsr display_wait
 sta PORTB

 lda #0 ; Zero E, RW, RS
 sta PORTA

 lda #DISP_E ; Enable E only
 sta PORTA

 lda #0; ; Clear E, RW, RS
 sta PORTA

 rts

reset:
 ldx #$ff
 txs

 lda #%11111111 ; Set all pins on port B to output
 sta DATADIRECTIONB

 lda #%11100000 ; Set first 3 pins on port A to outputs
 sta DATADIRECTIONA

 lda #%00111000 ; Initialize display size, comm mode, and font
 jsr write_display_settings

 lda #%00001110 ; Display on, cursor on, blinking off
 jsr write_display_settings

 lda #%00000110 ; Cursor moves forward; don't shift display
 jsr write_display_settings

 lda #%00000001 ; Clr display
 jsr write_display_settings

 ldx #0
write_message_loop:
 lda message,x
 beq loop ; Have to do this instead of bne because inx sets zero flag
 jsr write_display_character
 inx
 jmp write_message_loop

loop:
 jmp loop

 .org $fffc
 .word reset
 .word $0000