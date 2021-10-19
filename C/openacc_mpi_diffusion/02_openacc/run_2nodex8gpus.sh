#!/bin/bash
#PJM -L rscgrp=regular-a
#PJM -L node=2
#PJM --mpi proc=16
#PJM -L elapse=00:10:00
#PJM -g gz00

module purge
module load nvidia cuda ompi-cuda

export UCX_MEMTYPE_CACHE=n
mpiexec -machinefile $PJM_O_NODEINF -n $PJM_MPI_PROC -npernode 8 ./run
