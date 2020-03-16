---
title: "Kbuild"
date: 2020-03-02T22:29:09+08:00

tags: ['Linux', 'Kernel', 'Kbuild', 'Makefile']
categories: ['Linux']

draft: true
---


## Linux 内核 Makefile 规则
Most importantly: sub-Makefiles should only ever modify files in
 their own directory. If in some directory we have a dependency on
 a file in another dir (which doesn't happen often, but it's often
 unavoidable when linking the built-in.a targets which finally
 turn into vmlinux), we will call a sub make in that other dir, and
 after that we are sure that everything which is in that other dir
 is now up to date.


## 看懂 Linux 内核 Makefile 所需要的 Makefile 知识。

### Makefile 基本规则
### PHONY
### ifeq, ifneq, ifdef, ifndef
### unexport,export
### if
### error

## 函数
### origin
### findstring
### filter-out
### realpath
### lastword
### dir
### words

## Linux 内核 Makefile 中的变量
