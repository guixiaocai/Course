#include "queue.h"
#include "sched.h"

typedef pcb_t item_t;

void queue_init(queue_t *queue)
{
    queue->head = queue->tail = NULL;
}

int queue_is_empty(queue_t *queue)
{
    if (queue->head == NULL)
    {
        return 1;
    }
    return 0;
}

void queue_push(queue_t *queue, void *item)
{
    //printk("Get into queue_push successfully\n");
    //printk("queue addr: 0x%x\n",queue);
    item_t *_item = (item_t *)item;
    //printk("output pcb-entry point:0x%x\n",_item->kernel_context.regs[31]);
    /* queue is empty */
    if (queue->head == NULL)
    {
        //printk("If\n");
        queue->head = item;
        queue->tail = item;
        _item->next = NULL;
        _item->prev = NULL;
        //printk("If end\n");
    }
    else
    {
        //printk("Else\n");
        //printk("_item reg[31]: 0x%x\n",_item->kernel_context.regs[31]);
        //item_t *p = ((item_t *)(queue->tail));
        //printk("queue->tail: 0x%x\n",queue->tail);
        //printk("p->next: %x\n",(uint32_t )p->next);
        //p->next = item;
        ((item_t *)(queue->tail))->next = item;
        _item->next = NULL;
        _item->prev = queue->tail;
        queue->tail = item;
        //printk("Else end");
    }
    //printk("Get out of queue_push successfully\n");
}

void *queue_dequeue(queue_t *queue)
{
    item_t *temp = (item_t *)queue->head;

    /* this queue only has one item */
    if (temp->next == NULL)
    {
        queue->head = queue->tail = NULL;
    }
    else
    {
        queue->head = ((item_t *)(queue->head))->next;
        ((item_t *)(queue->head))->prev = NULL;
    }

    temp->prev = NULL;
    temp->next = NULL;

    return (void *)temp;
}

/* remove this item and return next item */
void *queue_remove(queue_t *queue, void *item)
{
    item_t *_item = (item_t *)item;
    item_t *next = (item_t *)_item->next;

    if (item == queue->head && item == queue->tail)
    {
        queue->head = NULL;
        queue->tail = NULL;
    }
    else if (item == queue->head)
    {
        queue->head = _item->next;
        ((item_t *)(queue->head))->prev = NULL;
    }
    else if (item == queue->tail)
    {
        queue->tail = _item->prev;
        ((item_t *)(queue->tail))->next = NULL;
    }
    else
    {
        ((item_t *)(_item->prev))->next = _item->next;
        ((item_t *)(pcb->next))->prev = _item->prev;
    }

    _item->prev = NULL;
    _item->next = NULL;

    return (void *)next;
}
