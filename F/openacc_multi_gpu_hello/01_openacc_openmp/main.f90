program main
  use omp_lib
  use openacc
  implicit none

  integer,parameter :: length=10
  integer :: a(length), b(length)
  integer :: nth,ith,ngpus,gpuid,str,end,i

  a = (/0,1,2,3,4,5,6,7,8,9/)

  !$omp parallel private(nth,ith,b,ngpus,gpuid,str,end)

  nth = omp_get_num_threads()
  ith = omp_get_thread_num()
  
  b(:) = 0

  if (nth .ne. 2) then
     print *, "error! nth must be 2. Please try `export OMP_NUM_THREADS=2`. nth =", nth
     stop
  end if
  
  ngpus = acc_get_num_devices(acc_device_nvidia);
  gpuid = mod(ith,ngpus);
  call acc_set_device_num(gpuid, acc_device_nvidia);
	
  str =       ith * (length / nth)+1;
  end = (ith + 1) * (length / nth);

  !$acc kernels copyin(a) copyout(b)
  b(str:end) = a(str:end)
  !$acc end kernels

  print *, "tid = ", ith, "gpuid =", gpuid, "b = ", b
  !$omp end parallel 

end program main
