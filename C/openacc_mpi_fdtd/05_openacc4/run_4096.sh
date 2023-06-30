#! /bin/sh
#PBS -q h-tutorial
#PBS -l select=2:mpiprocs=2:ompthreads=0
#PBS -W group_list=gt00
#PBS -l walltime=00:05:00

cd $PBS_O_WORKDIR

. /etc/profile.d/modules.sh
module purge
module load nvidia nvmpi

mkdir -p sim_run
cd sim_run

nprocs=4
mpirun -np $nprocs -mca btl_openib_want_cuda_gdr 1 ../run 4096 4096 $nprocs 2000 50



