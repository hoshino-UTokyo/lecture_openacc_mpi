#!/bin/bash
#PJM -L rscgrp=regular-a
#PJM -L node=2
#PJM --mpi proc=16
#PJM -L elapse=00:10:00
#PJM -g gr31

module purge
module load nvidia nvmpi

export UCX_MEMTYPE_CACHE=n
#mpiexec -machinefile $PJM_O_NODEINF -n $PJM_MPI_PROC ./run
mpiexec -machinefile $PJM_O_NODEINF -n 1 ./wrapper.sh ./run
mpiexec -machinefile $PJM_O_NODEINF -n 2 ./wrapper.sh ./run
mpiexec -machinefile $PJM_O_NODEINF -n 4 ./wrapper.sh ./run
mpiexec -machinefile $PJM_O_NODEINF -n 8 ./wrapper.sh ./run
mpiexec -machinefile $PJM_O_NODEINF -n 16 -npernode 8 ./wrapper.sh ./run


# mpiexec -machinefile $PJM_O_NODEINF -n 1 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 2 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 4 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 8 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 16 -npernode 8 ./run
