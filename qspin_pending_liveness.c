
#define SPIN_ANNOTATION
#define VERIFICATION

#include <assert.h>
#include <pthread.h>
#include <stddef.h>
#include <stdbool.h>
#include <genmc.h>

/* await_while annotation */
#ifdef SPIN_ANNOTATION
  #define await_while(cond) for (__VERIFIER_loop_begin();			\
	__VERIFIER_spin_start(), (cond) ? 1 : (__VERIFIER_spin_end(1), 0);	\
	__VERIFIER_spin_end(0))
#else
  #define await_while(cond) while(cond)
#endif

/* includes distributed in this repository */
#include <linux/atomic.h> /* a mapping of linux atomic to GenMC functions */
#include <defs.h>         /* replacement of several Linux macros */

__thread int tid;
#define smp_processor_id() tid
static void *get_node(int cpu);
#define per_cpu_ptr(p, cpu) get_node(cpu)
#define this_cpu_ptr(p) get_node(tid)
#define __this_cpu_dec(x) ((struct mcs_spinlock*) this_cpu_ptr(x))->count--;

#define CONFIG_NR_CPUS NTHREADS
#define nodes (*qnodes)


// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Queued spinlock
 *
 * (C) Copyright 2013-2015 Hewlett-Packard Development Company, L.P.
 * (C) Copyright 2013-2014,2018 Red Hat, Inc.
 * (C) Copyright 2015 Intel Corp.
 * (C) Copyright 2015 Hewlett-Packard Enterprise Development LP
 *
 * Authors: Waiman Long <longman@redhat.com>
 *          Peter Zijlstra <peterz@infradead.org>
 */

typedef struct qspinlock {
	union {
		atomic_t val;

		/*
		 * By using the whole 2nd least significant byte for the
		 * pending bit, we can allow better optimization of the lock
		 * acquisition for the pending bit holder.
		 */
		struct {
			u16	tail;
			u16	locked_pending;
		};
		struct {
			u8	reserved[2];
			u8	pending;
			u8	locked;
		};
	};
} arch_spinlock_t;

/*
 * Bitfields in the atomic value:
 *
 * When NR_CPUS < 16K
 *  0- 7: locked byte
 *     8: pending
 *  9-15: not used
 * 16-17: tail index
 * 18-31: tail cpu (+1)
 *
 * When NR_CPUS >= 16K
 *  0- 7: locked byte
 *     8: pending
 *  9-10: tail index
 * 11-31: tail cpu (+1)
 */
#define	_Q_SET_MASK(type)	(((1U << _Q_ ## type ## _BITS) - 1)\
				      << _Q_ ## type ## _OFFSET)
#define _Q_LOCKED_OFFSET	0
#define _Q_LOCKED_BITS		8
#define _Q_LOCKED_MASK		_Q_SET_MASK(LOCKED)

#define _Q_PENDING_OFFSET	(_Q_LOCKED_OFFSET + _Q_LOCKED_BITS)
#if CONFIG_NR_CPUS < (1U << 14)
#define _Q_PENDING_BITS		8
#else
#define _Q_PENDING_BITS		1
#endif
#define _Q_PENDING_MASK		_Q_SET_MASK(PENDING)

#define _Q_TAIL_IDX_OFFSET	(_Q_PENDING_OFFSET + _Q_PENDING_BITS)
#define _Q_TAIL_IDX_BITS	2
#define _Q_TAIL_IDX_MASK	_Q_SET_MASK(TAIL_IDX)

#define _Q_TAIL_CPU_OFFSET	(_Q_TAIL_IDX_OFFSET + _Q_TAIL_IDX_BITS)
#define _Q_TAIL_CPU_BITS	(32 - _Q_TAIL_CPU_OFFSET)
#define _Q_TAIL_CPU_MASK	_Q_SET_MASK(TAIL_CPU)

#define _Q_TAIL_OFFSET		_Q_TAIL_IDX_OFFSET
#define _Q_TAIL_MASK		(_Q_TAIL_IDX_MASK | _Q_TAIL_CPU_MASK)

#define _Q_LOCKED_VAL		(1U << _Q_LOCKED_OFFSET)
#define _Q_PENDING_VAL		(1U << _Q_PENDING_OFFSET)


struct mcs_spinlock {
	struct mcs_spinlock *next;
	unsigned int locked; /* 1 if lock acquired */
	int count;  /* nesting count, see qspinlock.c */
};

struct qnode {
	struct mcs_spinlock mcs;
#if defined(CONFIG_PARAVIRT_SPINLOCKS) || defined(CONFIG_NUMA_AWARE_SPINLOCKS)
	long reserved[2];
#endif
};

#define MAX_NODES	1
static DEFINE_PER_CPU_ALIGNED(struct qnode, qnodes[MAX_NODES]);
static void *get_node(int cpu) { return &qnodes[cpu]; }
#define _Q_PENDING_LOOPS	1

void queued_spin_lock(struct qspinlock *lock)
{
	struct mcs_spinlock *prev, *next, *node;
	u32 old, tail;
	int idx;
	u32 val = 0;

	if (likely(atomic_try_cmpxchg_acquire(&lock->val, &val, _Q_LOCKED_VAL)))
		return;

	if (val == _Q_PENDING_VAL) {
		int cnt = _Q_PENDING_LOOPS;
		val = atomic_cond_read_relaxed(&lock->val,
					       (VAL != _Q_PENDING_VAL) || !cnt--);
	}

	if (val & ~_Q_LOCKED_MASK)
		__VERIFIER_assume(0);

	val = atomic_fetch_or_acquire(_Q_PENDING_VAL, &lock->val);

	if (unlikely(val & ~_Q_LOCKED_MASK))
		__VERIFIER_assume(0);

	if (val & _Q_LOCKED_MASK)
		atomic_cond_read_acquire(&lock->val, !(VAL & _Q_LOCKED_MASK));

	atomic_add(-_Q_PENDING_VAL + _Q_LOCKED_VAL, &lock->val);
	return;
}

void queued_spin_unlock(struct qspinlock *lock)
{
	atomic_fetch_sub_release(_Q_LOCKED_VAL, &lock->val);
}

/*******************************************************************************
 * Client code
 ******************************************************************************/
struct qspinlock lock;
static int x = 0, y = 0;
static void* run(void *arg)
{
	tid = (intptr_t)arg;

	queued_spin_lock(&lock);
	WRITE_ONCE(x, READ_ONCE(x)+1); /* GenMC has issues here */
	WRITE_ONCE(y, READ_ONCE(y)+1); /* if these are plain accesses. */
	queued_spin_unlock(&lock);

	return NULL;
}

int main()
{
	pthread_t t[NTHREADS];
	for (intptr_t i = 0; i < NTHREADS; i++)
		pthread_create(t+i, 0, run, (void*)i);
	for (intptr_t i = 0; i < NTHREADS; i++)
		pthread_join(t[i], NULL);
	assert (x == y && x == NTHREADS);
	return 0;
}
