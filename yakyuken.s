;; ============================================================
;; YAKYUKEN - Rock Paper Scissors for NES/Famicom
;; A janken (rock-paper-scissors) game
;; ============================================================

.segment "HEADER"
    .byte "NES", $1A    ; iNES magic
    .byte $01            ; 1x 16KB PRG ROM
    .byte $01            ; 1x 8KB CHR ROM
    .byte $01            ; Mapper 0, vertical mirroring
    .byte $00            ; Mapper 0
    .byte $00, $00, $00, $00, $00, $00, $00, $00

;; ============================================================
;; Zero Page Variables
;; ============================================================
.segment "ZEROPAGE"

game_state:     .res 1   ; 0=title, 1=select, 2=reveal, 3=result
player_choice:  .res 1   ; 0=rock, 1=scissors, 2=paper
cpu_choice:     .res 1   ; 0=rock, 1=scissors, 2=paper
result:         .res 1   ; 0=draw, 1=win, 2=lose
player_score:   .res 1
cpu_score:      .res 1
frame_counter:  .res 1
rng_seed:       .res 2   ; 16-bit random seed
pad_state:      .res 1   ; current controller state
pad_prev:       .res 1   ; previous controller state
pad_new:        .res 1   ; newly pressed buttons
cursor_pos:     .res 1   ; 0-2 for select screen
anim_timer:     .res 1   ; animation timer
nmi_flag:       .res 1   ; set by NMI
temp:           .res 4   ; temp variables
ppu_buf_len:    .res 1   ; PPU buffer length
needs_draw:     .res 1   ; flag: screen needs redraw
reveal_step:    .res 1   ; animation step counter

;; ============================================================
;; BSS (RAM)
;; ============================================================
.segment "BSS"
ppu_buf:        .res 64  ; PPU update buffer

;; ============================================================
;; OAM
;; ============================================================
.segment "OAM"
oam_data:       .res 256

;; ============================================================
;; Constants
;; ============================================================
.segment "CODE"

; PPU registers
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014

; APU registers
APU_PULSE1_CTRL  = $4000
APU_PULSE1_SWEEP = $4001
APU_PULSE1_LO    = $4002
APU_PULSE1_HI    = $4003
APU_PULSE2_CTRL  = $4004
APU_PULSE2_SWEEP = $4005
APU_PULSE2_LO    = $4006
APU_PULSE2_HI    = $4007
APU_TRI_CTRL     = $4008
APU_TRI_LO       = $400A
APU_TRI_HI       = $400B
APU_NOISE_CTRL   = $400C
APU_NOISE_LO     = $400E
APU_NOISE_HI     = $400F
APU_STATUS        = $4015
APU_FRAME         = $4017

JOYPAD1   = $4016

; Controller bits
BTN_A      = %10000000
BTN_B      = %01000000
BTN_SELECT = %00100000
BTN_START  = %00010000
BTN_UP     = %00001000
BTN_DOWN   = %00000100
BTN_LEFT   = %00000010
BTN_RIGHT  = %00000001

; Game states
STATE_TITLE  = 0
STATE_SELECT = 1
STATE_REVEAL = 2
STATE_RESULT = 3

; Tile indices
TILE_BLANK  = $00
TILE_A      = $01
TILE_B      = $02
TILE_C      = $03
TILE_D      = $04
TILE_E      = $05
TILE_F      = $06
TILE_G      = $07
TILE_H      = $08
TILE_I      = $09
TILE_J      = $0A
TILE_K      = $0B
TILE_L      = $0C
TILE_M      = $0D
TILE_N      = $0E
TILE_O      = $0F
TILE_P      = $10
TILE_Q      = $11
TILE_R      = $12
TILE_S      = $13
TILE_T      = $14
TILE_U      = $15
TILE_V      = $16
TILE_W      = $17
TILE_X      = $18
TILE_Y      = $19
TILE_Z      = $1A
TILE_0      = $1B
TILE_1      = $1C
TILE_2      = $1D
TILE_3      = $1E
TILE_4      = $1F
TILE_5      = $20
TILE_6      = $21
TILE_7      = $22
TILE_8      = $23
TILE_9      = $24
TILE_COLON  = $25
TILE_EXCL   = $26
TILE_DASH   = $27
TILE_ARROW  = $28
TILE_DOT    = $29
TILE_QUEST  = $2A

TILE_GU     = $30
TILE_CHOU   = $31
TILE_CHI    = $32
TILE_SYO    = $33
TILE_KI     = $34
TILE_PA     = $35

TILE_ROCK_TL = $40
TILE_ROCK_TR = $41
TILE_ROCK_BL = $42
TILE_ROCK_BR = $43
TILE_SCIS_TL = $44
TILE_SCIS_TR = $45
TILE_SCIS_BL = $46
TILE_SCIS_BR = $47
TILE_PAPER_TL = $48
TILE_PAPER_TR = $49
TILE_PAPER_BL = $4A
TILE_PAPER_BR = $4B

; Character CG tiles
TILE_P_TOP0  = $60    ; player top-left
TILE_P_TOP1  = $61
TILE_P_TOP2  = $62
TILE_P_HEYE0 = $63   ; player happy eyes
TILE_P_HEYE1 = $64
TILE_P_HEYE2 = $65
TILE_P_HMTH0 = $66   ; player happy mouth
TILE_P_HMTH1 = $67
TILE_P_HMTH2 = $68
TILE_P_SEYE0 = $69   ; player sad eyes
TILE_P_SEYE1 = $6A
TILE_P_SEYE2 = $6B
TILE_P_SMTH0 = $6C   ; player sad mouth
TILE_P_SMTH1 = $6D
TILE_P_SMTH2 = $6E

TILE_C_TOP0  = $72    ; CPU top-left
TILE_C_TOP1  = $73
TILE_C_TOP2  = $74
TILE_C_HEYE0 = $75   ; CPU happy eyes
TILE_C_HEYE1 = $76
TILE_C_HEYE2 = $77
TILE_C_HMTH0 = $78   ; CPU happy mouth
TILE_C_HMTH1 = $79
TILE_C_HMTH2 = $7A
TILE_C_SEYE0 = $7B   ; CPU sad eyes
TILE_C_SEYE1 = $7C
TILE_C_SEYE2 = $7D
TILE_C_SMTH0 = $7E   ; CPU sad mouth
TILE_C_SMTH1 = $7F
TILE_C_SMTH2 = $80

TILE_HLINE_T = $50
TILE_HLINE_B = $51
TILE_VLINE_L = $52
TILE_VLINE_R = $53
TILE_CORNER_TL = $54
TILE_CORNER_TR = $55
TILE_CORNER_BL = $56
TILE_CORNER_BR = $57
TILE_STAR    = $58
TILE_VS      = $59

;; ============================================================
;; RESET handler
;; ============================================================
.proc reset
    sei
    cld
    ldx #$40
    stx APU_FRAME       ; disable APU frame IRQ
    ldx #$FF
    txs                  ; set up stack
    inx                  ; X = 0
    stx PPUCTRL          ; disable NMI
    stx PPUMASK          ; disable rendering
    stx $4010            ; disable DMC IRQs

    ; Wait for first vblank
:   bit PPUSTATUS
    bpl :-

    ; Clear RAM
    lda #$00
    ldx #$00
@clear_ram:
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne @clear_ram

    ; Hide all sprites (Y = $FF)
    lda #$FF
    ldx #$00
@clear_oam:
    sta $0200, x
    inx
    bne @clear_oam

    ; Wait for second vblank
:   bit PPUSTATUS
    bpl :-

    ; Initialize random seed
    lda #$A7
    sta rng_seed
    lda #$3B
    sta rng_seed+1

    ; Initialize game state
    lda #STATE_TITLE
    sta game_state
    lda #$00
    sta player_score
    sta cpu_score
    sta cursor_pos

    ; Enable APU channels
    lda #%00000011       ; enable pulse 1 and 2
    sta APU_STATUS

    ; Set up palettes
    jsr load_palettes

    ; Draw title screen
    jsr draw_title_screen

    ; Enable NMI and rendering
    lda #%10000000       ; NMI on, BG pattern table 0
    sta PPUCTRL
    lda #%00001110       ; show BG, no clipping
    sta PPUMASK

    ; Main loop
main_loop:
    ; Wait for NMI
    lda #$00
    sta nmi_flag
@wait_nmi:
    lda nmi_flag
    beq @wait_nmi

    ; Advance RNG every frame
    jsr random

    ; Read controller
    jsr read_controller

    ; Dispatch game state
    lda game_state
    cmp #STATE_TITLE
    beq @do_title
    cmp #STATE_SELECT
    beq @do_select
    cmp #STATE_REVEAL
    beq @do_reveal
    cmp #STATE_RESULT
    beq @do_result
    jmp main_loop

@do_title:
    jsr update_title
    jmp main_loop
@do_select:
    jsr update_select
    jmp main_loop
@do_reveal:
    jsr update_reveal
    jmp main_loop
@do_result:
    jsr update_result
    jmp main_loop
.endproc

;; ============================================================
;; NMI handler
;; ============================================================
.proc nmi
    pha
    txa
    pha
    tya
    pha

    ; Sprite DMA
    lda #$00
    sta OAMADDR
    lda #$02
    sta OAMDMA

    ; Increment frame counter (for blinking, RNG)
    inc frame_counter

    ; Reset scroll
    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL

    ; Set NMI flag
    lda #$01
    sta nmi_flag

    pla
    tay
    pla
    tax
    pla
    rti
.endproc

;; ============================================================
;; IRQ handler (unused)
;; ============================================================
.proc irq
    rti
.endproc

;; ============================================================
;; Read controller
;; ============================================================
.proc read_controller
    ; Save previous state
    lda pad_state
    sta pad_prev

    ; Strobe controller
    lda #$01
    sta JOYPAD1
    lda #$00
    sta JOYPAD1

    ; Read 8 buttons
    ldx #$08
    lda #$00
@loop:
    pha
    lda JOYPAD1
    and #$01
    lsr a           ; carry = button state
    pla
    rol a           ; shift into accumulator
    dex
    bne @loop
    sta pad_state

    ; Compute newly pressed buttons
    lda pad_state
    eor pad_prev     ; changed bits
    and pad_state    ; only newly pressed
    sta pad_new
    rts
.endproc

;; ============================================================
;; Random number generator (16-bit LFSR)
;; ============================================================
.proc random
    lda rng_seed+1
    asl a
    asl a
    eor rng_seed+1
    asl a
    eor rng_seed+1
    asl a
    asl a
    eor rng_seed+1
    asl a
    rol rng_seed
    rol rng_seed+1
    lda rng_seed
    rts
.endproc

;; ============================================================
;; Load palettes
;; ============================================================
.proc load_palettes
    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ldx #$00
@loop:
    lda palette_data, x
    sta PPUDATA
    inx
    cpx #$20
    bne @loop
    rts
.endproc

;; Palette data: 4 BG palettes + 4 sprite palettes
palette_data:
    ; BG Palette 0: general text (white on dark)
    .byte $0F, $30, $10, $00    ; black, white, gray, dark gray
    ; BG Palette 1: player character (warm skin)
    .byte $0F, $17, $36, $30    ; black, brown(hair), pale pink(skin), white(eyes)
    ; BG Palette 2: CPU character (cool blue)
    .byte $0F, $02, $12, $30    ; black, dark blue(hair), blue(skin), white(eyes)
    ; BG Palette 3: result/decoration
    .byte $0F, $1A, $2A, $38    ; black, green, light green, cream
    ; Sprite Palette 0: cursor
    .byte $0F, $16, $30, $27    ; black, red, white, orange
    ; Sprite Palette 1-3: unused
    .byte $0F, $00, $00, $00
    .byte $0F, $00, $00, $00
    .byte $0F, $00, $00, $00

;; ============================================================
;; PPU helper: set VRAM address
;; A = high byte, X = low byte
;; ============================================================
.proc ppu_set_addr
    bit PPUSTATUS
    sta PPUADDR
    stx PPUADDR
    rts
.endproc

;; ============================================================
;; Clear nametable at $2000
;; ============================================================
.proc clear_nametable
    lda #$20
    ldx #$00
    jsr ppu_set_addr

    lda #TILE_BLANK
    ldy #$04          ; 4 * 256 = 1024 bytes
    ldx #$00
@outer:
    sta PPUDATA
    inx
    bne @outer
    dey
    bne @outer
    rts
.endproc

;; ============================================================
;; Write a string to PPU
;; temp+0/+1 = string address, temp+2/+3 = PPU address
;; String is zero-terminated
;; ============================================================
.proc write_string
    lda temp+3        ; PPU addr high
    ldx temp+2        ; PPU addr low
    jsr ppu_set_addr

    ldy #$00
@loop:
    lda (temp), y
    beq @done
    sta PPUDATA
    iny
    bne @loop
@done:
    rts
.endproc

;; ============================================================
;; Write hand tiles at PPU address in temp+2/+3
;; A = hand type (0=rock, 1=scissors, 2=paper)
;; ============================================================
.proc draw_hand
    ; Calculate base tile: rock=$40, scis=$44, paper=$48
    asl a              ; *2
    asl a              ; *4
    clc
    adc #$40
    sta temp           ; base tile

    ; Draw top row (2 tiles)
    lda temp+3
    ldx temp+2
    jsr ppu_set_addr

    lda temp
    sta PPUDATA
    clc
    adc #$01
    sta PPUDATA

    ; Draw bottom row (2 tiles), 32 bytes ahead in nametable
    lda temp+2
    clc
    adc #$20
    sta temp+2
    lda temp+3
    adc #$00
    tax
    lda temp+3
    adc #$00
    jsr ppu_set_addr

    ; Recalculate because we need to set addr properly
    lda temp+3
    sta PPUADDR
    lda temp+2
    sta PPUADDR

    lda temp
    clc
    adc #$02
    sta PPUDATA
    adc #$01
    sta PPUDATA

    ; Restore temp+2
    lda temp+2
    sec
    sbc #$20
    sta temp+2
    rts
.endproc

;; ============================================================
;; Set attribute for a 2x2 tile area
;; temp+2/+3 = base nametable position
;; A = palette number (0-3)
;; ============================================================
.proc set_attribute_area
    ; Simplified: just set a full attribute byte
    ; This is approximate but works for our layout
    rts
.endproc

;; ============================================================
;; Play sound effect
;; A = sound type: 0=cursor, 1=confirm, 2=win, 3=lose, 4=draw
;; ============================================================
.proc play_sfx
    cmp #$00
    beq @cursor_sfx
    cmp #$01
    beq @confirm_sfx
    cmp #$02
    beq @win_sfx
    cmp #$03
    beq @lose_sfx
    cmp #$04
    beq @draw_sfx
    rts

@cursor_sfx:
    lda #%10000001       ; duty 50%, no loop, short
    sta APU_PULSE1_CTRL
    lda #$C0
    sta APU_PULSE1_LO
    lda #$08
    sta APU_PULSE1_HI
    rts

@confirm_sfx:
    lda #%10000010       ; duty 50%, medium
    sta APU_PULSE1_CTRL
    lda #$80
    sta APU_PULSE1_LO
    lda #$08
    sta APU_PULSE1_HI
    rts

@win_sfx:
    lda #%10000100       ; longer duration
    sta APU_PULSE1_CTRL
    lda #$40
    sta APU_PULSE1_LO    ; higher pitch
    lda #$08
    sta APU_PULSE1_HI
    rts

@lose_sfx:
    lda #%10000100
    sta APU_PULSE1_CTRL
    lda #$00
    sta APU_PULSE1_LO    ; lower pitch
    lda #$09
    sta APU_PULSE1_HI
    rts

@draw_sfx:
    lda #%10000010
    sta APU_PULSE1_CTRL
    lda #$A0
    sta APU_PULSE1_LO
    lda #$08
    sta APU_PULSE1_HI
    rts
.endproc

;; ============================================================
;; TITLE SCREEN
;; ============================================================
.proc draw_title_screen
    ; Disable rendering for bulk update
    lda #$00
    sta PPUMASK

    jsr clear_nametable

    ; --- Draw decorative border top ---
    lda #$20
    sta PPUADDR
    lda #$42
    sta PPUADDR
    lda #TILE_CORNER_TL
    sta PPUDATA
    ldx #$1A
@top_border:
    lda #TILE_HLINE_T
    sta PPUDATA
    dex
    bne @top_border
    lda #TILE_CORNER_TR
    sta PPUDATA

    ; Side borders (rows 2-25)
    ldx #$02
@side_loop:
    txa
    pha

    ; Calculate nametable address for this row
    ; Row X: addr = $2000 + X*32
    ; $2000 + X*32 = $2000 + X*$20
    lda #$20
    sta temp+3
    txa
    asl a             ; *2
    asl a             ; *4
    asl a             ; *8
    asl a             ; *16
    asl a             ; *32
    clc
    adc #$02
    sta temp+2
    lda temp+3
    adc #$00
    sta temp+3

    ; Left border
    lda temp+3
    sta PPUADDR
    lda temp+2
    sta PPUADDR
    lda #TILE_VLINE_L
    sta PPUDATA

    ; Right border (offset +$1B = +27 from left)
    lda temp+2
    clc
    adc #$1B
    sta temp+2
    lda temp+3
    adc #$00
    sta temp+3

    lda temp+3
    sta PPUADDR
    lda temp+2
    sta PPUADDR
    lda #TILE_VLINE_R
    sta PPUDATA

    pla
    tax
    inx
    cpx #$1A
    bne @side_loop

    ; Bottom border
    lda #$23
    sta PPUADDR
    lda #$42
    sta PPUADDR
    lda #TILE_CORNER_BL
    sta PPUDATA
    ldx #$1A
@bot_border:
    lda #TILE_HLINE_B
    sta PPUDATA
    dex
    bne @bot_border
    lda #TILE_CORNER_BR
    sta PPUDATA

    ; --- Title "YAKYUKEN" at row 6, centered ---
    lda #$20
    sta PPUADDR
    lda #$CC            ; row 6, col 12
    sta PPUADDR
    lda #TILE_Y
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_K
    sta PPUDATA
    lda #TILE_Y
    sta PPUDATA
    lda #TILE_U
    sta PPUDATA
    lda #TILE_K
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_N
    sta PPUDATA

    ; --- Stars around title ---
    lda #$20
    sta PPUADDR
    lda #$CA
    sta PPUADDR
    lda #TILE_STAR
    sta PPUDATA

    lda #$20
    sta PPUADDR
    lda #$D5
    sta PPUADDR
    lda #TILE_STAR
    sta PPUDATA

    ; --- Subtitle row 9: "JANKEN GAME" ---
    lda #$21
    sta PPUADDR
    lda #$2B            ; row 9, col 11
    sta PPUADDR
    lda #TILE_J
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_N
    sta PPUDATA
    lda #TILE_K
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_N
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_G
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_M
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA

    ; --- Show hand previews row 12 ---
    ; Rock at col 5
    lda #$21
    sta PPUADDR
    lda #$85
    sta PPUADDR
    lda #TILE_ROCK_TL
    sta PPUDATA
    lda #TILE_ROCK_TR
    sta PPUDATA
    lda #$21
    sta PPUADDR
    lda #$A5
    sta PPUADDR
    lda #TILE_ROCK_BL
    sta PPUDATA
    lda #TILE_ROCK_BR
    sta PPUDATA

    ; Scissors at col 14
    lda #$21
    sta PPUADDR
    lda #$8E
    sta PPUADDR
    lda #TILE_SCIS_TL
    sta PPUDATA
    lda #TILE_SCIS_TR
    sta PPUDATA
    lda #$21
    sta PPUADDR
    lda #$AE
    sta PPUADDR
    lda #TILE_SCIS_BL
    sta PPUDATA
    lda #TILE_SCIS_BR
    sta PPUDATA

    ; Paper at col 23
    lda #$21
    sta PPUADDR
    lda #$97
    sta PPUADDR
    lda #TILE_PAPER_TL
    sta PPUDATA
    lda #TILE_PAPER_TR
    sta PPUDATA
    lda #$21
    sta PPUADDR
    lda #$B7
    sta PPUADDR
    lda #TILE_PAPER_BL
    sta PPUDATA
    lda #TILE_PAPER_BR
    sta PPUDATA

    ; --- "PRESS START" at row 20, centered ---
    lda #$22
    sta PPUADDR
    lda #$8B            ; row 20, col 11
    sta PPUADDR
    lda #TILE_P
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_T
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_T
    sta PPUDATA

    ; --- Set attributes for title area ---
    ; Set attribute table for palette colors
    ; Attribute table starts at $23C0 for nametable $2000
    ; Each byte covers a 4x4 tile area (32x32 pixels)
    ; We'll set some areas to different palettes for color
    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    ; Row 0-3 (top border): palette 0
    ldx #$08
@attr_row0:
    lda #$00
    sta PPUDATA
    dex
    bne @attr_row0
    ; Row 4-7 (title): palette 3 (green)
    ldx #$08
@attr_row1:
    lda #$FF            ; palette 3 for all quadrants
    sta PPUDATA
    dex
    bne @attr_row1
    ; Row 8-11 (subtitle): palette 0
    ldx #$08
@attr_row2:
    lda #$00
    sta PPUDATA
    dex
    bne @attr_row2
    ; Row 12-15 (hands): palette 1 (warm)
    ldx #$08
@attr_row3:
    lda #$55            ; palette 1 for all quadrants
    sta PPUDATA
    dex
    bne @attr_row3
    ; Row 16-19: palette 0
    ldx #$08
@attr_row4:
    lda #$00
    sta PPUDATA
    dex
    bne @attr_row4
    ; Row 20-23 (press start): palette 3
    ldx #$08
@attr_row5:
    lda #$FF
    sta PPUDATA
    dex
    bne @attr_row5
    ; Row 24-27 (bottom border): palette 0
    ldx #$08
@attr_row6:
    lda #$00
    sta PPUDATA
    dex
    bne @attr_row6
    ; Row 28-29
    ldx #$08
@attr_row7:
    lda #$00
    sta PPUDATA
    dex
    bne @attr_row7

    ; Re-enable rendering
    lda #%00001110
    sta PPUMASK
    rts
.endproc

;; ============================================================
;; TITLE SCREEN update
;; ============================================================
.proc update_title
    ; Blink "PRESS START" by toggling visibility every 32 frames
    lda frame_counter
    and #$20
    beq @show_text

    ; Hide text - write blanks at row 20
    lda #$22
    sta PPUADDR
    lda #$8B
    sta PPUADDR
    ldx #$0B
@hide_loop:
    lda #TILE_BLANK
    sta PPUDATA
    dex
    bne @hide_loop
    jmp @check_input

@show_text:
    lda #$22
    sta PPUADDR
    lda #$8B
    sta PPUADDR
    lda #TILE_P
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_T
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_T
    sta PPUDATA

@check_input:
    ; Reset scroll after PPUADDR writes
    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL

    ; Check Start button
    lda pad_new
    and #BTN_START
    beq @done

    ; Transition to select screen
    lda #$01
    jsr play_sfx        ; confirm sound
    lda #STATE_SELECT
    sta game_state
    lda #$00
    sta cursor_pos
    jsr draw_select_screen
@done:
    rts
.endproc

;; ============================================================
;; SELECT SCREEN - draw
;; ============================================================
.proc draw_select_screen
    lda #$00
    sta PPUMASK          ; disable rendering

    jsr clear_nametable

    ; --- "ERABE!" (Choose!) at row 3 ---
    lda #$20
    sta PPUADDR
    lda #$6D            ; row 3, col 13
    sta PPUADDR
    lda #TILE_E
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_B
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_EXCL
    sta PPUDATA

    ; --- Choice 0: "GU-" (Rock) at row 8 ---
    ; Arrow + space + GU- + space + hand
    lda #$21
    sta PPUADDR
    lda #$06            ; row 8, col 6
    sta PPUADDR
    lda #TILE_ARROW     ; cursor (will be managed)
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_GU
    sta PPUDATA
    lda #TILE_CHOU
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    ; Hand graphic
    lda #TILE_ROCK_TL
    sta PPUDATA
    lda #TILE_ROCK_TR
    sta PPUDATA
    ; Bottom row of hand
    lda #$21
    sta PPUADDR
    lda #$2B            ; row 9, col 11
    sta PPUADDR
    lda #TILE_ROCK_BL
    sta PPUDATA
    lda #TILE_ROCK_BR
    sta PPUDATA

    ; --- Choice 1: "CHOKI" (Scissors) at row 12 ---
    lda #$21
    sta PPUADDR
    lda #$86            ; row 12, col 6
    sta PPUADDR
    lda #TILE_BLANK     ; no arrow initially
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_CHI
    sta PPUDATA
    lda #TILE_SYO
    sta PPUDATA
    lda #TILE_KI
    sta PPUDATA
    ; Hand graphic
    lda #TILE_SCIS_TL
    sta PPUDATA
    lda #TILE_SCIS_TR
    sta PPUDATA
    ; Bottom row
    lda #$21
    sta PPUADDR
    lda #$AB            ; row 13, col 11
    sta PPUADDR
    lda #TILE_SCIS_BL
    sta PPUDATA
    lda #TILE_SCIS_BR
    sta PPUDATA

    ; --- Choice 2: "PA-" (Paper) at row 16 ---
    lda #$22
    sta PPUADDR
    lda #$06            ; row 16, col 6
    sta PPUADDR
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_PA
    sta PPUDATA
    lda #TILE_CHOU
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    ; Hand graphic
    lda #TILE_PAPER_TL
    sta PPUDATA
    lda #TILE_PAPER_TR
    sta PPUDATA
    ; Bottom row
    lda #$22
    sta PPUADDR
    lda #$2B            ; row 17, col 11
    sta PPUADDR
    lda #TILE_PAPER_BL
    sta PPUDATA
    lda #TILE_PAPER_BR
    sta PPUDATA

    ; --- Score display at row 24 ---
    ; "P:0  C:0"
    lda #$23
    sta PPUADDR
    lda #$07            ; row 24, col 7
    sta PPUADDR
    lda #TILE_P
    sta PPUDATA
    lda #TILE_COLON
    sta PPUDATA
    lda player_score
    clc
    adc #TILE_0
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_VS
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_C
    sta PPUDATA
    lda #TILE_COLON
    sta PPUDATA
    lda cpu_score
    clc
    adc #TILE_0
    sta PPUDATA

    ; --- Set attributes ---
    ; Hands: palette 1, text: palette 0, score: palette 3
    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    ; Simple: palette 0 for most, palette 1 for hand areas
    ldx #$40
@attr_fill:
    lda #$00
    sta PPUDATA
    dex
    bne @attr_fill

    ; Re-enable rendering
    lda #%00001110
    sta PPUMASK
    rts
.endproc

;; ============================================================
;; SELECT SCREEN update
;; ============================================================
.proc update_select
    ; Handle D-pad Up
    lda pad_new
    and #BTN_UP
    beq @check_down
    lda cursor_pos
    beq @check_a         ; already at top
    dec cursor_pos
    lda #$00
    jsr play_sfx         ; cursor sound
    jsr redraw_cursor
    jmp @check_a

@check_down:
    lda pad_new
    and #BTN_DOWN
    beq @check_a
    lda cursor_pos
    cmp #$02
    beq @check_a         ; already at bottom
    inc cursor_pos
    lda #$00
    jsr play_sfx
    jsr redraw_cursor

@check_a:
    ; Check A button
    lda pad_new
    and #BTN_A
    beq @done

    ; Player made choice
    lda cursor_pos
    sta player_choice
    lda #$01
    jsr play_sfx         ; confirm sound

    ; Generate CPU choice
    jsr random
    ; Simple modulo 3: keep subtracting 3
    and #$07             ; 0-7
@mod3:
    cmp #$03
    bcc @mod3_done
    sec
    sbc #$03
    jmp @mod3
@mod3_done:
    ; If result is still >= 3 (shouldn't be), force 0
    cmp #$03
    bcc @store_cpu
    lda #$00
@store_cpu:
    sta cpu_choice

    ; Transition to reveal
    lda #STATE_REVEAL
    sta game_state
    lda #$00
    sta reveal_step
    sta anim_timer
    jsr draw_reveal_screen

@done:
    rts
.endproc

;; ============================================================
;; Redraw cursor on select screen
;; ============================================================
.proc redraw_cursor
    ; Clear all cursor positions, then draw at current

    ; Row 8 col 6 ($2106)
    lda #$21
    sta PPUADDR
    lda #$06
    sta PPUADDR
    lda #TILE_BLANK
    sta PPUDATA

    ; Row 12 col 6 ($2186)
    lda #$21
    sta PPUADDR
    lda #$86
    sta PPUADDR
    lda #TILE_BLANK
    sta PPUDATA

    ; Row 16 col 6 ($2206)
    lda #$22
    sta PPUADDR
    lda #$06
    sta PPUADDR
    lda #TILE_BLANK
    sta PPUDATA

    ; Draw arrow at cursor position
    lda cursor_pos
    cmp #$00
    beq @pos0
    cmp #$01
    beq @pos1
    ; pos2
    lda #$22
    sta PPUADDR
    lda #$06
    sta PPUADDR
    jmp @draw_arrow
@pos0:
    lda #$21
    sta PPUADDR
    lda #$06
    sta PPUADDR
    jmp @draw_arrow
@pos1:
    lda #$21
    sta PPUADDR
    lda #$86
    sta PPUADDR

@draw_arrow:
    lda #TILE_ARROW
    sta PPUDATA

    ; Reset scroll
    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL
    rts
.endproc

;; ============================================================
;; Draw a 3x3 tile face
;; temp+0/+1 = pointer to 9-byte tile index table
;; temp+2/+3 = PPU address (low/high)
;; ============================================================
.proc draw_face
    ; Row 0 (tiles 0,1,2)
    lda temp+3
    sta PPUADDR
    lda temp+2
    sta PPUADDR
    ldy #$00
    lda (temp), y
    sta PPUDATA
    iny
    lda (temp), y
    sta PPUDATA
    iny
    lda (temp), y
    sta PPUDATA

    ; Advance to next nametable row (+32)
    lda temp+2
    clc
    adc #$20
    sta temp+2
    lda temp+3
    adc #$00
    sta temp+3

    ; Row 1 (tiles 3,4,5)
    lda temp+3
    sta PPUADDR
    lda temp+2
    sta PPUADDR
    iny
    lda (temp), y
    sta PPUDATA
    iny
    lda (temp), y
    sta PPUDATA
    iny
    lda (temp), y
    sta PPUDATA

    ; Advance to next row
    lda temp+2
    clc
    adc #$20
    sta temp+2
    lda temp+3
    adc #$00
    sta temp+3

    ; Row 2 (tiles 6,7,8)
    lda temp+3
    sta PPUADDR
    lda temp+2
    sta PPUADDR
    iny
    lda (temp), y
    sta PPUDATA
    iny
    lda (temp), y
    sta PPUDATA
    iny
    lda (temp), y
    sta PPUDATA
    rts
.endproc

;; Face tile lookup tables (9 tiles each: top/eyes/mouth rows)
player_face_happy:
    .byte TILE_P_TOP0, TILE_P_TOP1, TILE_P_TOP2
    .byte TILE_P_HEYE0, TILE_P_HEYE1, TILE_P_HEYE2
    .byte TILE_P_HMTH0, TILE_P_HMTH1, TILE_P_HMTH2
player_face_sad:
    .byte TILE_P_TOP0, TILE_P_TOP1, TILE_P_TOP2
    .byte TILE_P_SEYE0, TILE_P_SEYE1, TILE_P_SEYE2
    .byte TILE_P_SMTH0, TILE_P_SMTH1, TILE_P_SMTH2
cpu_face_happy:
    .byte TILE_C_TOP0, TILE_C_TOP1, TILE_C_TOP2
    .byte TILE_C_HEYE0, TILE_C_HEYE1, TILE_C_HEYE2
    .byte TILE_C_HMTH0, TILE_C_HMTH1, TILE_C_HMTH2
cpu_face_sad:
    .byte TILE_C_TOP0, TILE_C_TOP1, TILE_C_TOP2
    .byte TILE_C_SEYE0, TILE_C_SEYE1, TILE_C_SEYE2
    .byte TILE_C_SMTH0, TILE_C_SMTH1, TILE_C_SMTH2

;; Attribute table for reveal screen (64 bytes)
attr_reveal:
    .byte $00,$55,$00,$00,$00,$00,$AA,$00  ; row 0 (tiles 0-3): labels
    .byte $00,$55,$00,$00,$00,$00,$AA,$00  ; row 1 (tiles 4-7): faces
    .byte $00,$55,$00,$00,$00,$00,$AA,$00  ; row 2 (tiles 8-11): hands+names
    .byte $00,$00,$F0,$F0,$F0,$F0,$00,$00  ; row 3 (tiles 12-15): result text
    .byte $00,$00,$00,$00,$00,$00,$00,$00  ; row 4 (tiles 16-19): score
    .byte $00,$00,$00,$F0,$F0,$00,$00,$00  ; row 5 (tiles 20-23): PRESS A
    .byte $00,$00,$00,$00,$00,$00,$00,$00  ; row 6
    .byte $00,$00,$00,$00,$00,$00,$00,$00  ; row 7

;; Lookup tables for hand tiles
hand_tile_tl: .byte TILE_ROCK_TL, TILE_SCIS_TL, TILE_PAPER_TL
hand_tile_tr: .byte TILE_ROCK_TR, TILE_SCIS_TR, TILE_PAPER_TR
hand_tile_bl: .byte TILE_ROCK_BL, TILE_SCIS_BL, TILE_PAPER_BL
hand_tile_br: .byte TILE_ROCK_BR, TILE_SCIS_BR, TILE_PAPER_BR

;; ============================================================
;; REVEAL SCREEN - draw (with character CG)
;; ============================================================
.proc draw_reveal_screen
    lda #$00
    sta PPUMASK
    jsr clear_nametable

    ; --- Determine result first (for face expressions) ---
    lda player_choice
    cmp cpu_choice
    beq @is_draw
    lda player_choice
    cmp #$00
    bne @chk1
    lda cpu_choice
    cmp #$01
    beq @is_win
    jmp @is_lose
@chk1:
    lda player_choice
    cmp #$01
    bne @chk2
    lda cpu_choice
    cmp #$02
    beq @is_win
    jmp @is_lose
@chk2:
    lda cpu_choice
    cmp #$00
    beq @is_win
    jmp @is_lose
@is_draw:
    lda #$00
    sta result
    jmp @begin_draw
@is_win:
    lda #$01
    sta result
    inc player_score
    jmp @begin_draw
@is_lose:
    lda #$02
    sta result
    inc cpu_score

@begin_draw:
    ; --- "YOU" at row 2, col 5 ---
    lda #$20
    sta PPUADDR
    lda #$45
    sta PPUADDR
    lda #TILE_Y
    sta PPUDATA
    lda #TILE_O
    sta PPUDATA
    lda #TILE_U
    sta PPUDATA

    ; "VS" at row 2, col 15
    lda #$20
    sta PPUADDR
    lda #$4F
    sta PPUADDR
    lda #TILE_V
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA

    ; "CPU" at row 2, col 24
    lda #$20
    sta PPUADDR
    lda #$58
    sta PPUADDR
    lda #TILE_C
    sta PPUDATA
    lda #TILE_P
    sta PPUDATA
    lda #TILE_U
    sta PPUDATA

    ; --- Draw player face CG at row 4, col 4 ---
    lda result
    cmp #$02
    beq @p_sad
    lda #<player_face_happy
    sta temp
    lda #>player_face_happy
    sta temp+1
    jmp @do_p_face
@p_sad:
    lda #<player_face_sad
    sta temp
    lda #>player_face_sad
    sta temp+1
@do_p_face:
    lda #$84              ; row 4, col 4
    sta temp+2
    lda #$20
    sta temp+3
    jsr draw_face

    ; --- Draw CPU face CG at row 4, col 24 ---
    lda result
    cmp #$01
    beq @c_sad
    lda #<cpu_face_happy
    sta temp
    lda #>cpu_face_happy
    sta temp+1
    jmp @do_c_face
@c_sad:
    lda #<cpu_face_sad
    sta temp
    lda #>cpu_face_sad
    sta temp+1
@do_c_face:
    lda #$98              ; row 4, col 24
    sta temp+2
    lda #$20
    sta temp+3
    jsr draw_face

    ; --- Player hand at row 8, col 4 ---
    lda #$21
    sta PPUADDR
    lda #$04
    sta PPUADDR
    ldx player_choice
    lda hand_tile_tl, x
    sta PPUDATA
    lda hand_tile_tr, x
    sta PPUDATA
    lda #$21
    sta PPUADDR
    lda #$24
    sta PPUADDR
    ldx player_choice
    lda hand_tile_bl, x
    sta PPUDATA
    lda hand_tile_br, x
    sta PPUDATA

    ; --- CPU hand at row 8, col 24 ---
    lda #$21
    sta PPUADDR
    lda #$18
    sta PPUADDR
    ldx cpu_choice
    lda hand_tile_tl, x
    sta PPUDATA
    lda hand_tile_tr, x
    sta PPUDATA
    lda #$21
    sta PPUADDR
    lda #$38
    sta PPUADDR
    ldx cpu_choice
    lda hand_tile_bl, x
    sta PPUDATA
    lda hand_tile_br, x
    sta PPUDATA

    ; --- Player choice name at row 11, col 4 ---
    lda #$21
    sta PPUADDR
    lda #$64
    sta PPUADDR
    jsr write_player_name

    ; --- CPU choice name at row 11, col 24 ---
    lda #$21
    sta PPUADDR
    lda #$78
    sta PPUADDR
    jsr write_cpu_name

    ; --- Result text at row 14 ---
    lda result
    cmp #$00
    bne @not_draw_txt
    jmp @txt_draw
@not_draw_txt:
    cmp #$01
    bne @txt_lose
    jmp @txt_win
@txt_lose:
    ; "YOU LOSE..." at row 14, col 10
    lda #$21
    sta PPUADDR
    lda #$CA
    sta PPUADDR
    lda #TILE_Y
    sta PPUDATA
    lda #TILE_O
    sta PPUDATA
    lda #TILE_U
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_L
    sta PPUDATA
    lda #TILE_O
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_DOT
    sta PPUDATA
    lda #TILE_DOT
    sta PPUDATA
    lda #TILE_DOT
    sta PPUDATA
    lda #$03
    jsr play_sfx
    jmp @draw_score

@txt_win:
    ; "YOU WIN!" at row 14, col 11
    lda #$21
    sta PPUADDR
    lda #$CB
    sta PPUADDR
    lda #TILE_Y
    sta PPUDATA
    lda #TILE_O
    sta PPUDATA
    lda #TILE_U
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_W
    sta PPUDATA
    lda #TILE_I
    sta PPUDATA
    lda #TILE_N
    sta PPUDATA
    lda #TILE_EXCL
    sta PPUDATA
    lda #$02
    jsr play_sfx
    jmp @draw_score

@txt_draw:
    ; "DRAW" at row 14, col 13
    lda #$21
    sta PPUADDR
    lda #$CD
    sta PPUADDR
    lda #TILE_D
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA
    lda #TILE_W
    sta PPUDATA
    lda #$04
    jsr play_sfx

@draw_score:
    ; Score at row 17, col 8
    lda #$22
    sta PPUADDR
    lda #$28
    sta PPUADDR
    lda #TILE_P
    sta PPUDATA
    lda #TILE_COLON
    sta PPUDATA
    lda player_score
    clc
    adc #TILE_0
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_VS
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_C
    sta PPUDATA
    lda #TILE_COLON
    sta PPUDATA
    lda cpu_score
    clc
    adc #TILE_0
    sta PPUDATA

    ; "PRESS A" at row 22, col 12
    lda #$22
    sta PPUADDR
    lda #$CC
    sta PPUADDR
    lda #TILE_P
    sta PPUDATA
    lda #TILE_R
    sta PPUDATA
    lda #TILE_E
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_S
    sta PPUDATA
    lda #TILE_BLANK
    sta PPUDATA
    lda #TILE_A
    sta PPUDATA

    ; --- Set attributes from table ---
    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    ldx #$00
@attr_loop:
    lda attr_reveal, x
    sta PPUDATA
    inx
    cpx #$40
    bne @attr_loop

    ; Set state to RESULT
    lda #STATE_RESULT
    sta game_state

    lda #%00001110
    sta PPUMASK
    rts
.endproc

;; Helper: write player choice name to PPU (address already set)
.proc write_player_name
    ldx player_choice
    cpx #$00
    beq @rock
    cpx #$01
    beq @scis
    lda #TILE_PA
    sta PPUDATA
    lda #TILE_CHOU
    sta PPUDATA
    rts
@rock:
    lda #TILE_GU
    sta PPUDATA
    lda #TILE_CHOU
    sta PPUDATA
    rts
@scis:
    lda #TILE_CHI
    sta PPUDATA
    lda #TILE_SYO
    sta PPUDATA
    lda #TILE_KI
    sta PPUDATA
    rts
.endproc

;; Helper: write CPU choice name to PPU (address already set)
.proc write_cpu_name
    ldx cpu_choice
    cpx #$00
    beq @rock
    cpx #$01
    beq @scis
    lda #TILE_PA
    sta PPUDATA
    lda #TILE_CHOU
    sta PPUDATA
    rts
@rock:
    lda #TILE_GU
    sta PPUDATA
    lda #TILE_CHOU
    sta PPUDATA
    rts
@scis:
    lda #TILE_CHI
    sta PPUDATA
    lda #TILE_SYO
    sta PPUDATA
    lda #TILE_KI
    sta PPUDATA
    rts
.endproc

;; ============================================================
;; REVEAL SCREEN update (animation phase)
;; ============================================================
.proc update_reveal
    ; Currently we skip animation and go straight to result
    ; The draw_reveal_screen already sets state to RESULT
    rts
.endproc

;; ============================================================
;; RESULT SCREEN update
;; ============================================================
.proc update_result
    ; Wait for A button to go back to select
    lda pad_new
    and #BTN_A
    beq @done

    lda #$01
    jsr play_sfx         ; confirm sound

    ; Check if score reached 9 - reset
    lda player_score
    cmp #$0A
    bcs @reset_score
    lda cpu_score
    cmp #$0A
    bcs @reset_score
    jmp @go_select

@reset_score:
    lda #$00
    sta player_score
    sta cpu_score

@go_select:
    lda #STATE_SELECT
    sta game_state
    lda #$00
    sta cursor_pos
    jsr draw_select_screen
@done:
    rts
.endproc

;; ============================================================
;; Interrupt Vectors
;; ============================================================
.segment "VECTORS"
    .addr nmi
    .addr reset
    .addr irq

;; ============================================================
;; CHR ROM - include binary tile data
;; ============================================================
.segment "TILES"
    .incbin "chr.bin"
