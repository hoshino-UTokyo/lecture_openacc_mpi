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
    MPI_Init(&argc, &argv);
    
    int nprocs = 1;
    int rank   = 0;

    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    const int rank_up   = rank != nprocs - 1 ? rank + 1 : MPI_PROC_NULL;
    const int rank_down = rank != 0          ? rank - 1 : MPI_PROC_NULL;
    
    const int nx0 = 128;
    //const int nx0 = 512;
    const int ny0 = nx0;
    const int nz0 = nx0;

    const int nx = nx0;
    const int ny = ny0;
    const int nz = nz0 / nprocs;
    
    if (nz * nprocs != nz0) {
        if (rank == 0) {
            fprintf(stdout, "Error: nz(%d) * nprocs(%d) != nz0(%d)\n", nz, nprocs, nz0);
        }
        MPI_Finalize();
        return 1;
    }

    if (rank == 0) {
        fprintf(stdout, "nprocs = %d\n", nprocs);
    }
    
    const int ngpus = acc_get_num_devices(acc_device_nvidia);
    if (rank == 0) {
        fprintf(stdout, "num of GPUs = %d\n", ngpus);
    }
    const int gpuid = ngpus > 0 ? rank % ngpus : -1;
    if (gpuid >= 0) {
        acc_set_device_num(gpuid, acc_device_nvidia);
    }

    /* if (rank == 0) { */
    /*     fprintf(stdout, "OMPI_MCA_btl_smcuda_use_cuda_ipc  = %s\n", getenv("OMPI_MCA_btl_smcuda_use_cuda_ipc")); */
    /*     fprintf(stdout, "OMPI_MCA_btl_openib_want_cuda_gdr = %s\n", getenv("OMPI_MCA_btl_openib_want_cuda_gdr")); */
    /* } */
    
    for (int r=0; r<nprocs; r++) {
        MPI_Barrier(MPI_COMM_WORLD);
        if (r != rank) continue;

        char hostname[128];
        gethostname(hostname, sizeof(hostname));
        fprintf(stdout, "Rank %d: hostname = %s, gpuid = %d\n", rank, hostname, gpuid);
        fflush(stdout);
    }
    
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

    init(nprocs, rank, nx, ny, nz, mgn, dx, dy, dz, f);
    
    MPI_Barrier(MPI_COMM_WORLD);

#pragma acc data copy(f[0:ln]) create(fn[0:ln])
    {
        
        start_timer();
    
        for (; icnt<nt && time + 0.5*dt < 0.1; icnt++) {
            if (rank == 0 && icnt % 100 == 0) fprintf(stdout, "time(%4d) = %7.5f\n", icnt, time);
            
            const int tag = 0;
            MPI_Status status;

#pragma acc host_data use_device(f)
            {
                MPI_Send(&f[nx*ny*nz]      , nx*ny, MPI_FLOAT, rank_up  , tag, MPI_COMM_WORLD);
                MPI_Recv(&f[0]             , nx*ny, MPI_FLOAT, rank_down, tag, MPI_COMM_WORLD, &status);

                MPI_Send(&f[nx*ny*mgn]     , nx*ny, MPI_FLOAT, rank_down, tag, MPI_COMM_WORLD);
                MPI_Recv(&f[nx*ny*(nz+mgn)], nx*ny, MPI_FLOAT, rank_up  , tag, MPI_COMM_WORLD, &status);
            }
        
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

