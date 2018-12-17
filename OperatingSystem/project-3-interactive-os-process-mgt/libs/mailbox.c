#include "lock.h"
#include "sync.h"
#include "stdio.h"
#include "string.h"
#include "mailbox.h"

#define MAX_NUM_BOX 32

static mailbox_t mboxs[MAX_NUM_BOX];

mutex_lock_t mbox_lock;

void mbox_init()
{
    int i;
    for(i = 0; i < MAX_NUM_BOX; i ++)
        do_mutex_lock_init(&mboxs[i].mutex);
    do_mutex_lock_init(&mbox_lock);
}

mailbox_t *mbox_open(char *name)
{
    int i = 0;
    int j = -1;
    mutex_lock_aquire(&mbox_lock);
    for(i = 0; i < MAX_NUM_BOX; i++){
        if(!strcmp(mboxs[i].name, name)){
            mboxs[i].used_times ++;
            mutex_lock_release(&mbox_lock);
            return &mboxs[i];
        }
        if(!mboxs[i].valid){
            j = i;
        }
    }
    if(j < 0){
        printf("Mailbox is FULL!\n");
    }
    mboxs[j].used_times ++;
    mboxs[j].valid = 1;
    mboxs[j].length = 0;
    strcpy(&mboxs[j].name, name);
    do_condition_init(&mboxs[j].empty);
    do_condition_init(&mboxs[j].full);
    mutex_lock_release(&mbox_lock);
    return &mboxs[j];
}

void mbox_close(mailbox_t *mailbox)
{
    mutex_lock_aquire(&mbox_lock);
    mailbox->used_times --;
    if(mailbox->used_times < 0)
        mailbox->valid = 0;
    mutex_lock_release(&mbox_lock);
}

void mbox_send(mailbox_t *mailbox, void *msg, int msg_length)
{
    mutex_lock_aquire(&mailbox->mutex);
    while(MAX_MAILBOX_SIZE < (mailbox->length + msg_length)){
        sys_condition_wait(&mailbox->mutex, &mailbox->empty);
    }
    mmemcpy(&(mailbox->msg) + mailbox->length, msg, msg_length);
    mailbox->length += msg_length;
    sys_condition_broadcast(&mailbox->full);
    mutex_lock_release(&mailbox->mutex);

}

void mbox_recv(mailbox_t *mailbox, void *msg, int msg_length)
{
    mutex_lock_aquire(&mailbox->mutex);
    while(mailbox->length < msg_length){
        sys_condition_wait(&mailbox->mutex, &mailbox->full);
    }
    mailbox->length -= msg_length;
    mmemcpy(msg, &(mailbox->msg) + mailbox->length, msg_length);
    sys_condition_broadcast(&mailbox->empty);
    mutex_lock_release(&mailbox->mutex);

}