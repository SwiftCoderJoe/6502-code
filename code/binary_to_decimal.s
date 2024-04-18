PORTB = $6000
DATADIRECTIONB = $6002

PORTA = $6001
DATADIRECTIONA = $6003

DISP_E  = %10000000
DISP_RW = %01000000
DISP_RS = %00100000

value = $0200 ; 2 byte size
modten = $0202
message = $0204 ; 6 bytes
 
 .org $8000

number: .word 1729

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

; Add the character in reg.a to a null-terminated `message`
push_character:
 pha
 ldy #0

push_character_loop:
 lda message,y ; get char from string and put it into x
 tax
 pla
 sta message,y ; replace that character with last character
 iny
 txa
 pha ; move that character back into the stack
 bne push_character_loop

 pla
 sta message,y ; Last null-terminator must be added back, finally

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

 ; initialize message to be null-terminated
 lda #0
 sta message

 ; initialize value to be number, to begin
 lda number
 sta value
 lda number + 1
 sta value + 1

divide:
 ; Initialize modten to be zero
 lda #0
 sta modten
 sta modten + 1
 clc
 
 ldx #16
division_loop:
 ; Rotate value and modten left
 rol value
 rol value + 1
 rol modten
 rol modten + 1

 ; a,y have dividend - divisor
 sec
 lda modten
 sbc #10
 tay ; save the low byte into Y
 lda modten + 1
 sbc #0
 bcc ignore_result
 sty modten
 sta modten + 1

ignore_result:
 dex
 bne division_loop
 rol value
 rol value + 1 

 lda modten
 clc
 adc #"0"
 jsr push_character

 ; if value != 0, continue dividing
 lda value
 ora value + 1
 bne divide
 
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