# ------------------------------------------------------------------
# Student Information
# ------------------------------------------------------------------
# Lab number            : 4
# Group number          : 22
# Section number        : 1269
# Student-1 name        : Akishai Sabaratnasarma
# Student-2 name        : Sheehan Lloyd
# ------------------------------------------------------------------
# -------------- YOUR CODE MUST BE WELL COMMENTED ------------------
# -------------- YOU MAY REMOVE UNNECESSARY COMMENTS ---------------
# ------------------------------------------------------------------


# Register allocation
# t0  GPIO and PLIC base addresses
# t1  scratch for masks while setting up, then the claim id inside the ISR
# t2 t3  scratch while setting up the control registers
# s0  the 0x00 to 0xFF counter shown on the LED bar
# s1  the 4 bit counter shown on the seven segment, only the ISR writes it
# a0  argument into DISPLAY_BYTE, DISPLAY_7SEG and Delay, scratch in the ISR
# t2 t4 t5  scratch inside the subroutines
#
# The main program owns s0 and the ISR owns s1, so neither can corrupt the other's
# count. Everything else the ISR touches it saves and restores, temporaries and
# argument registers included, because the interrupted code saved nothing itself.

.section .text
.align 2
.globl _start
.globl Lab_4

# --------------------------------------------------------------------------------------------------------------
# Constants and Register Definitions
# --------------------------------------------------------------------------------------------------------------

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000   # base address for the GPIO control registers
    .equ GPIO_INPUT_VAL, 0x00   # offset to read what the pins are doing
    .equ GPIO_INPUT_EN, 0x04   # offset to enable GPIO inputs
    .equ GPIO_OUTPUT_EN, 0x08   # offset to enable GPIO outputs
    .equ GPIO_OUTPUT_VAL, 0x0C   # offset to write GPIO outputs
    .equ GPIO_PUE, 0x10   # offset to turn on the internal pull up resistors
    .equ GPIO_FALL_IE, 0x20   # offset to arm the falling edge interrupt on a pin
    .equ GPIO_FALL_IP, 0x24   # offset for the falling edge pending flag, write a 1 to clear it
    .equ GPIO_IOF_EN, 0x38   # offset that hands a pin over to a hardware function

    .equ GPIO_7SEGLED_PINS, 0x0000023F   # the 7 seven segment display pins
    .equ GPIO_LEDBAR_PINS, 0x00FC0C00   # the 8 LED bar pins, bits 10 11 and 18 to 23
    .equ GPIO_ALL_LED_PINS, 0x00FC0E3F   # all 15 LED pins together
    .equ GPIO_PB_S1, 0x00001000   # pushbutton S1, bit 12
    .equ GPIO_PB_S2, 0x00002000   # pushbutton S2, bit 13
    .equ GPIO_PB_BOTH, 0x00003000   # both buttons together
    .equ GPIO_SW_PINS, 0x00FC3E3F   # every pin we drive or read, the LEDs and both buttons

# ------------------------------- PLIC MEMORY MAPPING -------------------------------
# A press passes three gates before the CPU sees it, the GPIO edge detect, the PLIC
# and the CPU, and a miss at any one of them is silent.
#
# Table 24 of the SiFive manual maps GPIO pin n onto PLIC source 8 + n.
    .equ PLIC_BASE_ADDR, 0x0C000000   # base address for the PLIC registers
    .equ PLIC_ENABLE_ADDR, 0x0C002000   # hart 0 M mode enable bits for sources 0 to 31
    .equ PLIC_THRESHOLD_ADDR, 0x0C200000   # hart 0 M mode priority threshold
    .equ PLIC_CLAIM_ADDR, 0x0C200004   # read to claim an interrupt, write back to complete it

    .equ S1_PLIC_ID, 20   # GPIO 12 is PLIC source 8 + 12
    .equ S2_PLIC_ID, 21   # GPIO 13 is PLIC source 8 + 13
    .equ S1_PRIORITY_ADDR, PLIC_BASE_ADDR + 4 * S1_PLIC_ID   # 0x0C000050
    .equ S2_PRIORITY_ADDR, PLIC_BASE_ADDR + 4 * S2_PLIC_ID   # 0x0C000054

    .equ PLIC_PRIORITY_HIGHEST, 7   # 7 is the top of the 7 priority levels, 0 means never interrupt
    .equ PLIC_THRESHOLD_LEVEL, 6   # the PLIC masks anything at or below the threshold, so only 7 gets through

# ---------------------------- TIMING CONSTANTS ---------------------
# The board runs at 16 MHz so one second is 16,000,000 clock cycles.
# Every wait is counted in 0.1 msec ticks, so there is only ever one constant
# to calibrate and every other delay is just a multiple of it.
#
# 0.1 msec is 16,000,000 x 0.0001 = 1600 cycles.
# The inner loop is an ADDI and a BNEZ which is 2 cycles a pass, and each tick
# costs another 3 cycles for the LI, the ADDI and the BNEZ in the outer loop.
# 2 x TICK_LOOPS + 3 = 1600 gives 798.5 so we round up to 799.
#
# That is the theoretical figure. Measured on the board in Lab 3, the counter took
# 12.6 sec to go from 0x00 to 0x80, which is 128 steps, so a step was 98.4 msec
# instead of 100 msec. Scaling 799 by 12.8 / 12.6 gives 812, which is what we use.
    .equ TICK_LOOPS, 812   # inner passes that add up to one 0.1 msec tick, measured
    .equ TICKS_0_1_SEC, 1000   # 0.1 sec is 1000 ticks

_start:
Lab_4:                                    # _start and Lab_4 are the same instruction

# Set up mtvec with the address of the interrupt vector (Buttons_ISR)
      la t0, Buttons_ISR                  # Load the address of the interrupt handler 'Buttons_ISR' into t0
                                          # Buttons_ISR represents the Interrupt Service Routine (ISR) found at the bottom of the code
      csrw mtvec, t0                      # csrw: CSR write,  writes the value in register t0 (which is the 
                                          # address of the interrupt handler) to the mtvec register.                        
                                          # Set the mtvec register to the address in t0 (Buttons_ISR)
# Enable "External" machine interrupts in the mie register
      li t0, (1 << 11)                    # Set bit 11 to "1" and write it to t0
                                          # This bit (bit 11) corresponds to the external interrupt enable
      csrs mie, t0                        # csrs: CSR Set, it performs a bitwise OR between the current 
                                          # value of mie and the value in t0
                                          # Set bit 11 in the mie register (enable external interrupts)
# mtvec: Machine Trap Vector register, it stores the address of the interrupt handler
# directing the processor to jump to this address, Buttons_ISR, when an interrupt occurs.

# Enable global machine interrupts (MIE, bit 3 of mstatus)
      csrr t0, mstatus                    # read the value of the mstatus into t0
      li t1, (1 << 3)                     # Set MIE (Machine Interrupt Enable)
                                          # (1<<3): this instruction puts "1" at the 3rd bit 
      or t0, t0, t1                       # add t0 "mstatus" to t1, where we actually are setting bit 3 to "1"
                                          # This sets the 3rd bit (MIE) in t0 without modifying other bits
      csrw mstatus, t0                    # Write the modified value in t0 back to the mstatus register

# ------------------------------Configure SW1 as an input------------------------------

    # Put the GPIO base address in t0, every access below is an offset from it
    li t0, GPIO_BASE_CTRL_ADDR
    # a pin handed to a hardware function ignores our writes, so take ours back first
    li t1, GPIO_SW_PINS
    not t2, t1
    lw t3, GPIO_IOF_EN(t0)
    and t3, t3, t2
    sw t3, GPIO_IOF_EN(t0)
    # t1 selects both pushbuttons, we mask off the one we want when we read
    li t1, GPIO_PB_BOTH
    # A 1 in INPUT_EN lets us read that pin. the button bits are deliberately left out
    # of OUTPUT_EN, a pressed button ties the pin to ground so driving it would short
    sw t1, GPIO_INPUT_EN(t0)
    # the pull up holds the pin at 3.3V while the button is open, which is what makes
    # it read 1 when it is not pressed, so a press shows up as a falling edge
    sw t1, GPIO_PUE(t0)

# -----------------------Configure GPIO LEDs pins as an output-------------------------

    # t1 selects all 15 pins connected to LEDs
    li t1, GPIO_ALL_LED_PINS
    # A 1 in OUTPUT_EN makes that GPIO pin an output
    sw t1, GPIO_OUTPUT_EN(t0)

# ----------------------------Turn Off all LEDs in LED Bar-----------------------------

    # clear only the LED bits, the buttons are inputs and must not be driven
    not t2, t1
    lw t3, GPIO_OUTPUT_VAL(t0)
    and t3, t3, t2
    sw t3, GPIO_OUTPUT_VAL(t0)



# ------------Enable Falling edge for S1: Remember S1 is a GPIO and not PLIC-----------

    # the pull up holds each button high while it is open, so pressing one pulls its
    # pin down and that 1 to 0 transition is the falling edge. arming the release
    # instead would fire the ISR when the user lets go, which is not what the lab asks
    # for. for Step 2 on its own this would be GPIO_PB_S1, Step 3 arms both
    li t1, GPIO_PB_BOTH
    sw t1, GPIO_FALL_IE(t0)

# ----------------------------Enable PLIC for S1 interrupt-----------------------------

    # the enable register is a bit per source, so S1 is bit 20 and S2 is bit 21 of the
    # word at PLIC_ENABLE_ADDR. we write the mask outright rather than ORing it in,
    # the reset value of this register is undefined and these are the only two sources
    # we ever want delivered
    li t1, PLIC_ENABLE_ADDR
    li t2, (1 << S1_PLIC_ID) | (1 << S2_PLIC_ID)
    sw t2, 0(t1)

# ----------------Set PLIC priority for S1 interrupt to 7 "Highest Priority"-----------
# -----------The address is calculated according to: PLIC_BASE + 4 × S1_PLIC_ID--------

    # every source has its own priority register, laid out as one word each starting
    # at the PLIC base, so S1 at source 20 lives at base + 80 and S2 at base + 84.
    # leaving either at its reset value would be fatal, a priority of 0 means never
    # interrupt, so a button configured everywhere else would still stay silent
    li t2, PLIC_PRIORITY_HIGHEST
    li t1, S1_PRIORITY_ADDR
    sw t2, 0(t1)
    li t1, S2_PRIORITY_ADDR
    sw t2, 0(t1)

# -------------------------------Set PLIC threshold to 6-------------------------------

    # the PLIC masks every source whose priority is less than or equal to the
    # threshold, so a threshold of 6 lets priority 7 through and nothing else
    li t1, PLIC_THRESHOLD_ADDR
    li t2, PLIC_THRESHOLD_LEVEL
    sw t2, 0(t1)


main_program:
# ----------   Code developped in Lab-3 task-1   ----------------
# -- 8-bits counter incremented every 0.1 second shown on LEDs --

    # s0 holds the 8 bit counter, it survives the calls below because it is callee
    # saved and none of the subroutines write to it
    li s0, 0x00

    # s1 is the 4 bit counter the ISR owns. seeding it here and showing it once means
    # the display reads 0 before the first press instead of sitting blank, which also
    # proves the seven segment is wired up before any interrupt is involved
    li s1, 0x00
    mv a0, s1
    jal ra, DISPLAY_7SEG

Main_Loop:
    # the counter goes to the LED bar only. once interrupts are armed the seven
    # segment belongs to the ISR, so writing it from here would wipe whatever digit
    # the last press put up, ten times a second
    mv a0, s0
    jal ra, DISPLAY_BYTE

    # Step 1 also showed the upper nibble on the seven segment from this loop.
    # uncomment the two lines below and the display tracks the counter again
    # srli a0, s0, 4
    # jal ra, DISPLAY_7SEG

    # hold the value for 0.1 second before moving on
    li a0, TICKS_0_1_SEC
    jal ra, Delay

    addi s0, s0, 1
    # keeping only the low 8 bits wraps 0xFF back round to 0x00 for us
    andi s0, s0, 0xFF
    j Main_Loop


# Interrupt Service Routine (ISR) for S1 and S2 pushbuttons
# In Step-2, only steup S1. In Step-3, setup both S1 and S2.  
.align 2                                  # mtvec needs the handler on a 4 byte boundary
Buttons_ISR:
# ----------------------------- Save Registers to Stack -----------------------------

    # the main program got no warning that this would run, so the calling convention
    # protects nothing and every register used here has to come back as it was.
    # s1 is the deliberate exception, its new value is the point of the interrupt
    addi sp, sp, -16
    sw ra, 0(sp)   # DISPLAY_7SEG is reached with jal, which overwrites ra
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw a0, 12(sp)

# -------------------------- Acknowledge Interrupt in PLIC --------------------------

    # reading the claim register hands the interrupt to us and returns the id of the
    # source. t1 holds it until the completion, the PLIC only accepts the same number
    li t0, PLIC_CLAIM_ADDR
    lw t1, 0(t0)

# ------------------------------- Service the interrupt -----------------------------

    # the id is how the two buttons are told apart. each branch moves the counter its
    # own way and leaves a0 holding the GPIO bit to clear, so the clear below does not
    # have to work that bit back out of the id. anything else is not ours and does nothing
    li a0, S1_PLIC_ID
    beq t1, a0, Buttons_ISR_S1
    li a0, S2_PLIC_ID
    beq t1, a0, Buttons_ISR_S2
    li a0, 0x00   # not one of ours, no flag to clear and no counter change
    j Buttons_ISR_Clear

Buttons_ISR_S1:
    addi s1, s1, 1   # S1 counts up
    li a0, GPIO_PB_S1
    j Buttons_ISR_Clear

Buttons_ISR_S2:
    addi s1, s1, -1   # S2 counts down
    li a0, GPIO_PB_S2

# ------------------------ Clear the falling interrupt pending in the GPIO ---------------

Buttons_ISR_Clear:
    # the GPIO latches the falling edge and holds the flag until we clear it, which is
    # what lets a press be remembered rather than missed. a 1 clears the bit, not a 0,
    # so this store only touches the button that fired.
    #
    # it has to happen before the PLIC completion, a flag still set keeps the line into
    # the PLIC asserted and the same press would be delivered again on return.
    # clearing it before the display rather than after also means a second press during
    # the update sets the flag again instead of being wiped by our store
    li t0, GPIO_BASE_CTRL_ADDR
    sw a0, GPIO_FALL_IP(t0)

    # the mask keeps the counter inside 0 to F both ways, 0xF counts up to 0x0 and
    # 0x0 counts down to 0xF
    andi s1, s1, 0x0F
    mv a0, s1
    jal ra, DISPLAY_7SEG

# -------------------------- Complete the Interrupt in the PLIC --------------------------

    # handing the id back tells the PLIC we are done with this source and allows it
    # to deliver from it again. skipping this would leave S1 dead after one press
    li t0, PLIC_CLAIM_ADDR
    sw t1, 0(t0)

# ----------------------------- Restore Registers & Return --------------------------

    lw a0, 12(sp)
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    mret                                  # Return from interrupt


# --------------------------------------------------------------------------------------------------------------
# Subroutines
# --------------------------------------------------------------------------------------------------------------

# ---------------------------- LED DISPLAY --------------------------
# Shows the low byte of a0 on the 8 LED bar LEDs
# Input: a0 = the value to display, only bits 7 to 0 are used
#
# The 8 LEDs are not on 8 consecutive pins. Byte bits 7 to 2 belong on GPIO bits
# 23 to 18 and byte bits 1 and 0 belong on GPIO bits 11 and 10, so the byte has to
# be split into two pieces that get shifted by different amounts.
#
# Shifting left by 16 lines byte bits 7 to 2 up with GPIO 23 to 18, and shifting
# left by 10 lines byte bits 1 and 0 up with GPIO 11 and 10. Each shifted copy also
# drags junk into the places the other copy owns, so each one is masked down to only
# the bits it is responsible for before the two get ORed back together.
DISPLAY_BYTE:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t2, 4(sp)
    sw t4, 8(sp)
    sw t5, 12(sp)

    slli t4, a0, 16   # byte bits 7 to 0 now sit at 23 to 16
    li t5, 0x00FC0000  # a mask with only bits 23 to 18 set
    and t4, t4, t5  # keep 23 to 18, which came from byte bits 7 to 2

    slli t2, a0, 10  # byte bits 7 to 0 now sit at 17 to 10
    li t5, 0x00000C00   # a mask with only bits 11 and 10 set
    and t2, t2, t5   # keep 11 and 10, which came from byte bits 1 and 0

    or t4, t4, t2   # the two halves together are the full GPIO pattern

    # read modify write so only the LED bar bits change, the 7 seg belongs to the ISR now
    # the mask alone is not enough, the lw and sw are separate so a press landing between
    # them would get its digit overwritten by the stale copy in t2. clearing MIE closes
    # that window, and only the main program calls this so turning it back on is safe
    csrci mstatus, 8   # clear mstatus.MIE, nothing can land inside the next six instructions
    li t0, GPIO_BASE_CTRL_ADDR
    lw t2, GPIO_OUTPUT_VAL(t0)  # what the pins are doing right now
    li t5, GPIO_LEDBAR_PINS  # 0x00FC0C00, the 8 LED bar bits
    not t5, t5   # 0xFF03F3FF, now every bit is set except those 8
    and t2, t2, t5   # clears the old pattern and changes nothing else
    or t2, t2, t4  # drop the new pattern in
    sw t2, GPIO_OUTPUT_VAL(t0)
    csrsi mstatus, 8   # set mstatus.MIE, presses are taken again from here on

    lw t5, 12(sp)
    lw t4, 8(sp)
    lw t2, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 16
    ret

# ------------------------ SEVEN SEGMENT DISPLAY --------------------
# Shows one hex digit on the seven segment display
# Input: a0 = the digit to display, only bits 3 to 0 are used
#
# The segments do not map onto the GPIO bits in any pattern a shift could produce,
# so Appendix A of the lab manual gives the bit set for each digit and SEG_TABLE
# holds those sixteen words. Each entry is a word, so the digit is shifted left by
# two to turn it into a byte offset.
#
# The mirror of DISPLAY_BYTE. That routine owns 0x00FC0C00 and this one owns
# 0x0000023F, so neither can disturb the half the other is responsible for.
DISPLAY_7SEG:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t2, 4(sp)
    sw t4, 8(sp)
    sw t5, 12(sp)

    la t4, SEG_TABLE   # the base of the sixteen entry pattern table
    andi t5, a0, 0x0F   # a digit is only ever 0 to F, drop anything above
    slli t5, t5, 2   # four bytes per entry, so the index becomes an offset
    add t4, t4, t5   # the address of this digit's entry
    lw t4, 0(t4)   # t4 is now the set of GPIO bits that lights the digit

    # read modify write so the LED bar is left alone
    li t0, GPIO_BASE_CTRL_ADDR
    lw t2, GPIO_OUTPUT_VAL(t0)  # what the pins are doing right now
    li t5, GPIO_7SEGLED_PINS  # 0x0000023F, the 7 segment bits
    not t5, t5   # every bit set except those 7
    and t2, t2, t5   # clears the old digit and changes nothing else
    or t2, t2, t4  # drop the new digit in
    sw t2, GPIO_OUTPUT_VAL(t0)

    lw t5, 12(sp)
    lw t4, 8(sp)
    lw t2, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 16
    ret

# ---------------------------- DELAY ROUTINES -----------------------
# Waits for a0 ticks, where one tick is 0.1 msec
# Input: a0 = how many 0.1 msec ticks to wait
#
# Every wait in the lab is expressed in these ticks so there is only ever one
# constant to calibrate. 0.1 sec is 1000 ticks, and that is the only delay this
# program needs, but keeping the routine general costs nothing.
Delay:
    addi sp, sp, -16
    sw t4, 0(sp)  # t4 is our inner counter so save the caller's copy
    sw t5, 4(sp)   # t5 counts how many ticks are left
    mv t5, a0   # take the tick count the caller asked for
    beqz t5, Delay_done   # zero ticks would wrap round and hang for hours

Delay_tick:
    li t4, TICK_LOOPS   # the count that gives us one 0.1 msec tick
Delay_loop:
    addi t4, t4, -1   # burn two cycles a pass until this tick is used up
    bnez t4, Delay_loop

    addi t5, t5, -1  # one more tick gone
    bnez t5, Delay_tick   # keep going until there are none left
Delay_done:
    lw t5, 4(sp)   # put t5 back
    lw t4, 0(sp)   # put t4 back
    addi sp, sp, 16
    ret


# --------------------------------------------------------------------------------------------------------------
# Seven segment patterns, taken from Appendix A of the lab manual
# Each word is the set of GPIO bits that lights the digit at that index
# --------------------------------------------------------------------------------------------------------------
.align 2
SEG_TABLE:
    .word 0x03F   # 0
    .word 0x006   # 1
    .word 0x21B   # 2
    .word 0x20F   # 3
    .word 0x226   # 4
    .word 0x22D   # 5
    .word 0x23D   # 6
    .word 0x007   # 7
    .word 0x23F   # 8
    .word 0x22F   # 9
    .word 0x237   # A
    .word 0x23C   # B
    .word 0x039   # C
    .word 0x21E   # D
    .word 0x239   # E
    .word 0x231   # F



