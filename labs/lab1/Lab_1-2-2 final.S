# ------------------------------------------------------------------
# Studnet Information
# ------------------------------------------------------------------
# Lab number            : 1
# Group number          : 22
# Section number        : 1269
# Student-1 name        : Akishai Sabaratnasarma
# Student-2 name        : Sheehan Lloyd
# ------------------------------------------------------------------
# -------------- YOUR CODE MUST BE WELL COMMENTED ------------------
# -------------- YOU MAY REMOVE UNNECESSARY COMMENTS ---------------
# ------------------------------------------------------------------

.section .text      # Begin code (text) section — stores executable instructions
.globl _start       # Make the '_start' label globally visible to the linker as entry point
.globl Lab_1        # make Lab_1 visible
.align  2           # Align the next instruction to a 4-byte boundary (2^2 = 4) for efficiency

_start:
Lab_1:              # make _start and Lab_1 begin at the same instruction

# Define base address and offsets for GPIO control registers (memory-mapped I/O)
# Refer to the lab manual or SiFive FE310-G002 Manual v1p5 on Learn for more info about the addresses
.equ GPIO_BASE_CTRL_ADDR,   0x10012000    # Base address for the GPIO control registers
.equ GPIO_OUTPUT_EN,        0x08          # address offset for enabling GPIO outputs
.equ GPIO_OUTPUT_VAL,       0x0C          # Address offset for writing to GPIO outputs

# Determine the correct bitmask values (in hex) for: LED Bar Pins, Seven Segment LED Display Pins
# All LED Pins, and LEDBAR LED1. Example is given here for GPIO_7SEGLED_PINS
.equ GPIO_7SEGLED_PINS, 0x0000023F      # Seven Segment LED Display Pins (7)
.equ GPIO_LEDBAR_PINS,  0x00FC0C00      # LED Bar Pins (8)
.equ GPIO_ALL_LED_PINS, 0x00FC0E3F      # All LED Pins (15)
.equ GPIO_LEDBAR_LED_1, 0x00000800      # LEDBAR LED1 (Bit 11)


# Initialize the GPIO control registers (configure all LEDs as output)
# -----------------------------write the instructions here-----------------------------

    # Put the GPIO base address in t0
    li t0, GPIO_BASE_CTRL_ADDR
    # t1 selects all 15 pins connected to LEDs
    li t1, GPIO_ALL_LED_PINS
    # A 1 in OUTPUT_EN makes that GPIO pin an output
    sw t1, GPIO_OUTPUT_EN(t0)

# Turn Off all LEDs
# -----------------------------write the instructions here-----------------------------

    # Turn the LED's all off initially
    li t1, 0x00000000
    sw t1, GPIO_OUTPUT_VAL(t0)

# Turn On (toggle) LED1
# -----------------------------write the instructions here-----------------------------

    # t2 has only bit 11 set, so it selects only LED1
    li t2, GPIO_LEDBAR_LED_1
    # Change LED1's bit from 0 to 1 (this turns it on)
    xor t1, t1, t2
    # Write the changed LED values to the GPIO pins
    sw t1, GPIO_OUTPUT_VAL(t0)

# Create a delay of ~500 ms, toggle LED1, then delay another ~500 ms and toggle again.
# Repeat this process indefinitely.
# To start, implement the design using two separate counters (see Flowchart 1 in the lab manual),
# then optimize it to use a single counter as shown in Flowchart 2,and demo this.

# Delay calculation:
# 16 MHz gives 8,000,000 clock cycles in 0.5 seconds.
# ADDI takes 1 cycle and BNEZ takes 1 cycle, so one pass takes 2 cycles.
# 8,000,000 / 2 = 4,000,000 loops, which is 0x003D0900 in hexadecimal.

loop:                               # Start of delay loop used as a simple timer (~0.5 sec)                                                           
    li t4, 0x003D0900               # Load the correct value that corresponds to 500 msec to t4
    loop1:                          # Here you have to write the conditons, for example: 
                                    # If t4 = 0x00000000  continue, else go back to loop1
                                    # and increment or decrement till t4 = 0x00000000 
# -----------------------------write the instructions here-----------------------------

    addi t4, t4, -1                 # Decrease the delay counter by one
    bnez t4, loop1                  # if the counter is not zero, we keep delaying

    xor t1, t1, t2                  # toggle bit 11, ON becomes OFF and OFF becomes ON
    sw t1, GPIO_OUTPUT_VAL(t0)      # Send the new LED1 state to the GPIO output

                          # Jump back to loop if if conditon(s) met
    j loop                          # Reload the counter and repeat forever


# Hand assembly of ADDI instruction: addi t4, t3, 0x100

# ADDI is an I-type instruction

# Immediate (0x100) = 000100000000
# rs1 (t3 = x28)    = 11100
# funct3             = 000
# rd (t4 = x29)     = 11101
# opcode             = 0010011
#
# Put together:


# RISC-V instruction format
# 000100000000 11100 000 11101 0010011

# Converting to hex
# 0001 0000 0000 1110 0000 1110 1001 0011

# Final machine code = 0x100E0E93
