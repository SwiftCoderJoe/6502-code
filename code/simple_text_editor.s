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

keyboard_buffer = $0200 ; 256-byte keyboard scancode bugger from 0200-02ff
keyboard_buffer_write_ptr = $0000
keyboard_buffer_read_ptr = $0001

keyboard_flags = $0002
RELEASE_SCANCODE_SEEN = %00000001
SHIFT_HELD = %00000010

; scancodes
KEYBOARD_RELEASE_SCANCODE = $f0
LSHIFT_SCANCODE = $12
RSHIFT_SCANCODE = $59

; ascii codes
ESCAPE_ASCII = $1b
QUOTE_ASCII = $22

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

 jmp keypress_return

write_display_settings:
 jsr display_wait

 sta PORTB ; Send data with E, RW, RS zeroed
 ora #DISP_E ; Enable E
 sta PORTB ; Send
 eor #DISP_E; Rezero E
 sta PORTB ; Send

 rts

key_pressed:
 ldx keyboard_buffer_read_ptr
 lda keyboard_buffer, x
 cmp #ESCAPE_ASCII
 beq escape_pressed
 jmp write_display_character
keypress_return:
 inc keyboard_buffer_read_ptr
 jmp loop

escape_pressed: ; TODO: change this when we change lcd instructions to easy 8-bit conversion
 lda #0
 jsr write_display_settings
 lda #%00010000
 jsr write_display_settings
 jmp keypress_return

reset:
 cli ; Allow interrupts

 ldx #$ff ; Initialize stack pointer to top of stack
 txs

 lda #%10000010 ; Enable interrupt with CA1 pin on the VIA
 sta INTERRUPT_ENABLE

 lda #%00000001
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

 lda #0
 sta keyboard_buffer_write_ptr
 sta keyboard_buffer_read_ptr
 sta keyboard_flags

loop:
 sei
 lda keyboard_buffer_read_ptr
 cmp keyboard_buffer_write_ptr
 cli
 bne key_pressed
 jmp loop

non_maskable_interrupt:
 rti

interrupt_request:
 pha
 txa
 pha

 lda keyboard_flags
 and #RELEASE_SCANCODE_SEEN ; check if we just saw a release code
 beq read_key ; if we did, continue, if we didn't, jump to read the key

 lda keyboard_flags
 eor #RELEASE_SCANCODE_SEEN
 sta keyboard_flags
 lda PORTA ; have to read the port to clear interrupt
 cmp #LSHIFT_SCANCODE
 beq handle_shift_up
 cmp #RSHIFT_SCANCODE
 beq handle_shift_up
 jmp end_interrupt

read_key
 lda PORTA

 ; Check for release
 cmp #KEYBOARD_RELEASE_SCANCODE
 beq handle_release

 ; Check for shift
 cmp #LSHIFT_SCANCODE
 beq handle_shift_down
 cmp #RSHIFT_SCANCODE
 beq handle_shift_down

 tax 
 lda keyboard_flags
 and #SHIFT_HELD
 bne shifted_key

 lda keymap, x
 jmp write_char_to_buffer

shifted_key:
 lda shifted_keymap, x
 jmp write_char_to_buffer

write_char_to_buffer
 ldx keyboard_buffer_write_ptr
 sta keyboard_buffer, x
 inc keyboard_buffer_write_ptr
 jmp end_interrupt

handle_release:
 lda keyboard_flags
 ora #RELEASE_SCANCODE_SEEN
 sta keyboard_flags
 jmp end_interrupt

handle_shift_down:
 lda keyboard_flags
 ora #SHIFT_HELD
 sta keyboard_flags
 jmp end_interrupt

handle_shift_up:
 lda keyboard_flags
 eor #SHIFT_HELD
 sta keyboard_flags
 jmp end_interrupt

end_interrupt:
 pla
 tax
 pla
 rti ; all processor flags restored here

 .org $fd00
keymap:
  .byte "????????????? `?" ; 00-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09??./l;p-?" ; 40-4F
  .byte "??'?[=?????]?\??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568",ESCAPE_ASCII,"??+3-*9??" ; 70-7F, esc
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF
shifted_keymap:
  .byte "????????????? ~?" ; 00-0F
  .byte "?????Q!???ZSAW@?" ; 10-1F
  .byte "?CXDE#$?? VFTR%?" ; 20-2F
  .byte "?NBHGY^???MJU&*?" ; 30-3F
  .byte "?<KIO)(??>?L:P_?" ; 40-4F
  .byte "??",QUOTE_ASCII,"?{+?????}?|??" ; 50-5F, "
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

 .org $fffa
 .word non_maskable_interrupt
 .word reset
 .word interrupt_request