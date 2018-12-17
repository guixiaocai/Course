#include "queue.h"
#include "sync.h"

#ifndef INCLUDE_MAIL_BOX_
#define INCLUDE_MAIL_BOX_

#define MAX_MAILBOX_SIZE 100

typedef struct mailbox
{
    char name[25];              // 邮箱的名字
    char msg[MAX_MAILBOX_SIZE]; // 消息内容
    int length;                 // 邮箱内消息的长度
    int used_times;             // 邮箱被使用的次数
    int valid;                  // 邮箱有效
    condition_t full;           // 表示邮箱满的条件变量
    condition_t empty;          // 表示邮箱空的条件变量
    mutex_lock_t mutex;         // 互斥锁
} mailbox_t;


void mbox_init();
mailbox_t *mbox_open(char *);
void mbox_close(mailbox_t *);
void mbox_send(mailbox_t *, void *, int);
void mbox_recv(mailbox_t *, void *, int);

#endif