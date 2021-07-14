#!/bin/bash
#PJM -L rscgrp=lecture-a
#PJM -L gpu=2
#PJM -L elapse=00:10:00
#PJM -g gt00



module load nvidia cuda ompi-cuda

mpirun -np 2 ./run



