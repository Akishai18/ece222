# ECE 222 Lab Assessment - Problem 105
# Swap the byte order of a 32 bit unsigned value.
# The number goes in 0x80000004 and the swapped value in 0x80000008
#
# t0 base address, t1 working copy of the number, t2 the swapped result,
# t3 the byte being moved, t4 how many bytes are left to do

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every store below is an offset off this
    li t1, 0x38054D34   # the number for my last student digit, change from the table

    sw t1, 4(t0)   # the question asks for the number itself at 0x80000004

    # Take the bottom byte off the number and push it onto the bottom of the
    # result, shifting the result left by a byte first to make room. The first
    # byte taken gets moved up three more times before we finish so it ends at
    # the top, and the last byte taken never moves so it stays at the bottom.
    #
    # This has to run 4 times and not stop early when the number reaches zero,
    # because a leading zero byte still has to be shifted past. Swapping
    # 0x00000012 has to give 0x12000000 and not 0x12.
    li t2, 0   # the swapped value being built up
    li t4, 4   # one pass for every byte in the word

Loop:
    slli t2, t2, 8   # make room for a byte at the bottom of the result
    andi t3, t1, 0xFF   # the bottom byte of the number
    or t2, t2, t3   # drop it into the slot we just made
    srli t1, t1, 8   # bring the next byte of the number down
    addi t4, t4, -1   # one byte done
    bnez t4, Loop   # keep going until all four have been moved

    sw t2, 8(t0)   # the swapped value at 0x80000008

Done:
    j Done

.end
