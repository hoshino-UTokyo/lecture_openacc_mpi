program main
  use mpi
  use diffusion
  use misc
  use openacc
  implicit none

  integer,parameter :: nx0 = 128
  integer,parameter :: ny0 = nx0
  integer,parameter :: nz0 = nx0
  integer,parameter :: nt = 100000
  real(KIND=4),parameter :: lx = 1.0
  real(KIND=4),parameter :: ly = 1.0
  real(KIND=4),parameter :: lz = 1.0
  real(KIND=4),parameter :: dx = lx/real(nx0)
  real(KIND=4),parameter :: dy = lx/real(ny0)
  real(KIND=4),parameter :: dz = lx/real(nz0)
  real(KIND=4),parameter :: kappa = 0.1
  real(KIND=4),parameter :: dt = 0.1*min(min(dx*dx, dy*dy), dz*dz)/kappa
  integer :: nx, ny, nz, n
  integer :: icnt
  double precision :: time, flop, elapsed_time, ferr, ferr_sum, faccuracy
  real(KIND=4),pointer,dimension(:,:,:) :: f,fn
  integer :: nprocs, rank, ierr, rank_up, rank_down, tag
  integer,allocatable :: istat(:)
  integer :: ngpus, gpuid

  call MPI_Init(ierr)
  allocate(istat(MPI_STATUS_SIZE))

  nprocs = 1
  rank   = 0
  ngpus = 0
  gpuid = 0

  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

  ngpus = acc_get_num_devices(acc_device_nvidia)
  gpuid = mod(rank,ngpus)
  call acc_set_device_num(gpuid,acc_device_nvidia)

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

  time = 0.d0
  flop = 0.d0 
  elapsed_time = 0.d0

  allocate(f(nx,ny,0:nz+1))
  allocate(fn(nx,ny,0:nz+1))

  call init(nprocs, rank, nx, ny, nz, dx, dy, dz, f);

  call MPI_Barrier(MPI_COMM_WORLD, ierr)

  !$acc data copy(f) create(fn)
  call start_timer()

  do icnt = 0, nt-1
     if(rank == 0 .and. mod(icnt,100) == 0) write (*,"(A5,I4,A4,F7.5)"), "time(",icnt,") = ",time

     tag = 0
     !$acc host_data use_device(f)
     call MPI_Send(f(1,1,nz)  , nx*ny, MPI_FLOAT, rank_up  , tag, MPI_COMM_WORLD, ierr)
     call MPI_Recv(f(1,1,0)   , nx*ny, MPI_FLOAT, rank_down, tag, MPI_COMM_WORLD, istat, ierr)

     call MPI_Send(f(1,1,1)   , nx*ny, MPI_FLOAT, rank_down, tag, MPI_COMM_WORLD, ierr)
     call MPI_Recv(f(1,1,nz+1), nx*ny, MPI_FLOAT, rank_up  , tag, MPI_COMM_WORLD, istat, ierr)
     !$acc end host_data

     flop = flop + diffusion3d(nprocs, rank, nx, ny, nz, dx, dy, dz, dt, kappa, f, fn)

     call swap(f, fn)

     time = time + dt
     if(time + 0.5*dt >= 0.1) exit
  end do

  call MPI_Barrier(MPI_COMM_WORLD, ierr)
    
  elapsed_time = get_elapsed_time();
  !$acc end data

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

end program main
