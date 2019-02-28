
#ifndef _PIVOT_CUH
#define _PIVOT_CUH

#include <cooperative_groups.h>

using namespace cooperative_groups;

template <class matrixEntriesT>
__device__ int blockAllFindRowPivot (const matrixEntriesT *matrix, const int n, const int ld, const thread_block g = this_thread_block())
{
  const thread_block_tile <32> warp = tiled_partition <32> (g);

  const int warp_id = g.thread_rank() / warpSize;
  const int lane_id = g.thread_rank() - warp_id * warpSize;

  int index = 0;
  matrixEntriesT max = 0; 

  /* Load all row entries in warps: Each warp can handle more than 1 warpsize of data or no data. */
  for (int i = g.thread_rank(); i < n; i += g.size())
  {
    const matrixEntriesT value = abs(matrix[i * ld]);
    if (value > max)
    { max = value; index = i; }
  }

  /* Reduction in all warps. No need to explicitly sync because warp shfl implies synchronization. */
  for (int mask = warpSize / 2; mask > 0; mask /= 2) 
  {
    const matrixEntriesT s_max = warp.shfl_xor(max, mask);
    const int s_index = warp.shfl_xor(index, mask);
    if (s_max > max) 
    { max = s_max; index = s_index; }
  }

  __shared__ matrixEntriesT shm_max[32];
  __shared__ int shm_index[32];

  /* The first lane of each warp writes into their corresponding shared memory slot. */
  if (lane_id == 0) { shm_max[warp_id] = max; shm_index[warp_id] = index; }

  g.sync(); /* Sync here to make sure shared mem is properly initialized, and reductions in all warps are completed. */

  /* Do the final reduction in the first warp, if there are more than 1 warp. */
  if (g.size() > warpSize && warp_id == 0) 
  {
    max = shm_max[lane_id];
    index = shm_index[lane_id];
    for (int mask = warpSize / 2; mask > 0; mask /= 2) 
    {
      const matrixEntriesT s_max = warp.shfl_xor(max, mask);
      const int s_index = warp.shfl_xor(index, mask);
      /* Uses more strict comparison to resolve ties. */
      if (s_max > max || (s_max == max && s_index < index)) 
      { max = s_max; index = s_index; }
    }

    if (lane_id == 0)
    {
      shm_max[lane_id] = max;
      shm_index[lane_id] = index;
    }
  }

  g.sync(); /* Sync here to stop other warps and waits for warp 0. */

  return shm_index[0];
}

template <class matrixEntriesT>
__device__ void blockSwapNSeqElements (matrixEntriesT *row1, matrixEntriesT *row2, const int n, const thread_group g = this_thread_block())
{
  /* Using a group of threads to exchange all elements in row with target row. */
  for (int i = g.thread_rank(); i < n; i += g.size()) /* swapping n elements in two rows. */
  {
    const matrixEntriesT t = row1[i];
    row1[i] = row2[i]; 
    row2[i] = t;
  }
}

template <class matrixEntriesT>
__device__ void blockApplyPivot (matrixEntriesT *matrix, const int *pivot, const int nx, const int ld, const int ny, 
  const bool recover = false, const thread_group g = this_thread_block())
{
  /* Using a group of threads to apply pivot the pivot swaps to the matrix. Recover flag retrieves original matrix. */
  for (int i = 0; i < ny; i++) 
  {
    bool smallest_row_in_cycle = true;
    int swapping_with = pivot[i];
    
    while (smallest_row_in_cycle && swapping_with != i)
    {
      if (swapping_with < i) { smallest_row_in_cycle = false; }
      swapping_with = pivot[swapping_with];
    }

    if (smallest_row_in_cycle)
    {
      int source_row = i;
      swapping_with = pivot[i];
      while (swapping_with != i) 
      { 
        blockSwapNSeqElements <matrixEntriesT> (&matrix[source_row * ld], &matrix[swapping_with * ld], nx);
        source_row = recover ? i : swapping_with;
        swapping_with = pivot[swapping_with];
      }
    }
  }
}

__device__ void resetPivot (int *pivot, const int n, const thread_group g = this_thread_block())
{
  for (int i = g.thread_rank(); i < n; i += g.size()) 
  { pivot[i] = i; }
}


#endif