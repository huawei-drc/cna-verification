// Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
// SPDX-License-Identifier: MIT

/* Spinloop annotations to help GenMC.
 *
 * To enable, compile with -DSPIN_ANNOTATION.
 * This should only be used with -disable-spin-assume option in GenMC
 */
#ifndef AWAIT_WHILE_H
#define AWAIT_WHILE_H

#if !defined(SPIN_ANNOTATION)
    #define await_while(cond) while (cond)
    #define await_do          do
    #define while_await(cond) while (cond)
#else
    void __VERIFIER_loop_begin(void);
    void __VERIFIER_spin_start(void);
    void __VERIFIER_spin_end(bool);
    #define await_while(cond)                                                  \
        for (int tmp = (__VERIFIER_loop_begin(), 0); __VERIFIER_spin_start(),  \
                 tmp = cond, __VERIFIER_spin_end(!tmp), tmp;)

    #define await_do                                                           \
        do {                                                                   \
            int __tmp;                                                         \
            __VERIFIER_loop_begin();                                           \
            do {                                                               \
                __VERIFIER_spin_start();

    #define while_await(cond)                                                  \
            } while (__tmp = (cond), __VERIFIER_spin_end(!__tmp), __tmp);      \
        } while (0)
#endif

#endif /* AWAIT_WHILE_H */
