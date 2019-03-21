
#ifndef _CUDA_TIMER_CUH
#define _CUDA_TIMER_CUH

#include <stdio.h>
#include <string.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <definitions.cuh>

class timer 
{
private:

  class event_chain 
  {
  private:

    cudaEvent_t event;
    mark_t type;
    event_chain *next;

  public:
  
    __host__ event_chain (const mark_t type_in, const cudaStream_t stream = 0)
    {
      cudaEventCreate (&event);
      cudaEventRecord (event, stream);
      type = type_in;
      next = nullptr;
    }
  
    __host__ ~event_chain ()
    {
      cudaEventDestroy (event);
      if (next != nullptr)
      { delete next; }
    }
  
    __host__ void hookNewEvent (const mark_t type_in, const cudaStream_t stream = 0)
    {
      if (next == nullptr)
      { next = new event_chain(type_in, stream); }
      else
      { next -> hookNewEvent(type_in, stream); }
    }
  
    __host__ int length () const
    {
      return (next == nullptr) ? 1 : 1 + next -> length();
    }

    __host__ int length (const mark_t type_in) const
    {
      int count = (int)(type == type_in);
      return (next == nullptr) ? count : count + next -> length(type_in);
    }

    __host__ float getTotal_Sync (const event_chain *e = nullptr) const
    {
      float millis = 0.0;
      switch (type)
      {
      case start: 
        millis = (next == nullptr) ? 0 : next -> getTotal_Sync(this);
        break;
      case end: 
        if (e != nullptr) { cudaEventElapsedTime(&millis, e -> event, event); }
        millis += (next == nullptr) ? 0 : next -> getTotal_Sync(e);
      }
      return millis;
    }
  
  };

  event_chain ** events;
  char ** names;
  int event_counter;
  int table_size;

public:

  __host__ timer (const int time_table_size = 1)
  {
    events = new event_chain * [time_table_size];
    names = new char * [time_table_size];
    memset ((void *) events, 0, time_table_size * sizeof(event_chain *));
    memset ((void *) names, 0, time_table_size * sizeof(char *));
    event_counter = 0;
    table_size = (time_table_size > 0) ? time_table_size : 1;
  }

  __host__ ~timer ()
  {
    for (int i = 0; i < event_counter; i++)
    { delete events[i]; delete names[i]; }
    delete[] events;
    delete[] names;
    printf("-- Timer destructed. --\n\n");
  }

  __host__ event_chain * getEvent (const char *event_name) const
  {
    for (int i = 0; i < event_counter; i++)
    {
      if (strcmp(event_name, names[i]) == 0) { return events[i]; }
    }
    return nullptr;
  }

  __host__ void change_table_size (const int time_table_size)
  {
    int size = (time_table_size > 0) ? time_table_size : 1;

    event_chain ** events_old = events; 
    events = new event_chain *[size];
    memset((void *)events, 0, size * sizeof(event_chain *));

    char ** names_old = names;
    names = new char *[size];
    memset((void *)names, 0, size * sizeof(char *));

    for (int i = 0; i < event_counter && i < size; i++)
    {
      events[i] = events_old[i];
      names[i] = names_old[i];
    }
    for (int i = size; i < table_size; i++)
    {
      delete events_old[i];
      delete names_old[i];
    }
    delete[] events_old;
    delete[] names_old;

    table_size = size;
    event_counter = (event_counter > table_size) ? table_size : event_counter;
    printf("-- Timer: Table size changed to %d --\n\n", table_size);
  }

  __host__ void newEvent (const char *event_name, mark_t type, cudaStream_t stream = 0)
  {
    event_chain *p = getEvent(event_name);
    
    if (p == nullptr)
    {
      if (event_counter == table_size)
      {
        change_table_size(table_size * 2);
      }
      events[event_counter] = new event_chain(type, stream);
      const int length = (int) strlen(event_name) + 1;
      names[event_counter] = new char[length];
      strcpy(names[event_counter], event_name);
      event_counter ++;
    }
    else
    { p -> hookNewEvent(type, stream); }

  }

  __host__ cudaError_t dumpAllEvents_Sync ()
  {
    cudaError_t error = cudaDeviceSynchronize();
    if (error != cudaSuccess) 
    { fprintf(stderr, "CUDA error from device synchronize: %s\n\n", cudaGetErrorString(error)); return error; }

    printf("-----------------------------------------------------\n");
    printf("CUDA device synchronized, start dumping timed events:\n");

    for (int i = 0; i < event_counter; i++)
    {
      float millis = events[i] -> getTotal_Sync();
      printf ("%s:  %f ms.\n", names[i], millis);

      delete events[i];
      delete[] names[i];
      events[i] = nullptr;
      names[i] = nullptr;
    }

    event_counter = 0;
    printf("All timed events dumped, table is cleared. \n");
    printf("-----------------------------------------------------\n\n");

    return cudaSuccess;
  }

  __host__ void printStatus () const
  {
    printf("-- Timer Status: --\n");
    printf("Total Timed Events: %d.\n", event_counter);
    printf("Time Table Size: %d.\n", table_size);

    for (int i = 0; i < event_counter; i++)
    {
      printf("Event: %s has %d start and %d end marks.\n", names[i], events[i] -> length(start), events[i] -> length(end));
    }

    printf("-- Timer Status End. --\n\n");
  }

};

#endif