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

#ifdef SC_MOCK
typedef enum memory_order {
	mo_rlx = __ATOMIC_SEQ_CST,
	mo_acq = __ATOMIC_SEQ_CST,
	mo_rel = __ATOMIC_SEQ_CST,
	mo_seq = __ATOMIC_SEQ_CST,
} memory_order;
#else
typedef enum memory_order {
	mo_rlx = __ATOMIC_RELAXED,
	mo_acq = __ATOMIC_ACQUIRE,
	mo_rel = __ATOMIC_RELEASE,
	mo_seq = __ATOMIC_SEQ_CST,
} memory_order;
#endif

#define barrier() __asm__ __volatile__ ("":::"memory")

#define smp_mb()                      __atomic_thread_fence(mo_seq)
#define smp_mb__after_atomic()        __atomic_thread_fence(mo_seq)
#define smp_rmb()                     assert (0 && "not implemented")
#define smp_wmb()                     assert (0 && "not implemented")
#define smp_acquire__after_ctrl_dep() assert (0 && "not implemented")

#define READ_ONCE(x)             __atomic_load_n(&x, mo_rlx)
#define WRITE_ONCE(x, v)         __atomic_store_n(&x, v, mo_rlx)
#define smp_load_acquire(p)      __atomic_load_n(p, mo_acq)
#define smp_store_release(p, v)  __atomic_store_n(p, v, mo_rel)

#define __xchg(p, v, m)	__atomic_exchange_n(p, v, m)
#define _xchg(p, v, m)							\
({									\
	__typeof__((v)) _v_ = (v);					\
	_v_ = __xchg(p, v, m);						\
	if (m == mo_seq) smp_mb__after_atomic();			\
	_v_;								\
})
#define xchg_relaxed(p, v) _xchg(p, v, mo_rlx)
#define xchg_release(p, v) _xchg(p, v, mo_rel)
#define xchg_acquire(p, v) _xchg(p, v, mo_acq)
#define xchg(p, v)         _xchg(p, v, mo_seq)

#define __cmpxchg(p, o, n, s, f)					\
({									\
	__typeof__((o)) _o_ = (o);					\
	(__atomic_compare_exchange_n(p, &_o_, n, 0, s, f));		\
	_o_;								\
})
#define _cmpxchg(p, o, n, m)						\
({									\
	__typeof__((o)) _o_ = (o);					\
	_o_ = __cmpxchg(p, o, n, m, m); 				\
	if (m == mo_seq) smp_mb__after_atomic();			\
	_o_;								\
})
#define cmpxchg_relaxed(p, o, n) _cmpxchg(p, o, n, mo_rlx)
#define cmpxchg_acquire(p, o, n) _cmpxchg(p, o, n, mo_acq)
#define cmpxchg_release(p, o, n) _cmpxchg(p, o, n, mo_rel)
#define cmpxchg(p, o, n)         _cmpxchg(p, o, n, mo_seq)

typedef struct {
	int counter;
} atomic_t;

#define atomic_read(v)            READ_ONCE((v)->counter)
#define atomic_read_acquire(v)    smp_load_acquire(&(v)->counter)
#define atomic_sub(i, v)          ((void)__atomic_fetch_sub(&(v)->counter, i, mo_rlx))
#define atomic_add(i, v)          ((int32_t)(i) >= 0 ? \
	((void)__atomic_fetch_add(&(v)->counter,  (i), mo_rlx)): \
	((void)__atomic_fetch_sub(&(v)->counter, -(i), mo_rlx)))

#define atomic_xchg(x, i)         xchg(&(x)->counter, i)
#define atomic_xchg_relaxed(x, i) xchg_relaxed(&(x)->counter, i)
#define atomic_xchg_release(x, i) xchg_release(&(x)->counter, i)
#define atomic_xchg_acquire(x, i) xchg_acquire(&(x)->counter, i)
#define atomic_cmpxchg_relaxed(x, e, i) cmpxchg_relaxed(&(x)->counter, (int) e, (int) i)
#define atomic_cmpxchg(x, e, i)   cmpxchg(&(x)->counter, (int) e, (int) i)

#define lkmm_atomic_fetch_sub(i, v, m) __atomic_fetch_sub(&(v)->counter, i, m)
#define atomic_fetch_sub_release(i, v) lkmm_atomic_fetch_sub(i, v, mo_rel)

#define lkmm_atomic_fetch_and(i, v, m) __atomic_fetch_and(&(v)->counter, i, m)
#define lkmm_atomic_and_noret(i, v, m) ((void)__atomic_fetch_and(&(v)->counter, i, m))
#define lkmm_atomic_fetch_or(i, v, m) __atomic_fetch_or(&(v)->counter, i, m)

#define atomic_fetch_or_relaxed(i, v) lkmm_atomic_fetch_or(i, v, mo_rlx)
#define atomic_fetch_or_acquire(i, v)  lkmm_atomic_fetch_or(i, v, mo_acq)
#define atomic_fetch_and_release(i, v) lkmm_atomic_fetch_and(&(v)->counter, i, mo_rel)

#endif /* LKMM_MOCK */