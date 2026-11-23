# ECE 222 Lab Assessment - Problem 108
# Greatest common divisor of two numbers.
# A goes in 0x80000004, B in 0x80000008 and the gcd in 0x80000010.
# Note that 0x8000000C is skipped.
#
# t0 base address, t1 and t2 the two numbers as given,
# t3 the larger, t4 the smaller, t5 the remainder

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every store below is an offset off this

    li t1, 0x1734   # A for my last student digit, change from the table
    li t2, 0x204C   # B for my last student digit

    sw t1, 0x04(t0)   # the question asks for A at 0x80000004
    sw t2, 0x08(t0)   # and B at 0x80000008

    # The question asks for the smaller and the larger to be sorted out first, so
    # t3 ends up holding the larger of the two and t4 the smaller.
    blt t1, t2, A_Smaller   # A below B so A is the smaller one
    mv t3, t1   # otherwise A is the larger
    mv t4, t2
    j Gcd

A_Smaller:
    mv t3, t2   # B is the larger
    mv t4, t1

    # Euclid. Replace the pair with the smaller number and the remainder of the
    # larger divided by the smaller. The remainder shrinks every pass so the
    # smaller one reaches zero eventually, and whatever is left in t3 at that
    # point divides both of the original numbers and is the largest thing that
    # does, which is the gcd.
Gcd:
    beqz t4, Store   # nothing left to divide by so t3 is the answer
    rem t5, t3, t4   # what is left over when the larger is divided by the smaller
    mv t3, t4   # the old smaller becomes the new larger
    mv t4, t5   # and the remainder becomes the new smaller
    j Gcd

Store:
    sw t3, 0x10(t0)   # the gcd at 0x80000010

Done:
    j Done

.end
