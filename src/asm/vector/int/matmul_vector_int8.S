    .globl matmul_asm_vector_int8
    .type  matmul_asm_vector_int8, @function

matmul_asm_vector_int8:
# Prologue
    addi   sp, sp, -112
    sd     ra, 104(sp)
    sd     s0, 96(sp)
    sd     s1, 88(sp)
    sd     s2, 80(sp)
    sd     s3, 72(sp)
    sd     s4, 64(sp)
    sd     s5, 56(sp)
    sd     s6, 48(sp)
    sd     s7, 40(sp)
    sd     s8, 32(sp)
    sd     s9, 24(sp)

# Save input parameters
    mv     s0, a0                            # s0 = A matrix pointer
    mv     s1, a1                            # s1 = B matrix pointer
    mv     s2, a2                            # s2 = C matrix pointer
    mv     s3, a3                            # s3 = a_rows
    mv     s4, a4                            # s4 = a_cols
    mv     s5, a5                            # s5 = b_cols
    mv     s6, a6                            # s6 = INT8_MIN
    mv     s7, a7                            # s7 = INT8_MAX

# Load stack arguments
    lwu    s8, 112(sp)                       # s8 = clamp_freq
    lwu    s9, 116(sp)                       # s9 = vlen_bytes

# Initialize outer loop (i)
    li     t1, 0                             # i = 0

outer_loop_vec_int8:
    bge    t1, s3, end_matmul_vec_int8       # Exit if i >= a_rows

# Initialize middle loop (j)
    li     t2, 0                             # j = 0

middle_loop_vec_int8:
    bge    t2, s5, end_outer_vec_int8        # Exit if j >= b_cols

# Initialize result accumulator
    li     t6, 0                             # sum = 0

# Initialize inner loop (k)
    li     t3, 0                             # k = 0

inner_loop_vec_int8:
    bge    t3, s4, end_inner_vec_int8        # Exit if k >= a_cols

# Calculate index for A[i][k]
    mul    a3, t1, s4                        # a3 = i * a_cols
    add    a3, a3, t3                        # a3 = i * a_cols + k
    add    a3, s0, a3                        # a3 = &A[i][k]

# Calculate index for B[k][j]
    mul    a4, t3, s5                        # a4 = k * b_cols
    add    a4, a4, t2                        # a4 = k * b_cols + j
    add    a4, s1, a4                        # a4 = &B[k][j]

# Load values (8-bit specific)
    lb     a5, 0(a3)                         # a5 = A[i][k]
    lb     a6, 0(a4)                         # a6 = B[k][j]

# Multiply and accumulate
    mul    a5, a5, a6                        # a5 = A[i][k] * B[k][j]
    add    t6, t6, a5                        # sum += a5

# Next k
    addi   t3, t3, 1                         # k++
    j      inner_loop_vec_int8               # Continue inner loop

end_inner_vec_int8:
# Clamp result between INT8_MIN and INT8_MAX
    bgt    t6, s7, clamp_max_vec_int8        # if sum > INT8_MAX, clamp to INT8_MAX
    blt    t6, s6, clamp_min_vec_int8        # if sum < INT8_MIN, clamp to INT8_MIN
    j      store_result_vec_int8             # Otherwise, store the result as is

clamp_max_vec_int8:
    mv     t6, s7                            # sum = INT8_MAX
    j      store_result_vec_int8

clamp_min_vec_int8:
    mv     t6, s6                            # sum = INT8_MIN

store_result_vec_int8:
# Calculate index for C[i][j]
    mul    a3, t1, s5                        # a3 = i * b_cols
    add    a3, a3, t2                        # a3 = i * b_cols + j
    add    a3, s2, a3                        # a3 = &C[i][j]

# Store result (8-bit specific)
    sb     t6, 0(a3)                         # C[i][j] = sum

# Next j
    addi   t2, t2, 1                         # j++
    j      middle_loop_vec_int8              # Continue middle loop

end_outer_vec_int8:
# Next i
    addi   t1, t1, 1                         # i++
    j      outer_loop_vec_int8               # Continue outer loop

end_matmul_vec_int8:
# Epilogue
    ld     ra, 104(sp)
    ld     s0, 96(sp)
    ld     s1, 88(sp)
    ld     s2, 80(sp)
    ld     s3, 72(sp)
    ld     s4, 64(sp)
    ld     s5, 56(sp)
    ld     s6, 48(sp)
    ld     s7, 40(sp)
    ld     s8, 32(sp)
    ld     s9, 24(sp)
    addi   sp, sp, 112                       # Restore stack pointer
    ret                                      # Return to caller