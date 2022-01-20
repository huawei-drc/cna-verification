#ifndef ATOMIC_H
#define ATOMIC_H

#ifdef MOCK_LKMM
  #include "lkmm-mock.h"
  #define smp_acquire__after_ctrl_dep() __atomic_thread_fence(__ATOMIC_ACQUIRE)
#else
  #include <genmc/lkmm.h>
  #define smp_acquire__after_ctrl_dep() smp_rmb()
#endif
#define atomic_try_cmpxchg_acquire(x, o, n) ((int) *o == cmpxchg_acquire(&(x)->counter, (int) *o, n))
#define atomic_try_cmpxchg_relaxed(x, o, n) ((int) *o == cmpxchg_relaxed(&(x)->counter, (int) *o, n))
#define atomic_try_cmpxchg_release(x, o, n) ((int) *o == cmpxchg_release(&(x)->counter, (int) *o, n))
#define atomic_try_cmpxchg(x, o, n)         ((int) *o == cmpxchg(&(x)->counter, (int) *o, n))

#define atomic_fetch_or_acquire(i, v) __atomic_fetch_or(&(v)->counter, i, __ATOMIC_ACQUIRE)

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
      await_do {                                              \
              VAL = READ_ONCE(*__PTR); 	                      \
	         } while_await (!cond_expr);                        \
      (typeof(*ptr))VAL;                                      \
})


#define smp_cond_load_acquire(ptr, cond_expr) ({                \
        __unqual_scalar_typeof(*ptr) _val;                      \
        _val = smp_cond_load_relaxed(ptr, cond_expr);           \
        smp_acquire__after_ctrl_dep();                          \
        (typeof(*ptr))_val;                                     \
})

#define atomic_cond_read_relaxed(ptr, cond_expr) smp_cond_load_relaxed(&(ptr)->counter, cond_expr)
#define atomic_cond_read_acquire(ptr, cond_expr) smp_cond_load_acquire(&(ptr)->counter, cond_expr)

#endif /* ATOMIC_H */