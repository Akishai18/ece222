# ------------------------------------------------------------------
# Studnet Information
# ------------------------------------------------------------------
# Lab number            :
# Group number          :
# Section number        :
# Student-1 name        : 
# Student-2 name        : 
# ------------------------------------------------------------------
# -------------- YOUR CODE MUST BE WELL COMMENTED ------------------
# -------------- YOU MAY REMOVE UNNECESSARY COMMENTS ---------------
# ------------------------------------------------------------------

.section .text      # Begin code (text) section — stores executable instructions
.globl _start       # Make the '_start' label globally visible to the linker as entry point
.align  2           # Align the next instruction to a 4-byte boundary (2^2 = 4) for efficiency

_start:

# Define base address and offsets for GPIO control registers (memory-mapped I/O)
# Refer to the lab manual or SiFive FE310-G002 Manual v1p5 on Learn for more info about the addresses
.equ GPIO_BASE_CTRL_ADDR,   0x10012000    # Base address for the GPIO control registers
.equ GPIO_OUTPUT_EN,        0x??          # address offset for enabling GPIO outputs
.equ GPIO_OUTPUT_VAL,       0x??          # Address offset for writing to GPIO outputs

# Determine the correct bitmask values (in hex) for: LED Bar Pins, Seven Segment LED Display Pins
# All LED Pins, and LEDBAR LED1. Example is given here for GPIO_7SEGLED_PINS
.equ GPIO_7SEGLED_PINS, 0x0000023F      # Seven Segment LED Display Pins (7)
.equ GPIO_LEDBAR_PINS,  0x????????      # LED Bar Pins (8)
.equ GPIO_ALL_LED_PINS, 0x????????      # All LED Pins (15)
.equ GPIO_LEDBAR_LED_1, 0x????????      # LEDBAR LED1 (Bit 11)


# Initialize the GPIO control registers (configure all LEDs as output)
# -----------------------------write the instructions here-----------------------------

# Turn Off all LEDs
# -----------------------------write the instructions here-----------------------------

# Turn On (toggle) LED1
# -----------------------------write the instructions here-----------------------------

# Create a delay of ~500 ms, toggle LED1, then delay another ~500 ms and toggle again.
# Repeat this process indefinitely.
# To start, implement the design using two separate counters (see Flowchart 1 in the lab manual),
# then optimize it to use a single counter as shown in Flowchart 2,and demo this.

loop:                               # Start of delay loop used as a simple timer (~0.5 sec)                                                           
    li t4, 0x????????               # Load the correct value that corresponds to 500 msec to t4
    loop1:                          # Here you have to write the conditons, for example: 
                                    # If t4 = 0x????????  continue, else go back to loop1
                                    # and increment or decrement till t4 = 0x???????? 
# -----------------------------write the instructions here-----------------------------

                          # Jump back to loop if if conditon(s) met
