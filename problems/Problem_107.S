# ECE 222 Lab Assessment - Problem 107
# Transpose a 3x3 matrix of 32 bit signed integers in place at 0x80000000
#
# Row major layout, every offset is off the base in t0
#   a 0x00   b 0x04   c 0x08
#   d 0x0C   e 0x10   f 0x14
#   g 0x18   h 0x1C   i 0x20
#
# A transpose swaps element [row][col] with [col][row], so the three elements on
# the diagonal never move and only three pairs have to be exchanged.
#
# t0 base address, t1 and t2 the pair being swapped

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every load and store is an offset off this

    # The matrix for my last student digit, stored row major
    li t1, 0x1B2C
    sw t1, 0x00(t0)   # a
    li t1, 0x2C3D
    sw t1, 0x04(t0)   # b
    li t1, 0x3D4E
    sw t1, 0x08(t0)   # c
    li t1, 0x4E5F
    sw t1, 0x0C(t0)   # d
    li t1, 0x5F6A
    sw t1, 0x10(t0)   # e
    li t1, 0x6A7B
    sw t1, 0x14(t0)   # f
    li t1, 0x7B8C
    sw t1, 0x18(t0)   # g
    li t1, 0x8C9D
    sw t1, 0x1C(t0)   # h
    li t1, 0x9D0E
    sw t1, 0x20(t0)   # i

    # Both values of a pair have to be loaded before either one is written back,
    # otherwise the first store overwrites the value the second one still needs.

    # swap b and d
    lw t1, 0x04(t0)
    lw t2, 0x0C(t0)
    sw t2, 0x04(t0)
    sw t1, 0x0C(t0)

    # swap c and g
    lw t1, 0x08(t0)
    lw t2, 0x18(t0)
    sw t2, 0x08(t0)
    sw t1, 0x18(t0)

    # swap f and h
    lw t1, 0x14(t0)
    lw t2, 0x1C(t0)
    sw t2, 0x14(t0)
    sw t1, 0x1C(t0)

    # a, e and i sit on the diagonal so they are already where they belong

Done:
    j Done

.end
