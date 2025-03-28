#pragma once

#include "matrix.h"
#include <string>
#include <typeinfo>
#include <typeindex>
#include <unordered_map>

// Implementation types
enum class MatMulImpl {
    CPP_NAIVE,      // C++ naive implementation
    ASM_NAIVE,      // Assembly naive implementation
    ASM_VECTOR,     // Assembly with vector instructions
    // Add more implementations as needed
};

// Implementation name mapping
inline std::string getImplName(MatMulImpl impl) {
    static const std::unordered_map<MatMulImpl, std::string> implNames = {
        {MatMulImpl::CPP_NAIVE, "C++ Naive"},
        {MatMulImpl::ASM_NAIVE, "Assembly Naive"},
        {MatMulImpl::ASM_VECTOR, "Assembly Vector"}
    };
    
    auto it = implNames.find(impl);
    return it != implNames.end() ? it->second : "Unknown";
}

// C++ reference implementation template
template<typename T>
Matrix<T> matmul_cpp_naive(const Matrix<T>& a, const Matrix<T>& b) {
    if (a.cols() != b.rows()) {
        throw std::invalid_argument("Matrix dimensions mismatch for multiplication");
    }
    
    Matrix<T> result(a.rows(), b.cols());
    
    for (size_t i = 0; i < a.rows(); ++i) {
        for (size_t j = 0; j < b.cols(); ++j) {
            T sum = static_cast<T>(0);
            for (size_t k = 0; k < a.cols(); ++k) {
                sum += a.at(i, k) * b.at(k, j);
            }
            result.at(i, j) = sum;
        }
    }
    
    return result;
}

// Assembly implementation declarations for different types
extern "C" {
    // Float implementations
    void matmul_asm_naive_float(const float* a, const float* b, float* c, 
                               int a_rows, int a_cols, int b_cols);
    
    void matmul_asm_vector_float(const float* a, const float* b, float* c, 
                                int a_rows, int a_cols, int b_cols);
    
    // Int8 implementations
    void matmul_asm_naive_int8(const int8_t* a, const int8_t* b, int8_t* c, 
                              int a_rows, int a_cols, int b_cols);
    
    void matmul_asm_vector_int8(const int8_t* a, const int8_t* b, int8_t* c, 
                               int a_rows, int a_cols, int b_cols);
}

// Wrapper function to call the appropriate assembly implementation
template<typename T>
void call_asm_impl(const T* a, const T* b, T* c, int a_rows, int a_cols, int b_cols, MatMulImpl impl) {
    // Default implementation (fallback to C++)
    matmul_cpp_naive(Matrix<T>(a_rows, a_cols, std::vector<T>(a, a + a_rows * a_cols)),
                    Matrix<T>(a_cols, b_cols, std::vector<T>(b, b + a_cols * b_cols))).data();
}

// Specializations for supported types
template<>
inline void call_asm_impl<float>(const float* a, const float* b, float* c, 
                               int a_rows, int a_cols, int b_cols, MatMulImpl impl) {
    if (impl == MatMulImpl::ASM_NAIVE) {
        matmul_asm_naive_float(a, b, c, a_rows, a_cols, b_cols);
    } else if (impl == MatMulImpl::ASM_VECTOR) {
        matmul_asm_vector_float(a, b, c, a_rows, a_cols, b_cols);
    }
}

template<>
inline void call_asm_impl<int8_t>(const int8_t* a, const int8_t* b, int8_t* c, 
                                int a_rows, int a_cols, int b_cols, MatMulImpl impl) {
    if (impl == MatMulImpl::ASM_NAIVE) {
        matmul_asm_naive_int8(a, b, c, a_rows, a_cols, b_cols);
    } else if (impl == MatMulImpl::ASM_VECTOR) {
        matmul_asm_vector_int8(a, b, c, a_rows, a_cols, b_cols);
    }
}

// Main matmul template function
template<typename T>
Matrix<T> matmul(const Matrix<T>& a, const Matrix<T>& b, MatMulImpl impl = MatMulImpl::CPP_NAIVE) {
    if (a.cols() != b.rows()) {
        throw std::invalid_argument("Matrix dimensions mismatch for multiplication");
    }
    
    // For C++ reference implementation, call directly
    if (impl == MatMulImpl::CPP_NAIVE) {
        return matmul_cpp_naive(a, b);
    }
    
    // For assembly implementations, prepare data and call the assembly function
    Matrix<T> result(a.rows(), b.cols());
    
    call_asm_impl(a.data(), b.data(), result.data(), 
                 a.rows(), a.cols(), b.cols(), impl);
    
    return result;
}