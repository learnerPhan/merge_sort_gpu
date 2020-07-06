#!/bin/bash
#nvcc --generate-code arch=compute_35,code=sm_35 -Xcompiler -fopenmp -lcuda -lcudart  -lgomp -o surfacemax_v0  surfacemax_v0.cu
nvcc -o MergeGPU MergeGPU.cu && ./MergeGPU $1
