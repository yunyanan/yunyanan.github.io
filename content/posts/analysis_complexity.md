---
title: "算法复杂度分析"
date: 2020-06-20T17:46:54+08:00
lastmod: 2020-06-20T17:46:54+08:00
draft: false
author: "YunYanan"
authorLink: "https://yunyanan.github.io"
description: ""

tags: ['算法', '时间复杂度', '空间复杂度']
categories: ['算法']

hiddenFromHomePage: false
hiddenFromSearch: false

featuredImage: "/images/posts/analysis_complexity/featured.jpg"
---

**"算法 + 数据结构 = 程序"** 这个公式想必所有的开发者都有所耳闻， 毕竟提出这个公式的
**Niklaus Wirth** 凭借这个公式获得了 1984 年的图灵奖， 也由此可见算法和数据结构的重
要性。

<!--more-->

## 引言

其实我在刚开始写程序的一段时间里， 并没有体会到数据结构和算法的重要性。 现在来看
原因可能是在当时工作内容中更多的是实现各种各样的应用逻辑， 而且有很大一部分代码
都是有之前项目的程序可以作为模板参考。 做的越多也就越来越熟练，需要思考的只是各
个项目之间的逻辑差异， 并不需要额外的考量。

后来我自己开始独立写系统功能模块了，需要自己来设计这个模块的架构， 需要考虑这
个模块内部的各种细节。 然后你会以为我从这里开始就意识到数据结构和算法的重要性了
吗？ 其实也并没有， 没有复杂的数据结构和算法，我依然可以实现这个模块。 然而随着
程序写的越来越多的时候，开始觉得自己好像是遇到了瓶颈，那种感觉很诡异。大概就是觉
得自己有点不会写程序了， 但又并不是真的写不出来， 总觉得差点意思。

直到有一天我开始学习之前没有掌握的数据结构， 去面对之前一直望而却步的算法。 几天
后，在工作的时候我发现前两天刚看到的东西可以用起来了。 此刻我才恍然大悟， 原来不
是在工作中用不到数据结构和算法， 而是当你不了解它们的时候，碰到一个问题你自然也
想不到要用它们。

在这篇文章中我们就先来说说算法。 而在选择一个算法的时候，我们往往需要了解这个算
法的两个性能指标 -- 时间复杂度和空间复杂度。 那要怎么分析一个算法的复杂度呢？

## 时间复杂度

我们通常使用 **"Big O notation"** 的方式来表示时间复杂度， 常见的时间复杂度有以下几
种：

	1. O(1): 常数时间复杂度
	2. O(log n): 对数时间复杂度
	3. O(n): 线性时间复杂度
	4. O(n^2): 平方时间复杂度
	5. O(n^3): 立方时间复杂度
	6. O(2^n): 指数时间复杂度
	7. O(n!): 阶乘时间复杂度

它们在图中表现出来大概是这个样子的：

![Comparison Complexity](/images/posts/analysis_complexity/Comparison_computational_complexity.svg)
<div style="text-align: center">
由<a href="//commons.wikimedia.org/wiki/User:Cmglee"
title="User:Cmglee">Cmglee</a> - <span class="int-own-work" lang="zh-cn">自己的
作品</span>，<a href="https://creativecommons.org/licenses/by-sa/4.0"
title="Creative Commons Attribution-Share Alike 4.0">CC BY-SA 4.0</a>，<a
href="https://commons.wikimedia.org/w/index.php?curid=50321072">链接</a>
</div>

从图上不难看出， 随着 **n** 不断加大， 各个时间复杂度 **T(n)** 的差异也不断加大。 那对
程序的影响也自然是不言而喻的。

当我们在分析算法的时间复杂度的时候有两点需要注意的是:

	1. 忽略常数系数对复杂度的影响。 例如时间复杂度 **T(n) = 5*n^2**, 这时候常数系数
	   **5** 便可以忽略， 最终 **T(n) = n^2**。 因为比起系数对 **T(n)** 的影响要
	   原低于函数的阶数对 **T(n)** 的影响。
	2. 只保留最高时间复杂度。 例如时间复杂度 **T(n) = n^3 + n^2**, 那么 **n^2** 便可以忽
	   略。 最终 **T(n) = n^3**。

### 常见时间复杂度实例
#### O(1)

```C
void swap(int *a, int *b)
{
	int tmp;

	tmp = *a;
	*a  = *b;
	*b  = tmp;
}
```

上面这个函数的执行是不受传入参数影响的， 函数中的代码只会被执行一次遍退出， 所以
时间复杂度 **T(n) = O(1)**。

#### O(log n)
```C
int binary_search(int *array, int size, int target)
{
	int l, r;
	int mid;

	l = 0;
	r = size - 1;
	while (l <= r) {
		mid = l + (r - l )/2;
		if (array[mid] == target) {
			return mid;
		}
		if (array[mid] > target) {
			r = mid - 1;
		} else {
			l = mid + 1;
		}
	}

	return -1;
}
```
在上面这个二分查找的代码中， 每次查找的区间以 2 的倍数减少， 所以时间复杂度即为
**O(log n)**。

#### O(n)
```C
int sum(int n)
{
	int i, ret;

	ret = 0;
	for (i=1; i<=n; i++) {
		ret += i;
	}

	return ret;
}
```
上面这个函数中有个 **for** 循环， 而循环次数受到传入参数 **n** 的影响， 循环体中
的代码会执行 **n** 次， 所以时间复杂度 **T(n) = O(n)**。

#### O(n^2)
```C
void selection_sort(int *array, int size)
{
	int i, j, t;
	int count = 0;

	for (i=0; i<size-1; i++) {
		for (j=i+1; j<size; j++) {
			if (array[i] > array[j]) {
				t = array[i];
				array[i] = array[j];
				array[j] = t;
				count ++;
			}
		}
	}
}
```
这个函数便是选择排序的实现， 它使用了两层 **for** 循环， 循环次数受到了传入的
**size** 的影响， 它是一个典型的 **O(n^2)** 的时间复杂度算法。

#### O(n^3)

上面的排序算法使用了两层 **for** 循环便有了 **O(n^2)** 的时间复杂度， 那不难想到，
使用三层的 **for** 循环便是最基本的立方阶时间复杂度算法了。

```C
int sum(int n)
{
	int i, j, k;
	int ret;

	ret = 0;
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			for (k=1; k<=n; k++) {
				ret++;
			}
		}
	}

	return ret;
}
```
#### O(2^n)
```C
int fibonacci(int n)
{
	if (n<1) {
		return 0;
	}
	if ((n == 1) || (n == 2)) {
		return 1;
	}

	return fibonacci(n-1) + fibonacci(n-2);
}
```
上面这个求斐波那契数列第 n 项的函数， 采用了暴力递归的解法。 它的时间复杂度即为
**O(2^n)**。

#### O(n!)
```C
void fac_runtime(int n)
{
	int i;

	for (i=0; i<n; i++) {
		fac_runtime(n-1);
	}
}
```
上面这段代码便是阶乘阶时间复杂度的算法。 阶乘阶已经算是最糟糕的时间复杂度了，在
写代码的时候应该经可能的去避免出现这样的代码。

## 空间复杂度

空间复杂度的分析其实要比时间复杂度的分析简单很多。 主要可以从两个方面判断：

	1. 新开数组长度
	2. 递归深度

比如使用了一个 **n** 个元素的数组， 那空间复杂度即为 **O(n)**, 而如果是一个二维
数组， 元素个数为 **n^2**, 那空间复杂度也就是 **O(n^2)**。

如果是使用了递归， 那么递归的深度就是空间复杂度的最大值了。 当然， 如果又开了数
组，又使用了递归， 那么两者的最大值即为该算法的空间复杂度了。

## 总结

时间复杂度为线性对数阶的时候其实就已经可以算是比较差了， 那就更别说平方阶， 指数
阶， 阶乘阶这些了。 时间复杂度在线性阶的时候可以算是一般，基本可以接受的程度，但
是如果能优化，那自然优化优化更好。 理想情况下是常数阶， 但很多时候可能达不到这个
阶层。 如果实在不行，不要忘了还有一个方法就是可以使用空间来换时间， 但是这个方法
也受限于硬件资源。 关键还是要具体问题具体分析了 😆

---
<div style="text-align: center">
<p>--END--</p>
<p>Happy Hacking!</p>
</div>
