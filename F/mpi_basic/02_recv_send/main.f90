program main
  use mpi
  implicit none
  integer :: nprocs, rank, ierr
  integer,allocatable :: istat(:)
  integer,parameter :: n = 16
  integer :: a(n), b(n)
  integer :: i

  call MPI_Init(ierr)
  allocate(istat(MPI_STATUS_SIZE))
    
  nprocs = 1
  rank   = 0

  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr);
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr);

  if (nprocs .ne. 4) then
     call MPI_Finalize(ierr)
     print *, "nprocs =", nprocs, "nprocs must be 4."
     stop
  end if

  do i = 1, n
     a(i) = i
     b(i) = 0
  end do

  if (rank == 1) then
     call MPI_Send(a, n, MPI_INT, 2, 100, MPI_COMM_WORLD, ierr)
  else if (rank == 2) then
     call MPI_Recv(b, n, MPI_INT, 1, 100, MPI_COMM_WORLD, istat, ierr)
  end if

  if (rank == 2) then
     print *, b
  end if
    
  call MPI_Finalize(ierr)

end program 
