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
    
    const int n = 16;
    
    int a[n];
    int b[n];
    for (int i=0; i<n; i++) {
        a[i] = i;
        b[i] = 0;
    }
    
    if (rank == 1) {
        MPI_Send(a, n, MPI_INT, 2, 100, MPI_COMM_WORLD);
    } else if (rank == 2) {
        MPI_Status status;
        MPI_Recv(b, n, MPI_INT, 1, 100, MPI_COMM_WORLD, &status);
    }

    if (rank == 2) {
        for (int i=0; i<n; i++) {
            fprintf(stdout, "%d ", b[i]);
        }
        fprintf(stdout, "\n");
    }
    
    MPI_Finalize();

    return 0;
}

