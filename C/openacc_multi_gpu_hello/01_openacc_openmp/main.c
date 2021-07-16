#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <openacc.h>


int main(int argc, char *argv[])
{

    int length = 12;
    char a[] = "Hello World";
    
#pragma omp parallel
    {
	int nth = omp_get_num_threads();
	int ith = omp_get_thread_num();

	char b[] = "           ";
	
	if (nth != 2) {
	    fprintf(stderr,"error! nth must be 2 (nth = %d). Please try `export OMP_NUM_THREADS=2`. \n", nth);
	    exit(1);
	}

	int ngpus = acc_get_num_devices(acc_device_nvidia);
	int gpuid = ith % ngpus;
	acc_set_device_num(gpuid, acc_device_nvidia);
	
	int str =       ith * (length / nth);
	int end = (ith + 1) * (length / nth);

#pragma acc kernels copyin(a[str:end-str]) copyout(b[str:end-str])
#pragma acc loop independent
	for (unsigned int i=str; i<end; i++) {
	    b[i] = a[i];
	}

	printf("tid = %d, gpuid = %d, b = %s\n", ith, gpuid, b);

    }

    return 0;
}
