#include<stdio.h>
#include<pthread.h>
#include<sys/time.h>
#include<math.h>
#include<stdlib.h>

#define true 1
#define false 0
#define RUNTIMES 100
#define MAX 10000000

int flag[2];
int turn;

int index = 0;
int data[MAX];

//thread1
void *thread1()
{
    int i = 0;
    while(i < MAX)
    {
        flag[0] = true;
        turn = 1;
        while(flag[1] == 1 && turn == 1);
        //critical section
        printf("thread1 enters critical section\n");
        int count = 0;
        for(count = 0; i < MAX && count < RUNTIMES; i += 2, count ++)
        {
            data[index] = i; //even ( i+1 for thread 2)
            index ++;
        }
        flag[0] = false;
        //reminder
    }    
}

//thread2
void *thread2()
{
    int i = 0;
    while(i < MAX)
    {
        flag[1] = true;
        turn = 0;
        while(flag[0] == 1 && turn == 0);
        //critical section
        printf("thread2 enters critical section\n");
        int count = 0;
        for(count = 0; i < MAX && count < RUNTIMES; i += 2, count ++)
        {
            data[index] = i + 1; // odd
            index ++;
        }
        flag[1] = false;
        //reminder
    }    
}

int main()
{
    pthread_t tid1, tid2;
    int i, err, diff, temp;
    struct timeval start_time, end_time;
    //flag[0] = flag[1] = false;
    gettimeofday(&start_time, NULL);
    for(i = 0; i < 1000; i ++)
    {
        index = 0;
        err = pthread_create(&tid1, NULL, thread1, NULL);
        if(err != 0)
        {
            printf("Create thread 1 failed!\n");
            exit(0);
        }
        err = pthread_create(&tid2, NULL, thread2, NULL);
        if(err != 0)
        {
            printf("Create thread 2 failed!\n");
            exit(0);
        }
        err = pthread_join(tid1, NULL);
        if(err != 0)
        {
            printf("Stop thread 1 failed!\n");
            exit(0);
        }
        err = pthread_join(tid2, NULL);
        if(err != 0)
        {
            printf("Stop thread 2 failed!\n");
            exit(0);
        }
    }
    gettimeofday(&end_time, NULL);
    
    diff = abs(data[0] - data[1]);
    for(i = 1; i < MAX && data[i]; i ++)
    {
        temp = abs(data[i] - data[i+1]);
        diff = diff < temp ? temp : diff;
    }

    printf("Max abstraction of difference is %d.\n", diff);
    printf("Runtime: %f.\n", difftime(end_time.tv_sec, start_time.tv_sec)/1000);
    return 0;
}
