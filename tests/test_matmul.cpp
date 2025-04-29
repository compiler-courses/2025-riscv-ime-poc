// #include <gtest/gtest.h>
// #include "matrix.h"
// #include "matmul.h"

// // Testing for float type
// class MatMulFloatTest : public ::testing::Test {
// protected:
//     void SetUp() override {
//         // Create test matrices
//         a = Matrix<float>(3, 2);
//         b = Matrix<float>(2, 4);
        
//         // Initialize with known values
//         a.at(0, 0) = 1.0f; a.at(0, 1) = 2.0f;
//         a.at(1, 0) = 3.0f; a.at(1, 1) = 4.0f;
//         a.at(2, 0) = 5.0f; a.at(2, 1) = 6.0f;
        
//         b.at(0, 0) = 7.0f; b.at(0, 1) = 8.0f; b.at(0, 2) = 9.0f; b.at(0, 3) = 10.0f;
//         b.at(1, 0) = 11.0f; b.at(1, 1) = 12.0f; b.at(1, 2) = 13.0f; b.at(1, 3) = 14.0f;
//     }
    
//     Matrix<float> a;
//     Matrix<float> b;
// };

// TEST_F(MatMulFloatTest, CPPNaiveImplementation) {
//     Matrix<float> c = matmul(a, b, MatMulImpl::CPP_NAIVE);
    
//     EXPECT_EQ(c.rows(), 3);
//     EXPECT_EQ(c.cols(), 4);
    
//     // Expected results calculated by hand
//     EXPECT_FLOAT_EQ(c.at(0, 0), 29.0f);  // 1*7 + 2*11
//     EXPECT_FLOAT_EQ(c.at(0, 1), 32.0f);  // 1*8 + 2*12
//     EXPECT_FLOAT_EQ(c.at(0, 2), 35.0f);  // 1*9 + 2*13
//     EXPECT_FLOAT_EQ(c.at(0, 3), 38.0f);  // 1*10 + 2*14
    
//     EXPECT_FLOAT_EQ(c.at(1, 0), 65.0f);  // 3*7 + 4*11
//     EXPECT_FLOAT_EQ(c.at(1, 1), 72.0f);  // 3*8 + 4*12
//     EXPECT_FLOAT_EQ(c.at(1, 2), 79.0f);  // 3*9 + 4*13
//     EXPECT_FLOAT_EQ(c.at(1, 3), 86.0f);  // 3*10 + 4*14
    
//     EXPECT_FLOAT_EQ(c.at(2, 0), 101.0f); // 5*7 + 6*11
//     EXPECT_FLOAT_EQ(c.at(2, 1), 112.0f); // 5*8 + 6*12
//     EXPECT_FLOAT_EQ(c.at(2, 2), 123.0f); // 5*9 + 6*13
//     EXPECT_FLOAT_EQ(c.at(2, 3), 134.0f); // 5*10 + 6*14
// }

// TEST_F(MatMulFloatTest, AsmNaiveImplementation) {
//     Matrix<float> c_cpp = matmul(a, b, MatMulImpl::CPP_NAIVE);
//     Matrix<float> c_asm = matmul(a, b, MatMulImpl::ASM_NAIVE);
    
//     EXPECT_TRUE(c_cpp.equals(c_asm));
// }

// TEST_F(MatMulFloatTest, AsmVectorImplementation) {
//     Matrix<float> c_cpp = matmul(a, b, MatMulImpl::CPP_NAIVE);
//     Matrix<float> c_asm = matmul(a, b, MatMulImpl::ASM_VECTOR);
    
//     EXPECT_TRUE(c_cpp.equals(c_asm));
// }

// // Testing for int32_t type
// class MatMulInt32Test : public ::testing::Test {
// protected:
//     void SetUp() override {
//         // Create test matrices
//         a = Matrix<int32_t>(3, 2);
//         b = Matrix<int32_t>(2, 4);
        
//         // Initialize with known values
//         a.at(0, 0) = 1; a.at(0, 1) = 2;
//         a.at(1, 0) = 3; a.at(1, 1) = 4;
//         a.at(2, 0) = 5; a.at(2, 1) = 6;
        
//         b.at(0, 0) = 7; b.at(0, 1) = 8; b.at(0, 2) = 9; b.at(0, 3) = 10;
//         b.at(1, 0) = 11; b.at(1, 1) = 12; b.at(1, 2) = 13; b.at(1, 3) = 14;
//     }
    
//     Matrix<int32_t> a;
//     Matrix<int32_t> b;
// };

// TEST_F(MatMulInt32Test, CPPNaiveImplementation) {
//     Matrix<int32_t> c = matmul(a, b, MatMulImpl::CPP_NAIVE);
    
//     EXPECT_EQ(c.rows(), 3);
//     EXPECT_EQ(c.cols(), 4);
    
//     // Expected results calculated by hand
//     EXPECT_EQ(c.at(0, 0), 29);  // 1*7 + 2*11
//     EXPECT_EQ(c.at(0, 1), 32);  // 1*8 + 2*12
//     EXPECT_EQ(c.at(0, 2), 35);  // 1*9 + 2*13
//     EXPECT_EQ(c.at(0, 3), 38);  // 1*10 + 2*14
    
//     EXPECT_EQ(c.at(1, 0), 65);  // 3*7 + 4*11
//     EXPECT_EQ(c.at(1, 1), 72);  // 3*8 + 4*12
//     EXPECT_EQ(c.at(1, 2), 79);  // 3*9 + 4*13
//     EXPECT_EQ(c.at(1, 3), 86);  // 3*10 + 4*14
    
//     EXPECT_EQ(c.at(2, 0), 101); // 5*7 + 6*11
//     EXPECT_EQ(c.at(2, 1), 112); // 5*8 + 6*12
//     EXPECT_EQ(c.at(2, 2), 123); // 5*9 + 6*13
//     EXPECT_EQ(c.at(2, 3), 134); // 5*10 + 6*14
// }

// TEST_F(MatMulInt32Test, AsmNaiveImplementation) {
//     Matrix<int32_t> c_cpp = matmul(a, b, MatMulImpl::CPP_NAIVE);
//     Matrix<int32_t> c_asm = matmul(a, b, MatMulImpl::ASM_NAIVE);
    
//     EXPECT_TRUE(c_cpp.equals(c_asm));
// }

// TEST_F(MatMulInt32Test, AsmVectorImplementation) {
//     Matrix<int32_t> c_cpp = matmul(a, b, MatMulImpl::CPP_NAIVE);
//     Matrix<int32_t> c_asm = matmul(a, b, MatMulImpl::ASM_VECTOR);
    
//     EXPECT_TRUE(c_cpp.equals(c_asm));
// }