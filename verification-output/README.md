This folder contains the logs of the verification runs for proving both qspinlock and cna correct under arm, power and LKMM (after applying the required fixes).

It also contains execution graphs showcasing the violations we found in qspinlock under LKMM. Each violation `BUGX` resulted in a fix in the code which is enabled by using `-DFIXX`. Using flags `-DFIX1 -DFIX2 -DFIX3 -DFIX4 -DFIX5` we proved the code correct under LKMM.

[BUG1.png](https://github.com/huawei-drc/cna-verification/tree/master/verification-output/BUG1.png) was generated using 3 threads and running
```
> export CFLAGS="-I($DAT3M_HOME)/include/smack -I($CNA_VERIFICATION_HOME)/include -I($DAT3M_HOME)/include/clang/ -DNTHREADS=3 -DALGORITHM=2 -DSKIP_PENDING"

❯ java -jar dartagnan/target/dartagnan-3.0.0.jar cat/linux-kernel.cat --target=lkmm --bound=1 --program.processing.constantPropagation=false ../cna-verification/client-code.c --refinement.baseline=no_oota,uniproc,atomic_rmw --property=liveness --witness.graphviz=true
```

[BUG2.png](https://github.com/huawei-drc/cna-verification/tree/master/verification-output/BUG2.png) was generated using 3 threads and running
```
> export CFLAGS="-I($DAT3M_HOME)/include/smack -I($CNA_VERIFICATION_HOME)/include -I($DAT3M_HOME)/include/clang/ -DNTHREADS=3 -DALGORITHM=2 -DSKIP_PENDING -DFIX1"

> java -jar dartagnan/target/dartagnan-3.0.0.jar cat/linux-kernel.cat --target=lkmm --bound=1 --program.processing.constantPropagation=false ../cna-verification/client-code.c --refinement.baseline=no_oota,uniproc,atomic_rmw --property=reachability --witness.graphviz=true
```

[BUG3.png](https://github.com/huawei-drc/cna-verification/tree/master/verification-output/BUG3.png) was generated using 3 threads and running
```
> export CFLAGS="-I($DAT3M_HOME)/include/smack -I($CNA_VERIFICATION_HOME)/include -I($DAT3M_HOME)/include/clang/ -DNTHREADS=3 -DALGORITHM=2 -DFIX1 -DFIX2"

> java -jar dartagnan/target/dartagnan-3.0.0.jar cat/linux-kernel.cat --target=lkmm --bound=1 --program.processing.constantPropagation=false ../cna-verification/client-code.c --refinement.baseline=no_oota,uniproc,atomic_rmw --property=reachability --witness.graphviz=true
```

[BUG4.png](https://github.com/huawei-drc/cna-verification/tree/master/verification-output/BUG4.png) was generated using 4 threads and running
```
> export CFLAGS="-I($DAT3M_HOME)/include/smack -I($CNA_VERIFICATION_HOME)/include -I($DAT3M_HOME)/include/clang/ -DNTHREADS=4 -DALGORITHM=2 -DFIX1 -DFIX2 -DFIX3"

> java -jar dartagnan/target/dartagnan-3.0.0.jar cat/linux-kernel.cat --target=lkmm --bound=1 --program.processing.constantPropagation=false ../cna-verification/client-code.c --refinement.baseline=no_oota,uniproc,atomic_rmw --property=reachability --witness.graphviz=true
```

[BUG5.png](https://github.com/huawei-drc/cna-verification/tree/master/verification-output/BUG5.png) was generated using 4 threads and running
```
> export CFLAGS="-I($DAT3M_HOME)/include/smack -I($CNA_VERIFICATION_HOME)/include -I($DAT3M_HOME)/include/clang/ -DNTHREADS=4 -DALGORITHM=2 -DFIX1 -DFIX2 -DFIX3 -DFIX4"

> java -jar dartagnan/target/dartagnan-3.0.0.jar cat/linux-kernel.cat --target=lkmm --bound=1 --program.processing.constantPropagation=false ../cna-verification/client-code.c --refinement.baseline=no_oota,uniproc,atomic_rmw --property=reachability --witness.graphviz=true
```

