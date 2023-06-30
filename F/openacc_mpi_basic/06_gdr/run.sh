#!/bin/bash
#PJM -L rscgrp=regular-a
#PJM -L node=2
#PJM --mpi proc=2
#PJM -L elapse=00:10:00
#PJM -g gz00

module purge
module load nvidia nvmpi

export UCX_MEMTYPE_CACHE=n
export UCX_IB_GPU_DIRECT_RDMA=y

mpiexec -machinefile $PJM_O_NODEINF -n $PJM_MPI_PROC -npernode 1 ./run
