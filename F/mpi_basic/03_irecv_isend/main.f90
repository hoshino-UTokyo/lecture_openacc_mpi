program main
  use mpi
  implicit none
  integer :: nprocs, rank, ierr, ireq_s, ireq_r
  integer,allocatable :: istat_s(:),istat_r(:)
  integer,parameter :: n = 16
  integer :: a(n), b(n)
  integer :: dst, src
  integer :: i

  call MPI_Init(ierr)
  allocate(istat_s(MPI_STATUS_SIZE))
  allocate(istat_r(MPI_STATUS_SIZE))

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
     a(i) = i + rank * 10
     b(i) = 0
  end do

  dst = mod((rank + 1), nprocs)
  src = mod((rank -1 + nprocs), nprocs)

  call MPI_Isend(a, n, MPI_INT, dst, 100, MPI_COMM_WORLD, ireq_s, ierr)
  call MPI_Irecv(b, n, MPI_INT, src, 100, MPI_COMM_WORLD, ireq_r, ierr)

  call MPI_Wait(ireq_s, istat_s, ierr)
  call MPI_Wait(ireq_r, istat_r, ierr)

  if (rank == 2) then
     print *, b
  end if
    
  call MPI_Finalize(ierr)

end program 

