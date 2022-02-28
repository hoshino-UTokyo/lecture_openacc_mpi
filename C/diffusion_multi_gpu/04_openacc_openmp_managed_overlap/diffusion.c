

#include <stdio.h>
#include <math.h>
#include <omp.h>
#include <openacc.h>

#define MIN(A,B) (A) < (B) ? (A) : (B)

double diffusion3d(int nx, int ny, int nz, float dx, float dy, float dz, float dt, float kappa,
                   const float *f, float *fn, int ngpus)
{
    const float ce = kappa*dt/(dx*dx);
    const float cw = ce;
    const float cn = kappa*dt/(dy*dy);
    const float cs = cn;
    const float ct = kappa*dt/(dz*dz);
    const float cb = ct;

    const float cc = 1.0 - (ce + cw + cn + cs + ct + cb);

    int nzgpu = (nz-1)/ngpus + 1;
#pragma omp parallel for
    for(int gpuid = 0; gpuid < ngpus; gpuid++) { 
        acc_set_device_num(gpuid, acc_device_nvidia);
	int end = MIN((gpuid+1)*nzgpu,nz);
	int k = gpuid*nzgpu;
#pragma acc kernels async(0)
#pragma acc loop independent collapse(2)
	for (int j = 0; j < ny; j++) {
	    for (int i = 0; i < nx; i++) {
		const int ix = nx*ny*k + nx*j + i;
		const int ip = i == nx - 1 ? ix : ix + 1;
		const int im = i == 0      ? ix : ix - 1;
		const int jp = j == ny - 1 ? ix : ix + nx;
		const int jm = j == 0      ? ix : ix - nx;
		const int kp = ix + nx*ny;
		const int km = k == 0      ? ix : ix - nx*ny;
		
		fn[ix] = cc*f[ix] + ce*f[ip] + cw*f[im] + cn*f[jp] + cs*f[jm] + ct*f[kp] + cb*f[km];
	    }
	}
	k = end-1;
#pragma acc kernels async(1)
#pragma acc loop independent collapse(2)
	for (int j = 0; j < ny; j++) {
	    for (int i = 0; i < nx; i++) {
		const int ix = nx*ny*k + nx*j + i;
		const int ip = i == nx - 1 ? ix : ix + 1;
		const int im = i == 0      ? ix : ix - 1;
		const int jp = j == ny - 1 ? ix : ix + nx;
		const int jm = j == 0      ? ix : ix - nx;
		const int kp = k == nz - 1 ? ix : ix + nx*ny;
		const int km = ix - nx*ny;
		
		fn[ix] = cc*f[ix] + ce*f[ip] + cw*f[im] + cn*f[jp] + cs*f[jm] + ct*f[kp] + cb*f[km];
	    }
	}
#pragma acc kernels async(2)
#pragma acc loop independent collapse(3)
	for(int k = gpuid*nzgpu+1; k < end-1; k++) {
	    for (int j = 0; j < ny; j++) {
		for (int i = 0; i < nx; i++) {
		    const int ix = nx*ny*k + nx*j + i;
		    const int ip = i == nx - 1 ? ix : ix + 1;
		    const int im = i == 0      ? ix : ix - 1;
		    const int jp = j == ny - 1 ? ix : ix + nx;
		    const int jm = j == 0      ? ix : ix - nx;
		    const int kp = ix + nx*ny;
		    const int km = ix - nx*ny;
		    
		    fn[ix] = cc*f[ix] + ce*f[ip] + cw*f[im] + cn*f[jp] + cs*f[jm] + ct*f[kp] + cb*f[km];
		}
            }
        }
#pragma acc wait
    }

    return (double)(nx*ny*nz)*13.0;
}


void init(int nx, int ny, int nz, float dx, float dy, float dz, float *f)
{
    const float kx = 2.0*M_PI;
    const float ky = kx;
    const float kz = kx;

    for(int k=0; k < nz; k++) {
        for(int j=0; j < ny; j++) {
            for(int i=0; i < nx; i++) {
                const int ix = nx*ny*k + nx*j + i;
                const float x = dx*((float)i + 0.5);
                const float y = dy*((float)j + 0.5);
                const float z = dz*((float)k + 0.5);

                f[ix] = 0.125*(1.0 - cos(kx*x))*(1.0 - cos(ky*y))*(1.0 - cos(kz*z));

            }
        }
    }
}

double accuracy(double time, int nx, int ny, int nz, float dx, float dy, float dz, float kappa, const float *f)
{
    const float kx = 2.0*M_PI;
    const float ky = kx;
    const float kz = kx;

    const float ax = exp(-kappa*time*(kx*kx));
    const float ay = exp(-kappa*time*(ky*ky));
    const float az = exp(-kappa*time*(kz*kz));

    double ferr = 0.0;

    for(int k=0; k < nz; k++) {
        for(int j=0; j < ny; j++) {
            for(int i=0; i < nx; i++) {
                const int ix = nx*ny*k + nx*j + i;
                const float x = dx*((float)i + 0.5);
                const float y = dy*((float)j + 0.5);
                const float z = dz*((float)k + 0.5);

                const float f0 = 0.125*(1.0 - ax*cos(kx*x)) * (1.0 - ay*cos(ky*y)) * (1.0 - az*cos(kz*z));

                ferr += (f[ix] - f0)*(f[ix] - f0);
            }
        }
    }

    return sqrt(ferr/(double)(nx*ny*nz));
}

