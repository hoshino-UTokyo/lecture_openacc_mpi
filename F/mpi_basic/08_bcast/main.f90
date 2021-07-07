program main
  use mpi
  implicit none
  integer :: nprocs, rank, ierr
  integer,parameter :: n = 8
  integer :: a(n)
  integer :: dst, src
  integer :: i

  call MPI_Init(ierr)

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
  end do

  call MPI_Bcast(a, 4, MPI_INT, 1, MPI_COMM_WORLD, ierr);

  if(rank == 2) then
     print *, a
  end if
    
  call MPI_Finalize(ierr)

end program 

