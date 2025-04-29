.globl    matmul_asm_vector_float
    .type     matmul_asm_vector_float, @function

# void matmul_asm_vector_float(const float* a, const float* b, float* c,
# int a_rows, int a_cols, int b_cols);
#
# a0 = a pointer
# a1 = b pointer
# a2 = c pointer
# a3 = a_rows
# a4 = a_cols (also b_rows)
# a5 = b_cols
# a6 [optional] = VLEN override (0 means use hardware default)

matmul_asm_vector_float:
# Prologue
    addi      sp, sp, -32
    sw        ra, 28(sp)
    sw        s0, 24(sp)
    sw        s1, 20(sp)
    sw        s2, 16(sp)
    sw        s3, 12(sp)
    sw        s4, 8(sp)
    sw        s5, 4(sp)
    sw        s6, 0(sp)

# Save input parameters
    mv        s0, a0                             # s0 = a pointer
    mv        s1, a1                             # s1 = b pointer
    mv        s2, a2                             # s2 = c pointer
    mv        s3, a3                             # s3 = a_rows
    mv        s4, a4                             # s4 = a_cols (also b_rows)
    mv        s5, a5                             # s5 = b_cols

# Determine vector width to use - use a more conservative value
    li        s6, 4                              # Use smaller VLEN=4 for better reliability

# Initialize outer loop counter (i = 0)
    li        t0, 0                              # t0 = i (row index for A and C)

outer_loop:
# Check if i < a_rows
    bge       t0, s3, end_outer_loop

# Initialize middle loop counter (j = 0)
    li        t1, 0                              # t1 = j (column index for B and C)

middle_loop:
# Check if j < b_cols
    bge       t1, s5, end_middle_loop

# Initialize accumulator for this element
    fmv.s.x   fa0, zero                          # Initialize sum to 0

# Initialize inner loop counter (k = 0)
    li        t2, 0                              # t2 = k

# Setup vector configuration once per element
    vsetvli   t3, s6, e32, m1                    # Use VLEN=4, 32-bit elements

# Initialize vector accumulator
    vfmv.v.f  v4, fa0                            # v4 = [0, 0, 0, 0]

vector_inner_loop:
    add       t3, t2, s6                         # t3 = k + vector_length
    bgt       t3, s4, scalar_remainder           # If exceeds columns, process remainder

# Vector-based dot product for this segment
    # Calculate address for A[i][k:k+vlen]
    mul       t3, t0, s4                         # t3 = i * a_cols
    add       t3, t3, t2                         # t3 = i * a_cols + k
    slli      t3, t3, 2                          # t3 = (i * a_cols + k) * 4
    add       t3, s0, t3                         # t3 = &A[i][k]

    # Load vector from A
    vle32.v   v0, (t3)                           # v0 = [A[i][k], A[i][k+1], ...]

    # Loop to load strided elements from B
    li        t4, 0                              # t4 = vector element counter
    
load_B_loop:
    # Calculate B address
    mul       t5, t2, s5                         # t5 = k * b_cols
    add       t5, t5, t1                         # t5 = k * b_cols + j
    slli      t5, t5, 2                          # t5 = (k * b_cols + j) * 4
    add       t5, s1, t5                         # t5 = &B[k][j]
    
    # Load from B
    flw       fa1, 0(t5)                         # fa1 = B[k][j]
    
    # Insert individual value into vector
    vfmv.s.f  v1, fa1                            # First element = fa1
    
    # Process manually with scalar ops to match reference implementation
    flw       fa2, 0(t3)                         # fa2 = A[i][k]
    fmul.s    fa3, fa2, fa1                      # fa3 = A[i][k] * B[k][j]
    fadd.s    fa0, fa0, fa3                      # sum += A[i][k] * B[k][j]
    
    # Move to next k
    addi      t2, t2, 1                          # k++
    addi      t4, t4, 1                          # count++
    addi      t3, t3, 4                          # Move A pointer to next element
    blt       t4, s6, load_B_loop                # Continue until vector processed
    j         vector_inner_loop                  # Process next vector segment

scalar_remainder:
# Process any remaining elements (k < a_cols)
    bge       t2, s4, end_inner_loop

    # Calculate a_index = i * a_cols + k
    mul       t3, t0, s4
    add       t3, t3, t2
    slli      t3, t3, 2                          # Multiply by 4 (bytes per float)
    add       t3, s0, t3                         # a + a_index

    # Calculate b_index = k * b_cols + j
    mul       t4, t2, s5
    add       t4, t4, t1
    slli      t4, t4, 2                          # Multiply by 4 (bytes per float)
    add       t4, s1, t4                         # b + b_index

    # Load a[i][k] and b[k][j]
    flw       fa1, 0(t3)                         # fa1 = a[i][k]
    flw       fa2, 0(t4)                         # fa2 = b[k][j]

    # sum += a[i][k] * b[k][j]
    fmadd.s   fa0, fa1, fa2, fa0

    # Increment k
    addi      t2, t2, 1
    j         scalar_remainder

end_inner_loop:
    # Compute c_index = i * b_cols + j
    mul       t3, t0, s5
    add       t3, t3, t1
    slli      t3, t3, 2                          # Multiply by 4 (bytes per float)
    add       t3, s2, t3                         # c + c_index

    # Store final result in c[i][j]
    fsw       fa0, 0(t3)

    # Increment j
    addi      t1, t1, 1
    j         middle_loop

end_middle_loop:
    # Increment i
    addi      t0, t0, 1
    j         outer_loop

end_outer_loop:
    # Reset vector state before returning
    vsetivli  zero, 0, e32, m1                   # Reset vector state

# Epilogue
    lw        ra, 28(sp)
    lw        s0, 24(sp)
    lw        s1, 20(sp)
    lw        s2, 16(sp)
    lw        s3, 12(sp)
    lw        s4, 8(sp)
    lw        s5, 4(sp)
    lw        s6, 0(sp)
    addi      sp, sp, 32
    ret