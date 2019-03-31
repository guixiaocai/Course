#include <stdio.h>
#include "mpi.h"

int main(int argc, char * argv[])
{
    int myrank, nprocs;
    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
    printf("Hello world!\n");
    printf("procs:%d rank:%d\n", nprocs, myrank);
    MPI_Finalize();
}