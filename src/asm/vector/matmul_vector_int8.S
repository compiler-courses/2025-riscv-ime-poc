.globl matmul_asm_vector_int8
.type matmul_asm_vector_int8, @function

# void matmul_asm_vector_int8(const int8_t* a, const int8_t* b, int8_t* c, 
#                           int a_rows, int a_cols, int b_cols);
#
# a0 = a pointer
# a1 = b pointer
# a2 = c pointer
# a3 = a_rows
# a4 = a_cols (also b_rows)
# a5 = b_cols

matmul_asm_vector_int8:
    # Prologue
    addi sp, sp, -28
    sw ra, 24(sp)
    sw s0, 20(sp)
    sw s1, 16(sp)
    sw s2, 12(sp)
    sw s3, 8(sp)
    sw s4, 4(sp)
    sw s5, 0(sp)
    
    # Save input parameters
    mv s0, a0       # s0 = a pointer
    mv s1, a1       # s1 = b pointer
    mv s2, a2       # s2 = c pointer
    mv s3, a3       # s3 = a_rows
    mv s4, a4       # s4 = a_cols (also b_rows)
    mv s5, a5       # s5 = b_cols
    
    # Initialize outer loop counter (i = 0)
    li t0, 0        # t0 = i (row index for A and C)
    
outer_loop:
    # Check if i < a_rows
    bge t0, s3, end_outer_loop
    
    # Compute row offset for matrix A
    mul t1, t0, s4      # t1 = i * a_cols (row offset in A)
    add t5, s0, t1      # t5 = a + row_offset (pointer to A[i][0])
    
    # Initialize middle loop counter (j = 0)
    li t1, 0            # t1 = j (column index for B and C)
    
middle_loop:
    # Check if we can process a block of 8 columns at once (j+8 <= b_cols)
    addi t2, t1, 8
    bgt t2, s5, middle_loop_scalar
    
    # Process 8 columns at once using vector instructions
    # First, set the vector configuration
    li t3, 8            # Process 8 elements per iteration
    vsetvli t3, s4, e8, m1  # 8-bit elements, 1 register group
    
    # Initialize vector accumulator for 8 results to zero
    vmv.v.i v4, 0       # v4 = [0, 0, 0, 0, 0, 0, 0, 0]
    
    # Initialize k loop counter 
    li t2, 0            # t2 = k
    
vector_loop_k:
    # Compute offset for A[i][k]
    add t3, t5, t2      # t3 = pointer to A[i][k]
    
    # Load one element from A
    lb a6, 0(t3)        # a6 = A[i][k]
    
    # Broadcast to vector register
    vmv.v.x v1, a6      # v1 = [A[i][k], A[i][k],...]
    
    # Compute offset for B[k][j]
    mul t3, t2, s5      # t3 = k * b_cols
    add t3, t3, t1      # t3 = k * b_cols + j
    add t3, s1, t3      # t3 = pointer to B[k][j]
    
    # Load 8 elements from matrix B
    vle8.v v2, (t3)     # v2 = [B[k][j], B[k][j+1],...]
    
    # Multiply and accumulate: v4 += v1 * v2
    vmacc.vv v4, v1, v2 # v4 += A[i][k] * [B[k][j]...]
    
    # Increment k and loop
    addi t2, t2, 1
    blt t2, s4, vector_loop_k
    
    # Store result vector to C
    mul t3, t0, s5      # t3 = i * b_cols
    add t3, t3, t1      # t3 = i * b_cols + j
    add t3, s2, t3      # t3 = pointer to C[i][j]
    
    vse8.v v4, (t3)     # Store 8 results
    
    # Increment j by 8 and continue
    addi t1, t1, 8
    j middle_loop_continue
    
# Fallback to scalar processing for remaining columns
middle_loop_scalar:
    # Check if j < b_cols
    bge t1, s5, end_middle_loop
    
    # Initialize inner loop for scalar processing
    li t2, 0            # t2 = k
    li a6, 0            # Initialize sum to 0
    
inner_loop_scalar:
    # Check if k < a_cols
    bge t2, s4, end_inner_loop_scalar
    
    # Compute a_index = i * a_cols + k
    mul t3, t0, s4
    add t3, t3, t2
    add t3, s0, t3      # a + a_index
    
    # Compute b_index = k * b_cols + j
    mul t4, t2, s5
    add t4, t4, t1
    add t4, s1, t4      # b + b_index
    
    # Load a[i][k] and b[k][j]
    lb a4, 0(t3)        # a4 = a[i][k]
    lb a5, 0(t4)        # a5 = b[k][j]
    
    # sum += a[i][k] * b[k][j]
    mul a5, a4, a5
    add a6, a6, a5
    
    # Increment k
    addi t2, t2, 1
    j inner_loop_scalar
    
end_inner_loop_scalar:
    # Compute c_index = i * b_cols + j
    mul t3, t0, s5
    add t3, t3, t1
    add t3, s2, t3      # c + c_index
    
    # Store sum in c[i][j]
    sb a6, 0(t3)
    
    # Increment j
    addi t1, t1, 1
    
middle_loop_continue:
    j middle_loop
    
end_middle_loop:
    # Increment i
    addi t0, t0, 1
    j outer_loop
    
end_outer_loop:
    # Epilogue
    lw ra, 24(sp)
    lw s0, 20(sp)
    lw s1, 16(sp)
    lw s2, 12(sp)
    lw s3, 8(sp)
    lw s4, 4(sp)
    lw s5, 0(sp)
    addi sp, sp, 28
    ret