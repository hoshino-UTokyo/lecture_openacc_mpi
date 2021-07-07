#! /bin/sh
#PBS -q h-tutorial
#PBS -l select=1:mpiprocs=2:ompthreads=0
#PBS -W group_list=gt00
#PBS -l walltime=00:05:00

cd $PBS_O_WORKDIR

. /etc/profile.d/modules.sh
module load pgi/17.10
module load openmpi/2.1.2/pgi

mpirun -np 2  --mca btl_smcuda_use_cuda_ipc 0 ./run

