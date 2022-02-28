#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <mpi.h>
#include <openacc.h>
#include "diffusion.h"
#include "misc.h"

int main(int argc, char *argv[])
{
    //const int nx0 = 128;
    const int nx0 = 512;
    const int ny0 = nx0;
    const int nz0 = nx0;

    const int ngpus = acc_get_num_devices(acc_device_nvidia);

    if (rank == 0) {
        fprintf(stdout, "num of GPUs = %d\n", ngpus);
    }

    const int nx = nx0;
    const int ny = ny0;
    const int nz = nz0 / ngpus;
    

    const int mgn = 1;
    const int lnx = nx;
    const int lny = ny;
    const int lnz = nz + 2*mgn;
    const int ln  = lnx*lny*lnz;
    
    const float lx = 1.0;
    const float ly = 1.0;
    const float lz = 1.0;
    
    const float dx = lx/(float)nx0;
    const float dy = ly/(float)ny0;
    const float dz = lz/(float)nz0;

    const float kappa = 0.1;
    const float dt    = 0.1*fmin(fmin(dx*dx, dy*dy), dz*dz)/kappa;

    const int   nt = 100000;
    double time = 0.0;
    int    icnt = 0;
    double flop = 0.0;
    double elapsed_time = 0.0;
    
    float *f  = (float *)malloc(sizeof(float)*ln);
    float *fn = (float *)malloc(sizeof(float)*ln);

    init(nx0, ny0, nz0, dx, dy, dz, f);

    {
        
        start_timer();
    
        for (; icnt<nt && time + 0.5*dt < 0.1; icnt++) {
            if (rank == 0 && icnt % 100 == 0) fprintf(stdout, "time(%4d) = %7.5f\n", icnt, time);
            
            flop += diffusion3d(nprocs, rank, nx, ny, nz, mgn, dx, dy, dz, dt, kappa, f, fn);
        
            swap(&f, &fn);

            time += dt;
        }

        MPI_Barrier(MPI_COMM_WORLD);
    
        elapsed_time = get_elapsed_time();

    }

    if (rank == 0) {
        const double performance = flop/elapsed_time*1.0e-09;
        fprintf(stdout, "Time = %8.3f [sec]\n", elapsed_time);
        fprintf(stdout, "Performance= %7.2f [GFlops/nprocs]\n", performance);
        fprintf(stdout, "             %7.2f [GFlops]\n", performance*nprocs);
    }
    
    const double ferr = err(nprocs, rank, time, nx, ny, nz, mgn, dx, dy, dz, kappa, f);

    double ferr_sum = 0.0;
    MPI_Reduce(&ferr, &ferr_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    
    const double faccuracy = sqrt(ferr_sum/(double)(nx0*ny0*nz0));

    if (rank == 0) {
        fprintf(stdout, "Error[%d][%d][%d] = %10.6e\n", nx0, ny0, nz0, faccuracy);
    }
    
    free(f);  f  = NULL;
    free(fn); fn = NULL;

    MPI_Finalize();
    
    return 0;
}

