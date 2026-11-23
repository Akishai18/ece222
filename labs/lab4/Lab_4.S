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

.section .text
.align 2
.globl _start

# --------------------------------------------------------------------------------------------------------------
# Constants and Register Definitions
# --------------------------------------------------------------------------------------------------------------


_start:

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
# -----------------------------write the instructions here-----------------------------


# -----------------------Configure GPIO LEDs pins as an output-------------------------
# -----------------------------write the instructions here-----------------------------


# ----------------------------Turn Off all LEDs in LED Bar-----------------------------
# -----------------------------write the instructions here-----------------------------



# ------------Enable Falling edge for S1: Remember S1 is a GPIO and not PLIC-----------
# -----------------------------write the instructions here-----------------------------


# ----------------------------Enable PLIC for S1 interrupt-----------------------------
# -----------------------------write the instructions here-----------------------------
                   

# ----------------Set PLIC priority for S1 interrupt to 7 "Highest Priority"-----------
# -----------The address is calculated according to: PLIC_BASE + 4 × S1_PLIC_ID--------
# -----------------------------write the instructions here-----------------------------


# -------------------------------Set PLIC threshold to 6-------------------------------
# -----------------------------write the instructions here-----------------------------


main_program:                             
# ----------   Code developped in Lab-3 task-1   ----------------
# -- 8-bits counter incremented every 0.1 second shown on LEDs --



# Interrupt Service Routine (ISR) for S1 and S2 pushbuttons 
# In Step-2, only steup S1. In Step-3, setup both S1 and S2.  
Buttons_ISR:
# ----------------------------- Save Registers to Stack -----------------------------


# -------------------------- Acknowledge Interrupt in PLIC --------------------------


# ----------------------------- Scale a7 and save it in a4 ---------------------------
      Scale:



# -------------------------- Complete the Interrupt in the PLIC --------------------------
# ------------------------ Clear the falling interrupt pending in the GPIO ---------------




# ----------------------------- Restore Registers & Return --------------------------
    mret                                  # Return from interrupt



