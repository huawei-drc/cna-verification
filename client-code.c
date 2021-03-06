// Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
// SPDX-License-Identifier: MIT

/*******************************************************************************
 * Run this client code with GenMC 0.7 to verify the correctness of the
 * CNA slowpath of qspinlock (qspinlock_cna.h) from Linux 5.14.
 * The client code can be alternatively configured to use the MCS slowpath or
 * just the plain MCS lock (mcs_spinlock.h).
 ******************************************************************************/

/* Number of threads */
#ifndef NTHREADS
#define NTHREADS 4
#endif

/* Number of threads that reacquire the lock (once) */
#ifndef REACQUIRE
#define REACQUIRE 0
#endif

/* Number of reacquires for each thread that does reacquires */ 
#ifndef REPEAT
#define REPEAT 1
#endif

/* Supported algorithms */
#define QSPINLOCK_CNA 1
#define QSPINLOCK_MCS 2
#ifndef ALGORITHM
#define ALGORITHM     QSPINLOCK_CNA
#endif

/* skip fast path and pending logic, jump directly to queue */
//#define SKIP_PENDING

/* GenMC can check liveness only if it knows the loops that depend on updates
 * from other threads (spinloops). Its automated spinloop detection does not
 * always work, in particular with these files. So we manually annotate the
 * spinloops. The annotation can be disabled by commenting the next line.
 * If SPIN_ANNOTATION is defined, please pass -disable-spin-assume to GenMC.
 */ 
#define SPIN_ANNOTATION

/*******************************************************************************
 * Includes, context, lock selection -- NO USER OPTIONS FROM HERE ON.
 ******************************************************************************/
#define VERIFICATION

#include <assert.h>
#include <pthread.h>
#include <stddef.h>
#include <stdbool.h>

/* await_while annotation */
#ifdef SPIN_ANNOTATION
  void __VERIFIER_loop_begin(void);
  void __VERIFIER_spin_start(void);
  void __VERIFIER_spin_end(bool);
  void __VERIFIER_loop_bound(int);
  #define await_while(cond) for (__VERIFIER_loop_begin();			\
	__VERIFIER_spin_start(), (cond) ? 1 : (__VERIFIER_spin_end(1), 0);	\
	__VERIFIER_spin_end(0))
#else
  #define await_while(cond) while(cond)
#endif

/* includes distributed in this repository */
#include <linux/atomic.h> /* a mapping of linux atomic to GenMC functions */
#include <defs.h>         /* replacement of several Linux macros */

/* smp_processor_id */
__thread int tid;
#define smp_processor_id() tid

/* functions and macros to retrieve mcs/cna node (context) */
static void *get_node(int cpu);
#define per_cpu_ptr(p, cpu) get_node(cpu)
#define this_cpu_ptr(p) get_node(tid)
#define __this_cpu_dec(x) ((struct mcs_spinlock*) this_cpu_ptr(x))->count--;

/* NUMA node mapping and intra-node threshold for CNA */
#if ALGORITHM == QSPINLOCK_CNA
#define CONFIG_NUMA_AWARE_SPINLOCKS
#define cpu_to_node(x) ((x < NTHREADS/2) ? 1 : 2)
static bool cna_threshold_reached = false;
#endif

/* include qspinlock / CNA code */
#define CONFIG_NR_CPUS NTHREADS
#include <asm-generic/qspinlock.h>
#include "kernel/locking/qspinlock.c"

/* select lock and context */
#if ALGORITHM == QSPINLOCK_CNA
	struct qspinlock lock;
	/* use this instead of qnodes to make type clear in debugging */
	struct cna_node nodes[NTHREADS];
	#define init()    cna_init_nodes();
	#define nondet()  WRITE_ONCE(cna_threshold_reached, true);
#ifdef SKIP_PENDING
	#define acquire() queued_spin_lock_slowpath(&lock, 0)
#else
	#define acquire() queued_spin_lock(&lock)
#endif /* SKIP_PENDING */
	#define release() queued_spin_unlock(&lock)
#elif ALGORITHM == QSPINLOCK_MCS
	struct qspinlock lock;
	#define nodes (*qnodes)
	#define init()
	#define nondet()
#ifdef SKIP_PENDING
	#define acquire() queued_spin_lock_slowpath(&lock, 0)
#else
	#define acquire() queued_spin_lock(&lock)
#endif /* SKIP_PENDING */
	#define release() queued_spin_unlock(&lock)
#else
	#error "Invalid algorithm"
#endif
static void *get_node(int cpu) { return &nodes[cpu]; }

/*******************************************************************************
 * Client code
 ******************************************************************************/
static int x = 0, y = 0;
static void* run(void *arg)
{
	tid = (intptr_t)arg;

	acquire();
	x = x + 1;
	y = y + 1;
	release();

	return NULL;
}

int main()
{
	pthread_t t0, t1, t2, t3;

	init();

    	pthread_create(&t0, 0, run, (void*)0);
    	pthread_create(&t1, 0, run, (void*)1);
    	pthread_create(&t2, 0, run, (void*)2);
    	pthread_create(&t3, 0, run, (void*)3);

    	nondet();

    	pthread_join(t0, NULL);
    	pthread_join(t1, NULL);
    	pthread_join(t2, NULL);
    	pthread_join(t3, NULL);

    	assert (READ_ONCE(x) == READ_ONCE(y));
	return 0;
}
