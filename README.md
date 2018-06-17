# iOS-Lock
iOS 开发中常用的的锁（Lock）

锁的性能的图表：
![](https://github.com/Satelens/iOS-Lock/blob/master/1899027-eb3ef0d444034362.png)

## 锁 是什么意思？
我们在使用多线程的时候多个线程可能会访问同一块资源，这样就很容易引发数据错乱和数据安全等问题，这时候就需要我们保证每次只有一个线程访问这一块资源，锁 应运而生。

### OSSpinLock 自旋锁
需导入头文件：#import <libkern/OSAtomic.h>

这种锁已经不再安全了，并且iOS10.0已不建议使用。
可参考：(https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)

### os_unfair_lock
需导入头文件：#import <os/lock.h>

os_unfair_lock可用来代替OSSpinLock

### dispatch_semaphore 信号量
指定当前最多同时执行几个任务，超过数量的任务将等待。初始信号量为0,我们设置的 overTime 生效。

dispatch_semaphore_create(1)： 传入值必须 >=0, 若传入为 0 则阻塞线程并等待timeout,时间到后会执行其后的语句
dispatch_semaphore_wait(signal, overTime)：可以理解为 lock,会使得 signal 值 -1
dispatch_semaphore_signal(signal)：可以理解为 unlock,会使得 signal 值 +1

### pthread_mutex 互斥锁
需导入头文件：#import <pthread.h>

pthread_mutex 中也有个pthread_mutex_trylock(&pLock)，和上面提到的 OSSpinLockTry(&oslock)区别在于，前者可以加锁时返回的是 0，否则返回一个错误提示码；后者返回的 YES和NO

### pthread_mutex(recursive) 递归锁
需导入头文件：#import <pthread.h>

加锁后只能有一个线程访问该对象，后面的线程需要排队，并且 lock 和 unlock 是对应出现的，同一线程多次 lock 是不允许的，而递归锁允许同一个线程在未释放其拥有的锁时反复对该锁进行加锁操作。

### NSLock 普通锁

API中的方法：lock、unlock、trylock、lockBeforeDate。

### NSCondition

lock: 加锁
unlock: 解锁
wait：进入等待状态
waitUntilDate:：让一个线程等待一定的时间
signal：唤醒一个等待的线程
broadcast：唤醒所有等待的线程

### NSRecursiveLock 递归锁

递归锁可以被同一线程多次请求，而不会引起死锁。这主要是用在循环或递归操作中。

### NSConditionLock 条件锁

NSConditionLock相比于 NSLock 多了个 condition 参数，我们可以理解为一个条件标示。

### @synchronized 条件锁
参考博客：(http://ios.jobbole.com/82826/)
