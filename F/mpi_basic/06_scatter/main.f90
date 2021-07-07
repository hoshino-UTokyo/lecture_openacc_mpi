program main
  use mpi
  implicit none
  integer :: nprocs, rank, ierr
  integer,parameter :: n = 8
  integer :: a(n), b(n)
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
     b(i) = 0
  end do

  call MPI_Scatter(a, 2, MPI_INT, b, 2, MPI_INT, 1, MPI_COMM_WORLD, ierr);

  print *, "Rank =", rank, ":", b
    
  call MPI_Finalize(ierr)

end program 

