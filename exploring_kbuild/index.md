# 内核编译的背后


<div style="text-align: center">
<img src="/images/posts/exploring_kbuild/kbuild.png"/>
</div>

上一篇简单介绍了下编译 **GNU Linux** 内核， 这篇就来了解一下编译 **GNU Linux**
内核背后的 **Kbuild** 系统吧。

<!--more-->

## 前言
---

最近了解 **Kbuild** 的时候, 在网上搜索相关的内容发现讲这方面内容的文章比起教你怎
么编译内核的文章数量上要少很多。 我觉得这也反应出 **Kbuild** 系统确实是容易被忽
视的一隅， 也说明了会编译内核的人不再少数，但是去研究过 **Kbuild** 系统的， 对
**Kbuild** 感兴趣的人则要少很大一部分。 下面呢来讲讲我对 **Kbuild** 的理解。

{{< admonition >}}
+ 本文中是以在 PC 上编译 `GNU Linux` 内核为例。
+ `GNU Linux` 的内核现在也还在活跃的更新中， 所以本篇文章中讲到的 `Kbuild` 规则
  可能会随着时间的推移，与最新的 `GNU Linux` 内核 `Kbuild` 规则的偏差逐渐加大。
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
目标可以说是 `kbuild` 系统的主要任务了。 内核的架构被分成了不同的模块， 每个模块
都由它自己在 `Makefile` 管理。 当编译内核时， 顶层的 `Makefile` 会按照正确的顺序
调用对应模块的 `Makefile`， 递归的进行编译。 因此， 内核中的 `Makefile` 也被分成
了下面的这几部分：

	Makefile		the top Makefile.
	.config			the kernel configuration file.
	arch/$(ARCH)/Makefile	the arch Makefile.
	scripts/Makefile.*	common rules etc. for all kbuild Makefiles.
	kbuild Makefiles	there are about 500 of these.

顶层 **Makefile** 包含了架构 **Makefile** 之后， 在 **scripts/Makefile.\*** 等
**Makefile** 中规则的帮助下， 会将各个模块编译为一个中间对象， 并且大多数都是
**built-in.a**。 最终将各个中间对象链接起来后就是最终的 **vmlinux** 对象了。
下面这个图是我画得生成 **vmlinux** 目标的依赖关系图：

![vmlinux]()

从图上可以看到 **vmlinux** 的依赖有三个： `scripts/link-vmlinux.sh`,
`autoksyms_recursive`, `$(vmlinux-deps)`。

**To be continued**

