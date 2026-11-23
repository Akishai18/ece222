# ECE 222 Lab Assessment - Problem 104
# Reverse the bit order of a 32 bit unsigned value.
# The number goes in 0x80000004 and the reversed value in 0x80000008
#
# t0 base address, t1 working copy of the number, t2 the reversed result,
# t3 the bit being moved, t4 how many bits are left to do

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every store below is an offset off this
    li t1, 0x380F1234   # the number for my last student digit, change from the table

    sw t1, 4(t0)   # the question asks for the number itself at 0x80000004

    # Take the bottom bit off the number and push it onto the bottom of the
    # result, shifting the result left first to make room. The first bit taken
    # gets shifted left another 31 times before we finish, so it ends up at the
    # top, and the last bit taken never moves, so it stays at the bottom. That
    # is exactly a reversal.
    #
    # This has to run 32 times and not stop early when the number reaches zero.
    # Leading zeros still count as bits and the result has to be shifted past
    # them, otherwise reversing something like 0x00000001 would give 1 instead
    # of 0x80000000.
    li t2, 0   # the reversed value being built up
    li t4, 32  # one pass for every bit in the word

Loop:
    slli t2, t2, 1   # make room at the bottom of the result
    andi t3, t1, 1   # the bottom bit of the number, either 0 or 1
    or t2, t2, t3   # drop it into the slot we just made
    srli t1, t1, 1   # bring the next bit of the number down
    addi t4, t4, -1   # one bit done
    bnez t4, Loop   # keep going until all 32 have been moved

    sw t2, 8(t0)   # the reversed value at 0x80000008

Done:
    j Done

.end
