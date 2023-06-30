for args in acc_managed acc_async_overlap_managed acc_async_overlap ompgpu_managed ompgpu_nowait_overlap_managed ompgpu_nowait_overlap stdpar1
do
    cd $args
    echo $args
    make clean
    make
    cp $args ../run
    cd ../
done
