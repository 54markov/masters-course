#include <cuda.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <cublas.h>
#include <cublas_v2.h>

double test(const int N)
{
    const int size = N * sizeof(float);
    
    float milliseconds = 0;
    float maxError     = 0.0f;

    const float alpha = 2.0;

    /*
     * Create CUDA events for timing purposes
     */
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cublasHandle_t handle;
    cublasCreate(&handle);

    float *d_x = NULL; // Device vectors
    float *d_y = NULL; // Device vectors

    /*
     * Allocate host memory
     */
    float *x = (float *)malloc(size); // Host vectors
    float *y = (float *)malloc(size); // Host vectors

    /*
     * Allocate device memory
     */
    cudaMalloc(&d_x, size);
    cudaMalloc(&d_y, size);

    for (int i = 0; i < N; i++)
    {
        x[i] = 1.0f;
        y[i] = 2.0f;
    }

    cublasInit();

    cublasSetVector(N, sizeof(x[0]), x, 1, d_x, 1);
    cublasSetVector(N, sizeof(y[0]), y, 1, d_y, 1);

    /*
     * Perform SAXPY
     */
    cudaEventRecord(start);
    cublasSaxpy(handle, N, &alpha, d_x, 1, d_y, 1);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    cublasGetVector(N, sizeof(y[0]), d_y, 1, y, 1);
    cublasShutdown();

    cudaEventElapsedTime(&milliseconds, start, stop);

    for (int i = 0; i < N; i++) 
    {
        maxError = max(maxError, abs(y[i] - 4.0f));
    }
/*
    printf("N = %d\n", N);
    //printf("Max error: %f\n", maxError);
    printf("Succesfully performed SAXPY on %d elements in %f milliseconds.\n", N, milliseconds);
    printf("Effective Bandwidth (GB/s): %f\n", (float)N * 4.0 / (float)milliseconds / (float)1e6);
*/
    free(x);
    free(y);
    cudaFree(d_x);
    cudaFree(d_y);
    cublasDestroy(handle);

    return milliseconds;
}

int main(int argc, char const *argv[])
{
    int size = 0;
    const int n_tests = 10;
    double time = 0.0;

    size = 1 << 16;
    for (int i = 0; i < n_tests; i++)
    {
        time += test(size);
    }

    printf("[%s] N = %d, time %f msec\n", __FILE__, size, time / n_tests);

    time = 0.0;
    size = 1 << 18;
    for (int i = 0; i < n_tests; i++)
    {
        time += test(size);
    }

    printf("[%s] N = %d, time %f msec\n", __FILE__, size, time / n_tests);

    time = 0.0;
    size = 1 << 20;
    for (int i = 0; i < n_tests; i++)
    {
        time += test(size);
    }

    printf("[%s] N = %d, time %f msec\n", __FILE__, size, time / n_tests);

    return 0;
}