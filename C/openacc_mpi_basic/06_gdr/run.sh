#!/bin/bash
#PJM -L rscgrp=lecture-a
#PJM -L gpu=2
#PJM -L elapse=00:10:00
#PJM -g gt00



module load nvidia cuda ompi-cuda

export UCX_MEMTYPE_CACHE=no

export OMPI_MCA_pml=ucx
export OMPI_MCA_osc=ucx
export OMPI_MCA_mtl=^ofi

mpirun -np 2 ./run



