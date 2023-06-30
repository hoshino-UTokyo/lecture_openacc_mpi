#ifndef MPI_TYPE
#define MPI_TYPE 2
! 0 ... by host (correct) 
! 1 ... cuda aware (error)
! other ... cuda aware (work around, correct)
#endif

program main
  use mpi
#ifdef _OPENACC
  use openacc
#endif
  use diffusion
  use misc
  implicit none

  integer,parameter :: nx0 = 256
  integer,parameter :: ny0 = nx0
  integer,parameter :: nz0 = nx0
  integer,parameter :: nt = 100000
  real(KIND=8),parameter :: lx = 1.0
  real(KIND=8),parameter :: ly = 1.0
  real(KIND=8),parameter :: lz = 1.0
  real(KIND=8),parameter :: dx = lx/real(nx0)
  real(KIND=8),parameter :: dy = lx/real(ny0)
  real(KIND=8),parameter :: dz = lx/real(nz0)
  real(KIND=8),parameter :: kappa = 0.1
  real(KIND=8),parameter :: dt = 0.1*min(min(dx*dx, dy*dy), dz*dz)/kappa
  integer :: nx, ny, nz, n
  integer :: icnt
  double precision :: time, flop, elapsed_time, ferr, ferr_sum, faccuracy
  real(KIND=8),pointer,dimension(:,:,:) :: f,fn
  integer :: nprocs, rank, ierr, rank_up, rank_down, tag
  integer,allocatable :: istat(:,:), ireq(:)
  integer :: ngpus, gpuid, i, len_name
  character :: hostname*12, eval*12

  call MPI_Init(ierr)
  allocate(istat(MPI_STATUS_SIZE,4))
  allocate(ireq(4))

  nprocs = 1
  rank   = 0

  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

  rank_up   = rank + 1
  rank_down = rank - 1
  if(rank == nprocs-1) rank_up   = MPI_PROC_NULL 
  if(rank == 0)        rank_down = MPI_PROC_NULL 

  nx = nx0
  ny = ny0
  nz = nz0 / nprocs
  n  = nx*ny*nz

  if (nz * nprocs .ne. nz0) then 
     if (rank == 0) then
        print *, "Error: nz * nprocs != nz0, (nz,nprocs,nz0) = ", nz, nprocs, nz0
     end if
     call MPI_Finalize(ierr)
     stop
  end if

  if (rank == 0) then 
     print *, "nprocs = ", nprocs
  end if

#ifdef _OPENACC
  ngpus = acc_get_num_devices(acc_device_nvidia)
  if(rank == 0) then
     print *, "num of GPUs = ", ngpus
  end if

  gpuid = mod(rank, ngpus)
  if(ngpus == 0) gpuid = -1
  if(gpuid >= 0) then
     call acc_set_device_num(gpuid, acc_device_nvidia)
  end if

  ! if (rank == 0) then
  !    call getenv("OMPI_MCA_btl_smcuda_use_cuda_ipc",eval)
  !    print *, "OMPI_MCA_btl_smcuda_use_cuda_ipc  =",eval
  !    call getenv("OMPI_MCA_btl_openib_want_cuda_ipc",eval)
  !    print *, "OMPI_MCA_btl_openib_want_cuda_gdr =",eval
  ! end if

  do i = 0, nprocs-1
     call MPI_Barrier(MPI_COMM_WORLD, ierr)
     if (i .ne. rank) cycle
     call MPI_get_processor_name(hostname, len_name, ierr)
     write(*,'(A5,I2,A14,A12,A10,I2)') "Rank ", rank, ": hostname = ", hostname, "GPU num = ", gpuid
  end do
#endif

  time = 0.d0
  flop = 0.d0 
  elapsed_time = 0.d0

  allocate(f(nx,ny,0:nz+1))
  allocate(fn(nx,ny,0:nz+1))

  call init(nprocs, rank, nx, ny, nz, dx, dy, dz, f);

  call MPI_Barrier(MPI_COMM_WORLD, ierr)

  !$omp target data map(tofrom:f,fn)
  tag = 0
#if MPI_TYPE==0
  call MPI_Isend(f(1,1,nz)  , nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(1), ierr)
  call MPI_Irecv(f(1,1,0)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(2), ierr)
  
  call MPI_Isend(f(1,1,1)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(3), ierr)
  call MPI_Irecv(f(1,1,nz+1), nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(4), ierr)
#elif MPI_TYPE==1
  call MPI_Isend(f(1,1,nz)  , nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(1), ierr)
  call MPI_Irecv(f(1,1,0)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(2), ierr)
  
  call MPI_Isend(f(1,1,1)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(3), ierr)
  call MPI_Irecv(f(1,1,nz+1), nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(4), ierr)
#else
  ! avoid openmpi(?) bug
  call work_around(f,nx,ny,nz,rank_up,rank_down,tag,ireq,ierr)
#endif
  call MPI_Waitall(4,ireq,istat,ierr)

  call start_timer()

  do icnt = 0, nt-1
     if(rank == 0 .and. mod(icnt,100) == 0) write (*,"(A5,I4,A4,F7.5)"), "time(",icnt,") = ",time


     flop = flop + diffusion3d_halo(nprocs, rank, nx, ny, nz, dx, dy, dz, dt, kappa, f, fn)
#if MPI_TYPE==0
     call MPI_Isend(fn(1,1,nz)  , nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(1), ierr)
     call MPI_Irecv(fn(1,1,0)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(2), ierr)
     
     call MPI_Isend(fn(1,1,1)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(3), ierr)
     call MPI_Irecv(fn(1,1,nz+1), nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(4), ierr)
#elif MPI_TYPE==1
     call MPI_Isend(fn(1,1,nz)  , nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(1), ierr)
     call MPI_Irecv(fn(1,1,0)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(2), ierr)
     
     call MPI_Isend(fn(1,1,1)   , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(3), ierr)
     call MPI_Irecv(fn(1,1,nz+1), nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(4), ierr)
#else
     ! avoid openmpi(?) bug
     call work_around(fn,nx,ny,nz,rank_up,rank_down,tag,ireq,ierr)
#endif
     call MPI_Waitall(4,ireq,istat,ierr)
     flop = flop + diffusion3d(nprocs, rank, nx, ny, nz, dx, dy, dz, dt, kappa, f, fn)

     call swap(f, fn)

     time = time + dt
     if(time + 0.5*dt >= 0.1) exit
  end do

  call MPI_Barrier(MPI_COMM_WORLD, ierr)
    
  elapsed_time = get_elapsed_time();
  !$omp end target data

  if (rank == 0) then
     write(*, "(A7,F8.3,A6)"), "Time = ",elapsed_time," [sec]"
     write(*, "(A13,F7.2,A16)"), "Performance= ",flop/elapsed_time*1.0e-09," [GFlops/nprocs]"
     write(*, "(A13,F7.2,A9)"), "Performance= ",flop/elapsed_time*1.0e-09*nprocs," [GFlops]"
  end if

  ferr = err(nprocs, rank, time, nx, ny, nz, dx, dy, dz, kappa, f)

  ferr_sum = 0.0
  call MPI_Reduce(ferr, ferr_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD, ierr)

  faccuracy = sqrt(ferr_sum/dble(nx0*ny0*nz0))

  if (rank == 0) then 
     write(*, "(A6,I0,A2,I0,A2,I0,A4,E12.6)"), "Error[",nx0,"][",ny0,"][",nz0,"] = ",faccuracy
  end if

  deallocate(f,fn)

  call MPI_Finalize(ierr)

contains

  subroutine work_around(f,nx,ny,nz,rank_up,rank_down,tag,ireq,ierr)
    implicit none
    real(kind=8), dimension(*) :: f
    integer :: nx,ny,nz,rank_up,rank_down,tag,ireq(:),ierr
    
    !$omp target data use_device_ptr(f)
    call MPI_Irecv(f(1)             , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(1), ierr)
    call MPI_Irecv(f(nx*ny*(nz+1)+1), nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(2), ierr)
    call MPI_Isend(f(nx*ny*nz+1)    , nx*ny, MPI_DOUBLE, rank_up  , tag, MPI_COMM_WORLD, ireq(3), ierr)
    call MPI_Isend(f(nx*ny+1)       , nx*ny, MPI_DOUBLE, rank_down, tag, MPI_COMM_WORLD, ireq(4), ierr)
    !$omp end target data
  end subroutine work_around

end program main
