#include <stdio.h>
#include <mpi.h>


int main(int argc, char *argv[])
{
    MPI_Init(&argc, &argv);
    
    int nprocs = 1;
    int rank   = 0;

    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    if (nprocs != 4) {
        MPI_Finalize();
        return 1;
    }
    
    const int n = 8;
    
    int a[n];
    for (int i=0; i<n; i++) {
        a[i] = i + rank * 10;
    }

    MPI_Bcast(a, 4, MPI_INT, 1, MPI_COMM_WORLD);

    if (rank == 2) {
        for (int i=0; i<n; i++) {
            fprintf(stdout, "%d ", a[i]);
        }
        fprintf(stdout, "\n");
    }
    
    MPI_Finalize();

    return 0;
}

