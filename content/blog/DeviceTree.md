---
title: "DeviceTree"
date: 2020-05-02T20:00:53+08:00
lastmod: 2020-05-02T20:00:53+08:00
draft: false
author: "YunYanan"
authorLink: "https://yunyanan.github.io"
description: "这篇文章主要介绍了设备树的语法，一些默认属性等相关内容。"

tags: ['DeviceTree', 'Linux']
categories: ['Linux']

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: "/images/posts/DeviceTree/featured.jpg"

---

<!--more-->

## 设备树简介

设备树概念的引入最早可以追溯到 **Kernel v2.6.22**, 它是用来描述硬件的一种数据结构和语言。 在设备树引入之前， 硬件相关的资源信息都是在驱动中直接写死的， 这种方法的特点就是会有很多的冗余代码， 移植性较差。 当硬件有变动时，需要重新描述新设备的硬件资源， 然后重新编译内核或者驱动。 而引入了设备树之后这些不足之处有了很好的改善， 现在如果要移植驱动的话就只需要修改设备树文件，提供一个新平台的 **dtb** 文件给内核即可。

**名词解释**：\
**dts  -- Device Tree Source files**　　　　　　// 设备树源文件\
**dtsi -- Device Tree Source Include files**　　// 可以被 **dts** 文件包含的设备树源文件， 主要包含一些通用的设备描述\
**dtb  -- Device Tree Blob**　　　　　　　　　// 设备树二进制文件， 由 dts 编译后得到\
**blob -- Binary Large Object**\
**dtc  -- Device Tree Compiler**　　　　　　　// 设备树编译器

## 设备树语法

### Devicetree node 格式
**Devicetree** 是由一系列的节点和属性组成， 一个节点也可以包含字节点：
```DTS
[label:] node-name[@unit-address] {
	[properties definitions]
	[child nodes]
};
```
+ `[label:]`: 标签。 方便别的节点引用， 可以省略。
+ `node-name[@unit-address]`: 节点名。 同一级别的节点名字不可以相同， 可以通过增
  加设备的地址 `[@unit-address]` 来区分 `node-name` 相同的节点。

### Property 格式
```DTS
[label:] property-name = value;	// 格式1： 有取值
[label:] property-name;			// 格式2： 无取值
```

使用分号结尾， 和 C 语言语法类似。

Property 的取值有 3 种类型：
1. **Arrays of cell**: 一个或多个 32 位数据， 64 位数据使用 2 个 32 位数据来表示。 格式： `<...>`。
2. **String**: 字符串。 格式： `"..."`。
3. **Bytestring**: 1 个或多个字节。 格式： `[...]`。

示例：
```DTS
interrupts = <17 0xc>;						// Arrays of cells, 2 个 32 位数。
clock-frequency = <0x00000001 0x00000000>;	// 2 个 32 位数表示一个64位数。

compatible = "simple-bus";					// String, 有结束符的字符串。

local-mac-address = [00 00 12 34 56 78];	// Bytestring， 每个字节使用 2 个 16 进制数表示。
local-mac-address = [000012345678];			// 字节和字节之间的空格可以省略。

compatible = "ns16550", "ns8250";			// 也可以是各种类型的组合， 用逗号隔开。
example = <0xf00f0000 19>, "a strange property format";
```
在 **DTS** 文件中被定义的各个属性的值的意义是完全取决于驱动程序的， 所以尽管可能
会有些看上去很奇怪的赋值方式或者格式， 但是只要符合 **DTS** 文件的语法就没有问题。

### 一些特殊默认的属性
#### **#address-cells**
在它的子节点的 **reg** 属性中， 使用多少个 **u32** 整数来描述地址。
#### **#size-cells**
在它的子节点的 **reg** 属性中， 使用多少个 **u32** 整数来描述大小。

示例：
```DTS
   #address-cells = <0x1>;
   #size-cells = <0x1>;
   ...
   ocram: sram@900000 {
	   ...
	   reg = <0x00900000 0x20000>;	// address: 0x00900000 size: 0x20000
	   ...
   };
```

#### **compatible**
**compatible** 属性的值是一系列字符串， 它用 **"manufacturer,model"** 的格式指定
出了具体的设备。 并且具有从左向右由高到低的兼容性优先级（越靠左边兼容性越好）。

示例：
```DTS
compatible = "samsung, smdk2440";	// 厂商： samsung 型号： smdk2440
```

#### **memory**
用来描述硬件内存布局。

示例：
```DTS
memory@80000000 {
	device_type = "memory";
	reg = <0x80000000 0x20000000>;	// 起始地址： 0x80000000 大小： 0x20000000
};
```

#### **chosen**
**bootargs** 属性： 内核启动时的 **command line** 参数。\
**stdout-path&stdin-path** 属性：指定标准输入输出， 可选。

示例：
```DTS
chosen {
	bootargs = "noinitrd root=/dev/mtdblock4 rw init=/linuxrc console=ttySAC0,115200";	// 内核启动时传入的参数
	stdout-path = &uart1;	// 使用 uart1 做标准输出
};
```

#### **cpus**
描述了 **cpu** 相关的信息。下面一般会有一个或多个子节点。

示例：
```DTS
cpus {
	#address-cells = <1>;	// 在子节点中使用 1 个 32 位数描述地址
	#size-cells = <0>;		// 在子节点中使用几个 32 位数描述大小， 固定为 0

	cpu0: cpu@0 {	// cpu0
	compatible = "arm,cortex-a7";	// 厂商： arm 型号： cortex-a7
	device_type = "cpu";
	reg = <0>;						// 表明自己是哪一个 cpu
	...
	};
};
```

### 节点的引用
#### phandle
节点中的 **phandle** 属性， 使用一个唯一的 **id** 来标识一个节点， 在
**property** 可以使用这个 **id** 来引用节点

示例：
```DTS
pic@10000000 {
	phandle = <1>;
	interrupt-controller;
};

another-device-node {
	interrupt-parent = <1>;		// 使用 phandle 的值来引用 **pic@10000000** 节点。
};
```

#### label
定义节点的时候增加标签属性， 使用标签来引用节点。

示例：
```DTS
PIC: pic@10000000 {
	phandle = <1>;
	interrupt-controller;
};

another-device-node {
	interrupt-parent = <&PIC>;		// 使用 **PIC** 这个i标签来引用 **pic@10000000** 节点。
};
```

## 设备树的编译与反编译

设备树的编译器叫做 **DTC**, 它会把设备树源文件 **DTS, DTSI** 编译成 **DTB**，也
可以把 **DTB** 文件反编译成 **DTS** 文件。 当我们在查看设备树文件的时候， 常常会
由于节点信息分散在多个 **DTS** 和 **DTSI** 文件中造成我们查看不方便， 而使用
**DTC** 反编译出来的 **DTS** 文件则是集中了所有的节点信息, 在查看设备树的时候这
会非常有用。 **DTC** 命令的语法是这样的：

```shell
dtc [-I input-format] [-O output-format] [-o output-filename] [-V output_version] input_filename
```

## 在根文件系统中查看设备树

### /sys/firmware/fdt
原始 **dtb** 文件， 可以使用 **DTC** 反编译它， 也可以用 `hexdump` 查看：

```shell
hexdump -C /sys/firmware/fdt
```

### /sys/firmware/devicetree
以目录的结构呈现 **DTB** 文件， 根节点对应 **base** 目录， 每一个节点对应一个目
录， 每一个属性对应一个文件。

## 内核对设备树的处理

Linux uses DT data for three major purposes:
1) platform identification,
2) runtime configuration, and
3) device population.

内核对设备树的处理也可以从这三个角度出发。

### platform identification

关于平台信息其实在上面的介绍中也算是讲到了， 就是 **compatible** 属性。 根节点下
的 **compatible** 属性即指定了当前系统名称。 如果是多个字符串，那么从左到右就代
表了从最兼容到次之。

### runtime configuration

内核对运行时配置信息的处理也比较简单， 简单来说就是从 **DTB** 文件中把所需要的信
息提取出来赋值给内核中的变量即可。 主要是处理了:
1. **chosen** 节点中的 **bootargs** 属性的值， 赋值给了全局变量
   **boot_command_line**。
2. 根节点下的 **#address-cells** 和 **#size-cells** 属性的值， 赋值给了全局变量：
   **dt_root_addr_cells** 和 **dt_root_size_cells**。
3. 提取出 **memory** 节点中的 **arg** 属性的值 **base** 和 **size**, 最终调用
   **memblock_add(base, size)**。

### device population

设备树文件中的每个节点都会被转换成一个 **device_node** 结构体， **device_node**
结构体中的 **property** 结构体用来描述该节点的属性， 每一个属性对应一个
**property** 结构体。 这些 **device_node** 构成了一棵树， 根节点为 **root_node**。
而这其中一部分的 **device_node** 又会转换成 **platform_device** 结构。 转换的条
件为：
+ 根节点下含有 **compatile** 属性的子节点。
+ 如果一个节点的 **compatile** 属性含有这些特殊的值 **("simpli-bus", "simple-mfd",
  "isa", "arm, amba-bus")** 之一， 那么它的子节点（需含 **compatile** 属性）也可
  以转换为 **platform_device**。 i2c， spi 等总线节点下的子节点， 应该交给对应的
  总线驱动程序来处理， 它们不应该被转换为 **platform_device**。

最后， **platform_device** 转换完成后就可以和 **platform_driver** 匹配了， 之后
就是驱动程序的处理了。

## 为什么 PC 上没有设备树

下面这段内容来自
**[StackExchange](https://unix.stackexchange.com/a/399621/410471)**，
我挑选了里面一部分内容并翻译了出来。

外设和主处理器之间是通过总线建立连接的。 有一些总线协议支持枚举， 即主处理器可以
在总线上询问 “有哪些设备连接到了这个总线上？” 这些设备会以一种标准的格式回复一些
关于它们的类型，制造商，型号和配置的信息。 有了这些信息， 操作系统就可以报告可用
设备的列表， 并决定为每个可用设备使用哪个设备驱动程序。 所有现代 PC 总线都支持枚
举， 但是许多的嵌入式系统使用的是不支持枚举的简单总线， 所以这种情况下就必须告诉
操作系统有哪些设备以及如何访问他们。 设备树就是描述这样信息的一个标准格式。

---
<div style="text-align: center">
<p>--END--</p>
<p>Happy Hacking!</p>
</div>
