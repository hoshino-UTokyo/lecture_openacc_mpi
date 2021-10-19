#!/bin/bash
#PJM -L rscgrp=lecture-a
#PJM -L gpu=2
#PJM --mpi proc=2
#PJM -L elapse=00:10:00
#PJM -g gt00


module purge
module load nvidia cuda ompi-cuda

export UCX_MEMTYPE_CACHE=no
export UCX_IB_GPU_DIRECT_RDMA=no

mpirun -np 2 ./run

