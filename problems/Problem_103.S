# ECE 222 Lab Assessment - Problem 103
# Parity of a 32 bit unsigned integer.
# The number goes in 0x80000004, the count of set bits in 0x80000008 and the
# parity in 0x80000010. Note that 0x8000000C is skipped.
#
# t0 base address, t1 working copy of the number, t2 how many ones we found,
# t3 the bit we are looking at, t4 the parity

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every store below is an offset off this
    li t1, 0x380049B4   # the number for my last student digit, change from the table

    sw t1, 4(t0)   # the question asks for the number itself at 0x80000004

    # Count the ones by looking at the bottom bit and then shifting the number
    # right. ANDing with 1 gives either 0 or 1, which is exactly how much the
    # count has to go up by, so no branch is needed to decide. srli is the
    # logical shift so zeros come in at the top and the loop always ends.
    li t2, 0   # how many ones we have counted so far

Loop:
    beqz t1, Parity   # nothing left to look at, every one has been counted
    andi t3, t1, 1   # the bottom bit, either 0 or 1
    add t2, t2, t3   # add it straight onto the count
    srli t1, t1, 1   # bring the next bit down into the bottom
    j Loop

    # the parity is just whether the count is odd, which is its bottom bit
Parity:
    andi t4, t2, 1   # 1 if the count is odd, 0 if it is even

    sw t2, 8(t0)   # the number of ones at 0x80000008
    sw t4, 16(t0)  # the parity at 0x80000010

Done:
    j Done

.end
