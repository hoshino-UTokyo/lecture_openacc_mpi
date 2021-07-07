program main
  use mpi
  implicit none
  integer :: nprocs,rank,ierr

  call MPI_Init(ierr)

  nprocs = 1
  rank = -1

  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

  print *, "rank =", rank, "nprocs =", nprocs

  call MPI_Finalize(ierr)

end program

