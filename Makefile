# Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
# SPDX-License-Identifier: MIT

all: verification

default: verification

help:
	@echo "Goals:"
	@echo "	linux_files     download Linux qspinlock (Linux 5.14)"
	@echo "	cna_patch       apply CNA patch"
	@echo "	verif_patch     apply verification patch"
	@echo "	empty_headers   create supporting empty headers"
	@echo "	verification    verify qspinlock_cna with GenMC"

###############################################################################
# Step 1: get qspinlock files from kernel
###############################################################################
LINUX_URL     = https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/
LINUX_VERSION = v5.14
LINUX_FILES = \
	kernel/locking/lock_events_list.h \
	kernel/locking/lock_events.h \
	kernel/locking/qspinlock_stat.h \
	kernel/locking/qspinlock.c \
	kernel/locking/mcs_spinlock.h \
	include/asm-generic/qspinlock.h \
	include/asm-generic/qspinlock_types.h

$(LINUX_FILES): %:
	curl --create-dirs -o $* $(LINUX_URL)/$*?h=$(LINUX_VERSION) > /dev/null

.PHONY: linux_files
linux_files: $(LINUX_FILES)

###############################################################################
# Step 2: apply CNA patch
###############################################################################
CNA_PATCH_DIR = cna-v15
CNA_PATCH_URL = https://lkml.org/lkml/diff/2021/5/14
CNA_FILE  = kernel/locking/qspinlock_cna.h

$(CNA_FILE): $(LINUX_FILES)
	for patch_id in 820 818 822 823 817 819; do \
		curl --create-dirs -o $(CNA_PATCH_DIR)/$$patch_id.diff $(CNA_PATCH_URL)/$$patch_id/1 ; \
		patch -p1 --force < $(CNA_PATCH_DIR)/$$patch_id.diff ; \
	done

.PHONY: cna_patch
cna_patch: $(CNA_FILE)

###############################################################################
# Step 3: apply verification patch
###############################################################################
VERIF_PATCH = verification.patch
VERIF_FILE  = .patch.applied

$(VERIF_FILE): $(VERIF_PATCH) $(CNA_FILE)
	patch -p1 < $(VERIF_PATCH)
	@touch $@

.PHONY: verif_patch
verif_patch: $(VERIF_FILE)

###############################################################################
# Step 4: create a bunch of empty header files to make qspinlock happy
###############################################################################
EMPTY_HEADERS = \
	include/linux/hardirq.h \
	include/linux/bug.h \
	include/linux/percpu.h \
	include/linux/sched/clock.h \
	include/linux/sched/rt.h \
	include/linux/prefetch.h \
	include/linux/moduleparam.h \
	include/linux/smp.h \
	include/linux/random.h \
	include/linux/mutex.h \
	include/linux/topology.h \
	include/linux/cpumask.h \
	include/asm/byteorder.h \
	include/asm/qspinlock.h \
	include/asm/mcs_spinlock.h

$(EMPTY_HEADERS): %:
	@mkdir -p $(@D) 2> /dev/null
	touch $@

.PHONY: empty_headers
empty_headers: $(EMPTY_HEADERS)

###############################################################################
# Step 5: GenMC verification
###############################################################################
GENMC_OPTS = -mo -lkmm -check-liveness \
	-disable-race-detection \
	-disable-load-annotation \
	-disable-cast-elimination \
	-disable-code-condenser \
	-disable-spin-assume
INCLUDES = -I/usr/share/genmc/include -Iinclude
CLIENT   = client-code.c

qspinlock_cna.ok: $(VERIF_FILE) $(EMPTY_HEADERS)
	genmc $(GENMC_OPTS) -- $(INCLUDES) $(CLIENT) \
		-DNTHREADS=4 -DALGORITHM=1 > $(@:.ok=.log) 2>&1 && touch $@

qspinlock_mcs.ok: $(VERIF_FILE) $(EMPTY_HEADERS)
	genmc $(GENMC_OPTS) -- $(INCLUDES) $(CLIENT) \
		-DNTHREADS=3 -DALGORITHM=2 > $(@:.ok=.log) 2>&1 && touch $@

mcs_spinlock.ok: $(VERIF_FILE) $(EMPTY_HEADERS)
	genmc $(GENMC_OPTS) -- $(INCLUDES) $(CLIENT) \
		-DNTHREADS=3 -DALGORITHM=3 > $(@:.ok=.log) 2>&1 && touch $@

.PHONY: verification
verification: mcs_spinlock.ok qspinlock_mcs.ok qspinlock_cna.ok

###############################################################################
# Other goals
###############################################################################
.PHONY: clean
clean:
	rm -rf $(EMPTY_HEADERS) $(LINUX_FILES) $(CNA_FILE) $(VERIF_FILE) \
		*.ok *.log
