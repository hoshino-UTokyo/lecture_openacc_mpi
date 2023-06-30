#!/bin/bash
##PJM -g gt00
##PJM -L rscgrp=lecture-a
##PJM -L gpu=1
#PJM -g gr31
#PJM -L rscgrp=regular-a
#PJM -L node=2
#PJM --mpi proc=16
#PJM -L elapse=00:10:00

module purge
module load nvidia nvmpi

export UCX_MEMTYPE_CACHE=n
# mpiexec -machinefile $PJM_O_NODEINF -n 1 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 2 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 4 ./run
# mpiexec -machinefile $PJM_O_NODEINF -n 8 ./run
mpiexec -machinefile $PJM_O_NODEINF -n 16 -npernode 8 ./run
