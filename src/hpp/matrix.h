#pragma once

#include <vector>
#include <cstddef>
#include <ostream>
#include <random>
#include <algorithm>
#include <stdexcept>
#include <iomanip>
#include <cmath>
#include <type_traits>

// Type traits for numerical types
template<typename T>
struct NumericTraits {
    static constexpr T epsilon() { return static_cast<T>(1e-5); }
    static constexpr T random_min() { return static_cast<T>(-1); }
    static constexpr T random_max() { return static_cast<T>(1); }
};

// Specializations for different types
template<>
struct NumericTraits<int8_t> {
    static constexpr int8_t epsilon() { return 0; }
    static constexpr int8_t random_min() { return -127; }
    static constexpr int8_t random_max() { return 127; }
};

// Add more specializations for other types as needed

template<typename T>
class Matrix {
public:
    // Constructors
    Matrix(size_t rows, size_t cols)
        : rows_(rows), cols_(cols), data_(rows * cols, static_cast<T>(0)) {}
    
    Matrix(size_t rows, size_t cols, const std::vector<T>& data)
        : rows_(rows), cols_(cols) {
        if (data.size() != rows * cols) {
            throw std::invalid_argument("Data size doesn't match matrix dimensions");
        }
        data_ = data;
    }
    
    // Access elements
    T& at(size_t row, size_t col) {
        if (row >= rows_ || col >= cols_) {
            throw std::out_of_range("Matrix indices out of bounds");
        }
        return data_[row * cols_ + col];
    }
    
    const T& at(size_t row, size_t col) const {
        if (row >= rows_ || col >= cols_) {
            throw std::out_of_range("Matrix indices out of bounds");
        }
        return data_[row * cols_ + col];
    }
    
    // Matrix properties
    size_t rows() const { return rows_; }
    size_t cols() const { return cols_; }
    
    // Raw data access (needed for assembly implementations)
    T* data() { return data_.data(); }
    const T* data() const { return data_.data(); }
    
    // Utility functions
    void fill(T value) {
        std::fill(data_.begin(), data_.end(), value);
    }
    
    void randomize(T min = NumericTraits<T>::random_min(), 
                   T max = NumericTraits<T>::random_max()) {
        std::random_device rd;
        std::mt19937 gen(rd());
        
        if constexpr (std::is_integral_v<T>) {
            std::uniform_int_distribution<int> dist(min, max);
            for (auto& val : data_) {
                val = static_cast<T>(dist(gen));
            }
        } else {
            std::uniform_real_distribution<float> dist(min, max);
            for (auto& val : data_) {
                val = static_cast<T>(dist(gen));
            }
        }
    }
    
    bool equals(const Matrix<T>& other, T epsilon = NumericTraits<T>::epsilon()) const {
        if (rows_ != other.rows_ || cols_ != other.cols_) {
            return false;
        }
        
        for (size_t i = 0; i < data_.size(); ++i) {
            if constexpr (std::is_floating_point_v<T>) {
                if (std::fabs(data_[i] - other.data_[i]) > epsilon) {
                    return false;
                }
            } else {
                if (data_[i] != other.data_[i]) {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    // Output
    friend std::ostream& operator<<(std::ostream& os, const Matrix<T>& matrix) {
        os << "Matrix " << matrix.rows_ << "x" << matrix.cols_ << ":\n";
        for (size_t i = 0; i < matrix.rows_; ++i) {
            os << "  ";
            for (size_t j = 0; j < matrix.cols_; ++j) {
                if constexpr (std::is_floating_point_v<T>) {
                    os << std::setw(9) << std::fixed << std::setprecision(4) 
                       << matrix.at(i, j) << " ";
                } else {
                    os << std::setw(6) << matrix.at(i, j) << " ";
                }
            }
            os << "\n";
        }
        return os;
    }

private:
    size_t rows_;
    size_t cols_;
    std::vector<T> data_;
};