# Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
# Copyright (c) 2025 Hernan Ponce de Leon
# SPDX-License-Identifier: MIT

all: prepared

default: prepared

help:
	@echo "Goals:"
	@echo " docker_build    build dartagnan and genmc docker images"
	@echo " linux_files     download Linux qspinlock"
	@echo " empty_headers   create supporting empty headers"
	@echo " prepared        ready for verification"

###############################################################################
# Step 0: build docker images
###############################################################################
.PHONY: docker_build
docker_build:
	mkdir -p certificates
	scripts/build.sh -f dockerfiles/dartagnan.dockerfile -t cna-dartagnan .
	scripts/build.sh -f dockerfiles/genmc.dockerfile -t cna-genmc .


###############################################################################
# Step 1: get qspinlock files from kernel
###############################################################################
LINUX_URL     = https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/
LINUX_VERSION = 7586ac7c340c3672f116052c1d150f134810965b
LINUX_FILES = \
	kernel/locking/lock_events_list.h \
	kernel/locking/lock_events.h \
	kernel/locking/qspinlock_stat.h \
	kernel/locking/qspinlock.c \
	kernel/locking/qspinlock.h \
	kernel/locking/mcs_spinlock.h \
	include/asm-generic/mcs_spinlock.h \
	include/asm-generic/qspinlock.h \
	include/asm-generic/qspinlock_types.h

$(LINUX_FILES): %:
	curl -L --create-dirs -o $* $(LINUX_URL)/$*?h=$(LINUX_VERSION) > /dev/null

.PHONY: linux_files
linux_files: $(LINUX_FILES)

###############################################################################
# Step 2: create a bunch of empty header files to make qspinlock happy
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
	include/linux/percpu-defs.h \
	include/asm/byteorder.h \
	include/asm/qspinlock.h \
	include/asm/mcs_spinlock.h \
	include/asm-generic/percpu.h \
	include/trace/events/lock.h

$(EMPTY_HEADERS): %:
	@mkdir -p $(@D) 2> /dev/null
	touch $@

.PHONY: empty_headers
empty_headers: $(EMPTY_HEADERS)

.PHONY: prepared
prepared: $(LINUX_FILES) $(EMPTY_HEADERS)

###############################################################################
# Other goals
###############################################################################
.PHONY: clean
clean:
	rm -rf $(EMPTY_HEADERS) $(LINUX_FILES) $(CNA_FILE) $(VERIF_FILE) $(FIXES_FILE) \
		$(CNA_PATCH_DIR) $(PATCH_PREP_FILE) $(NEW_VERIF_PATCH) \
		*.ok *.log
	find . -empty -type d -delete
