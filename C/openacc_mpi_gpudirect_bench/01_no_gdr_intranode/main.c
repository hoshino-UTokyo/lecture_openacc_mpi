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
    const int gpuid = rank % ngpus;
    acc_set_device_num(gpuid, acc_device_nvidia);

    char hostname[128];
    gethostname(hostname, sizeof(hostname));
    fprintf(stdout, "Rank %d: hostname = %s, GPU num = %d\n", rank, hostname, gpuid);
    
    const unsigned int n  = 1 << 30;
    double *a = malloc(n*sizeof(double));
    double *b = malloc(n*sizeof(double));

    
    /**** Begin ****/

#pragma acc data create(a[0:n], b[0:n])
    {

	for (unsigned int w=1; w<=n; w=(w<<1)){
	    
#pragma acc kernels copyout(a[0:n], b[0:n])
#pragma acc loop independent
	    for (unsigned int i=0; i<n; i++) {
		a[i] = 1.0;
		b[i] = 0.0;
	    }

	    const int dst_rank = (rank + 1) % nprocs;
	    const int tag      = 0;

	    struct timeval tv0, tv1;

	    MPI_Barrier(MPI_COMM_WORLD);
	    gettimeofday(&tv0, NULL);

	    if (rank == 0) {
		MPI_Status status;
#pragma acc host_data use_device(b)
		MPI_Recv(b, w, MPI_DOUBLE, dst_rank, tag, MPI_COMM_WORLD, &status);
	    } else {
#pragma acc host_data use_device(a)
		MPI_Send(a, w, MPI_DOUBLE, dst_rank, tag, MPI_COMM_WORLD);
	    }
	    
	    MPI_Barrier(MPI_COMM_WORLD);
	    gettimeofday(&tv1, NULL);
	    
	    double sum = 0.0;
#pragma acc kernels copyin(b[0:n])
#pragma acc loop reduction(+:sum)
	    for (unsigned int i=0; i<n; i++) {
		sum += b[i];
	    }
	    if (rank == 0) {
		fprintf(stdout, "Message Size = %11d \n", w);
#ifdef DEBUG
		fprintf(stdout, "Sum (==size) = %f \n", f);
#endif
		fprintf(stdout, "Time         = %11.6f [sec]\n", get_elapsed_time(&tv0, &tv1));
		fprintf(stdout, "Throughput   = %11.5e [GB/sec]\n", (double)w*8.0*1.0E-9/get_elapsed_time(&tv0, &tv1));
	    }
	}
    }

    /**** End ****/

    free(a);
    free(b);

    MPI_Finalize();

    return 0;
}

double get_elapsed_time(const struct timeval *tv0, const struct timeval *tv1)
{
    return (double)(tv1->tv_sec - tv0->tv_sec) + (double)(tv1->tv_usec - tv0->tv_usec)*1.0e-6;
}
