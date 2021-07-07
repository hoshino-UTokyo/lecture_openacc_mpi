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
    int b[n];
    for (int i=0; i<n; i++) {
        a[i] = i + rank * 10;
        b[i] = 0;
    }

    MPI_Gather(a, 2, MPI_INT, b, 2, MPI_INT, 1, MPI_COMM_WORLD);

    if (rank == 1) {
        for (int i=0; i<n; i++) {
            fprintf(stdout, "%d ", b[i]);
        }
        fprintf(stdout, "\n");
    }
    
    MPI_Finalize();

    return 0;
}

