#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <mpi.h>
#include <openacc.h>


double get_elapsed_time(const struct timeval *tv0, const struct timeval *tv1);

int main(int argc, char *argv[])
{
    MPI_Init(&argc, &argv);
    
    int nprocs = 1;
    int rank   = 0;

    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    if (nprocs != 2) {
        MPI_Finalize();
        return 1;
    }

    const int ngpus = acc_get_num_devices(acc_device_nvidia);
    if (rank == 0) {
        fprintf(stdout, "num of GPUs = %d\n", ngpus);
    }
    acc_set_device_num(rank % ngpus, acc_device_nvidia);
    
    const unsigned int nx = 4096;
    const unsigned int ny = 4096;
    const unsigned int n  = nx * ny;
    float *a = malloc(n*sizeof(float));
    float *b = malloc(n*sizeof(float));

    const unsigned int w  = 10;
    
    MPI_Barrier(MPI_COMM_WORLD);
    
    struct timeval tv0;
    gettimeofday(&tv0, NULL);

    /**** Begin ****/

    double sum = 0.0;
#pragma acc data create(a[0:n], b[0:n])
    {
    
#pragma acc kernels copyout(a[0:n], b[0:n])
#pragma acc loop independent
        for (unsigned int i=0; i<n; i++) {
            a[i] = 3.0 * rank * ny;
            b[i] = 0.0;
        }

        const int dst_rank = (rank + 1) % nprocs;
        const int tag      = 0;
        if (rank == 0) {
            MPI_Status status;
            MPI_Recv(b, w * nx, MPI_FLOAT, dst_rank, tag, MPI_COMM_WORLD, &status);
#pragma acc update device(b[0:w *nx])
        } else {
#pragma acc update host(a[0:w *nx])
            MPI_Send(a, w * nx, MPI_FLOAT, dst_rank, tag, MPI_COMM_WORLD);
        }

#pragma acc kernels copyin(b[0:n])
#pragma acc loop reduction(+:sum)
        for (unsigned int i=0; i<n; i++) {
            sum += b[i];
        }
    }

    /**** End ****/

    MPI_Barrier(MPI_COMM_WORLD);
    
    struct timeval tv1;
    gettimeofday(&tv1, NULL);

    if (rank == 0) {
        fprintf(stdout, "mean = %5.2f\n", sum / n);
        fprintf(stdout, "Time = %8.3f [sec]\n", get_elapsed_time(&tv0, &tv1));
    }
    
    free(a);
    free(b);

    MPI_Finalize();

    return 0;
}

double get_elapsed_time(const struct timeval *tv0, const struct timeval *tv1)
{
    return (double)(tv1->tv_sec - tv0->tv_sec) + (double)(tv1->tv_usec - tv0->tv_usec)*1.0e-6;
}
