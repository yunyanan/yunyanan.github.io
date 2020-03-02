---
title: "编译 Linux 内核"
date: 2020-02-29T17:40:32+08:00

tags: ['Linux', 'Kernel', 'Kbuild']
categories: ['Linux']
---

![Linux](/images/posts/linux_kernel_compile/linux_logo.jpg)

## 前言
---

为了能更深入的了解 Linux 内核， 最近想研究一下 Linux 的整个 Kbuild 系统， 既然如
此那就少不了要实际编译一遍 Linux 内核。 说起来接触 Linux 这么长时间以来我编译过
工作中供应商提供的 SDK，
[Raspberry Pi](https://github.com/raspberrypi/linux), 还有为了修改 Ubuntu 的一个
驱动编译过和当时 Ubuntu 同样版本的内核， 就是没有单独编译过最新最纯粹的 Linux 内
核。 虽然说都是 Linux 内核的编译，但是前面说的那些要么是内核版本比较老，要么就是
编译动作多多少少被修改过， 编译的时候存在些许差别。所以这次我直接下载了 GItHub上
[Linux](https://github.com/torvalds/linux) 仓库的 master 分支来编译。这次就先记
录一下编译 Linux 内核的方法和过程，后面在来写一个 Kbuild 系统的介绍。


## 编译
---

先简单说一下下载吧， 我是直接从 GitHub 上 Linux 的仓库直接下载的， 当然也可以去内核
的[官方网站](https://www.kernel.org)上下载, 这上面不仅有最新稳定版本的内核，一些
历史版本的内核也可以从这里下载到。 不仅如此， Linux 的内核仓库中其实还包含了大量
的文档， 可以选择自己编译出内核文档，也可以使用
[在线文档](https://www.kernel.org/doc/html/latest/index.html)。

NOTE: 在线的文档可能更方便一点， 自己编译的话要在自己电脑上安装一些工具啥的。

现在进入正题:

#### 配置内核

Linux 内核的配置方法有很多， 下面这三种应该是目前使用比较广泛的三种方式：

``` shell
make menuconfig		# Update current config utilising a menu based program
make xconfig		# Update current config utilising a Qt based front-end
make gconfig		# Update current config utilising a GTK+ based front-end
```

这三个命令在配置时只需要用一个就可以了， 命令后面的注释说明了这三个命令的使用条件。
这里先介绍一下 `make help` 命令。 这条命令可以查看到内核编译时所有 Make 可用的目标
及介绍， 上面的注释便出自这里。 我之前配置时也只用过第一种方法，这次编译我的电脑也支持
后面两个命令的条件，所以在这里我也展示一下这三种配置方式的界面。

 + 首先是 `make menuconfig` 的配置界面：

![make menuconfig](/images/posts/linux_kernel_compile/menuconfig.png)

 + 然后是 `make xconfig` 的配置界面：

![make xconfig](/images/posts/linux_kernel_compile/xconfig.png)

 + 最后是 `make gconfig` 的配置界面：

![make gconfig](/images/posts/linux_kernel_compile/gconfig.png)

使用哪种方式可以说取决于个人喜好了或者自己电脑所具备的条件了，毕竟他们最终的目的
都是生成名为 `.config` 的内核配置文件。 在配置具体功能时最多有三种选择：

+ Y -- 将该功能编译进内核
+ N -- 不要将该功能编译进内核
+ M -- 将该功能编译成模块

基本每个功能配置都会有对应的帮助说明， 非常的人性化。 需要注意的是这个步骤其实并
不是每次都必须的， 比如之前已经配置过了，或者从其他地方拷贝来了可用的配置文件，
这一步是完全可以跳过的。配置完成后就可以开始编译了。

#### 编译内核

开始编译时直接使用 `make` 命令即可。 当然如果想加快编译的速度， 可以追加 `-j` 参
数。

``` shell
make -j 4			# 同时运行 4 个作业，这里取值推荐为 2 倍的 CPU Core 数
make -j $(nproc)		# 可以通过 nproc 命令得到可用处理单元的数量
```

#### 编译模块

上面配置内核时说到有三种选择，配置时候选择 `M` 编译为模块的功能特性在这里可以用
下面的命令编译出来：

``` shell
make modules
```
至此，需要编译的代码都已经编译完成。

## 结语
---

Linux 内核的 Makefile 还有很多目标，例如这些：

``` shell
make modules_install		# 安装内核模块
make htmldocs			# 生成 html 格式的内核文档
```
在这里就不一一介绍了，以后用到再说。我想说的是正是有这么多的编译目标的存在才让现
在 Linux 内核的编译如此的简单且人性化。 而在 Linux 的内核中更是处处充满了令人眼
前一亮的细节，这应该也是 Linux 内核魅力的来源之一吧。以后慢慢去发现它们吧。 ：）

**Happy Hacking!**
