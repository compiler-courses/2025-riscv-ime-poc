#pragma once

#include "matrix.h"
#include <algorithm>
#include <limits>
#include <string>
#include <type_traits>
#include <typeindex>
#include <typeinfo>
#include <unordered_map>

// Implementation types
enum class MatMulImpl {
  CPP_NAIVE,  // C++ naive implementation
  ASM_NAIVE,  // Assembly naive implementation
  ASM_VECTOR, // Assembly with vector instructions
};

// Implementation name mapping
inline std::string getImplName(MatMulImpl impl) {
  static const std::unordered_map<MatMulImpl, std::string> implNames = {
      {MatMulImpl::CPP_NAIVE, "C++ Naive"},
      {MatMulImpl::ASM_NAIVE, "Assembly Naive"},
      {MatMulImpl::ASM_VECTOR, "Assembly Vector"}};

  auto it = implNames.find(impl);
  return it != implNames.end() ? it->second : "Unknown";
}

// Generic clamping for any numeric type
template <typename T, typename AccumulatorT = T>
T clamp_int(AccumulatorT value) {
  if constexpr (std::is_integral_v<T>) {
    // For integral types, clamp to type limits
    if (value > static_cast<AccumulatorT>(std::numeric_limits<T>::max()))
      return std::numeric_limits<T>::max();
    if (value < static_cast<AccumulatorT>(std::numeric_limits<T>::min()))
      return std::numeric_limits<T>::min();
  }
  // For floating types, no explicit clamping (IEEE handles overflow/underflow)
  return static_cast<T>(value);
}

// C++ reference implementation template
template <typename T>
Matrix<T> matmul_cpp_naive(const Matrix<T> &a, const Matrix<T> &b) {
  if (a.cols() != b.rows())
    throw std::invalid_argument(
        "Matrix dimensions mismatch for multiplication");

  Matrix<T> result(a.rows(), b.cols());

  for (size_t i = 0; i < a.rows(); ++i) {
    for (size_t j = 0; j < b.cols(); ++j) {
      // Choose appropriate accumulator type based on T
      using AccumulatorType = std::conditional_t<
          std::is_integral_v<T>,
          std::conditional_t<sizeof(T) < sizeof(int32_t), int32_t, int64_t>, T>;

      AccumulatorType sum = static_cast<AccumulatorType>(0);

      for (size_t k = 0; k < a.cols(); ++k)
        sum += static_cast<AccumulatorType>(a.at(i, k)) *
               static_cast<AccumulatorType>(b.at(k, j));

      // Apply clamping only for integral types
      result.at(i, j) = clamp_int<T, AccumulatorType>(sum);
    }
  }

  return result;
}

// Assembly implementation declarations for different types
extern "C" {
// Float implementations
void matmul_asm_naive_float(const float *a, const float *b, float *c,
                            int a_rows, int a_cols, int b_cols);

void matmul_asm_vector_float(const float *a, const float *b, float *c,
                             int a_rows, int a_cols, int b_cols, int vlen);

// Integer implementations
// For int8_t
void matmul_asm_naive_int8(const int8_t *a, const int8_t *b, int8_t *c,
                           int a_rows, int a_cols, int b_cols, int int_min,
                           int int_max);

void matmul_asm_vector_int8(const int8_t *a, const int8_t *b, int8_t *c,
                            int a_rows, int a_cols, int b_cols, int int_min,
                            int int_max, int clamp_freq, int vlen);

// For int16_t
void matmul_asm_naive_int16(const int16_t *a, const int16_t *b, int16_t *c,
                            int a_rows, int a_cols, int b_cols, int int_min,
                            int int_max);

void matmul_asm_vector_int16(const int16_t *a, const int16_t *b, int16_t *c,
                             int a_rows, int a_cols, int b_cols, int int_min,
                             int int_max, int clamp_freq, int vlen);

// For int32_t
void matmul_asm_naive_int32(const int32_t *a, const int32_t *b, int32_t *c,
                            int a_rows, int a_cols, int b_cols, int int_min,
                            int int_max);

void matmul_asm_vector_int32(const int32_t *a, const int32_t *b, int32_t *c,
                             int a_rows, int a_cols, int b_cols, int int_min,
                             int int_max, int clamp_freq, int vlen);
}

// Add type traits for vector operations
template <typename T> struct VectorOpTraits {
  // Default implementation (should be specialized)
  static constexpr int element_width() { return 0; }
  static constexpr T max_value() { return T(0); }
  static constexpr T min_value() { return T(0); }

  // Dynamic clamp frequency based on matrix dimensions
  static int clamp_frequency(int rows, int cols) {
    // Default implementation
    return 16;
  }
};

template <> struct VectorOpTraits<int8_t> {
  static constexpr int element_width() {
    return 1 << 3;
  } // Already correct format
  static constexpr int8_t max_value() {
    return std::numeric_limits<int8_t>::max();
  }
  static constexpr int8_t min_value() {
    return std::numeric_limits<int8_t>::min();
  }

  // Dynamic clamp frequency based on matrix size
  static int clamp_frequency(int rows, int cols) {
    int size = std::max(rows, cols);
    if (size <= (1 << 5))
      return 1 << 2; // Small matrices: clamp every 4 iterations
    else if (size <= (1 << 7))
      return 1 << 4; // Medium matrices: clamp every 16 iterations
    else if (size <= (1 << 8))
      return 1 << 6; // Large matrices: clamp every 64 iterations
    else
      return 1 << 7; // Very large matrices: clamp every 128 iterations
  }
};

template <> struct VectorOpTraits<int16_t> {
  static constexpr int element_width() {
    return 1 << 4;
  } // Already correct format
  static constexpr int16_t max_value() {
    return std::numeric_limits<int16_t>::max();
  }
  static constexpr int16_t min_value() {
    return std::numeric_limits<int16_t>::min();
  }

  // Dynamic clamp frequency based on matrix size
  static int clamp_frequency(int rows, int cols) {
    int size = std::max(rows, cols);
    if (size <= (1 << 5))
      return 1 << 4; // Small matrices: clamp every 16 iterations
    else if (size <= (1 << 7))
      return 1 << 6; // Medium matrices: clamp every 64 iterations
    else if (size <= (1 << 8))
      return 1 << 8; // Large matrices: clamp every 256 iterations
    else
      return 1 << 9; // Very large matrices: clamp every 512 iterations
  }
};

template <> struct VectorOpTraits<int32_t> {
  static constexpr int element_width() { return 1 << 5; }
  static constexpr int32_t max_value() {
    return std::numeric_limits<int32_t>::max();
  }
  static constexpr int32_t min_value() {
    return std::numeric_limits<int32_t>::min();
  }

  // Dynamic clamp frequency based on matrix size
  static int clamp_frequency(int rows, int cols) {
    int size = std::max(rows, cols);
    // For int32_t using int64_t accumulator, overflow is extremely unlikely
    if (size <= (1 << 5))
      return 1 << 10; // Small matrices: very infrequent clamping (1024)
    else if (size <= (1 << 7))
      return 1 << 12; // Medium matrices: almost no clamping (4096)
    else if (size <= (1 << 8))
      return 1 << 14; // Large matrices: extremely rare clamping (16384)
    else
      return 1 << 16; // Very large matrices: practically no clamping (65536)
  }
};

template <typename T>
inline void call_asm_impl(const T *a, const T *b, T *c, int a_rows, int a_cols,
                          int b_cols, MatMulImpl impl, int vlen) {
  // Default implementation
  throw std::runtime_error(
      "Unsupported element type for matrix multiplication");
}

// Update specializations to pass the vlen parameter
template <>
inline void call_asm_impl<float>(const float *a, const float *b, float *c,
                                 int a_rows, int a_cols, int b_cols,
                                 MatMulImpl impl, int vlen) {
  if (impl == MatMulImpl::ASM_NAIVE)
    matmul_asm_naive_float(a, b, c, a_rows, a_cols, b_cols);
  else if (impl == MatMulImpl::ASM_VECTOR)
    matmul_asm_vector_float(a, b, c, a_rows, a_cols, b_cols, vlen);
}

template <>
inline void call_asm_impl<int8_t>(const int8_t *a, const int8_t *b, int8_t *c,
                                  int a_rows, int a_cols, int b_cols,
                                  MatMulImpl impl, int vlen) {
  if (impl == MatMulImpl::ASM_NAIVE) {
    matmul_asm_naive_int8(a, b, c, a_rows, a_cols, b_cols,
                          VectorOpTraits<int8_t>::min_value(),
                          VectorOpTraits<int8_t>::max_value());
  } else if (impl == MatMulImpl::ASM_VECTOR) {
    int clamp_freq = VectorOpTraits<int8_t>::clamp_frequency(a_rows, b_cols);
    matmul_asm_vector_int8(
        a, b, c, a_rows, a_cols, b_cols, VectorOpTraits<int8_t>::min_value(),
        VectorOpTraits<int8_t>::max_value(), clamp_freq, vlen);
  }
}

template <>
inline void call_asm_impl<int16_t>(const int16_t *a, const int16_t *b,
                                   int16_t *c, int a_rows, int a_cols,
                                   int b_cols, MatMulImpl impl, int vlen) {
  if (impl == MatMulImpl::ASM_NAIVE) {
    matmul_asm_naive_int16(a, b, c, a_rows, a_cols, b_cols,
                           VectorOpTraits<int16_t>::min_value(),
                           VectorOpTraits<int16_t>::max_value());
  } else if (impl == MatMulImpl::ASM_VECTOR) {
    int clamp_freq = VectorOpTraits<int16_t>::clamp_frequency(a_rows, b_cols);
    matmul_asm_vector_int16(
        a, b, c, a_rows, a_cols, b_cols, VectorOpTraits<int16_t>::min_value(),
        VectorOpTraits<int16_t>::max_value(), clamp_freq, vlen);
  }
}

template <>
inline void call_asm_impl<int32_t>(const int32_t *a, const int32_t *b,
                                   int32_t *c, int a_rows, int a_cols,
                                   int b_cols, MatMulImpl impl, int vlen) {
  if (impl == MatMulImpl::ASM_NAIVE) {
    matmul_asm_naive_int32(a, b, c, a_rows, a_cols, b_cols,
                           VectorOpTraits<int32_t>::min_value(),
                           VectorOpTraits<int32_t>::max_value());
  } else if (impl == MatMulImpl::ASM_VECTOR) {
    int clamp_freq = VectorOpTraits<int32_t>::clamp_frequency(a_rows, b_cols);
    matmul_asm_vector_int32(
        a, b, c, a_rows, a_cols, b_cols, VectorOpTraits<int32_t>::min_value(),
        VectorOpTraits<int32_t>::max_value(), clamp_freq, vlen);
  }
}

// Main matmul template function
template <typename T>
Matrix<T> matmul(const Matrix<T> &a, const Matrix<T> &b,
                 MatMulImpl impl = MatMulImpl::CPP_NAIVE, int vlen = 0) {
  if (a.cols() != b.rows())
    throw std::invalid_argument(
        "Matrix dimensions mismatch for multiplication");

  // For C++ reference implementation, call directly
  if (impl == MatMulImpl::CPP_NAIVE)
    return matmul_cpp_naive(a, b);

  // For assembly implementations, prepare data and call the assembly function
  Matrix<T> result(a.rows(), b.cols());

  call_asm_impl(a.data(), b.data(), result.data(), a.rows(), a.cols(), b.cols(),
                impl, vlen);

  return result;
}