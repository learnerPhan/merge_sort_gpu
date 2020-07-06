#!/bin/bash

gcc -o mergesortOMP -fopenmp parallelMergeOPENMP.c && ./mergesortOMP $1

