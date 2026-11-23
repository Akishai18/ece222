# ECE 222 Lab Assessment - Problem 106
# Multiply two 2x2 matrices of 32 bit signed integers.
# A goes at 0x80000000, B right after it at 0x80000010, and C = A x B at 0x80000020
#
# A   0x00 a   0x04 b   0x08 c   0x0C d
# B   0x10 a   0x14 b   0x18 c   0x1C d
# C   0x20 a   0x24 b   0x28 c   0x2C d
#
# t0 base address
# s0 s1 s2 s3  the four elements of A
# s4 s5 s6 s7  the four elements of B
# t1 t2 t3     the two products and their sum

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every load and store is an offset off this

    # Matrix A for my last student digit, stored row major
    li s0, 0x1AF   # A.a
    li s1, 0x7E2   # A.b
    li s2, 0x9D3   # A.c
    li s3, 0x5C1   # A.d
    sw s0, 0x00(t0)
    sw s1, 0x04(t0)
    sw s2, 0x08(t0)
    sw s3, 0x0C(t0)

    # Matrix B goes immediately after A
    li s4, 0x6B9   # B.a
    li s5, 0x2F3   # B.b
    li s6, 0x4A8   # B.c
    li s7, 0x11E   # B.d
    sw s4, 0x10(t0)
    sw s5, 0x14(t0)
    sw s6, 0x18(t0)
    sw s7, 0x1C(t0)

    # Each element of C is a row of A dotted with a column of B. The values are
    # already sitting in registers from the stores above so there is nothing to
    # load back. Everything here is well under 32 bits so mul alone is enough
    # and the high half from mulh is not needed.

    # C.a = A.a x B.a + A.b x B.c
    mul t1, s0, s4
    mul t2, s1, s6
    add t3, t1, t2
    sw t3, 0x20(t0)

    # C.b = A.a x B.b + A.b x B.d
    mul t1, s0, s5
    mul t2, s1, s7
    add t3, t1, t2
    sw t3, 0x24(t0)

    # C.c = A.c x B.a + A.d x B.c
    mul t1, s2, s4
    mul t2, s3, s6
    add t3, t1, t2
    sw t3, 0x28(t0)

    # C.d = A.c x B.b + A.d x B.d
    mul t1, s2, s5
    mul t2, s3, s7
    add t3, t1, t2
    sw t3, 0x2C(t0)

Done:
    j Done

.end
