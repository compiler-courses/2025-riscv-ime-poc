    .globl matmul_asm_naive_int8
    .type  matmul_asm_naive_int8, @function

# void matmul_asm_naive_int8(const void* a, const void* b, void* c,
# int a_rows, int a_cols, int b_cols,
# int int_min, int int_max);
#
# a0 = a pointer
# a1 = b pointer
# a2 = c pointer
# a3 = a_rows
# a4 = a_cols (also b_rows)
# a5 = b_cols
# a6 = INT8_MIN
# a7 = INT8_MAX

matmul_asm_naive_int8:
# Prologue
    addi   sp, sp, -28
    sw     ra, 24(sp)
    sw     s0, 20(sp)
    sw     s1, 16(sp)
    sw     s2, 12(sp)
    sw     s3, 8(sp)
    sw     s4, 4(sp)
    sw     s5, 0(sp)

# Save input parameters
    mv     s0, a0                           # s0 = a pointer
    mv     s1, a1                           # s1 = b pointer
    mv     s2, a2                           # s2 = c pointer
    mv     s3, a3                           # s3 = a_rows
    mv     s4, a4                           # s4 = a_cols (also b_rows)
    mv     s5, a5                           # s5 = b_cols
# a6 = INT_MIN
# a7 = INT_MAX

# Initialize outer loop (i)
    li     t1, 0                            # i = 0

outer_loop_int8:
    bge    t1, s3, end_matmul_int8          # if i >= a_rows, exit

# Initialize middle loop (j)
    li     t2, 0                            # j = 0

middle_loop_int8:
    bge    t2, s5, end_outer_int8           # if j >= b_cols, next row

# Initialize result accumulator
    li     t6, 0                            # sum = 0

# Initialize inner loop (k)
    li     t3, 0                            # k = 0

inner_loop_int8:
    bge    t3, s4, end_inner_int8           # if k >= a_cols, store result

# Calculate index for A[i][k]
    mul    t4, t1, s4                       # t4 = i * a_cols
    add    t4, t4, t3                       # t4 = i * a_cols + k
    add    t4, s0, t4                       # t4 = &A[i][k]

# Calculate index for B[k][j]
    mul    t5, t3, s5                       # t5 = k * b_cols
    add    t5, t5, t2                       # t5 = k * b_cols + j
    add    t5, s1, t5                       # t5 = &B[k][j]

# Load values (8-bit specific)
    lb     a3, 0(t4)                        # a3 = A[i][k]
    lb     a4, 0(t5)                        # a4 = B[k][j]

# Multiply and accumulate
    mul    a3, a3, a4                       # a3 = A[i][k] * B[k][j]
    add    t6, t6, a3                       # sum += a3

# Next k
    addi   t3, t3, 1
    j      inner_loop_int8

end_inner_int8:
# Clamp result between INT8_MIN and INT8_MAX
    bgt    t6, a7, clamp_max_int8
    blt    t6, a6, clamp_min_int8
    j      store_result_int8

clamp_max_int8:
    mv     t6, a7                           # result = INT8_MAX
    j      store_result_int8

clamp_min_int8:
    mv     t6, a6                           # result = INT8_MIN

store_result_int8:
# Calculate index for C[i][j]
    mul    t4, t1, s5                       # t4 = i * b_cols
    add    t4, t4, t2                       # t4 = i * b_cols + j
    add    t4, s2, t4                       # t4 = &C[i][j]

# Store result (8-bit specific)
    sb     t6, 0(t4)                        # C[i][j] = sum

# Next j
    addi   t2, t2, 1
    j      middle_loop_int8

end_outer_int8:
# Next i
    addi   t1, t1, 1
    j      outer_loop_int8

end_matmul_int8:
# Epilogue
    lw     ra, 24(sp)
    lw     s0, 20(sp)
    lw     s1, 16(sp)
    lw     s2, 12(sp)
    lw     s3, 8(sp)
    lw     s4, 4(sp)
    lw     s5, 0(sp)
    addi   sp, sp, 28
    ret