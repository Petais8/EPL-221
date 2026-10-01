# =====================================================================
# Binomial series (1+x)^k = sum_{n>=0} [k(k-1)...(k-n+1) / n!] * x^n
# Computed iteratively and recursively, for -0.9 <= x <= 1, 0.5 <= k < 2
#
# Calling convention used in this program:
#   float args  : $f12 (1st), $f14 (2nd), $f16 (3rd), $f18 (4th)
#   int arg     : $a0
#   float result: $f0        int result: $v0
#   Callee-saved registers ($ra, $s0, $f20-$f30) are saved on the
#   stack by every function that uses them.
#   Everything else ($t0-$t9, $a0, $f4-$f18) may be clobbered by a call.
# =====================================================================

.data
#    strings used for printing
title: .asciiz "--- Recursive Binomial Series ---\n"
subtitle: .asciiz "--- \t\t\tbinomial_series\t-->binomial_series_recursice ---\n"
str1: .asciiz "(1+"
str2: .asciiz ")^"
str3: .asciiz "\t\t-->\t\t"
str4: .asciiz "\t"
str5: .asciiz "\n"

# floating points constants
f_zero:  .float 0.0
f_one:  .float 1.0
f_neg_one:  .float -1.0
f_epsilon: .float 0.01
f_xstart: .float -0.9       
f_xstep:  .float 0.2        
f_kstart: .float 0.5        
f_kstep:  .float 0.1        
f_klimit: .float 2.0 

.text
.globl main
    j main                            # jumb to the main function

# =====================================================================
# float my_abs(float x)          x:$f12  ->  $f0
# Returns the absolute value of x.
# =====================================================================
my_abs: 
    lwc1   $f4, f_zero                # $f4 = 0.0
    c.lt.s $f12, $f4                  # x < 0 ?
    bc1f  exit
    lwc1   $f4, f_neg_one             # $f4 = -1.0  
    mul.s  $f0,$f4, $f12              # return x * -1
    jr     $ra
exit:
    mov.s  $f0, $f12                  # return x
    jr     $ra


# =====================================================================
# float powerR(float x, int n)   x:$f12  n:$a0  ->  $f0
# Recursive power: x^n = x * x^(n-1), x^0 = 1.0
# =====================================================================
powerR:
    bne   $a0, $zero, recursive      # $a0 != 0 goto recursive
    lwc1  $f0, f_one                 # return 1.0
    jr    $ra
recursive:
    addi  $sp, $sp, -12              # allocate stack frame
    swc1  $f12, 8($sp)               # save x
    sw    $ra, 4($sp)                # save return adress
    sw    $a0, 0($sp)                # save n
    addi  $a0, $a0, -1               # n - 1
    jal powerR                       # call powerR 
    lwc1  $f12, 8($sp)               # restore x
    lw    $ra, 4($sp)                # restore return adress
    lw    $a0, 0($sp)                # restore n
    addi  $sp, $sp, 12               # free stack frame
    mul.s $f0, $f0, $f12             # return powerR(x, n-1) * x
    jr    $ra


# =====================================================================
# float power(float x, int n)    x:$f12  n:$a0  ->  $f0
# Iterative power: multiplies 1.0 by x, n times.
# =====================================================================
power:
    lwc1  $f0, f_one                 # result = 1.0
    li    $t0, 0                     # i = 0 
loop:
    slt   $t1, $t0, $a0              # $t1 = (i < n)
    beq   $t1, $zero, loop_end       # if i >= n goto loop_end
    mul.s $f0, $f0, $f12             # result *= x
    addi  $t0, $t0, 1                # i++
    j     loop
loop_end:
    jr    $ra

# =====================================================================
# int factorial(int n)           n:$a0  ->  $v0
# Iterative factorial.
# =====================================================================
factorial:
    beq  $a0, $zero, fact_one       # n == 0 goto fact_one
    li   $t0, 1                     # $t0 = 1
    beq  $a0, $t0, fact_one         # n == 1 goto fact_one
    li   $v0, 1                     # result = 1
    li   $t1, 2                     # i = 2
fact_loop:
    slt  $t2, $a0, $t1              # $t2 = (n < i)
    bne  $t2, $zero, fact_end       # if i > n goto done
    mul  $v0, $v0, $t1              # result *= i
    addi $t1, $t1, 1                # i++
    j    fact_loop
fact_end:
    jr   $ra                        # return result
fact_one:
    li   $v0, 1                     # return 1
    jr   $ra


# =====================================================================
# int factorialR(int n)          n:$a0  ->  $v0
# Recursive factorial: n! = n * (n-1)!
# =====================================================================
factorialR:
    beq  $a0, $zero, factR_one      # n == 0 goto factR_one
    li   $t0, 1                     
    beq  $a0, $t0, factR_one        # n == 1 goto factR_one
    addi $sp, $sp, -8               # allocate stack frame
    sw   $a0, 4($sp)                # save n
    sw   $ra, 0($sp)                # save return adress
    addi $a0, $a0, -1               # n - 1
    jal  factorialR                 # call factorialR
    lw   $a0, 4($sp)                # restore n
    lw   $ra, 0($sp)                # restore return adress
    addi $sp, $sp, 8                # free stack frame  
    mul  $v0, $v0, $a0              # return factorialR(n-1) * n
    jr   $ra
factR_one:
    li   $v0,1                      # return 1
    jr   $ra



# =====================================================================
# float falling_factorial(float k, int n)   k:$f12  n:$a0  ->  $f0
# Iterative: k * (k-1) * ... * (k-n+1)
# =====================================================================
falling_factorial:
    lwc1    $f0, f_one                  # product = 1.0
    li      $t0, 0                      # i = 0
ff_loop:
    slt     $t1, $t0, $a0               # $t1 = (i < n)
    beq     $t1, $zero, ff_end          # if i >= n goto done
    mtc1    $t0, $f4                    # move i into the FP register
    cvt.s.w $f4, $f4                    # $f4 = (float) i
    sub.s   $f4, $f12, $f4              # $f4 = k - i
    mul.s   $f0, $f0, $f4               # product *= (k - i)
    addi    $t0, $t0, 1                 # i++
    j       ff_loop
ff_end:   
    jr      $ra                         # return product


# =====================================================================
# float falling_factorialR(float k, int n)  k:$f12  n:$a0  ->  $f0
# Recursive: ffR(k, n) = ffR(k, n-1) * (k - n + 1), ffR(k, 0) = 1.0
# =====================================================================
falling_factorialR:
    slt     $t0, $zero, $a0             # $t0 = (0 < n)
    bne     $t0, $zero, ffR_rec         # if n > 0 goto ffR_rec
    lwc1    $f0, f_one                  # return 1.0
    jr      $ra
ffR_rec:      
    addi    $sp, $sp, -12               # allocate stack frame
    swc1    $f12, 8($sp)                # save k
    sw      $ra, 4($sp)                 # save return adress
    sw      $a0, 0($sp)                 # save n

    addi    $a0, $a0, -1                # n - 1
    jal     falling_factorialR          # call falling_factorialR 
    lwc1    $f12, 8($sp)                # restore k
    lw      $ra, 4($sp)                 # restore return adress
    lw      $a0, 0($sp)                 # restore n
    addi    $sp, $sp, 12                # free stack frame
    li      $t0, 1
    sub     $a0, $t0, $a0               # $a0 = 1 - n
    mtc1    $a0, $f4
    cvt.s.w $f4, $f4                    # $f4 = (float)(1 - n)
    add.s   $f4, $f12, $f4              # $f4 = k + (1 - n) = k - n + 1
    mul.s   $f0, $f0, $f4               # return ffR(k, n-1) * (k - n + 1)
    jr      $ra


# =====================================================================
# float binomial_series(float x, float k)   x:$f12  k:$f14  ->  $f0
#   $f20=x  $f22=k  $f24=sum  $f26=term  $f28=epsilon  $f30=temp  $s0=n
# =====================================================================
binomial_series:
    addiu   $sp, $sp, -32           # allocate stack frame
    sw      $ra, 28($sp)            # save callee-saved registers
    sw      $s0, 24($sp)
    swc1    $f20, 20($sp)
    swc1    $f22, 16($sp)
    swc1    $f24, 12($sp)
    swc1    $f26, 8($sp)
    swc1    $f28, 4($sp)
    swc1    $f30, 0($sp)

    mov.s   $f20, $f12               # $f20 = x
    mov.s   $f22, $f14               # $f22 = k

    jal     my_abs                   # call my_abs
    lwc1    $f4, f_one               # $f4 = 1.0
    c.lt.s  $f0, $f4                 # flag = (x < 1.0)
    bc1t    contineue                # if x < 1 goto contineue
    lwc1    $f0, f_zero              # else return 0.0
    j       bs_epilogue 
contineue:
    lwc1    $f24, f_one              # sum = 1.0
    lwc1    $f26, f_one              # term = 1.0
    li      $s0, 1                   # n = 1
    lwc1    $f28, f_epsilon          # epsilon = 0.01   
bs_loop:  
    mov.s   $f12, $f26               # $f12 = term
    jal     my_abs                   # call my_abs
    c.lt.s  $f28, $f0                # flag = my_abs(term) > epsilon 
    bc1f    end_bs_loop              # if term <= epsilon goto end_bs_loop

    mov.s   $f12, $f22               # $f12 = k
    addu    $a0, $s0, $zero          # $a0 = n     
    jal     falling_factorial        # call falling_factorial
    mov.s   $f30, $f0                # $f30 = falling_factorial(k, n)

    addu    $a0, $s0, $zero          # $a0 = n
    jal     factorial                # call factorial
    mtc1    $v0, $f4                 # $f4 = factorial(n)
    cvt.s.w $f4, $f4
    div.s   $f30, $f30, $f4          # $f30 = falling_factorialR(k, n) / factorialR(n))

    mov.s   $f12, $f20               # $f12 = x
    addu    $a0, $s0, $zero          # $a0 = n  
    jal     power                    # call power
    mul.s   $f26, $f30, $f0          # term = falling_factorialR(k, n) / factorialR(n)) * powerR(x, n)

    add.s   $f24, $f24, $f26         # sum += term
    addiu   $s0, $s0, 1              # n++

    li      $t0, 100000              # safety limit on the number of terms 
    slt     $t1, $t0, $s0            # $t1 = (100000 < n)
    bne     $t1, $zero, end_bs_loop  # if n > 100000 -> break
    j       bs_loop
end_bs_loop:
    mov.s   $f0, $f24                # return sum
bs_epilogue:
    lw      $ra, 28($sp)             # restore callee-saved registers
    lw      $s0, 24($sp)
    lwc1    $f20, 20($sp)
    lwc1    $f22, 16($sp)
    lwc1    $f24, 12($sp)
    lwc1    $f26, 8($sp)
    lwc1    $f28, 4($sp)
    lwc1    $f30, 0($sp)
    addiu   $sp, $sp, 32             # free stack frame    
    jr      $ra


# =====================================================================
# float binomial_recursive_r(x, k, n, current_term, epsilon)
#   x:$f12  k:$f14  current_term:$f16  epsilon:$f18  n:$a0  ->  $f0
#      frame: 20=ra 16=n 12=x 8=k 4=eps 0=temp/next_term
# =====================================================================
binomial_recursive_r:
    addiu   $sp, $sp, -28           # allocate stack frame
    sw      $ra, 24($sp)            # save return adress
    swc1    $f20, 20($sp)           # save reg $f20
    sw      $a0, 16($sp)            # save n
    swc1    $f12, 12($sp)           # save x
    swc1    $f14, 8($sp)            # save k
    swc1    $f16, 4($sp)            # save current_term
    swc1    $f18, 0($sp)            # save epsilon

    mov.s   $f12, $f16              # $f12 = current_term   

    jal     my_abs                  # call my_abs
    c.le.s  $f0, $f18               # flag = my_abs(current_term) <= epsilon 
    bc1t    brr_zero                # if so goto brr_zero 
    li      $t0, 1000               # $t0 = 1000
    lw      $a0, 16($sp)            # $a0 = n
    slt     $t1, $t0, $a0           # $t1 = n > 1000           
    bne     $t1, $zero, brr_zero    # if n > 1000 goto brr_zero

    lwc1    $f12, 8($sp)            # $f12 = k
    lw      $a0, 16($sp)            # $a0 = n
    jal     falling_factorialR      # call falling_factorialR   
    mov.s   $f20, $f0               # $f20 = falling_factorialR(k, n)

    lw      $a0, 16($sp)            # $a0 = n
    jal     factorialR              # call factorialR
    mtc1    $v0, $f4                # $f4 = $v0
    cvt.s.w $f4, $f4                # metatrepw tin int timi mesa ston $f4 se float
    div.s   $f20, $f20, $f4         # falling_factorialR(k, n) / factorialR(n)

    lw      $a0, 16($sp)            # $a0 = n
    lwc1    $f12, 12($sp)           # $f12 = x
    jal     powerR                  # call powerR
    mul.s   $f20, $f20, $f0         # $f20 = (falling_factorialR(k, n) / factorialR(n)) * powerR(x, n)

    lwc1    $f12, 12($sp)           # $f12 = x
    lwc1    $f14, 8($sp)            # $f14 = k
    lw      $a0, 16($sp)            # $a0 = n
    mov.s   $f16, $f20              # $f16 = next_term
    lwc1    $f18, 0($sp)            # $f18 = epsilon
    addi    $a0, $a0, 1             # $a0 = n + 1
    jal     binomial_recursive_r    # call binomial_recursive_r
    add.s   $f0, $f0, $f20          # return next_term + recursive result

    lw      $ra, 24($sp)            # restore return address
    lwc1    $f20, 20($sp)           # restore $f20
    addiu   $sp, $sp, 28            # free stack frame
    jr      $ra
brr_zero:
    lw      $ra, 24($sp)            # restore return address
    lwc1    $f20, 20($sp)           # restore $f20
    addiu   $sp, $sp, 28            # free stack frame
    lwc1    $f0, f_zero             # return 0.0
    jr      $ra

# =====================================================================
# float binomial_series_recursive(float x, float k)
#   x:$f12  k:$f14  ->  $f0
# Returns 0 if |x| >= 1, otherwise 1.0 + binomial_recursive_r(...)
# Registers: $f20=epsilon  $f22=first_term
# =====================================================================
binomial_series_recursive:
    addiu  $sp, $sp, -24            # allocate stack frame
    sw     $ra, 20($sp)             # save return address
    swc1   $f24, 16($sp)            # save callee-saved registers
    swc1   $f22, 12($sp)
    swc1   $f20, 8($sp)
    swc1   $f14, 4($sp)             # save k
    swc1   $f12, 0($sp)             # save x
 
    jal    my_abs                   # $f0 = x  ($f12 is still x)
    lwc1   $f4, f_one               # $f4 = 1.0
    c.le.s $f4, $f0                 # flag = (1.0 <= x)
    bc1t   bsr_zero                 # if x >= 1 goto bsr_zero
 
    lwc1   $f20, f_epsilon          # epsilon = 0.01
    lwc1   $f22, f_one              # first_term = 1.0
 
    lwc1   $f12, 0($sp)             # $f12 = x
    lwc1   $f14, 4($sp)             # $f14 = k
    mov.s  $f16, $f22               # $f16 = first_term
    mov.s  $f18, $f20               # $f18 = epsilon
    li     $a0, 1                   # $a0 = n = 1
    jal    binomial_recursive_r     # $f0 = binomial_recursive_r(x, k, 1, first_term, epsilon)
 
    add.s  $f0, $f0, $f22           # $f0 = first_term + result (before restoring $f22)
    lw     $ra, 20($sp)             # restore callee-saved registers
    lwc1   $f24, 16($sp)
    lwc1   $f22, 12($sp)
    lwc1   $f20, 8($sp)
    addiu  $sp, $sp, 24             # free stack frame
    jr     $ra
bsr_zero:
    lw     $ra, 20($sp)             # restore callee-saved registers
    lwc1   $f24, 16($sp)
    lwc1   $f22, 12($sp)
    lwc1   $f20, 8($sp)
    addiu  $sp, $sp, 24             # free stack frame
    lwc1   $f0, f_zero              # return 0.0
    jr     $ra

    
# =====================================================================
# main
# Prints the title, then for every x in [-0.9, 1] (step 0.2) and
# k in [0.5, 2) (step 0.1) prints (1+x)^k computed both ways.
# Registers: $f20=x  $f22=k  $f24=iterative result  $f26=recursive result
# ($f20-$f26 are preserved by the functions that use them)
# =====================================================================
main:
    la     $a0, title
    li     $v0, 4
    syscall                               # print the title
    la     $a0, subtitle 
    li     $v0, 4
    syscall                               # print the subtitle

    lwc1   $f20, f_xstart                 # x = -0.9
x_loop:
    lwc1   $f4, f_one
    c.le.s $f20, $f4                      # x <= 1 ?
    bc1f   main_end
    lwc1   $f22, f_kstart                 # k = 0.5
k_loop:
    lwc1   $f4, f_klimit 
    c.lt.s $f22, $f4                      # k < 2 ?
    bc1f   k_end

    mov.s  $f12, $f20                     # $f12 = x
    mov.s  $f14, $f22                     # $f13 = k
    jal    binomial_series                # call binomial_series
    mov.s  $f24, $f0                      # $f24 = binomial_series(x, k)


    mov.s  $f12, $f20                     # $f12 = x
    mov.s  $f14, $f22                     # $f13 = k
    jal    binomial_series_recursive      # call binomial_series_recursive 
    mov.s  $f26, $f0                      # $f26 = binomial_series_recursive(x,k)

    la     $a0, str1                      # print "(1+"
    li     $v0, 4
    syscall
    mov.s  $f12, $f20                     # x
    li     $v0, 2                         # print x value
    syscall
    la     $a0, str2                      # ")^"
    li     $v0, 4
    syscall
    mov.s  $f12, $f22                     # k
    li     $v0, 2                         # print k value
    syscall
    la     $a0, str4                      # "\t"
    li     $v0, 4
    syscall
    mov.s  $f12, $f24                     # binomial_series
    li     $v0, 2                         # print binomial_series return value
    syscall
    la     $a0, str3                      # "\t\t-->\t\t"
    li     $v0, 4
    syscall
    mov.s  $f12, $f26                     # binomial_series_recursive
    li     $v0, 2                         # print binomial_series_recursive return value
    syscall
    la     $a0, str5                      # print "\n"
    li     $v0, 4                
    syscall

    lwc1   $f4, f_kstep
    add.s  $f22, $f22, $f4                # k += 0.1
    j      k_loop
k_end:
    lwc1   $f4, f_xstep
    add.s  $f20, $f20, $f4                # x += 0.2
    j      x_loop
main_end:
    li     $v0, 10
    syscall






 








    
