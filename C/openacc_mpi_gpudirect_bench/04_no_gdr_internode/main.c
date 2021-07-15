#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <unistd.h>
#include <openacc.h>


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

	if (rank == 0) fprintf(stdout, " Message Size (byte),       (min,max,median) Time (sec), Throughput (MB/sec) \n");

	for (unsigned int w=1; w<=n; w=(w<<1)){
	    
#pragma acc kernels copyout(a[0:n], b[0:n])
#pragma acc loop independent
	    for (unsigned int i=0; i<n; i++) {
		a[i] = 1.0;
		b[i] = 0.0;
	    }

	    const int dst_rank = (rank + 1) % nprocs;
	    const int tag      = 0;

	    double st,en,times[11];

	    for (unsigned int i=0; i<11; i++) {

		MPI_Barrier(MPI_COMM_WORLD);
		st = MPI_Wtime();
		
		if (rank == 0) {
		    MPI_Status status;
#pragma acc host_data use_device(b)
		    MPI_Recv(b, w, MPI_DOUBLE, dst_rank, tag, MPI_COMM_WORLD, &status);
		} else {
#pragma acc host_data use_device(a)
		    MPI_Send(a, w, MPI_DOUBLE, dst_rank, tag, MPI_COMM_WORLD);
		}
		
		MPI_Barrier(MPI_COMM_WORLD);
		en = MPI_Wtime();

		times[i] = en - st;
	    }

	    for (unsigned int i=0; i<11; i++) {
		for (unsigned int j=i+1; j<11; j++) {
		    if(times[i] > times[j]){
			double tmp = times[i];
			times[i] = times[j];
			times[j] = tmp;
		    }
		}
	    }
	    
	    double sum = 0.0;
#pragma acc kernels copyin(b[0:n])
#pragma acc loop reduction(+:sum)
	    for (unsigned int i=0; i<n; i++) {
		sum += b[i];
	    }
	    if (rank == 0) {
		if(sum != (double)w) {
		    fprintf(stderr, "error! sum = %f should be same as w = %d \n", sum, w);
		}
		fprintf(stdout, "%20llu,(%10.7f,%10.7f,%10.7f),%20.8f \n", (unsigned long long)w*8, times[0],times[10],times[5], (double)w*8.0*1.0E-6/times[5]);
	    }
	}
    }

    /**** End ****/

    free(a);
    free(b);

    MPI_Finalize();

    return 0;
}

