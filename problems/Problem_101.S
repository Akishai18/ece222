# ECE 222 Lab Assessment - Problem 101
# Exponentiation: second last digit of the student ID to the power of the
# last digit, result stored at 0x80000008
#
# s0 base, s1 exponent, t1 running result, t2 how many times we have multiplied

.section .text
.align 2
.globl _start

_start:
    li s0, 7   # second last digit of my student ID, this is the base
    li s1, 5   # last digit of my student ID, this is the exponent

    # A 0 has to become an 8 and a 1 has to become a 9, and the swap has to be
    # decided at run time. Both of those cases are just the digit plus 8, and no
    # other digit needs touching, so one branch per digit covers it. The digits
    # are loaded as they really are and the 8 is only added if the branch falls
    # through, so neither 8 nor 9 is written in anywhere.
    li t0, 2   # digits below 2 are the ones that need fixing

    bge s0, t0, FixExp   # 2 or more so the base is already fine
    addi s0, s0, 8   # 0 becomes 8 and 1 becomes 9

FixExp:
    bge s1, t0, Power   # 2 or more so the exponent is already fine
    addi s1, s1, 8

    # s0 to the power of s1, by multiplying the base in s1 times
Power:
    li t1, 1   # the running result, starts at 1 not at the base
    li t2, 0   # how many multiplications we have done so far

Loop:
    beq t2, s1, Store   # once the counter reaches the exponent we are done
    mul t1, t1, s0   # result = result x base
    addi t2, t2, 1   # one more multiplication done
    j Loop   # go back and check the counter again

    # base and offset, t0 holds 0x80000000 and the 8 in the store is the offset
Store:
    li t0, 0x80000000
    sw t1, 8(t0)

Done:
    j Done

.end
