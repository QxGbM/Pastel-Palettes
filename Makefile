.SUFFIXES: .cu

NVCC = nvcc 
NVCC += -ccbin g++ -std=c++11

HOME_DIR = ./

PSPL_DIR = $(HOME_DIR)
BIN_DIR = $(HOME_DIR)bin/
INCLUDE_DIR = $(PSPL_DIR)include/

ARCH += -gencode arch=compute_60,code=sm_60
ARCH += -gencode arch=compute_61,code=sm_61
ARCH += -gencode arch=compute_70,code=sm_70
ARCH += -gencode arch=compute_75,code=sm_75
ARCH += -gencode arch=compute_75,code=compute_75

NVCCFLAGS = -maxrregcount=64 --machine 64 -rdc=true -O3 
NVCCFLAGS += -I$(INCLUDE_DIR) 
NVCCFLAGS += $(ARCH) 

LDFLAGS = -lstdc++ -lm -lcuda -lcudart 
LDFLAGS += -L/usr/lib/x86_64-linux-gnu $(ARCH)

#USE_MKL = TRUE

ifdef USE_MKL

INCLUDE += 
LDFLAGS += -lmkl_intel_lp64 -lmkl_sequential -lmkl_core

endif

all:
	mkdir --parents $(BIN_DIR)
	$(NVCC) $(NVCCFLAGS) -c $(PSPL_DIR)main.cu -o $(BIN_DIR)main.o
	$(NVCC) $(BIN_DIR)main.o $(LDFLAGS) -o $(BIN_DIR)main
	./$(BIN_DIR)main

clean:
	rm -rf $(BIN_DIR)
