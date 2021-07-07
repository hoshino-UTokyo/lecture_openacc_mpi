#! /bin/sh
#PBS -q h-lecture
#PBS -l select=1:mpiprocs=1:ompthreads=1
#PBS -W group_list=gt00
#PBS -l walltime=00:05:00

cd $PBS_O_WORKDIR

. /etc/profile.d/modules.sh
module load pgi/18.7

./run

