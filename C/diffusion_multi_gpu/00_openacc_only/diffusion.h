

#ifndef DIFFUSION_H
#define DIFFUSION_H


double diffusion3d(int nprocs, int rank, int nx, int ny, int nz, int mgn, float dx, float dy, float dz, float dt, float kappa,
                   const float *f, float *fn);
void init(int nprocs, int rank, int nx, int ny, int nz, int mgn, float dx, float dy, float dz, float *f);
double err(int nprocs, int rank, double time, int nx, int ny, int nz, int mgn, float dx, float dy, float dz, float kappa, const float *f);



#endif /* DIFFUSION_H */
