# Copyright (c) 2021 Diogo Behrens, Antonio Paolillo
# SPDX-License-Identifier: MIT

all: prepared

default: prepared

help:
	@echo "Goals:"
	@echo " docker_build    build dartagnan and genmc docker images"
	@echo " linux_files     download Linux qspinlock (Linux 5.14)"
	@echo " cna_patch       apply CNA patch"
	@echo " verif_patch     apply verification patch"
	@echo " empty_headers   create supporting empty headers"
	@echo " prepared        apply all patches and be ready for verification"

###############################################################################
# Step 0: build docker images
###############################################################################
.PHONY: docker_build
docker_build:
	scripts/build.sh -f dockerfiles/dartagnan.dockerfile -t cna-dartagnan .
	scripts/build.sh -f dockerfiles/genmc.dockerfile -t cna-genmc .


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
# Step 4: apply lkmm fixes patch
###############################################################################
FIXES_PATCH = lkmm-fixes.patch
FIXES_FILE  = .fixes.applied

$(FIXES_FILE): $(FIXES_PATCH) $(VERIF_FILE)
	patch -p1 < $(FIXES_PATCH)
	@touch $@

.PHONY: fixes_patch
fixes_patch: $(FIXES_FILE)

###############################################################################
# Step 5: create a bunch of empty header files to make qspinlock happy
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

.PHONY: prepared
prepared: $(FIXES_FILE) $(EMPTY_HEADERS)


###############################################################################
# Patch creation targets
#
# Workflow
# 1- start with clean repository from master
# 2- run: make patch_prepare
# 3- do the changes to the qspinlock and CNA files
# 4- run: make patch_create
# 5- review new patch file; if not ready, goto 3
# 6- run: make patch_update
# 7- commit modified verification patch to master
###############################################################################
PATCH_PREP_FILE = .patch.prepared
NEW_VERIF_PATCH = $(VERIF_PATCH).new
PATCH_BASE ?= HEAD

$(PATCH_PREP_FILE):
	git checkout -b patch-branch
	make linux_files cna_patch empty_headers
	git add include kernel
	git commit -m"applied cna patch"
	touch $@
patch_prepare: $(PATCH_PREP_FILE)

patch_update: $(PATCH_PREP_FILE)
	git diff $(PATH_BASE) > $(NEW_VERIF_PATCH)

patch_abort: clean
	git reset --hard
	git checkout master
	git branch -D patch-branch

.PHONY: patch_prepare patch_update patch_abort
###############################################################################
# Other goals
###############################################################################
.PHONY: clean
clean:
	rm -rf $(EMPTY_HEADERS) $(LINUX_FILES) $(CNA_FILE) $(VERIF_FILE) $(FIXES_FILE) \
		$(CNA_PATCH_DIR) $(PATCH_PREP_FILE) $(NEW_VERIF_PATCH) \
		*.ok *.log
	find . -empty -type d -delete
