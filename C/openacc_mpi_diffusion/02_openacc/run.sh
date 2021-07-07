#!/bin/bash
#PJM -L rscgrp=regular-a
#PJM -L node=1
#PJM -L elapse=00:10:00
#PJM -g gz00

module load nvidia/21.3 ompi-cuda/4.1.1-11.2

nprocs=2
export UCX_IB_GPU_DIRECT_RDMA=n
#mpirun -np $nprocs -mca btl_openib_want_cuda_gdr 0 ./run
mpirun -np $nprocs ./run
