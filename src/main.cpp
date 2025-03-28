#include <iostream>
#include <chrono>
#include <iomanip>
#include <typeinfo>
#include <string>
#include "hpp/matrix.h"
#include "hpp/matmul.h"

template<typename T>
std::string getTypeName() {
    if (std::is_same<T, float>::value) return "float";
    if (std::is_same<T, int8_t>::value) return "int8_t";
    if (std::is_same<T, int32_t>::value) return "int32_t";
    return "unknown";
}

template<typename T>
void printTimingInfo(const std::string& implName, double milliseconds) {
    std::cout << std::left << std::setw(20) << implName 
              << "Time: " << std::fixed << std::setprecision(3) 
              << milliseconds << " ms" << std::endl;
}

template<typename T>
void runBenchmark(size_t size) {
    std::cout << "\n==== Matrix multiplication benchmark (" << size << "x" << size 
              << ") with type " << getTypeName<T>() << " ====" << std::endl;
    
    Matrix<T> a(size, size);
    Matrix<T> b(size, size);
    
    // Initialize with random values
    a.randomize();
    b.randomize();
    
    // Test all implementations and measure time
    auto start = std::chrono::high_resolution_clock::now();
    Matrix<T> c_cpp = matmul(a, b, MatMulImpl::CPP_NAIVE);
    auto end = std::chrono::high_resolution_clock::now();
    auto cpp_time = std::chrono::duration<double, std::milli>(end - start).count();
    printTimingInfo<T>("C++ Naive:", cpp_time);
    
    start = std::chrono::high_resolution_clock::now();
    Matrix<T> c_asm_naive = matmul(a, b, MatMulImpl::ASM_NAIVE);
    end = std::chrono::high_resolution_clock::now();
    auto asm_naive_time = std::chrono::duration<double, std::milli>(end - start).count();
    printTimingInfo<T>("ASM Naive:", asm_naive_time);
    
    start = std::chrono::high_resolution_clock::now();
    Matrix<T> c_asm_vector = matmul(a, b, MatMulImpl::ASM_VECTOR);
    end = std::chrono::high_resolution_clock::now();
    auto asm_vector_time = std::chrono::duration<double, std::milli>(end - start).count();
    printTimingInfo<T>("ASM Vector:", asm_vector_time);
    
    // Verify all implementations produce the same result
    bool naive_ok = c_cpp.equals(c_asm_naive);
    bool vector_ok = c_cpp.equals(c_asm_vector);
    
    std::cout << "\nVerification:" << std::endl;
    std::cout << "  ASM Naive:  " << (naive_ok ? "PASS" : "FAIL") << std::endl;
    std::cout << "  ASM Vector: " << (vector_ok ? "PASS" : "FAIL") << std::endl;
    
    // Display speedup
    std::cout << "\nSpeedup:" << std::endl;
    std::cout << "  ASM Naive:  " << (cpp_time / asm_naive_time) << "x" << std::endl;
    std::cout << "  ASM Vector: " << (cpp_time / asm_vector_time) << "x" << std::endl;
}

int main() {
    const size_t small_size = 32;
    const size_t medium_size = 64;
    
    // Run benchmarks for different types
    runBenchmark<float>(small_size);
    runBenchmark<int8_t>(small_size);
    
    runBenchmark<float>(medium_size);
    runBenchmark<int8_t>(medium_size);
    
    return 0;
}