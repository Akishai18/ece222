# ------------------------------------------------------------------
# Student Information
# ------------------------------------------------------------------
# Lab number            : 3
# Group number          : 22
# Section number        : 1269
# Student-1 name        : Akishai Sabaratnasarma
# Student-2 name        : Sheehan Lloyd
# ------------------------------------------------------------------
# -------------- YOUR CODE MUST BE WELL COMMENTED ------------------
# -------------- YOU MAY REMOVE UNNECESSARY COMMENTS ---------------
# ------------------------------------------------------------------


# Register allocation
# t0  GPIO base address
# t1  scratch for masks while setting up the control registers
# s0  the 0x00 to 0xFF counter in task 1
# s2  the reaction time in 0.1 msec ticks
# s3  working copy of s2 while the four bytes are shifted out
# s5  how many bytes are left to display, then how many blinks are left
# s6  how many passes of the four byte display are left
# a0  argument passed into DISPLAY_BYTE and Delay
# t2 t4 t5  scratch inside the subroutines
# a7  pseudo random state, only RandomNum is allowed to write it
#
# RandomNum destroys t1, t3 and s4, so anything that has to survive a call
# to it cannot be kept in those three


.section .text
.align 2
.globl _start
.globl Lab_3


_start:
Lab_3:   # _start and Lab_3 are the same instruction
    
    # GPIO Control Registers Memory Mapping
    # Refer to lab manual or SiFive FE310-G002 Manual v1p5
    # Define the GPIO control register base address and offsets
    # (Output enable, output value, input enable, input value, etc.)
    # -----------------------------write the instructions here-----------------------------

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000   # base address for the GPIO control registers
    .equ GPIO_INPUT_VAL, 0x00  # offset to read what the pins are doing
    .equ GPIO_INPUT_EN, 0x04   # offset to enable GPIO inputs
    .equ GPIO_OUTPUT_EN, 0x08   # offset to enable GPIO outputs
    .equ GPIO_OUTPUT_VAL, 0x0C  # offset to write GPIO outputs
    .equ GPIO_PUE, 0x10   # offset to turn on the internal pull up resistors


    # Define GPIO Pin Mapping for LEDs (8 LEDs in LED bar, LED6)
    # Optional: you may also configure the 7-segment display pins
    # -----------------------------write the instructions here-----------------------------

    .equ GPIO_7SEGLED_PINS, 0x0000023F   # the 7 seven segment display pins
    .equ GPIO_LEDBAR_PINS, 0x00FC0C00  # the 8 LED bar pins, bits 10 11 and 18 to 23
    .equ GPIO_ALL_LED_PINS, 0x00FC0E3F   # all 15 LED pins together
    .equ GPIO_LEDBAR_LED_6, 0x00400000  # LED6 on its own, bit 22


    # Configure the GPIO Outputs for all LEDs
    # -----------------------------write the instructions here-----------------------------

    # Put the GPIO base address in t0
    li t0, GPIO_BASE_CTRL_ADDR
    # t1 selects all 15 pins connected to LEDs
    li t1, GPIO_ALL_LED_PINS
    # A 1 in OUTPUT_EN makes that GPIO pin an output
    sw t1, GPIO_OUTPUT_EN(t0)


    # Define GPIO Pin Mapping for Pushbuttons (S1, S2, and both)
    # -----------------------------write the instructions here-----------------------------

    .equ GPIO_PB_S1, 0x00001000   # pushbutton S1, bit 12
    .equ GPIO_PB_S2, 0x00002000  # pushbutton S2, bit 13
    .equ GPIO_PB_BOTH, 0x00003000   # both buttons together


    # Configure the GPIO Inputs for the pushbuttons used (S1, S2, or both)
    # -----------------------------write the instructions here-----------------------------

    # t1 selects both pushbuttons, we mask off the one we want when we read
    li t1, GPIO_PB_BOTH
    # A 1 in INPUT_EN lets us read that pin. the button bits are deliberately left out
    # of OUTPUT_EN, a pressed button ties the pin to ground so driving it would short
    sw t1, GPIO_INPUT_EN(t0)
    # the pull up holds the pin at 3.3V while the button is open, which is what makes
    # it read 1 when it is not pressed. the shield has its own but turning the internal
    # one on as well costs nothing and covers us if it does not
    sw t1, GPIO_PUE(t0)


    # Turn off all LEDs
    # -----------------------------write the instructions here-----------------------------

    # nothing should be lit before the first task starts
    li t1, 0x00000000
    sw t1, GPIO_OUTPUT_VAL(t0)


# ---------------------------- TIMING CONSTANTS ---------------------
# The board runs at 16 MHz so one second is 16,000,000 clock cycles.
# Every wait in this lab is counted in 0.1 msec ticks, because that is also the
# resolution the reflex meter has to measure at, so one constant covers all of them.
#
# 0.1 msec is 16,000,000 x 0.0001 = 1600 cycles.
# The inner loop is an ADDI and a BNEZ which is 2 cycles a pass, and each tick
# costs another 3 cycles for the LI, the ADDI and the BNEZ in the outer loop.
# 2 x TICK_LOOPS + 3 = 1600 gives 798.5 so we round up to 799.
#
# That is the theoretical figure, and it turned out to be close. Measured on the
# board, the counter took 12.6 sec to go from 0x00 to 0x80, which is 128 steps, so
# a step was 98.4 msec instead of 100 msec. Scaling 799 by 12.8 / 12.6 gives 812.
#
# The reaction counter needs its own constant because its loop does real work before
# it pads. The increment, the RandomNum call and the S1 read come to about 30 cycles,
# so 2 x COUNT_LOOPS + 30 = 1600 leaves 785.
    .equ TICK_LOOPS, 812  # inner passes that add up to one 0.1 msec tick, measured
    .equ COUNT_LOOPS, 821   # the same tick but with the counting loop body paid for
    .equ TICKS_0_1_SEC, 1000   # 0.1 sec is 1000 ticks
    .equ TICKS_2_SEC, 20000  # 2 sec, how long each byte sits on the LEDs
    .equ TICKS_BLINK, 500   # 0.05 sec, half of one 10 Hz on off cycle
    .equ BLINK_CYCLES, 50  # 50 cycles of 0.1 sec makes the 5 sec blink
    .equ DISPLAY_PASSES, 3   # the four byte value gets shown three times over

# ----------------------Initialize the pseudo-random number generator-----------------------
InitRandomNum:
    # Sets a7 to a 16-bit non-zero value; only the PRNG subroutine should modify a7
    li a7, 0xABCD


# -------------------Task 1: LED Binary Counter and GPIO Verification----------------------
Task_1:
    # -----------------------------write the instructions here-----------------------------

    # Task 1 is really a hardware test. The counting is trivial, what it proves is
    # that the LED bit mapping is right and that the delay is calibrated. LED0 should
    # toggle every 0.1 sec and LED7 every 12.8 sec, and the whole count wraps in
    # 25.6 sec, which is easy to check against a stopwatch.

    li s0, 0x00   # step b, the counter starts at zero

Task_1_Loop:
    mv a0, s0  # step c, hand the counter to the display routine
    jal ra, DISPLAY_BYTE

    li a0, TICKS_0_1_SEC   # step d, hold it for 0.1 sec
    jal ra, Delay

    addi s0, s0, 1   # step f

    # step e. the manual checks before incrementing, but that lets 0x100 reach the
    # LEDs for one tick and show up as a blank frame, so we check straight after the
    # increment instead. the counter only ever goes up by one so it lands on 0x100
    # exactly, which is the same test as asking whether it went past 0xFF
    li t2, 0x100
    bne s0, t2, Task_1_CheckS2
    li s0, 0x00  # back to step a, start the count over

    # the demo has to link the two tasks, pressing S2 drops us into the reflex meter
Task_1_CheckS2:
    li t0, GPIO_BASE_CTRL_ADDR
    lw t2, GPIO_INPUT_VAL(t0)   # this reads every pin at once
    li t4, GPIO_PB_S2
    and t2, t2, t4  # keep only bit 13
    beqz t2, Task_2   # a zero means pressed, the buttons are active low

    j Task_1_Loop   # step g



# ----------------------------------Task 2: Reflex Meter-----------------------------------
Task_2:
    # -----------------------------write the instructions here-----------------------------

    # Each round starts here. Every LED goes out, then we take a fresh random number
    # and scale it into a 2 to 10 second wait before LED6 comes on.
Task_2_Round:
    li a0, 0x00   # step a, nothing lit while the user waits
    jal ra, DISPLAY_BYTE
    jal ra, RandomNum

    # --------------------------------Use the Stack Properly if needed---------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------


# ----------------------------------------Scaling-------------------------------------------
# Scaling the randum number generated (a7) between 2 and 10 sec
Scale:
    # -----------------------------write the instructions here-----------------------------

    # a7 is not actually a 16 bit value. RandomNum shifts it left every call without
    # masking, so after a few calls the old bits have piled up above bit 15 and a7 is
    # a full 32 bit number. Only the low 16 bits are the real generator state, so we
    # take a copy of those and leave a7 alone.
    li t2, 0xFFFF
    and t2, a7, t2   # t2 is the real 0 to 65535 random value

    # we need 20000 to 100000 ticks, which is 2 to 10 sec. the span is 80000 and the
    # value we have spans 65535, so the scale factor is 80000/65535 = 1.2207. dividing
    # is expensive so we use 1.25 instead, which is the value plus a quarter of itself

    srli t4, t2, 2   # a quarter of the random value
    add t2, t2, t4   # now 1.25 x it, so 0 to 81918
    li t4, TICKS_2_SEC
    add a0, t2, t4   # 20000 to 101918 ticks, which is 2.0000 to 10.19 sec

    # step c and the wait itself, a0 is already the tick count Delay wants
    jal ra, Delay
    # --------------------------------Use the Stack Properly if needed---------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------


    # ------------------------------------Complete the task--------------------------------
    # -----------------------------write the instructions here-----------------------------

    # step d. LED6 is bit 6 of the byte so DISPLAY_BYTE can light it on its own, and
    # the same write clears the other seven for us
    li a0, 0x40
    jal ra, DISPLAY_BYTE

    # step e and f. s2 counts 0.1 msec ticks while we watch S1, and the pad at the
    # bottom of the loop is what stretches one pass out to a full tick
    li s2, 0x00

Count_loop:
    addi s2, s2, 1   # one more 0.1 msec of reaction time
    jal ra, RandomNum   # keep stirring the generator so the next round differs

    li t0, GPIO_BASE_CTRL_ADDR
    lw t2, GPIO_INPUT_VAL(t0)   # read every pin at once
    li t4, GPIO_PB_S1
    and t2, t2, t4  # keep only bit 12
    beqz t2, Count_done   # step g, a zero means S1 is down so stop the timer

    li t4, COUNT_LOOPS   # pad out whatever is left of this tick
Count_pad:
    addi t4, t4, -1   # count down
    bnez t4, Count_pad  # keep going until the tick is used up
    j Count_loop

# step h, send the 32 bit result out one byte at a time starting with the least
# significant, each byte held on the LEDs for 2 sec
#
# step j wants the whole four byte display to run three times. that is there so the
# person watching can actually read the value, nobody takes in 32 bits in one pass.
# the step list puts the blink between the first and second pass, but the timing
# summary and the flow chart both put the 5 sec phase after the display is finished,
# so the three passes run together and the blink closes the round out
Count_done:
    li s6, DISPLAY_PASSES   # step j, three times through the whole value

Display_pass:
    mv s3, s2   # a fresh copy each pass so we always shift the real time again
    li s5, 4   # four bytes to get through

Byte_loop:
    andi a0, s3, 0xFF   # the low byte of whatever is left
    jal ra, DISPLAY_BYTE

    li a0, TICKS_2_SEC   # hold this byte for 2 sec
    jal ra, Delay

    srli s3, s3, 8  # slide the next byte down into the low 8 bits
    addi s5, s5, -1   # one byte done
    bnez s5, Byte_loop   # keep going until all four have been shown

    addi s6, s6, -1   # one pass through the value done
    bnez s6, Display_pass   # show the whole thing again

    # step i, blink every LED at 10 Hz for 5 sec to close the round out.
    # 10 Hz is one on off cycle every 0.1 sec, so 0.05 sec lit and 0.05 sec dark,
    # and 5 sec of that comes to 50 cycles
    li s5, BLINK_CYCLES

Blink_loop:
    li a0, 0xFF   # all eight LEDs on
    jal ra, DISPLAY_BYTE
    li a0, TICKS_BLINK
    jal ra, Delay
    li a0, 0x00   # and all eight off again
    jal ra, DISPLAY_BYTE
    li a0, TICKS_BLINK
    jal ra, Delay
    addi s5, s5, -1   # one blink done
    bnez s5, Blink_loop   # keep blinking until the 5 sec is used up

    j Task_2_Round   # step k, start the whole test again
    # --------------------------------Use the Stack Properly if needed---------------------


# -------------------------Pseudo-Random Number Generator------------------------------
# Register a7 will hold the generated random number
# You may read this register anywhere in your program.
# Important: Only this subroutine should write to a7.

    # --------------------------------Use the Stack Properly if needed---------------------
RandomNum:
    addi sp, sp, -16
    sw ra, 12(sp)                  # Save return address

    li s4, 0x8000                  # Select bit 15 of a7
    and t1, a7, s4                 # Extract bit 15

    li s4, 0x2000                  # Select bit 13 of a7
    and t3, a7, s4                 # Extract bit 13

    slli t3, t3, 2                 # Shift extracted bit 13 left by 2
    xor t3, t1, t3                 # Combine with extracted bit 15

    li s4, 0x1000                  # Select bit 12 of a7
    and t1, a7, s4                 # Extract bit 12

    slli t1, t1, 3                 # Shift extracted bit 12 left by 3
    xor t3, t3, t1                 # Combine with previous result

    andi t1, a7, 0x0400            # Select bit 10 of a7
    slli t1, t1, 5                 # Shift bit 10 left by 5
    xor t3, t3, t1                 # Combine with previous result

    srli t3, t3, 15                # Shift result right by 15
    slli a7, a7, 1                 # Shift a7 left by 1
    or a7, a7, t3                  # Update a7 with new pseudo-random value

    lw ra, 12(sp)                  # Restore return address
    addi sp, sp, 16                # Restore stack pointer
    ret                             # Return from subroutine

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

    # read modify write so the seven segment pins are left alone
    li t0, GPIO_BASE_CTRL_ADDR
    lw t2, GPIO_OUTPUT_VAL(t0)  # what the pins are doing right now
    li t5, GPIO_LEDBAR_PINS  # 0x00FC0C00, the 8 LED bar bits
    not t5, t5   # 0xFF03F3FF, now every bit is set except those 8
    and t2, t2, t5   # clears the old pattern and changes nothing else
    or t2, t2, t4  # drop the new pattern in
    sw t2, GPIO_OUTPUT_VAL(t0)

    lw t5, 12(sp)
    lw t4, 8(sp)
    lw t2, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 16
    ret

# ---------------------------- DELAY ROUTINES -----------------------
# Create as much as you need.

# Waits for a0 ticks, where one tick is 0.1 msec
# Input: a0 = how many 0.1 msec ticks to wait
#
# Every wait in the lab is expressed in these ticks so there is only ever one
# constant to calibrate. 0.1 sec is 1000 ticks, 2 sec is 20000, 5 sec is 50000,
# and the random delay is just whatever the scaling gives us.
Delay:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly if needed---------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------



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

# ------------------------- LAB REPORT QUESTIONS --------------------
#
# a. Prove that the time for the pseudorandom number is within +/- 5% of the
#    specified time (2 to 10 seconds).
#
#    RandomNum hands us a 16 bit value r. A zero state would lock an LFSR up for
#    good so the generator never produces one, which means r is always 1 to 65535.
#    Scale turns it into
#
#        ticks = 20000 + r + (r >> 2)      which is 20000 + 1.25 x r
#
#    and one tick is 0.1 msec, so the delay in seconds is ticks / 10000.
#
#    The factor we would really want is 80000 / 65535 = 1.22070, because the range
#    to cover is 20000 to 100000 ticks and that is a span of 80000. A divide costs
#    a lot of instructions so we use 1.25 instead, which is one shift and one add.
#
#    Shortest delay, r = 1:
#        1 >> 2 = 0
#        20000 + 1 + 0 = 20001 ticks = 2.0001 sec
#        which is 0.0001 / 2 = 0.005% off the 2 sec end
#
#    Longest delay, r = 65535:
#        65535 >> 2 = 16383
#        20000 + 65535 + 16383 = 101918 ticks = 10.1918 sec
#        which is 0.1918 / 10 = 1.92% off the 10 sec end
#
#    The difference between 1.25 and 1.22070 only applies to the scaled part and not
#    to the 20000 offset, so the error grows with r and is worst at the top of the
#    range. 1.92% is the largest it ever gets. Every delay the program can produce
#    therefore falls between 2.0001 and 10.1918 seconds, which is inside +/- 5% of
#    the specified 2 to 10 seconds at both ends.
#
#    This holds as long as TICK_LOOPS is calibrated so one tick really is 0.1 msec.
#    The scaling above is exact arithmetic, the tick length is the part measured on
#    the board with the 5 second check from the lab manual.
#
#
# b. If a 32 bit register is counting user reaction time in 0.1 millisecond
#    increments, what is the maximum amount of time which can be stored in
#    8, 16, 24 and 32 bits?
#
#    An n bit counter holds a largest value of 2^n - 1 and every count is 0.1 msec,
#    so the longest time it can hold is (2^n - 1) x 0.1 msec.
#
#    i.    8 bits    2^8  - 1 = 255           25.5 msec
#    ii.   16 bits   2^16 - 1 = 65535         6553.5 msec = 6.5535 sec
#    iii.  24 bits   2^24 - 1 = 16777215      1677721.5 msec = 1677.72 sec
#                                             = 27 min 57.7 sec
#    iv.   32 bits   2^32 - 1 = 4294967295    429496729.5 msec = 429496.73 sec
#                                             = 119.3 hours = 4.97 days
#
#
# c. Considering typical human reaction time, which size would be the best for this
#    task (8, 16, 24, or 32 bits)?
#
#    A typical reaction to something appearing in front of you is about 200 to 300
#    msec, which is 2000 to 3000 of our 0.1 msec ticks.
#
#    8 bits tops out at 25.5 msec. That is shorter than any reaction a person has
#    ever managed, so the counter would overflow on every single attempt and the
#    number on the LEDs would be meaningless.
#
#    16 bits reaches 6.5535 sec. That holds a 250 msec reaction about 26 times over,
#    so there is room for someone who is distracted or looking away and still no
#    realistic chance of overflow.
#
#    24 bits reaches nearly 28 minutes and 32 bits nearly 5 days. Both work, but the
#    extra bytes are dead weight. They are always zero, and on this board they also
#    cost 2 or 4 extra seconds of display time per pass showing nothing.
#
#    16 bits is the best fit. Our own program is the evidence for it. We use a 32 bit
#    counter because the lab asks for one, and bytes 2 and 3 come out as 0x00 on
#    every single run, because reaching byte 2 at all would take a reaction slower
#    than 6.5535 sec.
End:
    .end