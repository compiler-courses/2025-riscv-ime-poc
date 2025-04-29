    .globl matmul_asm_naive_int16
    .type  matmul_asm_naive_int16, @function

# void matmul_asm_naive_int16(const void* a, const void* b, void* c,
# int a_rows, int a_cols, int b_cols,
# int int_min, int int_max);
#
# a0 = a pointer
# a1 = b pointer
# a2 = c pointer
# a3 = a_rows
# a4 = a_cols (also b_rows)
# a5 = b_cols
# a6 = INT16_MIN
# a7 = INT16_MAX

matmul_asm_naive_int16:
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
    mv     s0, a0                            # s0 = a pointer
    mv     s1, a1                            # s1 = b pointer
    mv     s2, a2                            # s2 = c pointer
    mv     s3, a3                            # s3 = a_rows
    mv     s4, a4                            # s4 = a_cols (also b_rows)
    mv     s5, a5                            # s5 = b_cols
# a6 = INT16_MIN
# a7 = INT16_MAX

# Initialize outer loop (i)
    li     t1, 0                             # i = 0

outer_loop_int16:
    bge    t1, s3, end_matmul_int16          # if i >= a_rows, exit

# Initialize middle loop (j)
    li     t2, 0                             # j = 0

middle_loop_int16:
    bge    t2, s5, end_outer_int16           # if j >= b_cols, next row

# Initialize result accumulator
    li     t6, 0                             # sum = 0

# Initialize inner loop (k)
    li     t3, 0                             # k = 0

inner_loop_int16:
    bge    t3, s4, end_inner_int16           # if k >= a_cols, store result

# Calculate index for A[i][k] - for 16-bit elements
    mul    t4, t1, s4                        # t4 = i * a_cols
    add    t4, t4, t3                        # t4 = i * a_cols + k
    slli   t4, t4, 1                         # t4 = (i * a_cols + k) * 2 (16-bit = 2 bytes)
    add    t4, s0, t4                        # t4 = &A[i][k]

# Calculate index for B[k][j] - for 16-bit elements
    mul    t5, t3, s5                        # t5 = k * b_cols
    add    t5, t5, t2                        # t5 = k * b_cols + j
    slli   t5, t5, 1                         # t5 = (k * b_cols + j) * 2
    add    t5, s1, t5                        # t5 = &B[k][j]

# Load values (16-bit specific)
    lh     a3, 0(t4)                         # a3 = A[i][k]
    lh     a4, 0(t5)                         # a4 = B[k][j]

# Multiply and accumulate
    mul    a3, a3, a4                        # a3 = A[i][k] * B[k][j]
    add    t6, t6, a3                        # sum += a3

# Next k
    addi   t3, t3, 1
    j      inner_loop_int16

end_inner_int16:
# Clamp result between INT16_MIN and INT16_MAX
    bgt    t6, a7, clamp_max_int16
    blt    t6, a6, clamp_min_int16
    j      store_result_int16

clamp_max_int16:
    mv     t6, a7                            # result = INT16_MAX
    j      store_result_int16

clamp_min_int16:
    mv     t6, a6                            # result = INT16_MIN

store_result_int16:
# Calculate index for C[i][j] - for 16-bit elements
    mul    t4, t1, s5                        # t4 = i * b_cols
    add    t4, t4, t2                        # t4 = i * b_cols + j
    slli   t4, t4, 1                         # t4 = (i * b_cols + j) * 2
    add    t4, s2, t4                        # t4 = &C[i][j]

# Store result (16-bit specific)
    sh     t6, 0(t4)                         # C[i][j] = sum

# Next j
    addi   t2, t2, 1
    j      middle_loop_int16

end_outer_int16:
# Next i
    addi   t1, t1, 1
    j      outer_loop_int16

end_matmul_int16:
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