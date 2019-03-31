#include <stdio.h>
#include <string.h>
#include "mpi.h"

int main(int argc, char * argv[])
{
    int myrank, nprocs, tag = 0;
    MPI_Status status;
    //MPI_Comm comm;
    char send_msg[] = "I'm a message", recv_msg[100];

    MPI_Init(&argc, &argv);
    //MPI_Comm_dup(MPI_COMM_WORLD, &comm);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    
    int src = (myrank - 1 + nprocs) % nprocs;
    int dst = (myrank + 1) % nprocs;

    if (myrank == 0)
    {
        MPI_Sendrecv(send_msg, strlen(send_msg)+1, MPI_CHAR, dst, tag, recv_msg, 100, MPI_CHAR, src, tag, MPI_COMM_WORLD, &status);
    }
    else
    {
        MPI_Recv(recv_msg, 50, MPI_CHAR, src, tag, MPI_COMM_WORLD, &status);
        MPI_Send(recv_msg, strlen(recv_msg)+1, MPI_CHAR, dst, tag, MPI_COMM_WORLD);  
    }
    
    printf("%d, %s\n", myrank, recv_msg);
    MPI_Finalize();
    return 0;
}