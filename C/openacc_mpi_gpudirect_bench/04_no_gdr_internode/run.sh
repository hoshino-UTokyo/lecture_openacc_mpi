#!/bin/bash
#PJM -L rscgrp=short-a
#PJM -L node=2
#PJM --mpi proc=2
#PJM -L elapse=00:10:00
#PJM -g gx44

module load nvidia cuda ompi-cuda

export UCX_MEMTYPE_CACHE=no
export UCX_IB_GPU_DIRECT_RDMA=no

mpiexec -machinefile $PJM_O_NODEINF -n $PJM_MPI_PROC -npernode 1 ./run
