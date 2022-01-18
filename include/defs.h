// Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
// SPDX-License-Identifier: MIT

#ifndef DEFS_H
#define DEFS_H

/* types */
#define u64 uint64_t
#define u32 uint32_t
#define u16 uint16_t
#define u8 uint8_t
#define ulong u64

/* per cpu data */
#define DEFINE_PER_CPU_ALIGNED(T, V) T __thread V
#define DEFINE_PER_CPU(T, V) DEFINE_PER_CPU_ALIGNED(T, V)
#define this_cpu_read(X) (X)
#define this_cpu_write(X,Y) (X=Y)
#define for_each_possible_cpu(X) for (X=0 ; X < NTHREADS; X++)

/* mock macros */
#define prefetchw(X) do {} while (0)
#define BUILD_BUG_ON(X)
#define EXPORT_SYMBOL(X)
#define WARN_ON(X)
#define unlikely(X) (X)
#define likely(X) (X)
#define __init
#define __pure
#define cpu_relax() do {} while(0)

/* additional macros used in qspinlock_cna.h */
#define module_param(A,B,C)
#define local_clock() (2)
#define next_pseudo_random32(X) (X)
#define irqs_disabled() 0
#define rt_task(X) 0
#define in_task() 1
#define pr_info(X)
#define __setup(A,B)

#endif
