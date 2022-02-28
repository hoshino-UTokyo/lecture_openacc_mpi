#!/bin/bash
#PJM -L rscgrp=regular-a
#PJM -L node=1
#PJM --mpi proc=8
#PJM -L elapse=00:10:00
#PJM -g gz00

module purge
module load nvidia cuda ompi-cuda

export UCX_MEMTYPE_CACHE=n
#export NVCOMPILER_ACC_TIME=1
mpiexec -machinefile $PJM_O_NODEINF -n 1 ./run
mpiexec -machinefile $PJM_O_NODEINF -n 2 ./run
mpiexec -machinefile $PJM_O_NODEINF -n 4 ./run
mpiexec -machinefile $PJM_O_NODEINF -n 8 ./run
