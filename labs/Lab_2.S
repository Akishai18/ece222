# ------------------------------------------------------------------
# Student Information
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


# ---------------------------- DATA SECTION -------------------------
.section .rodata          # Read-only data section for constants / lookup tables
.align 2                  # Align to 4-byte boundary (2^2 = 4)

# Input string (Message) to be sent / converted to Morse code
InputLUT:
    .asciz "BIRDS"        # Null-terminated string

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
.globl _start                                # Entry point
.align  2                                    # Align to 4-byte boundary

_start:
    # GPIO Control Registers Memory Mapping
    # Refer to lab manual or SiFive FE310-G002 Manual v1p5
    .equ GPIO_BASE_CTRL_ADDR,   0x10012000      # Base address for GPIO control registers
    .equ GPIO_OUTPUT_EN,        0x??            # Offset to enable GPIO outputs
    .equ GPIO_OUTPUT_VAL,       0x??            # Offset to write GPIO outputs

    # LED Pin Masks
    .equ GPIO_7SEGLED_PINS, 0x0000023F          # Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x????????          # LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x????????          # All LED Pins (15)
    .equ GPIO_LEDBAR_LED_7, 0x????????          # LEDBAR LED7 (Bit ??)

    # Initialize GPIO outputs
    # -----------------------------write the instructions here-----------------------------

    # Turn off all LEDs
    # -----------------------------write the instructions here-----------------------------


# ---------------------------- MAIN LOOP -----------------------------
# Initialize pointer and start processing each character of the input string
InputPointer:
    la s1, InputLUT                             # Load address of input string into s1

# Process each character in the input string
NextChar:
    lbu a0, 0(s1)                               # Load next character into a0 (unsigned)
    addi s1, s1, 1                              # Increment pointer to next character
    snez a1, a0                                 # Set a1 = 1 if a0 != 0 (not null)
    bnez a1, CHAR2MORSE                         # If character valid, convert to Morse
    jal ra, DELAY                               # If null terminator reached, wait 3.5 sec
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

# ---------------------------- SUBROUTINES ---------------------------
# ---------------------------- LED CONTROL ---------------------------
# Turn On LED7
LED_ON:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------


# Turn LED7 off
LED_OFF:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------


# ---------------------------- DELAY ROUTINES -----------------------
# You can implement three separate subroutines for 0.5s, 1.5s, and 3.5s delays
# Or use a single 0.5s Delay and call it multiple times as requried
Delay:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------


End:
    .end
