#ifndef ATOMIC_H
#define ATOMIC_H

#ifdef MOCK_LKMM
  /* to debug issues with LKMM mapping of genmc while using IMM */
  #include "lkmm-mock.h"
  #define atomic_or(i, v)      ((void)__atomic_fetch_or(&(v)->counter, i, __ATOMIC_RELAXED))
  #define atomic_andnot(i, v)  ((void)__atomic_fetch_and(&(v)->counter, ~(i), __ATOMIC_RELAXED))

#elif !defined(GENMC_DEV)
  /* fixes necessary for GenMC 0.7 */
  #include <lkmm.h>
  //#define smp_acquire__after_ctrl_dep() smp_rmb()  
  #define smp_acquire__after_ctrl_dep() smp_mb()  
  #undef atomic_cmpxchg_relaxed
  #define atomic_cmpxchg_relaxed(x, o, n) cmpxchg_relaxed(&(x)->counter, (int) o, n) 
  #define atomic_fetch_or_acquire(i, v)  __atomic_fetch_or(&(v)->counter, i, memory_order_acquire)
 
  #undef atomic_add
  #define atomic_add(i, v) ((int32_t)(i) >= 0 ? \
	  (__atomic_add( (i), v, memory_order_relaxed)): \
	  (__atomic_sub(-(i), v, memory_order_relaxed)))

  #define atomic_or(i, v)           ((void)__atomic_fetch_or(&(v)->counter, i, memory_order_relaxed))
  #define atomic_andnot(i, v)       ((void)__atomic_fetch_and(&(v)->counter, ~(i), memory_order_relaxed))

#else
  /* fixes necessary for GenMC 0.7.* (dev) */
  #include <genmc_internal.h>
  #include <lkmm.h>
  
  #define smp_acquire__after_ctrl_dep() smp_rmb()

  #undef atomic_cmpxchg_relaxed
  #define atomic_cmpxchg_relaxed(x, o, n) cmpxchg_relaxed(&(x)->counter, (int) o, n) 

  #undef atomic_add
  #define atomic_add(i, v) do { \
            __VERIFIER_atomicrmw_noret();           \
            ((int32_t)(i) >= 0 ? \
	             (atomic_fetch_add_explicit(&(v)->counter, (i), memory_order_relaxed), 0) : \
	              (atomic_fetch_sub_explicit(&(v)->counter, -(i), memory_order_relaxed), 0)); \
  } while (0)
 
  #define atomic_fetch_or_acquire(i, v)  __atomic_fetch_or(&(v)->counter, i, memory_order_acquire)
 
  #define atomic_or(i, v)  do { \
      (void) /*__VERIFIER_atomicrmw_noret();   */        \
      atomic_fetch_or_explicit(&(v)->counter, i, memory_order_relaxed); \
  } while(0)
  #define atomic_andnot(i, v) do { \
    (void ) /*__VERIFIER_atomicrmw_noret();*/           \
    atomic_fetch_and_explicit(&(v)->counter, ~(i), memory_order_relaxed); \
  } while(0)
#endif


#define __atomic_try_cmpxchg(x, o, n, mo) ({         \
        typeof(*o) r;                                \
        r = cmpxchg##mo(&(x)->counter, (int) *o, n); \
        (r == *o) ? 1 : (*o = r, 0);                 \
})
#define atomic_try_cmpxchg_acquire(x, o, n) __atomic_try_cmpxchg(x, o, n, _acquire)
#define atomic_try_cmpxchg_relaxed(x, o, n) __atomic_try_cmpxchg(x, o, n, _relaxed)
#define atomic_try_cmpxchg_release(x, o, n) __atomic_try_cmpxchg(x, o, n, _release)
#define atomic_try_cmpxchg(x, o, n)         __atomic_try_cmpxchg(x, o, n,)
 
#define __scalar_type_to_expr_cases(type)                               \
                unsigned type:  (unsigned type)0,                       \
                signed type:    (signed type)0

#define __unqual_scalar_typeof(x) typeof(                               \
                _Generic((x),                                           \
                         char:  (char)0,                                \
                         __scalar_type_to_expr_cases(char),             \
                         __scalar_type_to_expr_cases(short),            \
                         __scalar_type_to_expr_cases(int),              \
                         __scalar_type_to_expr_cases(long),             \
                         __scalar_type_to_expr_cases(long long),        \
                         default: (x)))

#define smp_cond_load_relaxed(ptr, cond_expr) ({              \
      typeof(ptr) __PTR = (ptr);                              \
      __unqual_scalar_typeof(*ptr) VAL;                       \
      await_while((VAL = READ_ONCE(*__PTR), !(cond_expr)));   \
      (typeof(*ptr))VAL;                                      \
})

#define smp_cond_load_acquirex(ptr, cond_expr) ({              \
        __unqual_scalar_typeof(*ptr) _val;                    \
        _val = smp_cond_load_relaxed(ptr, cond_expr);         \
        smp_acquire__after_ctrl_dep();                         \
        (typeof(*ptr))_val;                                   \
})

/* this is almost equivalent to the above macro and works better with GenMC */
#define smp_cond_load_acquire(ptr, cond_expr) ({              \
      typeof(ptr) __PTR = (ptr);                              \
      __unqual_scalar_typeof(*ptr) VAL;                       \
      await_while((VAL = smp_load_acquire(__PTR), !(cond_expr)));   \
      (typeof(*ptr))VAL;                                      \
})

#define atomic_cond_read_relaxed(ptr, cond_expr) smp_cond_load_relaxed(&(ptr)->counter, cond_expr)
#define atomic_cond_read_acquire(ptr, cond_expr) smp_cond_load_acquire(&(ptr)->counter, cond_expr)

#endif /* ATOMIC_H */