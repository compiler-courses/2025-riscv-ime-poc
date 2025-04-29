#include "hpp/matmul.h"
#include "hpp/matrix.h"
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include <typeinfo>
#include <vector>
#include <algorithm>

template <typename T> std::string getTypeName() {
  if (std::is_same<T, float>::value)
    return "float";
  if (std::is_same<T, int8_t>::value)
    return "int8_t";
  if (std::is_same<T, int16_t>::value)
    return "int16_t";
  if (std::is_same<T, int32_t>::value)
    return "int32_t";

  return "unknown";
}

template <typename T>
void printTimingInfo(const std::string &implName, double milliseconds) {
  std::cout << std::left << std::setw(30) << implName << "Time: " << std::fixed
            << std::setprecision(3) << milliseconds << " ms\n";
}

template <typename T> void runBenchmark(size_t size, int vlen = 0) {
  std::cout << "\n==== Matrix multiplication benchmark (" << size << "x" << size
            << ") with type " << getTypeName<T>();

  if (vlen > 0) {
    std::cout << " (VLEN=" << vlen << ")";
  }
  std::cout << " ====\n";

  Matrix<T> a(size, size);
  Matrix<T> b(size, size);

  // Initialize with random values
  a.randomize();
  b.randomize();

  // Test all implementations and measure time

  // C++ naive implementation
  auto start = std::chrono::high_resolution_clock::now();
  Matrix<T> c_cpp = matmul(a, b, MatMulImpl::CPP_NAIVE);
  auto end = std::chrono::high_resolution_clock::now();
  auto cpp_time =
      std::chrono::duration<double, std::milli>(end - start).count();
  printTimingInfo<T>("C++ Naive implementation:", cpp_time);

  // Assembly implementations
  start = std::chrono::high_resolution_clock::now();
  Matrix<T> c_asm_naive = matmul(a, b, MatMulImpl::ASM_NAIVE);
  end = std::chrono::high_resolution_clock::now();
  auto asm_naive_time =
      std::chrono::duration<double, std::milli>(end - start).count();
  printTimingInfo<T>("RV64 ASM naive implementation:", asm_naive_time);

  // Assembly vector implementation - pass the VLEN parameter
  start = std::chrono::high_resolution_clock::now();
  Matrix<T> c_asm_vector = matmul(a, b, MatMulImpl::ASM_VECTOR, vlen);
  end = std::chrono::high_resolution_clock::now();
  auto asm_vector_time =
      std::chrono::duration<double, std::milli>(end - start).count();

  // Include VLEN in the vector implementation name if specified
  std::string vector_impl_name = "RV64 ASM vector implementation";
  printTimingInfo<T>(vector_impl_name + ":", asm_vector_time);

  // Verify all implementations produce the same result
  bool naive_ok = c_cpp.equals(c_asm_naive);
  bool vector_ok = c_cpp.equals(c_asm_vector);

  std::cout << "\nVerification:" << "\n";
  std::cout << "  ASM Naive vs C++:  " << (naive_ok ? "PASS" : "FAIL") << "\n";
  std::cout << "  ASM Vector vs C++: " << (vector_ok ? "PASS" : "FAIL") << "\n";

  // Display speedup as percentage faster than C++ Naive
  std::cout << "\nSpeedup vs C++ Naive:" << std::endl;
  double naive_speedup_percent = (asm_naive_time > 1e-9) ? ((cpp_time / asm_naive_time) - 1.0) * 100.0 : 0.0;
  double vector_speedup_percent = (asm_vector_time > 1e-9) ? ((cpp_time / asm_vector_time) - 1.0) * 100.0 : 0.0;

  std::cout << "  ASM Naive:  " << std::fixed << std::setprecision(1)
            << naive_speedup_percent << "% faster\n";
  std::cout << "  ASM Vector: " << std::fixed << std::setprecision(1)
            << vector_speedup_percent << "% faster\n";
}

// Run VLEN experiments for a specific matrix size
template <typename T>
void runVlenExperiments(size_t size, const std::vector<int>& vlen_values) {
  std::cout << "\n===== VLEN Experiments for " << size << "x" << size 
            << " matrices with " << getTypeName<T>() << " =====\n";
            
  // Run benchmark with each VLEN value
  for (int vlen : vlen_values) {
    runBenchmark<T>(size, vlen);
  }
}

int main(int argc, char* argv[]) {
  // Matrix sizes to benchmark
  std::vector<size_t> dimensions = {16, 32, 64, 128, 256, 512};
  
  // VLEN values to test
  std::vector<int> vlen_values = {16, 32, 64};
  
  // Standard benchmarks with fixed VLEN
  std::cout << "\n===== STANDARD BENCHMARKS =====\n";
  for (size_t size : dimensions) {
    std::cout << "\n==== Benchmarking " << size << "x" << size << " ====\n";
    // runBenchmark<int8_t>(size, 8);  
    // runBenchmark<int16_t>(size, 32);
    // runBenchmark<int32_t>(size, 64);
    // runBenchmark<float>(size, 32);
    runBenchmark<int8_t>(size, 64);  
    runBenchmark<int16_t>(size, 64);
    runBenchmark<int32_t>(size, 64);
    runBenchmark<float>(size, 64);
  }
  // decltype types = {int8_t{}, int16_t{}, int32_t{}, float{}};
  // for (auto type : types) {
  //   std::cout << "\n==== Benchmarking " << getTypeName<decltype(type)>() << " ====\n";
  //   runBenchmark<decltype(type)>(256, 4);
  // }
  
  // // VLEN experiments for selected matrix sizes
  // std::cout << "\n\n===== VLEN EXPERIMENTS =====\n";
  // for (size_t size : {64, 128}) {  
  //   runVlenExperiments<int8_t>(size, vlen_values);
  //   runVlenExperiments<int16_t>(size, vlen_values);
  //   runVlenExperiments<int32_t>(size, vlen_values);
  //   runVlenExperiments<float>(size, vlen_values);
  // }
  
  return 0;
}