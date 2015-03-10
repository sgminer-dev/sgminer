setx GPU_FORCE_64BIT_PTR 0

setx GPU_MAX_HEAP_SIZE 100

setx GPU_USE_SYNC_OBJECTS 1

setx GPU_MAX_ALLOC_PERCENT 100

del *.bin


sgminer.exe --no-submit-stale --kernel Lyra2RE -o stratum+tcp://92.27.201.170:9174 -u m -p 1 --gpu-platform 2 -I 19 --shaders 2816  -w 64 -g 2 

pause