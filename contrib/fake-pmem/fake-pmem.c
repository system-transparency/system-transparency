// SPDX-License-Identifier: GPL-2.0-only
/*
 * drivers/fake-pmem/fake-pmem.c
 *
 * Copyright (C) 2023 Glasklar AB
 * Author: Kai Michaelis <kai.michaelis@immune.gmbh>
 */

#include "linux/kern_levels.h"
#include <linux/version.h>
#include <linux/init.h>
#include <linux/module.h>
#include <asm/io.h>
#include <linux/sysfs.h>
#include <linux/kobject.h>
#include <stddef.h>

#define BLOCK_SIZE 2 * 1024 * 1024

static struct memory_block {
	struct kobject *kobj;
	void *virt;
	phys_addr_t phys;
	size_t size;
} memory_block;

static ssize_t address_show(struct kobject *kobj, struct kobj_attribute *attr,
			    char *buffer)
{
	// never >PAGE_SIZE
	return sprintf(buffer, "%pa\n", &memory_block.phys);
}

static ssize_t contents_show(struct file *file, struct kobject *kobj,
			     struct bin_attribute *attr, char *buffer,
			     loff_t offset, size_t count)
{
	if (offset + count > memory_block.size) {
		count = memory_block.size - offset;
	}
	count = min(count, PAGE_SIZE);
	memcpy(buffer, memory_block.virt + offset, count);
	return count;
}

static ssize_t contents_store(struct file *file, struct kobject *kobj,
			      struct bin_attribute *attr, char *buffer,
			      loff_t offset, size_t count)
{
	if (offset + count > memory_block.size) {
		count = memory_block.size - offset;
	}
	memcpy(memory_block.virt + offset, buffer, count);
	return count;
}

static struct kobj_attribute address_attr = __ATTR_RO(address);
BIN_ATTR(contents, 0644, contents_show, contents_store, BLOCK_SIZE);

static int __init fake_pmem_init(void)
{
	int ret = 0;

	memory_block.size = BLOCK_SIZE;

	/* allocate 2MB of memory */
	memory_block.virt = alloc_pages_exact(memory_block.size, GFP_KERNEL);
	if (!memory_block.virt) {
		pr_err("alloc_pages_exact failed\n");
		goto out;
	}

	/* get physical memory_block */
	memory_block.phys = virt_to_phys(memory_block.virt);

	/* add marker */
	memcpy(memory_block.virt, "fake-pmem", 9);

	/* create sysfs entry under kernel object */
	memory_block.kobj = kobject_create_and_add("fake_pmem", kernel_kobj);
	if (!memory_block.kobj) {
		pr_err("kobject_create_and_add failed\n");
		goto out;
	}

	/* extend with a single binary attribute to read the flash */
	ret = sysfs_create_file(memory_block.kobj, &address_attr.attr);
	if (ret) {
		pr_err("sysfs_create_bin_file failed\n");
		goto error;
	}
	ret = sysfs_create_bin_file(memory_block.kobj, &bin_attr_contents);
	if (ret) {
		pr_err("sysfs_create_bin_file failed\n");
		goto error;
	}

	return ret;

error:
	kobject_put(memory_block.kobj);
out:
	return ret;
}
module_init(fake_pmem_init);

static void __exit fake_pmem_exit(void)
{
	/* we leak memory on purpose */

	if (memory_block.kobj) {
		sysfs_remove_file(kernel_kobj, &address_attr.attr);
		sysfs_remove_file(kernel_kobj, &bin_attr_contents.attr);
		kobject_put(memory_block.kobj);
	}
}
module_exit(fake_pmem_exit);

MODULE_AUTHOR("Kai Michaelis <kai.michaelis@immune.gmbh>");
MODULE_DESCRIPTION("Fake persistent memory driver");
MODULE_LICENSE("GPL v2");
