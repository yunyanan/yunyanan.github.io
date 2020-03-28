---
title: "内核编译的背后"
date: 2020-03-15T10:29:35+08:00

tags: ['Linux', 'Kernel', 'Kbuild', 'Makefile', 'Kconfig']
categories: ['Linux']

toc: true
autoCollapseToc: true
---

<div style="text-align: center">
<img src="/images/posts/exploring_kbuild/kbuild.png"/>
</div>

Hey, 会编译内核了之后还想知道内核编译背后的 `Kbuild` 吗 :smirk:

<!--more-->

## 前言
---

最近了解 **Kbuild** 的时候, 在网上搜索相关的内容发现讲这方面内容的文章比起教你怎
么编译内核的文章数量上要少很多。 我觉得这也反应出 **Kbuild** 系统确实是容易被忽
视的一隅， 也说明了会编译内核的人不再少数，但是去研究过 **Kbuild** 系统的， 对
**Kbuild** 感兴趣的人则要少很大一部分。 下面呢来讲讲我对 **Kbuild** 的理解。

{{< admonition >}}
+ 本文中是以在 PC 上编译 `GNU Linux` 内核为例。
+ 本文研究使用的内核版本信息如下：
  >VERSION = 5	\
  >PATCHLEVEL = 6 \
  >SUBLEVEL = 0	\
  >EXTRAVERSION = -rc3	\
  >NAME = Kleptomaniac Octopus
{{< /admonition >}}

## Kbuild && Kconfig
---

刚开始接触 **GNU Linux** 内核的时候我就知道在内核中有一系列的 **Kconfig** 和
**Makefile** 文件， 内核源码的很多目录下也都是一个 **Kconfig** 文件搭配一个
**Makefile** 文件。我知道 **Kbuild** 这个名词的时候是很久之后了。 当看到这个词的
时候我的第一反应是觉得 **"Kbuild"** 它是内核中具体的某个配置文件或者编译脚本之类
的东西。 网上一众文章中也很少有直接给 **Kbuild** 下一个定义， 我在官方的
[内核文档 modules 篇](https://www.kernel.org/doc/Documentation/kbuild/modules.txt)
中找到这样的一句话， 也算是通俗易懂的介绍了 **kbuild**：

> "kbuild" is the build system used by the Linux kernel.

这里定义的 **Kbuild** 是从广义上来说的 **Kbuild**。 而内核中也存在一些名字就是
**Kbuild** 的文件， 那这些文件是什么呢？ 这其实有个有趣的地方， 在
[内核文档 makefiles 篇](https://www.kernel.org/doc/Documentation/kbuild/makefiles.txt)
中的第三节有这样的一个介绍：

>	"Most Makefiles within the kernel are kbuild Makefiles that use the kbuild
>	infrastructure. This chapter introduces the syntax used in the kbuild
>	makefiles. The preferred name for the kbuild files are 'Makefile' but
>	'Kbuild' can be used and if both a 'Makefile' and a 'Kbuild' file exists,
>	then the 'Kbuild' file will be used."

所以说我上面提到的我的第一感觉也不能算错， 从狭义上讲 **Kbuild** 也可以指内核中的编
译脚本， 只不过官方更推荐使用 **"Makefile"** 这个名字。

关于 **Kconfig**， 这里其实不用更多的解释了，它就是指内核的配置，没有歧义。网上好多
文章把 **Kconfig** 和 Kbuild 是以并列的架构讲解的， 而内核中关于 **Kconfig** 描
述文档则全部都归类在 **Kbuild** 下的。 这其实也是从 广义还是狭义上来看待
**Kbuild** 的问题了。

构建内核的第一步始终是配置内核。 在上一篇文章中也讲了如何配置内核， 这里就先来看看
在 `menuconfig`, `xconfig` 等这些配置方式的背后到底发生了什么。

### make *config 的背后
---

当我们执行 `make menuconfig` 或 `make xconfig` 等命令时， 匹配到的是顶层
**Makefile** 中的 `%config` 目标：

```Makefile
%config: outputmakefile scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@
```

它有三个依赖： `outputmakefile`, `scripts_basic`, `FORCE` 以及一条命令。 我们一个一个来看。

#### outputmakefile

我把 outputmakefile 目标的来源以及它所依赖的一些变量来源从顶层 Makefile 中拿
出来放在了一起：

```Makefile
#####################
# abs_objtree 变量来源

ifeq ("$(origin O)", "command line")
  KBUILD_OUTPUT := $(O)
endif

ifneq ($(KBUILD_OUTPUT),)
# Make's built-in functions such as $(abspath ...), $(realpath ...) cannot
# expand a shell special character '~'. We use a somewhat tedious way here.
abs_objtree := $(shell mkdir -p $(KBUILD_OUTPUT) && cd $(KBUILD_OUTPUT) && pwd)
$(if $(abs_objtree),, \
     $(error failed to create output directory "$(KBUILD_OUTPUT)"))

# $(realpath ...) resolves symlinks
abs_objtree := $(realpath $(abs_objtree))
else
abs_objtree := $(CURDIR)
endif # ifneq ($(KBUILD_OUTPUT),)

#####################
# abs_srctree 变量来源

abs_srctree := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

################################
# building_out_of_srctree 变量来源

ifeq ($(abs_srctree),$(abs_objtree))
        # building in the source tree
        srctree := .
	building_out_of_srctree :=
else
        ifeq ($(abs_srctree)/,$(dir $(abs_objtree)))
                # building in a subdirectory of the source tree
                srctree := ..
        else
                srctree := $(abs_srctree)
        endif
	building_out_of_srctree := 1
endif

#####################
# outputmakefile 目标

outputmakefile:
ifdef building_out_of_srctree
	$(Q)if [ -f $(srctree)/.config -o \
		 -d $(srctree)/include/config -o \
		 -d $(srctree)/arch/$(SRCARCH)/include/generated ]; then \
		echo >&2 "***"; \
		echo >&2 "*** The source tree is not clean, please run 'make$(if $(findstring command line, $(origin ARCH)), ARCH=$(ARCH)) mrproper'"; \
		echo >&2 "*** in $(abs_srctree)";\
		echo >&2 "***"; \
		false; \
	fi
	$(Q)ln -fsn $(srctree) source
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile $(srctree)
	$(Q)test -e .gitignore || \
	{ echo "# this is build directory, ignore it"; echo "*"; } > .gitignore
endif

```
我们从下往上看， `outputmakefile` 目标的内容是否有效取决于这样的一个依赖关系链：

	outputmakefile --> building_out_of_srctree --> abs_srctree, abs_objtree

- `abs_objtree` 取决于命令行是否有 `O=DIR` 参数传入。 **DIR** 表示编译输出文件的
  存放路径， 默认是在源码路径下。 如果有这个参数传入则 `abs_objtree` 的值为传入
  的路径，否则为源码路径。

  {{< admonition >}}
  当指定了 `O=DIR` 参数的时候 **Makefile** 不仅会去创建这个目录，并且会将工作路
  径切换到 **DIR** 这个路径去。
  {{< /admonition >}}

- `abs_srctree` 是由 `MAKEFILE_LIST` 变量经过 `lastword`, `dir`, `realpath` 几个函
  数处理后得到的结果，最后的结果是顶层 **Makefile** 的绝对路径。

- `building_out_of_srctree` 的值则取决于 `abs_objtree` 和 `abs_srctree` 是否相等，
  不相等时 `building_out_of_srctree` 的值为 1， 否则为空。

- 到这里其实可以看得出 `outputmakefile` 这个目标是为 `O=DIR` 这个参数服务的。 它真正
  做了这么两件事：

	1. 在 **DIR** 路径下创建了源码目录的软链接。
	2. 执行了 `$(srctree)/scripts/mkmakefile $(srctree)` 这条 **shell** 命令。

  关键在于第二条， 这条命令是去执行源码路径下的 `scripts/mkmakefile` 脚本，并且将
  源码路径作为参数传入。而这个脚本的内容如下：

  ```shell
  cat << EOF > Makefile
  # Automatically generated by $0: don't edit
  include $1/Makefile
  EOF
  ```
  可以看出，它的作用就是在 **DIR** 路径下创建出一个 **Makefile** 文件并包含源码目录下的顶
  层 **Makefile**。

#### scripts_basic

`scripts_basic` 目标的内容是这样的：

```Makefile
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic
	$(Q)rm -f .tmp_quiet_recordmcount
```

{{< admonition info >}}
变量 `$(Q)` 是定义在顶层 **Makefile** 中的， 它的作用是编译时控制 **Makefile**
否要回显命令。 它的值取决于命令行有没有 `V=1` 的参数传入，如果有这个参数传入，
`$(Q)` 的值为空， 否则为 `@`。 在这里分析 **Makefile** 时都可以先忽略它。
{{< /admonition >}}

这里面比较麻烦的是 `build` 这个变量，其实它是定义在了 **"scripts/Kbuild.include"**
中。 它的定义是这样的：

```Makefile
###
# Shorthand for $(Q)$(MAKE) -f scripts/Makefile.build obj=
# Usage:
# $(Q)$(MAKE) $(build)=dir
build := -f $(srctree)/scripts/Makefile.build obj
```

这里注释也解释了为什么把它定义成这样和怎么使用它。而 `MAKE` 变量是 `GNU make` 定义
的变量，一般它的值都是 `make`， 有关它的详细介绍可以参考
[这里](https://www.gnu.org/software/make/manual/html_node/MAKE-Variable.html)。
所以上面 `$(Q)$(MAKE) $(build)=scripts/basic` 这条规则可以展开成这样：
`make -f $(srctree)/scripts/Makefile.build obj=scripts/basic`。
这里没有指定目标，所以编译的是 `Makefile.build` 的默认目标：

```Makefile
__build: $(if $(KBUILD_BUILTIN),$(builtin-target) $(lib-target) $(extra-y)) \
	 $(if $(KBUILD_MODULES),$(obj-m) $(mod-targets) $(modorder-target)) \
	 $(subdir-ym) $(always-y)
	@:
```

当配置内核时， **$(KBUILD_BUILTIN)**， **$(KBUILD_MODULES)**， **$(subdir-ym)** 的值都为空， 所以
只有 **$(always-y)** 目标有效, 此时 **$(always-y)** 的值为 `fixdep`。
所以 `scripts_basic` 这个目标其实是去编译了 `scripts/basic` 下的源码生成 `fixdep` 工具。

关于 **fixdep** 工具的作用在 `scripts/basic/Makefile` 里有一段这样的解释：

> fixdep: used to generate dependency information during build process

在这里就不对 **fixdep** 工具展开详细分析了。

#### FORCE

`FORCE` 目标是定义在顶层 **Makefile** 的最后：

```Makefile
PHONY += FORCE
FORCE:

# Declare the contents of the PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)
```

这里其实也是一个比较有意思的地方， 在 **Makefile** 中 `FORCE` 目标并没有依赖，
也没有要执行的命令， 但是 `FORCE` 目标的使用却不止一处两处。 那么为什么要这么用
呢？ 这个答案其实 `GNU Make` 官方就已经给出了：

> If a rule has no prerequisites or recipe, and the target of the rule is a
> nonexistent file, then make imagines this target to have been updated whenever
> its rule is run. This implies that all targets depending on this one will
> always have their recipe run.

简而言之就是这样定义出的 `FORCE` 目标在使用时其实可以把它当成一个关键字， 如果依
赖中加上 `FORCE` 的话, **make** 工具便会认为这个目标的依赖更新过， 需要重新生成
这个目标。 详细内容可以参考 `GNU Make`
[官方手册](https://www.gnu.org/software/make/manual/html_node/Force-Targets.html)。

#### %config 目标的命令

`%config` 的命令原本是这样的： `$(Q)$(MAKE) $(build)=scripts/kconfig $@`。 这条
命令展开后就变成了这样：

```Makefile
make -f $(srctree)/scripts/Makefile.build obj=scripts/kconfig %config
```

可以看出， 它又去调用了 `scripts/Makefile.build` 文件， 只不过此时有参数
`obj=scripts/kconfig`， 有目标 `%config`。

{{< admonition info >}}
这里目标 `%config` 在传入 `scripts/Makefile.build` 时就是在执行 `make` 时传入的
目标。 例如使用的是 `make menuconfig` 命令配置内核， 这里目标就是 `menuconfig`。
{{< /admonition >}}

因为传入了参数 `obj=scripts/kconfig`， 所以 `srcipts/kconfig` 目录下的
`Makefile` 会被包含进来。 对应的 `%config` 目标也都在其中：

```Makefile
################
# Kconfig 变量定义

ifdef KBUILD_KCONFIG
Kconfig := $(KBUILD_KCONFIG)
else
Kconfig := Kconfig
endif

ifndef KBUILD_DEFCONFIG
KBUILD_DEFCONFIG := defconfig
endif

###############
# silent 变量定义

ifeq ($(quiet),silent_)
silent := -s
endif

################
# %config 目标定义

xconfig: $(obj)/qconf
	$< $(silent) $(Kconfig)

gconfig: $(obj)/gconf
	$< $(silent) $(Kconfig)

menuconfig: $(obj)/mconf
	$< $(silent) $(Kconfig)

config: $(obj)/conf
	$< $(silent) --oldaskconfig $(Kconfig)

nconfig: $(obj)/nconf
	$< $(silent) $(Kconfig)
```

继续以 `menuconfig` 目标为例， 它有一个依赖 `$(obj)/mconf`。 这个 `mconf` 其实是
个可执行程序， 而这里的依赖也就是它的生成过程。 关于它的生成过程也还是比较复杂的，
下面是我整理出来的它的依赖关系图， 其他的几个目标也是大同小异， 这里我就不展开分
析了。 这部分工作主要是在 `scripts/Makefile.host` 和 `scripts/kconfig/Makefile`
中实现的。

![menuconfig](/images/posts/exploring_kbuild/menuconfig.png)

回过头来， `menuconfig` 的命令展开后是这样的：

```Makefile
scripts/kconfig/mconf Kconfig
```

其实就是调用了生成的 `mconf` 程序， 并把 `Kconfig` 作为输入参数。 这里的
`Kconfig` 便是指源码根目录下的 `Kconfig` 文件， 目的就是用 `mconf` 去解析这个文
件。 顶层的 `Kconfig` 内容并不复杂， 基本都是去包含各个子模块下的 `Kconfig` 文件。
解析完之后开始构建初始配置数据库， 然后根据以下优先级读取现有配置文件来更新初始
数数据库：

+ .config
+ /lib/modules/$(shell,uname -r)/.config
+ /etc/kernel-config
+ /boot/config-$(shell,uname -r)
+ ARCH_DEFCONFIG
+ arch/$(ARCH)/defconfig

之后我们就可以通过 `GUI` 界面开始配置内核， 完成后会生成 `.config` 文件。所以整
个配置过程是这样的：

![config flow](/images/posts/exploring_kbuild/config_flow.png)

### vmlinux 生成的背后

通过上面对内核配置过程的分析， **kbuild** 的套路也被揭露了一二。 而编译 `vmlinux`
目标可以说是 `kbuild` 系统的核心任务了。 内核的架构被分成了不同的模块， 每个模块
都由它自己在 `Makefile` 管理。 当编译内核时， 顶层的 `Makefile` 会按照正确的顺序
调用对应模块的 `Makefile`， 递归的进行编译。 因此， 内核中的 `Makefile` 也被分成
了下面的这几部分：

    Makefile		the top Makefile.
     .config			the kernel configuration file.
     arch/$(ARCH)/Makefile	the arch Makefile.
     scripts/Makefile.*	common rules etc. for all kbuild Makefiles.
     kbuild Makefiles	there are about 500 of these.

没错，就是在它们的共同努力下编译出了 `vmlinux`。 我把 **vmlinux** 编译的编译整理
成了下面这张依赖关系图：

![vmlinux](/images/posts/exploring_kbuild/vmlinux.png)

那接下来就来讲一下编译时最核心的部分。 从上面的图中也可以看到， `vmlinux` 的依赖
有三大块。

#### $(vmlinux-deps)

这部分主要是负责源码部分的编译， 从变量的名字也可以看得出，这
个变量属于 `vmlinux` 的依赖。 图中可以看到， 这部分最终的依赖基本都是名为
`built-in.a` 的文件， 那这些文件是什么呢？ 我们先来看看另一个问题， 在上面提到过，
`kbuild` 系统的编译是采用递归的方式进行的, 那这是怎么实现的呢？ 这个秘密在
`scripts/Makefile.build` 和 `scripts/Makefile.lib` 中：

```Makefile
# Handle objects in subdirs
# ---------------------------------------------------------------------------
# o if we encounter foo/ in $(obj-y), replace it by foo/built-in.a
#   and add the directory to the list of dirs to descend into: $(subdir-y)
# o if we encounter foo/ in $(obj-m), remove it from $(obj-m)
#   and add the directory to the list of dirs to descend into: $(subdir-m)
__subdir-y	:= $(patsubst %/,%,$(filter %/, $(obj-y)))
subdir-y	+= $(__subdir-y)
__subdir-m	:= $(patsubst %/,%,$(filter %/, $(obj-m)))
subdir-m	+= $(__subdir-m)

# Subdirectories we need to descend into
subdir-ym	:= $(sort $(subdir-y) $(subdir-m))
subdir-ym	:= $(addprefix $(obj)/,$(subdir-ym))

# $(subdir-obj-y) is the list of objects in $(obj-y) which uses dir/ to
# tell kbuild to descend
subdir-obj-y := $(filter %/built-in.a, $(obj-y))

$(subdir-ym):
	$(Q)$(MAKE) $(build)=$@ \
	$(if $(filter $@/, $(KBUILD_SINGLE_TARGETS)),single-build=) \
	need-builtin=$(if $(filter $@/built-in.a, $(subdir-obj-y)),1) \
	need-modorder=$(if $(need-modorder),$(if $(filter $@/modules.order, $(modorder)),1))

ifdef need-builtin
builtin-target := $(obj)/built-in.a
endif

$(builtin-target): $(real-obj-y) FORCE
	$(call if_changed,ar_builtin)
```
上面这些内容是从那两个 `Makefile` 中摘抄出来的， 他们并不在一起。 这点东西我觉得应该算
是 `kbuild` 系统及其核心的一个部分了。 `obj-y/m` 变量中存放的是需要编译的文件和
需要递归进入的目录。 `kbuild Makefiles` 中的内容大多都是增加它们的值。
`$(subdir-obj-y)` 变量则是从 `$(obj-y)` 中过滤出了所有的 `%/built-in.a`。
在 `$(subdir-ym)` 的命令执行时会去判断 `$(subdir-obj-y)` 变量里是否存在
`$@/built-in.a`， 如果存在自然就会有 `$(builtin-target)` 目标存在。 而
`$(builtin-target)` 目标的参数是执行了 `$(call if_changed,ar_builtin)`。
这里就不得不讲讲 `if_changed` 这个东西了， 它在 `kbuild` 中的出场率也是非常高的。
它的定义是在 `scripts/Kbuild.include` 中：

```Makefile
# echo command.
# Short version is used, if $(quiet) equals `quiet_', otherwise full one.
echo-cmd = $(if $($(quiet)cmd_$(1)),\
	echo '  $(call escsq,$($(quiet)cmd_$(1)))$(echo-why)';)

# printing commands
cmd = @set -e; $(echo-cmd) $(cmd_$(1))

# Execute command if command has changed or prerequisite(s) are updated.
if_changed = $(if $(newer-prereqs)$(cmd-check),                              \
	$(cmd);                                                              \
	printf '%s\n' 'cmd_$@ := $(make-cmd)' > $(dot-target).cmd, @:)
```

可以看出如果 `$(newer-prereqs)` 和 `$(cmd-check)` 只要有一个不为空，那么就会执行
`$(cmd)` 命令， 否则会打印一些日志。 `$(newer-prereqs)` 表示任何比目标更新或不存
在的先决条件。 `$(cmd-check)` 的作用则是检查 `$(cmd_@)` 是否为空，或者
`$(cmd_@)` 和 `$(cmd_$(1))` 是否相等。 说的简单点就是去判断了是否存在有效的
`$(cmd_$(1))` 目标。 而 `cmd` 目标实际上做了两件事： 一个是打印当前命令，第二个是
执行 `cmd_$(1)` 命令。 这里的 `$(1)` 便是调用 `if_changed` 时传入的参数。 所以
`$(builtin-target)` 目标的命令就是去执行 `cmd_ar_builtin` 目标。 而它的定义是这
样的：

```Makefile
cmd_ar_builtin = rm -f $@; $(AR) cDPrST $@ $(real-prereqs)
```
这也可以看出， `cmd_ar_builtin` 命令就是将当前目录下的编译目标们都用 `$(AR)` 命
令打包成 `$(builtin-target)`， 也就是 `$(obj)/built-in.a`。 这就是在图中各个程序
模块目录下 `built-in.a` 的来源。

#### autoksyms_recursive

这部分从的功能从图中看是被分成了两个分支：

`descend` 依赖的 `prepare` 主要是去做了一些编译前的准备工作。 例如
`outputmakefile` 是去编译输出目录生成一个 `Makefile`等。

`modules.order` 目标的命令是这样的：
```Makefile
$(Q)$(AWK) '!x[$$0]++' $(addsuffix /$@, $(build-dirs)) > $@
```
它主要是生成了 `modules.order` 文件。 这个文件是用来记录编译的外部模块， 目的是
给 `modprobe` 命令加卸载模块时使用。

而 `autoksyms_recursive` 目标的命令是这样的：

```Makefile
ifdef CONFIG_TRIM_UNUSED_KSYMS
autoksyms_recursive: descend modules.order
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/adjust_autoksyms.sh \
	  "$(MAKE) -f $(srctree)/Makefile vmlinux"
endif
```

这里的 `CONFIG_TRIM_UNUSED_KSYMS` 默认是没有被定义的， 所以在默认情况下，这里的
命令也就不会被执行。 命令中的 `$(CONFIG_SHELL)` 在 `kbuild` 中也是比较常见的，
它的值在顶层 `Makefile`中被定义成了 `CONFIG_SHELL := sh`。 所以它的作用就是确定
了 `kbuild` 所使用的 `SHELL`。 所以上面的命令其实就是去执行了
`scripts/adjust_autoksyms.sh` 脚本。 而这个脚本的作用在脚本开头的注释中也有介绍：

	# Create/update the include/generated/autoksyms.h file from the list
	 # of all module's needed symbols as recorded on the second line of *.mod files.

	 # For each symbol being added or removed, the corresponding dependency
	 # file's timestamp is updated to force a rebuild of the affected source
	 # file. All arguments passed to this script are assumed to be a command
	 # to be exec'd to trigger a rebuild of those files.

说简单点就是生成或者更新 `include/generated/autoksyms.h` 和其他依赖文件。 所以综
合来看这部分的内容主要是做好编译前的准备工作。

#### scripts/link-vmlinux.sh

这个脚本的作用是用于链接生成最终的 `vmlinux` 目标的。 同样的， 这个脚本开头的注
释我觉得讲的比较清楚， 也非常的有意义：

```Text
# vmlinux is linked from the objects selected by $(KBUILD_VMLINUX_OBJS) and
# $(KBUILD_VMLINUX_LIBS). Most are built-in.a files from top-level directories
# in the kernel tree, others are specified in arch/$(ARCH)/Makefile.
# $(KBUILD_VMLINUX_LIBS) are archives which are linked conditionally
# (not within --whole-archive), and do not require symbol indexes added.
#
# vmlinux
#   ^
#   |
#   +--< $(KBUILD_VMLINUX_OBJS)
#   |    +--< init/built-in.a drivers/built-in.a mm/built-in.a + more
#   |
#   +--< $(KBUILD_VMLINUX_LIBS)
#   |    +--< lib/lib.a + more
#   |
#   +-< ${kallsymso} (see description in KALLSYMS section)
#
# vmlinux version (uname -v) cannot be updated during normal
# descending-into-subdirs phase since we do not yet know if we need to
# update vmlinux.
# Therefore this step is delayed until just before final link of vmlinux.
#
# System.map is generated to document addresses of all kernel symbols
```

### 构建的目标

虽然在上面的讲述中一直是以 `vmlinux` 当作最终目标来讲的， 但是实际上如果我们在编
译内核时输入 `make` 时没有指定任何目标时， 默认目标 `all` 会使用
`arch/$(ARCH)/Makefile` 文件中定义的值。 在 `x86` 平台上是这样定义的: `all:
bzImage`。 那这里就来说说 `vmlinux` 和 `bzImage` 之间的关系。

`vmlinux` 只是编译出来的最原始的内核文件， 它的本质是一个包含静态链接，带调试信
息的 `ELF` 文件， 不带有引导信息。 而有些时候，尤其是在嵌入式 `ARM` 处理器上我们
需要的是一个可被引导的内核镜像， 而 `bzImage` 就是这样的一个目标。 一般来说， 创
建一个可引导的内核镜像时， 这个镜像都会先经过压缩处理， 而在创建好的镜像的开头会
嵌有解压代码， 这里的 `bzImage` 文件也是这样的。 它是经过了 `gzip` 和 `objcopy`
工具制作出来的压缩文件。 不仅如此， `bzImage` 文件还包含了 `bootsect.o`，
`setup.o`， `misc.o`， `piggy.o` 等内容。


## 结语

关于 `kbuild` 系统就分析到这里了， 下面和大家分享一点我的感想。

从上面的讲解过程也可以看到， 我引用了很多内核里的文档和注释。 不得不说， 内核的
文档和注释真的非常值得我们学习。 从文档和注释的内容上来说， 它们可以帮助我们更好
更快的理解内核中的内容， 从编程的方面来说我们平时写程序的时候写文档写注释也应该
向内核中的文档注释学习, 即简单明了又能抓住重点理清逻辑。 当然， 不止是文档和注释，
`GNU Linux` 的内核中处处都有值得我们学习的地方, 宛如一个宝藏。

最后， 如果大家发现文章中有什么错误或者疑问， 欢迎留言一起交流。

---
**Happy Hacking!**
