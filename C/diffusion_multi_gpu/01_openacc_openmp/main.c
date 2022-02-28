

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <openacc.h>
#include "diffusion.h"
#include "misc.h"

#define MAX(A,B) (A) > (B) ? (A):(B)
#define MIN(A,B) (A) < (B) ? (A):(B)

int main(int argc, char *argv[])
{
    const int nx = 128;
    const int ny = nx;
    const int nz = nx;
    const int n  = nx*ny*nz;

    const float lx = 1.0;
    const float ly = 1.0;
    const float lz = 1.0;
    
    const float dx = lx/(float)nx;
    const float dy = ly/(float)ny;
    const float dz = lz/(float)nz;

    const float kappa = 0.1;
    const float dt    = 0.1*fmin(fmin(dx*dx, dy*dy), dz*dz)/kappa;

    const int   nt = 100000;
    double time = 0.0;
    int    icnt = 0;
    double flop = 0.0;
    double elapsed_time = 0.0;

    float *f  = (float *)malloc(sizeof(float)*n);
    float *fn = (float *)malloc(sizeof(float)*n);

    init(nx, ny, nz, dx, dy, dz, f);

    const int ngpus = acc_get_num_devices(acc_device_nvidia);
    fprintf(stdout, "num of GPUs = %d\n", ngpus);

    for(int gpuid = 0; gpuid < ngpus; gpuid++) {
	int nzgpu = (nz-1)/ngpus+1;
	int st = MAX(0,gpuid*nzgpu-1);
	if(gpuid == 0) nzgpu = nzgpu-1;
	if(gpuid == ngpus-1) nzgpu = nzgpu-1;
	int ln = nx*ny*(nzgpu+2);
        acc_set_device_num(gpuid, acc_device_nvidia);
#pragma acc enter data copyin(f[st:ln]) create(fn[st:ln]) async(gpuid)
    }
#pragma acc wait
    
    start_timer();
    
    for (; icnt<nt && time + 0.5*dt < 0.1; icnt++) {
	if (icnt % 100 == 0) fprintf(stdout, "time(%4d) = %7.5f\n", icnt, time);
        
	flop += diffusion3d(nx, ny, nz, dx, dy, dz, dt, kappa, f, fn, ngpus);
        
	swap(&f, &fn);
	
	time += dt;
    }
    
    elapsed_time = get_elapsed_time();

    for(int gpuid = 0; gpuid < ngpus; gpuid++) {
	int nzgpu = (nz-1)/ngpus+1;
	int st = MAX(0,gpuid*nzgpu-1);
	if(gpuid == 0) nzgpu = nzgpu-1;
	if(gpuid == ngpus-1) nzgpu = nzgpu-1;
	int ln = nx*ny*(nzgpu+2);
        acc_set_device_num(gpuid, acc_device_nvidia);
#pragma acc exit data copyout(f[st:ln]) delete(fn[st:ln]) async(gpuid)
    }
#pragma acc wait
    
    fprintf(stdout, "Time = %8.3f [sec]\n", elapsed_time);
    fprintf(stdout, "Performance= %7.2f [GFlops]\n",flop/elapsed_time*1.0e-09);
    
    const double ferr = accuracy(time, nx, ny, nz, dx, dy, dz, kappa, f);
    fprintf(stdout, "Error[%d][%d][%d] = %10.6e\n", nx, ny, nz, ferr);
    
    free(f);  f  = NULL;
    free(fn); fn = NULL;

    return 0;
}

