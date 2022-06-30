#ifndef ATOMIC_H
#define ATOMIC_H

#include <lkmm.h>
#define smp_acquire__after_ctrl_dep() smp_rmb()

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

/* this is the original macro from the Linux tree */
#define smp_cond_load_relaxed(ptr, cond_expr) ({        \
      typeof(ptr) __PTR = (ptr);                        \
      __unqual_scalar_typeof(*ptr) VAL;                 \
      for (;;) {                                        \
          VAL = READ_ONCE(*__PTR);                      \
          if (cond_expr)                                \
              break;                                    \
          cpu_relax();                                  \
      }                                                 \
      (typeof(*ptr))VAL;                                \
})

/* this is the original macro from the Linux tree */
#define smp_cond_load_acquire(ptr, cond_expr) ({        \
      __unqual_scalar_typeof(*ptr) _val;                \
      _val = smp_cond_load_relaxed(ptr, cond_expr);     \
      smp_acquire__after_ctrl_dep();                    \
      (typeof(*ptr))_val;                               \
})

#define atomic_cond_read_relaxed(ptr, cond_expr) smp_cond_load_relaxed(&(ptr)->counter, cond_expr)
#define atomic_cond_read_acquire(ptr, cond_expr) smp_cond_load_acquire(&(ptr)->counter, cond_expr)

#endif /* ATOMIC_H */
