    .globl matmul_asm_vector_int16
    .type  matmul_asm_vector_int16, @function

# void matmul_asm_vector_int16(const void* a, const void* b, void* c,
# int a_rows, int a_cols, int b_cols,
# int int_min, int int_max, int clamp_freq, int vlen);

matmul_asm_vector_int16:
# Prologue
    addi   sp, sp, -48
    sw     ra, 44(sp)
    sw     s0, 40(sp)
    sw     s1, 36(sp)
    sw     s2, 32(sp)
    sw     s3, 28(sp)
    sw     s4, 24(sp)
    sw     s5, 20(sp)
    sw     s6, 16(sp)
    sw     s7, 12(sp)
    sw     s8, 8(sp)
    sw     s9, 4(sp)
    sw     s10, 0(sp)

# Save input parameters
    mv     s0, a0                             # s0 = a pointer
    mv     s1, a1                             # s1 = b pointer
    mv     s2, a2                             # s2 = c pointer
    mv     s3, a3                             # s3 = a_rows
    mv     s4, a4                             # s4 = a_cols
    mv     s5, a5                             # s5 = b_cols
    mv     s6, a6                             # s6 = INT16_MIN
    mv     s7, a7                             # s7 = INT16_MAX
    lw     s8, 48(sp)                         # s8 = clamp_freq (unused)
    lw     s9, 52(sp)                         # s9 = vlen_bytes (unused)

# Initialize outer loop (i)
    li     t1, 0                              # i = 0

outer_loop_vec_int16:
    bge    t1, s3, end_matmul_vec_int16       # if i >= a_rows, exit

# Initialize middle loop (j)
    li     t2, 0                              # j = 0

middle_loop_vec_int16:
    bge    t2, s5, end_outer_vec_int16        # if j >= b_cols, next row

# Initialize result accumulator
    li     t6, 0                              # sum = 0

# Initialize inner loop (k)
    li     t3, 0                              # k = 0

inner_loop_vec_int16:
    bge    t3, s4, end_inner_vec_int16        # if k >= a_cols, store result

# Calculate index for A[i][k] - for 16-bit elements
    mul    a3, t1, s4                         # a3 = i * a_cols
    add    a3, a3, t3                         # a3 = i * a_cols + k
    slli   a3, a3, 1                          # a3 = (i * a_cols + k) * 2 (16-bit = 2 bytes)
    add    a3, s0, a3                         # a3 = &A[i][k]

# Calculate index for B[k][j] - for 16-bit elements
    mul    a4, t3, s5                         # a4 = k * b_cols
    add    a4, a4, t2                         # a4 = k * b_cols + j
    slli   a4, a4, 1                          # a4 = (k * b_cols + j) * 2
    add    a4, s1, a4                         # a4 = &B[k][j]

# Load values (16-bit specific)
    lh     a5, 0(a3)                          # a5 = A[i][k]
    lh     a6, 0(a4)                          # a6 = B[k][j]

# Multiply and accumulate
    mul    a5, a5, a6                         # a5 = A[i][k] * B[k][j]
    add    t6, t6, a5                         # sum += a5

# Next k
    addi   t3, t3, 1                          # k++
    j      inner_loop_vec_int16               # Continue inner loop

end_inner_vec_int16:
# Clamp result between INT16_MIN and INT16_MAX
    bgt    t6, s7, clamp_max_vec_int16        # if sum > INT16_MAX, clamp to INT16_MAX
    blt    t6, s6, clamp_min_vec_int16        # if sum < INT16_MIN, clamp to INT16_MIN
    j      store_result_vec_int16             # Otherwise, store the result as is

clamp_max_vec_int16:
    mv     t6, s7                             # sum = INT16_MAX
    j      store_result_vec_int16

clamp_min_vec_int16:
    mv     t6, s6                             # sum = INT16_MIN

store_result_vec_int16:
# Calculate index for C[i][j] - for 16-bit elements
    mul    a3, t1, s5                         # a3 = i * b_cols
    add    a3, a3, t2                         # a3 = i * b_cols + j
    slli   a3, a3, 1                          # a3 = (i * b_cols + j) * 2
    add    a3, s2, a3                         # a3 = &C[i][j]

# Store result (16-bit specific)
    sh     t6, 0(a3)                          # C[i][j] = sum

# Next j
    addi   t2, t2, 1                          # j++
    j      middle_loop_vec_int16              # Continue middle loop

end_outer_vec_int16:
# Next i
    addi   t1, t1, 1                          # i++
    j      outer_loop_vec_int16               # Continue outer loop

end_matmul_vec_int16:
# Epilogue
    lw     ra, 44(sp)
    lw     s0, 40(sp)
    lw     s1, 36(sp)
    lw     s2, 32(sp)
    lw     s3, 28(sp)
    lw     s4, 24(sp)
    lw     s5, 20(sp)
    lw     s6, 16(sp)
    lw     s7, 12(sp)
    lw     s8, 8(sp)
    lw     s9, 4(sp)
    lw     s10, 0(sp)
    addi   sp, sp, 48                         # Restore stack pointer
    ret                                       # Return to caller