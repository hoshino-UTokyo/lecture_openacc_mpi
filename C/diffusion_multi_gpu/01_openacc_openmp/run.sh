#!/bin/bash
#PJM -L rscgrp=lecture-a
#PJM -L gpu=2
#PJM -L elapse=00:10:00
#PJM -g gt00

module purge
module load nvidia 

./run
#export NVCOMPILER_ACC_TIME=0



