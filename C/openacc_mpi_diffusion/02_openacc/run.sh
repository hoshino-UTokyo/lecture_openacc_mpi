#!/bin/bash
#PJM -L rscgrp=lecture-a
#PJM -L gpu=2
#PJM --mpi proc=2
#PJM -L elapse=00:10:00
#PJM -g gt00

module load nvidia cuda ompi-cuda

export UCX_MEMTYPE_CACHE=n
mpiexec -machinefile $PJM_O_NODEINF -n $PJM_MPI_PROC ./run
