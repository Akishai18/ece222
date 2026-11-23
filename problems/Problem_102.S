# ECE 222 Lab Assessment - Problem 102
# Factor a number that is the product of two primes.
# The number goes in 0x80000004 and the two factors in 0x80000008 and 0x8000000C
#
# t0 base address, t1 the number, t2 the trial divisor, t3 remainder, t4 the other factor

.section .text
.align 2
.globl _start

_start:
    li t0, 0x80000000   # base address, every store below is an offset off this
    li t1, 20291   # the number for my last student digit, change this from the table

    sw t1, 4(t0)   # the question asks for the number itself at 0x80000004

    # Walk a divisor up from 2 until one divides the number exactly. Because the
    # number is a product of two primes the first divisor we hit has to be the
    # smaller of the two, so there is no need to stop at the square root and no
    # need to check whether the divisor is prime.
    li t2, 2   # the trial divisor

Loop:
    rem t3, t1, t2   # what is left over when we divide by this divisor
    beqz t3, Found   # no remainder so t2 is the smaller prime
    addi t2, t2, 1   # try the next divisor
    j Loop

Found:
    div t4, t1, t2   # the other prime is just the number divided by the first one

    sw t2, 8(t0)   # smaller prime at 0x80000008
    sw t4, 12(t0)  # larger prime at 0x8000000C

Done:
    j Done

.end
