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
    
    //const int n = 16;
    const int n = 1024 * 1024;
    
    int a[n];
    int b[n];
    for (int i=0; i<n; i++) {
        a[i] = i + rank * 10; 
        b[i] = 0;
    }

    const int dst = (rank + 1) % nprocs;
    const int src = (rank - 1 + nprocs) % nprocs;

    MPI_Status status;
    MPI_Send(a, n, MPI_INT, dst, 100, MPI_COMM_WORLD);
    MPI_Recv(b, n, MPI_INT, src, 100, MPI_COMM_WORLD, &status);    
    
    if (rank == 2) {
        for (int i=0; i<n; i++) {
            fprintf(stdout, "%d ", b[i]);
        }
        fprintf(stdout, "\n");
    }
    
    MPI_Finalize();

    return 0;
}

