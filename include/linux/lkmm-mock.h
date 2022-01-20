#ifndef LKMM_MOCK
#define LKMM_MOCK
/* This file mocks the interface of LKMM using builtins and
 * strong fences/barriers. It does not implement equivalent
 * fences/barriers as LKMM and should only be used only for
 * debugging purposes. 
 * 
 * The file is based on genmc/lkmm.h
 */
#include <stdint.h>

#define barrier() __asm__ __volatile__ ("":::"memory")

#define __LKMM_FENCE(type)          __atomic_thread_fence(__ATOMIC_SEQ_CST)
#define smp_mb()                    __LKMM_FENCE(mb)
#define smp_rmb()                   __LKMM_FENCE(rmb)
#define smp_wmb()                   __LKMM_FENCE(wmb)
#define smp_mb__before_atomic()     __LKMM_FENCE(ba)
#define smp_mb__after_atomic()      __LKMM_FENCE(aa)
#define smp_mb__after_spinlock()    __LKMM_FENCE(as)
#define smp_mb__after_unlock_lock() __LKMM_FENCE(aul)

#define READ_ONCE(x)             __atomic_load_n(&x, __ATOMIC_RELAXED)
#define WRITE_ONCE(x, v)         __atomic_store_n(&x, v, __ATOMIC_RELAXED)
#define smp_load_acquire(p)      __atomic_load_n(p, __ATOMIC_ACQUIRE)
#define smp_store_release(p, v)  __atomic_store_n(p, v, __ATOMIC_RELEASE)

#define __xchg(p, v, m)	__atomic_exchange_n(p, v, m)
#define xchg(p, v)							\
({									\
	__typeof__((v)) _v_ = (v);					\
	smp_mb__before_atomic();					\
	_v_ = __xchg(p, v, __ATOMIC_RELAXED);				\
	smp_mb__after_atomic();						\
	_v_;								\
})
#define xchg_relaxed(p, v) __xchg(p, v, __ATOMIC_RELAXED)
#define xchg_release(p, v) __xchg(p, v, __ATOMIC_RELEASE)
#define xchg_acquire(p, v) __xchg(p, v, __ATOMIC_ACQUIRE)

#define __cmpxchg(p, o, n, s, f)					\
({									\
	__typeof__((o)) _o_ = (o);					\
	(__atomic_compare_exchange_n(p, &_o_, n, 0, s, f));		\
	_o_;								\
})
#define cmpxchg(p, o, n)						\
({									\
	__typeof__((o)) _o_ = (o);					\
	smp_mb__before_atomic();					\
	_o_ = __cmpxchg(p, o, n, __ATOMIC_RELAXED, __ATOMIC_RELAXED); 	\
	smp_mb__after_atomic();						\
	_o_;								\
})
#define cmpxchg_relaxed(p, o, n)				\
	__cmpxchg(p, o, n, __ATOMIC_RELAXED, __ATOMIC_RELAXED)
#define cmpxchg_acquire(p, o, n)				\
	__cmpxchg(p, o, n, __ATOMIC_ACQUIRE, __ATOMIC_ACQUIRE)
#define cmpxchg_release(p, o, n)				\
	__cmpxchg(p, o, n, __ATOMIC_RELEASE, __ATOMIC_RELEASE)

typedef struct {
	int counter;
} atomic_t;

typedef struct {
	int64_t counter;
} atomic64_t;
typedef atomic64_t  atomic_long_t;

#define atomic_read(v)            READ_ONCE((v)->counter)
#define atomic_add(i, v)          __atomic_add(i, v, __ATOMIC_RELAXED)
#define atomic_xchg(x, i)         xchg(&(x)->counter, i)
#define atomic_xchg_relaxed(x, i) xchg_relaxed(&(x)->counter, i)
#define atomic_xchg_release(x, i) xchg_release(&(x)->counter, i)
#define atomic_xchg_acquire(x, i) xchg_acquire(&(x)->counter, i)

#endif /* LKMM_MOCK */