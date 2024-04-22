PORTB = $6000
DATADIRECTIONB = $6002

PORTA = $6001
DATADIRECTIONA = $6003

PERIPHERAL_CONTROL = $600c
INTERRUPT_FLAGS = $600d
INTERRUPT_ENABLE = $600e

DISP_E  = %00000100
DISP_RW = %00000010
DISP_RS = %00000001

value = $0200 ; 2 byte size
modten = $0202
message = $0204 ; 6 bytes

counter = $020a ; 2 bytes
 
 .org $8000

display_wait:
 pha ; Save whatever was on reg.a
 lda #%00001111 ; Port B data input
 sta DATADIRECTIONB
display_wait_internal_loop:
 ; Get busy flag
 lda #DISP_RW
 sta PORTB ; Send RW
 ora #DISP_E
 sta PORTB ; Send RW, E
 lda PORTB ; Read the high nibble, which has busy flag
 pha

 ; Do the Enable routine again because we're in 4-bit mode
 lda #DISP_RW
 sta PORTB ; Send RW
 ora #DISP_E ; Send RW, E
 sta PORTB
 ; Skip low nibble, we don't care

 pla
 and #%10000000
 bne display_wait_internal_loop

 lda #DISP_RW
 sta PORTB ; Send RW
 lda #%11111111 ; Port B output
 sta DATADIRECTIONB

 pla
 rts

write_display_character:
 jsr display_wait
 pha
 ; first four bits
 and #%11110000 ; mask to just the first four bits
 ora #DISP_RS ; enable RS
 sta PORTB
 ora #DISP_E ; enable E
 sta PORTB
 eor #DISP_E ; disable E
 sta PORTB

 pla ; Pull back the original 8 bit sequence
 asl ; and shift it left four times
 asl ; in order to send the low nibble
 asl
 asl ; we don't need to bitmask because asl doesn't shift in the carry bit
 ora #DISP_RS ; enable RS
 sta PORTB
 ora #DISP_E ; enable E
 sta PORTB
 eor #DISP_E ; disable E
 sta PORTB

 rts

write_display_settings:
 jsr display_wait

 sta PORTB ; Send data with E, RW, RS zeroed
 ora #DISP_E ; Enable E
 sta PORTB ; Send
 eor #DISP_E; Rezero E
 sta PORTB ; Send

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
 cli ; Allow interrupts

 ldx #$ff ; Initialize stack pointer to top of stack
 txs

 lda #%10000010 ; Enable interrupt with CA1 pin on the VIA
 sta INTERRUPT_ENABLE

 lda #%00000000
 sta PERIPHERAL_CONTROL

 lda #%11111111 ; Set all pins on port B to output
 sta DATADIRECTIONB

 lda #%00000000 ; Set port A to input
 sta DATADIRECTIONA

 lda #%00100000 ; Initialize comm mode. This is understood as an 8-bit command, so it must be sent again to correctly initialize display.
 jsr write_display_settings

 lda #%00100000 ; Initialize display size and font.
 jsr write_display_settings
 lda #%10000000
 jsr write_display_settings

 lda #%00000000 ; Display on, cursor on, blinking off
 jsr write_display_settings
 lda #%11100000
 jsr write_display_settings

 lda #%00000000 ; Cursor moves forward; don't shift display
 jsr write_display_settings
 lda #%01100000
 jsr write_display_settings

 lda #%00000000 ; Clr display
 jsr write_display_settings
 lda #%00010000
 jsr write_display_settings

 lda #"J"
 jsr write_display_character
loop:
 jmp loop


non_maskable_interrupt:
interrupt_request:
 rti

 .org $fffa
 .word non_maskable_interrupt
 .word reset
 .word interrupt_request