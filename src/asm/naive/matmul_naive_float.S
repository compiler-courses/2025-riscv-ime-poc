    .globl  matmul_asm_naive_float
    .type   matmul_asm_naive_float, @function

# void matmul_asm_naive_float(const float* a, const float* b, float* c,
# int a_rows, int a_cols, int b_cols);
#
# a0 = a pointer
# a1 = b pointer
# a2 = c pointer
# a3 = a_rows
# a4 = a_cols (also b_rows)
# a5 = b_cols

matmul_asm_naive_float:
# Prologue
    addi    sp, sp, -24
    sw      ra, 20(sp)
    sw      s0, 16(sp)
    sw      s1, 12(sp)
    sw      s2, 8(sp)
    sw      s3, 4(sp)
    sw      s4, 0(sp)

# Save input parameters
    mv      s0, a0                            # s0 = a pointer
    mv      s1, a1                            # s1 = b pointer
    mv      s2, a2                            # s2 = c pointer
    mv      s3, a3                            # s3 = a_rows
    mv      s4, a4                            # s4 = a_cols (also b_rows)
    mv      t0, a5                            # t0 = b_cols

# Initialize outer loop counter (i = 0)
    li      t1, 0                             # t1 = i

outer_loop:
# Check if i < a_rows
    bge     t1, s3, end_outer_loop

# Initialize middle loop counter (j = 0)
    li      t2, 0                             # t2 = j

middle_loop:
# Check if j < b_cols
    bge     t2, t0, end_middle_loop

# Compute c[i][j] = sum of a[i][k] * b[k][j]
# Initialize sum to 0
    li      t3, 0                             # t3 = k
    fmv.s.x fa0, zero

inner_loop:
# Check if k < a_cols
    bge     t3, s4, end_inner_loop

# Compute a_index = i * a_cols + k
    mul     t4, t1, s4
    add     t4, t4, t3
    slli    t4, t4, 2                         # Multiply by 4 (bytes per float)
    add     t4, s0, t4                        # a + a_index

# Compute b_index = k * b_cols + j
    mul     t5, t3, t0
    add     t5, t5, t2
    slli    t5, t5, 2                         # Multiply by 4 (bytes per float)
    add     t5, s1, t5                        # b + b_index

# Load a[i][k] and b[k][j]
    flw     fa1, 0(t4)                        # fa1 = a[i][k]
    flw     fa2, 0(t5)                        # fa2 = b[k][j]

# sum += a[i][k] * b[k][j]
    fmadd.s fa0, fa1, fa2, fa0

# Increment k
    addi    t3, t3, 1
    j       inner_loop

end_inner_loop:
# Compute c_index = i * b_cols + j
    mul     t4, t1, t0
    add     t4, t4, t2
    slli    t4, t4, 2                         # Multiply by 4 (bytes per float)
    add     t4, s2, t4                        # c + c_index

# Store sum in c[i][j]
    fsw     fa0, 0(t4)

# Increment j
    addi    t2, t2, 1
    j       middle_loop

end_middle_loop:
# Increment i
    addi    t1, t1, 1
    j       outer_loop

end_outer_loop:
# Epilogue
    lw      ra, 20(sp)
    lw      s0, 16(sp)
    lw      s1, 12(sp)
    lw      s2, 8(sp)
    lw      s3, 4(sp)
    lw      s4, 0(sp)
    addi    sp, sp, 24
    ret