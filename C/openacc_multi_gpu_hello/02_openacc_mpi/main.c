#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <openacc.h>


int main(int argc, char *argv[])
{

    int length = 12;
    char a[] = "Hello World";

    MPI_Init(&argc, &argv);

    int nprocs = 1;
    int rank   = 0;

    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    if (nprocs != 2) {
	MPI_Finalize();
	fprintf(stderr,"error! nprocs must be 2 (nprocs = %d).\n", nprocs);
	exit(1);
    }

    int ngpus = acc_get_num_devices(acc_device_nvidia);
    int gpuid = rank % ngpus;
    acc_set_device_num(gpuid, acc_device_nvidia);
    
    int str =       rank * (length / nprocs);
    int end = (rank + 1) * (length / nprocs);

    char b[] = "           ";

#pragma acc kernels
#pragma acc loop independent
    for (unsigned int i=str; i<end; i++) {
	b[i] = a[i];
    }
    
    printf("rank = %d, gpuid = %d, b = %s\n", rank, gpuid, b);

    return 0;
}
