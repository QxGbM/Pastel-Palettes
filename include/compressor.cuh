
#ifndef _COMPRESSOR_CUH
#define _COMPRESSOR_CUH

#include <pspl.cuh>

template <class T, int shm_size>
__global__ void compressor_kernel (const int length, T ** __restrict__ U_ptrs, T ** __restrict__ V_ptrs, int * __restrict__ ranks, const int * __restrict__ dims)
{
  __shared__ int shm[shm_size];


}

class compressor
{

private:
  int size;
  int length;

  void ** U_ptrs;
  void ** V_ptrs;

  int * ranks;
  int * dims;

public:
  __host__ compressor (const int rnd_seed_in = 0, const int default_size = _DEFAULT_COMPRESSOR_LENGTH)
  {
    size = default_size;
    length = 0;

    const int size_3 = size * 3;

    dims = new int [size_3];
    ranks = new int [size];
    U_ptrs = new void * [size];
    V_ptrs = new void * [size];

    size_t size_b = size * sizeof (void *);
    memset (U_ptrs, 0, size_b);
    memset (V_ptrs, 0, size_b);

    size_b = size * sizeof (int);
    memset (ranks, 0, size_b);

    size_b = 3 * size_b;
    memset (dims, 0, size_b);

    double * rnd_seed = new double [_RND_SEED_LENGTH];
    srand(rnd_seed_in);

#pragma omp parallel for
    for (int i = 0; i < _RND_SEED_LENGTH; i++) 
    { rnd_seed[i] = (double) rand() / RAND_MAX; }

    cudaMemcpyToSymbol(dev_rnd_seed, rnd_seed, _RND_SEED_LENGTH * sizeof(double), 0, cudaMemcpyHostToDevice);
    delete[] rnd_seed;
    
  }

  __host__ ~compressor()
  {
    delete[] U_ptrs;
    delete[] V_ptrs;
    delete[] ranks;
    delete[] dims;

  }

  __host__ void resize (const int size_in)
  {
    if (size_in > 0 && size_in != size)
    {
      const int size_3 = size_in * 3;
      int * dims_new = new int [size_3];
      int * ranks_new = new int [size_in];
      void ** U_ptrs_new = new void * [size_in];
      void ** V_ptrs_new = new void * [size_in];

      const int n = size_in > size ? size : size_in;

#pragma omp parallel for
      for (int i = 0; i < n; i++)
      {
        const int i_3 = i * 3;

        U_ptrs_new[i] = U_ptrs[i];
        V_ptrs_new[i] = V_ptrs[i];
        ranks_new[i] = ranks[i];
        dims_new[i_3] = dims[i_3];
        dims_new[i_3 + 1] = dims[i_3 + 1];
        dims_new[i_3 + 2] = dims[i_3 + 2];
      }

      if (n < size_in)
      {
#pragma omp parallel for
        for (int i = size; i < size_in; i++)
        {
          const int i_3 = i * 3;

          U_ptrs_new[i] = nullptr;
          V_ptrs_new[i] = nullptr;
          dims_new[i_3] = 0;
          dims_new[i_3 + 1] = 0;
          dims_new[i_3 + 2] = 0;
          ranks_new[i] = 0;
        }
      }

      delete[] U_ptrs;
      delete[] V_ptrs;
      delete[] ranks;
      delete[] dims;

      U_ptrs = U_ptrs_new;
      V_ptrs = V_ptrs_new;
      ranks = ranks_new;
      dims = dims_new;

      size = size_in;
      length = (length > size_in) ? size_in : length;

    }
  }

  template <class T> __host__ void compress (dev_low_rank <T> * M)
  {
    if (length == size)
    { resize(size * 2); }

    const int nx = M -> getNx(), ny = M -> getNy(), n = nx > ny ? ny : nx, i_3 = length * 3;
    M -> adjustRank(n);

    dims[i_3] = nx; dims[i_3 + 1] = ny; dims[i_3 + 2] = n;

    U_ptrs[length] = M -> getUxS() -> getElements();
    V_ptrs[length] = M -> getVT() -> getElements();

    length++;
  }

  template <class T> __host__ cudaError_t launch ()
  {


    return cudaSuccess;
  }

};


#endif