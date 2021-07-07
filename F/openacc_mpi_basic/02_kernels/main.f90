program main
  use mpi
  use openacc
  implicit none
  integer :: ierr, nprocs, rank
  integer, parameter :: nx = 4096
  integer, parameter :: ny = 4096
  integer, parameter :: w = 10
  real, allocatable :: a(:,:), b(:,:)
  integer :: i, j
  double precision :: st, et
  integer :: dst_rank, tag, ngpus, gpuid
  integer, allocatable :: istat(:)
  double precision :: sum

  call MPI_Init(ierr)
  
  nprocs = 1
  rank = 0

  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

  allocate(istat(MPI_STATUS_SIZE))

  if (nprocs .ne. 2) then 
     call MPI_Finalize(ierr)
     stop
  end if

  ngpus = acc_get_num_devices(acc_device_nvidia)
  if(rank == 0) then
     print *, "num of GPUs = ", ngpus
  end if

  gpuid = mod(rank, ngpus)
  if(ngpus == 0) gpuid = -1
  if(gpuid >= 0) then
     call acc_set_device_num(gpuid, acc_device_nvidia)
  end if

  allocate(a(nx,ny))
  allocate(b(nx,ny))
    
  call MPI_Barrier(MPI_COMM_WORLD, ierr)
    
  st = MPI_WTIME()
  !**** Begin ****

  !$acc kernels copyout(a,b)
  !$acc loop independent
  do j = 1, ny
     !$acc loop independent
     do i = 1, nx
        a(i,j) = 3.0 * rank * ny
        b(i,j) = 0.0
     end do
  end do
  !$acc end kernels

  dst_rank = mod((rank + 1),nprocs)
  tag      = 0

  if (rank == 0) then
     call MPI_Recv(b, w * nx, MPI_FLOAT, dst_rank, tag, MPI_COMM_WORLD, istat, ierr)
  else
     call MPI_Send(a, w * nx, MPI_FLOAT, dst_rank, tag, MPI_COMM_WORLD, ierr)
  end if

  sum = 0.0
  !$acc kernels copyin(b)
  !$acc loop reduction(+:sum)
  do j = 1, ny
     !$acc loop reduction(+:sum)
     do i = 1, nx
        sum = sum + b(i,j)
     end do
  end do
  !$acc end kernels
 
  !**** End ****

  call MPI_Barrier(MPI_COMM_WORLD, ierr)
    
  et = MPI_WTIME()

  if (rank == 0) then
     write(*,'(A6,F10.6)'), "mean =", sum / (nx*ny)
     write(*,'(A6,F10.6,A6)'), "Time =", et-st, " [sec]"
  end if
    
  deallocate(a,b)
  
  call MPI_Finalize(ierr)

end program main
