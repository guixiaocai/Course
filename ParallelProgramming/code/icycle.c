#include <stdio.h>
#include <string.h>
#include "mpi.h"

int main(int argc, char * argv[])
{
    int myrank, nprocs, tag = 0;
    MPI_Status status;
    MPI_Request req;
    char send_msg[] = "I'm a message", recv_msg[100];

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    
    int src = (myrank - 1 + nprocs) % nprocs;
    int dst = (myrank + 1) % nprocs;

    if (myrank == 0)
    {
        MPI_Isend(send_msg, strlen(send_msg)+1, MPI_CHAR, dst, tag, MPI_COMM_WORLD, &req);
        MPI_Wait(&req, &status);
        MPI_Irecv(recv_msg, 100, MPI_CHAR, src, tag, MPI_COMM_WORLD, &req);
        MPI_Wait(&req, &status);
    }
    else
    {
        MPI_Irecv(recv_msg, 50, MPI_CHAR, src, tag, MPI_COMM_WORLD, &req);
        MPI_Wait(&req, &status);
        MPI_Isend(recv_msg, strlen(recv_msg)+1, MPI_CHAR, dst, tag, MPI_COMM_WORLD, &req);  
        MPI_Wait(&req, &status);
    }
    
    printf("%d, %s\n", myrank, recv_msg);
    MPI_Finalize();
    return 0;
}