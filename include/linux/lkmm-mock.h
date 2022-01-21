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

#define barrier() //__asm__ __volatile__ ("":::"memory")

#define __LKMM_FENCE(type)          __atomic_thread_fence(__ATOMIC_SEQ_CST)
#define smp_mb()                    __LKMM_FENCE(mb)
#define smp_rmb()                   __LKMM_FENCE(rmb)
#define smp_wmb()                   __LKMM_FENCE(wmb)
#define smp_mb__before_atomic()     __LKMM_FENCE(ba)
#define smp_mb__after_atomic()      __LKMM_FENCE(aa)
#define smp_mb__after_spinlock()    __LKMM_FENCE(as)
#define smp_mb__after_unlock_lock() __LKMM_FENCE(aul)
#define smp_acquire__after_ctrl_dep() __LKMM_FENCE(mb)

#define READ_ONCE(x)             __atomic_load_n(&x, __ATOMIC_SEQ_CST)
#define WRITE_ONCE(x, v)         __atomic_store_n(&x, v, __ATOMIC_SEQ_CST)
#define smp_load_acquire(p)      __atomic_load_n(p, __ATOMIC_SEQ_CST)
#define smp_store_release(p, v)  __atomic_store_n(p, v, __ATOMIC_SEQ_CST)

#define __xchg(p, v, m)	__atomic_exchange_n(p, v, m)
#define xchg(p, v)							\
({									\
	__typeof__((v)) _v_ = (v);					\
	_v_ = __xchg(p, v, __ATOMIC_SEQ_CST);				\
	smp_mb__after_atomic();						\
	_v_;								\
})
#define xchg_relaxed(p, v) xchg(p, v)
#define xchg_release(p, v) xchg(p, v)
#define xchg_acquire(p, v) xchg(p, v)

#define __cmpxchg(p, o, n, s, f)					\
({									\
	__typeof__((o)) _o_ = (o);					\
	(__atomic_compare_exchange_n(p, &_o_, n, 0, s, f));		\
	_o_;								\
})
#define cmpxchg(p, o, n)						\
({									\
	__typeof__((o)) _o_ = (o);					\
	_o_ = __cmpxchg(p, o, n, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST); 	\
	smp_mb__after_atomic();						\
	_o_;								\
})
#define cmpxchg_relaxed(p, o, n) cmpxchg(p, o, n)
#define cmpxchg_acquire(p, o, n) cmpxchg(p, o, n)
#define cmpxchg_release(p, o, n) cmpxchg(p, o, n)

typedef struct {
	int counter;
} atomic_t;

#define atomic_read(v)            READ_ONCE((v)->counter)
#define atomic_read_acquire(v)    smp_load_acquire(&(v)->counter)
#define atomic_sub(i, v)          ((void)__atomic_fetch_sub(&(v)->counter, i, __ATOMIC_SEQ_CST))
#define atomic_add(i, v)          ((int32_t)(i) >= 0 ? \
	((void)__atomic_fetch_add(&(v)->counter,  (i), __ATOMIC_SEQ_CST)): \
	((void)__atomic_fetch_sub(&(v)->counter, -(i), __ATOMIC_SEQ_CST)))

#define atomic_xchg(x, i)         xchg(&(x)->counter, i)
#define atomic_xchg_relaxed(x, i) xchg_relaxed(&(x)->counter, i)
#define atomic_xchg_release(x, i) xchg_release(&(x)->counter, i)
#define atomic_xchg_acquire(x, i) xchg_acquire(&(x)->counter, i)
#define atomic_cmpxchg_relaxed(x, e, i) cmpxchg_relaxed(&(x)->counter, (int) e, (int) i)
#define atomic_cmpxchg(x, e, i)   cmpxchg(&(x)->counter, (int) e, (int) i)

#define lkmm_atomic_fetch_sub(i, v, m) __atomic_fetch_sub(&(v)->counter, i, m)
#define atomic_fetch_sub_release(i, v) lkmm_atomic_fetch_sub(i, v, __ATOMIC_SEQ_CST)
#define atomic_fetch_sub(i, v)						\
({									\
	__typeof__((i)) _i_ = (i);					\
	_i_ = lkmm__atomic_fetch_sub(i, v, __ATOMIC_SEQ_CST);		\
	smp_mb__after_atomic();						\
	_i_;								\
})

#define lkmm_atomic_fetch_and(i, v, m) __atomic_fetch_and(&(v)->counter, i, m)
#define lkmm_atomic_and_noret(i, v, m) ((void)__atomic_fetch_and(&(v)->counter, i, m))
#define lkmm_atomic_fetch_or(i, v, m) __atomic_fetch_or(&(v)->counter, i, m)
#define atomic_fetch_or_relaxed(i, v) lkmm_atomic_fetch_or(i, v, __ATOMIC_SEQ_CST)

#define atomic_fetch_or_acquire(i, v)  lkmm_atomic_fetch_or(i, v, __ATOMIC_SEQ_CST)
#define atomic_fetch_and_release(i, v) lkmm_atomic_fetch_and(&(v)->counter, i, __ATOMIC_SEQ_CST)

#endif /* LKMM_MOCK */