// Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
// SPDX-License-Identifier: MIT

/*
$ genmc -mo -imm -disable-spin-assume -disable-cast-elimination -random-schedule-seed=3 -schedule-policy=random cna-c11-relaxed.c 
WARNING: Atomic xchg support is experimental under dependency-tracking models!
BUG: Failure at GenMCDriver.cpp:798/getWriteValue()!
 */

/******************************************************************************
 * Compact NUMA-Aware (CNA) Lock by Dave Dice and Alex Kogan
 *   https://arxiv.org/abs/1810.05600
 *
 * This version of the code is implemented with C11 (stdatomic.h) and contains
 * a maximally relaxed combination of memory barriers for the IMM memory model.
 * The barriers were discovered with the VSync tool as described here:
 *   https://arxiv.org/abs/2111.15240
 *
 * With these barriers, CNA guarantees safety (mutual exclusion) and liveness
 * (await loop termination) on Armv8, RISC-V, Power and x86.
 *
 * To verify this code with GenMC 0.7 use the following command:
 *   genmc -mo -imm -check-liveness -disable-spin-assume cna-c11.c
 *
 * Note that the minimum number of threads is 4. With less threads than that,
 * some scenarios are not exercised.
 *****************************************************************************/
#include <pthread.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <assert.h>

#define NTHREADS 4

#include <genmc.h>
/* spin-assume transformation of GenMC 0.7 does not always work. Instead
 * we use the following annotation for spinloops and disable the transformation
 * with -disable-spin-assume.
 */
#define await_while(cond) for (__VERIFIER_loop_begin();                \
    __VERIFIER_spin_start(), (cond) ? 1 : (__VERIFIER_spin_end(1), 0); \
    __VERIFIER_spin_end(0))

#define CPU_PAUSE() do {} while(0)

typedef struct cna_node {
    _Atomic(uintptr_t) spin;
    _Atomic(int) socket;
    _Atomic(struct cna_node *) secTail;
    _Atomic(struct cna_node *) next;
} cna_node_t;

static int current_numa_node();
static bool keep_lock_local();

typedef struct {
    _Atomic(cna_node_t *) tail;
} cna_lock_t;

static void cna_lock(cna_lock_t *lock, cna_node_t *me)
{
    atomic_store_explicit(&me->next, 0, memory_order_relaxed);
    atomic_store_explicit(&me->socket, -1, memory_order_relaxed);
    atomic_store_explicit(&me->spin, 0, memory_order_relaxed);

    cna_node_t *tail = atomic_exchange_explicit(&lock->tail, me, memory_order_seq_cst);
    if (!tail) {
        atomic_store_explicit(&me->spin, 1, memory_order_relaxed);
        return;
    }

    atomic_store_explicit(&me->socket, current_numa_node(), memory_order_relaxed);
    atomic_store_explicit(&tail->next, me, memory_order_release);

    await_while (!atomic_load_explicit(&me->spin, memory_order_acquire))
        CPU_PAUSE();
}

static cna_node_t* find_successor(cna_node_t *me)
{
    cna_node_t *next = atomic_load_explicit(&me->next, memory_order_relaxed);
    int mySocket = atomic_load_explicit(&me->socket, memory_order_relaxed);

    if (mySocket == -1)
        mySocket = current_numa_node();
    if (atomic_load_explicit(&next->socket, memory_order_relaxed) == mySocket)
       return next;
    
    cna_node_t *secHead = next;
    cna_node_t *secTail = next;
    cna_node_t *cur = atomic_load_explicit(&next->next, memory_order_acquire);
    
    while (cur) {
        if (atomic_load_explicit(&cur->socket, memory_order_relaxed) == mySocket) {
            if (atomic_load_explicit(&me->spin, memory_order_relaxed) > 1) {
                cna_node_t *_spin = (cna_node_t*) atomic_load_explicit(&me->spin, memory_order_relaxed);
                cna_node_t *_secTail = atomic_load_explicit(&_spin->secTail, memory_order_relaxed);
                atomic_store_explicit(&_secTail->next, secHead, memory_order_relaxed);
            } else {
                atomic_store_explicit(&me->spin, (uintptr_t) secHead, memory_order_relaxed);
            }
            atomic_store_explicit(&secTail->next, NULL, memory_order_relaxed);
            cna_node_t *_spin = (cna_node_t*) atomic_load_explicit(&me->spin, memory_order_relaxed);
            atomic_store_explicit(&_spin->secTail, secTail, memory_order_relaxed);
            return cur;
        }
        secTail = cur;
        cur = atomic_load_explicit(&cur->next, memory_order_acquire);
    }
    return NULL;
}

static void cna_unlock(cna_lock_t *lock, cna_node_t *me)
{
    if (!atomic_load_explicit(&me->next, memory_order_acquire)) {
        if (atomic_load_explicit(&me->spin, memory_order_relaxed) == 1) {
            cna_node_t *local_me = me;
            if (atomic_compare_exchange_strong_explicit(&lock->tail, &local_me, NULL, memory_order_seq_cst, memory_order_seq_cst)) {
                return;
            }
        } else {
            cna_node_t *secHead = (cna_node_t *) atomic_load_explicit(&me->spin, memory_order_relaxed);
            cna_node_t *local_me = me;
            if (atomic_compare_exchange_strong_explicit(&lock->tail, &local_me,
                    atomic_load_explicit(&secHead->secTail, memory_order_relaxed),
                    memory_order_seq_cst, memory_order_seq_cst)) {
                atomic_store_explicit(&secHead->spin, 1, memory_order_release);
                return;
            }
        }
        await_while (atomic_load_explicit(&me->next, memory_order_relaxed) == NULL)
            CPU_PAUSE();
    }
    cna_node_t *succ = NULL;
    if (keep_lock_local() && (succ = find_successor(me))) {
        atomic_store_explicit(&succ->spin, 
            atomic_load_explicit(&me->spin, memory_order_relaxed),
            memory_order_release);
    } else if (atomic_load_explicit(&me->spin, memory_order_relaxed) > 1) {
        succ = (cna_node_t *) atomic_load_explicit(&me->spin, memory_order_relaxed);
        atomic_store_explicit(
            &atomic_load_explicit(&succ->secTail, memory_order_relaxed)->next,
            atomic_load_explicit(&me->next, memory_order_relaxed),
            memory_order_relaxed);
        atomic_store_explicit(&succ->spin, 1, memory_order_release);
    } else {
        succ = (cna_node_t*) atomic_load_explicit(&me->next, memory_order_relaxed);
        atomic_store_explicit(&succ->spin, 1, memory_order_relaxed);
    }
}

__thread intptr_t tid;
atomic_bool cna_threshold_reached;
static int current_numa_node() {
    return tid < 2;
}

static bool keep_lock_local() {
    return atomic_load_explicit(&cna_threshold_reached, memory_order_relaxed);
}

cna_lock_t lock;
cna_node_t node[NTHREADS];
int shared = 0;

void *run(void *arg)
{
    tid = ((intptr_t) arg);
    cna_lock(&lock, &node[tid]);
    shared++;
    cna_unlock(&lock, &node[tid]);
    return NULL;
}

int main()
{
    pthread_t t[NTHREADS];

    for (intptr_t i = 0; i < NTHREADS; i++)
        pthread_create(&t[i], NULL, run, (void *) i);

    /* non-deterministically decide when threshold is reached */
    atomic_store_explicit(&cna_threshold_reached, true, memory_order_relaxed);

    for (intptr_t i = 0; i < NTHREADS; i++)
        pthread_join(t[i], 0);

    assert (shared == NTHREADS);

    return 0;
}
