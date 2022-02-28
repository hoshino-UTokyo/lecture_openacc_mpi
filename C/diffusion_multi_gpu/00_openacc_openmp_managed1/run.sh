#!/bin/bash
##PJM -g gt00
##PJM -L rscgrp=lecture-a
##PJM -L gpu=1
#PJM -g gr31
#PJM -L rscgrp=regular-a
#PJM -L node=1
#PJM -L elapse=00:10:00

module load nvidia 

export NVCOMPILER_ACC_TIME=0

# export OMP_NUM_THREADS=1
# ./run
# export OMP_NUM_THREADS=2
# ./run
# export OMP_NUM_THREADS=4
# ./run
export OMP_NUM_THREADS=8
./run
