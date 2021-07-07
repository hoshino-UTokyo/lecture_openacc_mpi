#! /bin/sh
#PBS -q h-lecture
#PBS -l select=1:mpiprocs=4:ompthreads=0
#PBS -W group_list=gt00
#PBS -l walltime=00:05:00

cd $PBS_O_WORKDIR

. /etc/profile.d/modules.sh
module purge
module load pgi/17.10
module load openmpi/2.1.2/pgi

mpirun -np 4 ./run



