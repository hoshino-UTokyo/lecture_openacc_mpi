#! /bin/sh
#PBS -q h-lecture
#PBS -l select=2:mpiprocs=2:ompthreads=0
#PBS -W group_list=gt00
#PBS -l walltime=00:05:00

cd $PBS_O_WORKDIR

. /etc/profile.d/modules.sh
module load pgi/17.10
module load openmpi/2.1.2/pgi

# export MV2_USE_CUDA=1
# export MV2_USE_GPUDIRECT=1
# mpirun -np 4 -f ${PBS_NODEFILE} ./run

mpirun -np 4 -mca btl_openib_want_cuda_gdr 1 ./run

