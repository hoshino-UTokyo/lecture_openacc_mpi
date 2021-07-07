#! /bin/sh
#PBS -q h-lecture
#PBS -l select=2:mpiprocs=1:ompthreads=1
#PBS -W group_list=gt00
#PBS -l walltime=00:05:00

cd $PBS_O_WORKDIR

. /etc/profile.d/modules.sh
module load pgi/17.10
module load openmpi/2.1.2/pgi

mpirun -np 2 -mca btl_openib_want_cuda_gdr 1 ./run

