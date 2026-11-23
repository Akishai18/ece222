# ------------------------------------------------------------------
# Student Information
# ------------------------------------------------------------------
# Lab number            : 2
# Group number          : 22
# Section number        : 1269
# Student-1 name        : Akishai Sabaratnasarma
# Student-2 name        : Sheehan Lloyd
# ------------------------------------------------------------------
# -------------- YOUR CODE MUST BE WELL COMMENTED ------------------
# -------------- YOU MAY REMOVE UNNECESSARY COMMENTS ---------------
# ------------------------------------------------------------------

# Register allocation
# s1  pointer into the input string
# a0  the ASCII character we are working on
# a1  the 16 bit Morse pattern for that character
# t0  GPIO base address / index into MorseLUT
# t1  GPIO pin value / MorseLUT pointer
# t2  bit mask for LED7
# t3  working copy of the pattern while we shift through it
# t4  delay counter inside Delay
# t5  counts how many 0.5 sec ticks are left in a gap

# ---------------------------- DATA SECTION -------------------------
.section .rodata          # Read-only data section for constants / lookup tables
.align 2                  # Align to 4-byte boundary (2^2 = 4)

# Input string (Message) to be sent / converted to Morse code
# S and L are Sheehan Lloyd, A and S are Akishai Sabaratnasarma, H is the extra letter
InputLUT:
    .asciz "SLASH"        # Null-terminated string


# Morse Code Look-Up Table
# Each character is mapped to a 16-bit pattern for the Morse LED display
.align 2
MorseLUT:
    .half 0x17, 0x1D5, 0x75D, 0x75       # A, B, C, D
    .half 0x1, 0x15D, 0x1DD, 0x55        # E, F, G, H
    .half 0x5, 0x1777, 0x1D7, 0x175      # I, J, K, L
    .half 0x77, 0x1D, 0x777, 0x5DD       # M, N, O, P
    .half 0x1DD7, 0x5D, 0x15, 0x7        # Q, R, S, T
    .half 0x57, 0x157, 0x177, 0x757      # U, V, W, X
    .half 0x1D77, 0x775                  # Y, Z


# ---------------------------- CODE SECTION -------------------------
.section .text                               # Begin code section
.globl _start
.globl Lab_2
.align  2                                    # Align to 4-byte boundary

_start:
Lab_2:   # _start and Lab_2 are the same instruction
    # GPIO Control Registers Memory Mapping
    # Refer to lab manual or SiFive FE310-G002 Manual v1p5
    .equ GPIO_BASE_CTRL_ADDR,   0x10012000      # Base address for GPIO control registers
    .equ GPIO_OUTPUT_EN,        0x08            # Offset to enable GPIO outputs
    .equ GPIO_OUTPUT_VAL,       0x0C            # Offset to write GPIO outputs

    # LED Pin Masks
    .equ GPIO_7SEGLED_PINS, 0x0000023F          # Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x00FC0C00          # LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x00FC0E3F          # All LED Pins (15)
    .equ GPIO_LEDBAR_LED_7, 0x00800000          # LEDBAR LED7 (Bit 23)

    # Initialize GPIO outputs
    # -----------------------------write the instructions here-----------------------------

    # Put the GPIO base address in t0
    li t0, GPIO_BASE_CTRL_ADDR
    # t1 selects all 15 pins connected to LEDs
    li t1, GPIO_ALL_LED_PINS
    # A 1 in OUTPUT_EN makes that GPIO pin an output
    sw t1, GPIO_OUTPUT_EN(t0)



    # Turn off all LEDs
    # -----------------------------write the instructions here-----------------------------

    # nothing should be lit before the message starts
    li t1, 0x00000000
    sw t1, GPIO_OUTPUT_VAL(t0)

# ---------------------------- MAIN LOOP -----------------------------
# Initialize pointer and start processing each character of the input string
InputPointer:
    la s1, InputLUT                             # Load address of input string into s1

# Process each character in the input string
# we keep going until the null terminator so the length of the word is never assumed,
# swapping the word in InputLUT is all it takes and no other code has to change
NextChar:
    lbu a0, 0(s1)                               # Load next character into a0 (unsigned)
    addi s1, s1, 1                              # Increment pointer to next character
    beqz a0, WordEnd   # a zero byte is the null terminator so the word is done

    jal ra, CHAR2MORSE   # a1 comes back with the 16 bit pattern for this letter
    jal ra, PROCESSCHAR  # flash LED7 using that pattern

    li t5, 3   # the gap between letters is 1.5 sec which is three 0.5 sec ticks
LetterGap:
    jal ra, Delay
    addi t5, t5, -1   # one tick done
    bnez t5, LetterGap   # keep waiting until all three are used up
    j NextChar   # go and do the next letter

# we land here once the whole message has been sent
WordEnd:
    li t5, 4  # the gap after the word is 2 sec which is four ticks
WordGap:
    jal ra, Delay
    addi t5, t5, -1
    bnez t5, WordGap
    j InputPointer                              # Restart from first character


# Converts an ASCII uppercase letter (A-Z) into its Morse pattern and Flash the LED according to the pattern
CHAR2MORSE:
    # --------------Optional: You may separate the logic into two subroutines:-------------
    # ------------------1. CHAR2MORSE: Lookup Morse pattern from ASCII---------------------
    # ------------------2. PROCESSCHAR: Flash the LED according to the pattern-------------
    # -----------------------------write the instructions here-----------------------------

    # Input: a0 = ASCII character. Store Output in a1 = Morse code pattern
    # Index into MorseLUT must be by steps of 2 bytes
    # Example layout in MorseLUT:
    # 0000 0000 | 0000 0000 | 0000 0000 | 0000 0000
    #       B (2 Bytes)     |        A (2 bytes)

    # 'A' is 0x41 so subtracting 0x41 turns A into 0, B into 1 and so on up to Z which is 25.
    # Each entry is a .half which is 2 bytes so the byte offset is the index times 2,
    # and shifting left by one is the same as multiplying by two.
    # lhu is used because the pattern is just a bit map, sign extending it would be wrong.

    # save the registers we are about to use so the caller gets them back untouched
    addi sp, sp, -16
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)

    addi t0, a0, -0x41   # index = ASCII - 'A'
    slli t0, t0, 1  # offset = index x 2 because each entry is 2 bytes
    la t1, MorseLUT   # point at the start of the table
    add t1, t1, t0   # move along to this letter's entry
    lhu a1, 0(t1)   # read the 16 bit pattern, zero extended

    # put everything back the way we found it and return
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    ret


# Flashes LED7 with the Morse pattern
# Input: a1 = the 16 bit pattern that CHAR2MORSE just looked up
#
# The pattern is the on/off timeline itself, one bit per 0.5 sec.
# A dot is 1, a dash is 111, and a single 0 sits between the elements.
# Every pattern starts and ends with a 1 and the longest one is 13 bits,
# so the top of the 16 bit value is padded with zeros we have to throw away first.
#
# We cannot test bit 15 with andi because an I-type immediate is only 12 bits signed
# so 0x8000 does not fit in it. Instead the pattern is shifted up by 16 so the bit we
# care about sits in bit 31, which is the sign bit, and then bltz can test it for free.
PROCESSCHAR:
    addi sp, sp, -16
    sw ra, 0(sp)   # this routine calls others so ra must be saved
    sw t3, 4(sp)  # t3 is our working copy of the pattern
    sw t5, 8(sp)   # t5 counts the bits that are left

    slli t3, a1, 16   # move the 16 bit pattern up so its top bit is bit 31
    li t5, 16   # we start with a 16 bit window

# drop the leading zeros so we begin on the first real element of the letter
StripZeros:
    bltz t3, SendBits   # a 1 in the top bit means the real pattern starts here
    slli t3, t3, 1  # otherwise throw away this leading zero
    addi t5, t5, -1   # the window is one bit shorter
    j StripZeros

# send the bits one at a time, most significant first, each one held for 0.5 sec
SendBits:
    bltz t3, BitIsOne   # top bit is 1 so the LED should be on for this tick
    jal ra, LED_OFF   # top bit is 0 so the LED should be off
    j BitDone
BitIsOne:
    jal ra, LED_ON
BitDone:
    jal ra, Delay   # hold this bit for 0.5 sec
    slli t3, t3, 1  # shift the next bit up into bit 31
    addi t5, t5, -1   # one bit done
    bnez t5, SendBits   # keep going until the whole character has been sent

    jal ra, LED_OFF   # the pattern ends on a 1 so turn the LED off before the gap

    lw t5, 8(sp)
    lw t3, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

# ---------------------------- SUBROUTINES ---------------------------
# ---------------------------- LED CONTROL ---------------------------
# Turn On LED7
LED_ON:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------

    # LED7 is bit 23 of the GPIO output register and setting that bit turns the LED on.
    # We read the pins first so the other 14 LEDs keep doing whatever they were doing.

    addi sp, sp, -16

    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)

    li t0, GPIO_BASE_CTRL_ADDR
    lw t1, GPIO_OUTPUT_VAL(t0)   # read what the pins are doing right now
    li t2, GPIO_LEDBAR_LED_7  # a mask with only bit 23 set

    or t1, t1, t2   # or forces bit 23 to 1 and cannot change any other bit

    sw t1, GPIO_OUTPUT_VAL(t0)   # write it back, LED7 is now on

    lw t2, 12(sp)
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16

    ret



# Turn LED7 off
LED_OFF:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------

    # clearing a bit needs the mask flipped first, because and can only clear bits
    # and or can only set them

    addi sp, sp, -16

    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)

    li t0, GPIO_BASE_CTRL_ADDR
    lw t1, GPIO_OUTPUT_VAL(t0)   # read what the pins are doing right now

    li t2, GPIO_LEDBAR_LED_7   # 0x00800000, only bit 23 is set
    not t2, t2  # 0xFF7FFFFF, now bit 23 is 0 and everything else is 1
    and t1, t1, t2   # clears bit 23 and leaves every other pin alone

    sw t1, GPIO_OUTPUT_VAL(t0)   # write it back, LED7 is now off

    lw t2, 12(sp)
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16

    ret




# ---------------------------- DELAY ROUTINES -----------------------
# You can implement three separate subroutines for 0.5s, 1.5s, and 3.5s delays
# Or use a single 0.5s Delay and call it multiple times as requried

# We went with the single 0.5 sec version. The 1.5 sec gap between letters calls it
# 3 times and the 2 sec gap after the whole word calls it 4 times.
#
# Delay calculation:
# 16 MHz gives 8,000,000 clock cycles in 0.5 seconds.
# ADDI takes 1 cycle and BNEZ takes 1 cycle, so one pass takes 2 cycles.
# 8,000,000 / 2 = 4,000,000 loops, which is 0x003D0900 in hexadecimal.
Delay:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------
    addi sp, sp, -16
    sw t4, 0(sp)   # t4 is our counter so save the caller's copy
    li t4, 0x003D0900  # the count that gives us 500 msec

Delay_loop:
    addi t4, t4, -1   # count down
    bnez t4, Delay_loop   # keep going until it hits zero
    lw t4, 0(sp)   # put t4 back
    addi sp, sp, 16
    ret

# ------------------------- MORSE DECODING --------------------------
# Message "SLASH"
# A dot is 1, a dash is 111, a single 0 separates the elements,
# and every bit is held on the LED for 0.5 sec.
# The gaps are written out as zeros too, 000 is 1.5 sec and 0000 is 2 sec.
#
#   S      1.5s   L             1.5s   A        1.5s   S        1.5s   H          1.5s   2s
#  1 0101  000    1 0111 0101   000    1 0111   000    1 0101   000    101 0101   000    0000
#
# S   ...     1 0101          0x15
# L   .-..    1 0111 0101     0x175
# A   .-      1 0111          0x17
# S   ...     1 0101          0x15
# H   ....    101 0101        0x55


End:
    .end