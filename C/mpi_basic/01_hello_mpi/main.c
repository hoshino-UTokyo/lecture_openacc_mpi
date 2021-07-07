#include <stdio.h>
#include <mpi.h>


int main(int argc, char *argv[])
{
    MPI_Init(&argc, &argv);
    
    int nprocs = 1;
    int rank   = 0;

    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    fprintf(stdout, "rank = %d, nprocs = %d\n", rank, nprocs);
    
    MPI_Finalize();

    return 0;
}

