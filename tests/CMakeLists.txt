# # Find GTest package
# find_package(GTest REQUIRED)

# # Create test executable for matrix multiplication
# add_executable(matrix_mul_tests
#     test_matmul.cpp  # Main test file
# )

# # Link against the matrix_mul library and GTest
# target_link_libraries(matrix_mul_tests
#     PRIVATE
#     matrix_mul
#     GTest::GTest
#     GTest::Main
# )

# # Add RISC-V specific compile options
# target_compile_options(matrix_mul_tests PRIVATE 
#     -march=rv32imafv 
#     -mabi=ilp32f
# )

# # Register with CTest
# add_test(
#     NAME matrix_mul_tests
#     COMMAND matrix_mul_tests
# )

# # Optional: Add test discovery
# gtest_discover_tests(matrix_mul_tests)