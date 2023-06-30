#!/bin/bash
#PJM -L rscgrp=short-a
#PJM -L node=2
#PJM --mpi proc=16
#PJM -L elapse=00:10:00
#PJM -g gz00

module purge
module load nvidia nvmpi

#export UCX_MEMTYPE_CACHE=n
#mpiexec -machinefile $PJM_O_NODEINF -n $PJM_MPI_PROC ./run
mpiexec -machinefile $PJM_O_NODEINF -n 1 ./acc_overlap
mpiexec -machinefile $PJM_O_NODEINF -n 2 ./acc_overlap
mpiexec -machinefile $PJM_O_NODEINF -n 4 ./acc_overlap
mpiexec -machinefile $PJM_O_NODEINF -n 8 ./acc_overlap
mpiexec -machinefile $PJM_O_NODEINF -n 16 -npernode 8 ./acc_overlap
