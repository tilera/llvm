export RUNTIMELIMIT=2400
lnt runtest nt --sandbox ~/llvm-results  --cc ~/GitHub/build-llvm/Debug+Asserts/bin/clang --test-suite ~/GitHub/test-suite -j 28
#lnt runtest nt --sandbox ~/llvm-results  --cc ~/GitHub/install-release-llvm/bin/clang --test-suite ~/GitHub/test-suite -j 28
#lnt runtest nt --sandbox ~/llvm-results  --cc /home/jiwang/llvm-3.3/install/bin/clang --test-suite ~/GitHub/test-suite -j 28
#lnt runtest nt --sandbox ~/llvm-results  --cc /home/jiwang/GitHub/build-release-llvm-bootstrap/Debug+Asserts/bin/clang --test-suite ~/GitHub/test-suite -j 28
