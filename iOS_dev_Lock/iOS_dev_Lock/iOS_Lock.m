//
//  iOS_Lock.m
//  iOS_dev_Lock
//
//  Created by 侯博野 on 2018/6/11.
//  Copyright © 2018 satelens. All rights reserved.
//

#import "iOS_Lock.h"

#pragma mark - 自旋锁，已弃用，一般都用os_unfair_lock代替
#import <libkern/OSAtomic.h>
void functionTestOSSpinLock(void) {
    __block OSSpinLock oslock = OS_SPINLOCK_INIT;
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        OSSpinLockLock(&oslock);
        sleep(4);
        NSLog(@"线程1");
        OSSpinLockUnlock(&oslock);
        NSLog(@"线程1 解锁成功");
        NSLog(@"--------------------------------------------------------");
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 准备上锁");
        OSSpinLockLock(&oslock);
        NSLog(@"线程2");
        OSSpinLockUnlock(&oslock);
        NSLog(@"线程2 解锁成功");
    });
}

#pragma mark - os_unfair_lock,用来代替OSSpinLock
#import <os/lock.h>
void functionTestOSUnfairLock(void) {
    __block os_unfair_lock oslock = OS_UNFAIR_LOCK_INIT;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        os_unfair_lock_lock(&oslock);
        NSLog(@"线程1 进入睡眠");
        sleep(4);
        NSLog(@"线程1 睡眠结束，即将解锁");
        os_unfair_lock_unlock(&oslock);
        NSLog(@"线程1 解锁成功");
        NSLog(@"-------------------------");
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 准备上锁");
        os_unfair_lock_lock(&oslock);
        NSLog(@"线程2 即将解锁");
        os_unfair_lock_unlock(&oslock);
        NSLog(@"线程2 解锁成功");
    });
}


#pragma mark - dispatch_semaphore 信号量,指定当前最多同时执行几个任务，超过数量的任务将等待。初始信号量为0,我们设置的 overTime 生效。
/*
 dispatch_semaphore_create(1)： 传入值必须 >=0, 若传入为 0 则阻塞线程并等待timeout,时间到后会执行其后的语句
 dispatch_semaphore_wait(signal, overTime)：可以理解为 lock,会使得 signal 值 -1
 dispatch_semaphore_signal(signal)：可以理解为 unlock,会使得 signal 值 +1
 */
/*
 关于信号量，我们可以用停车来比喻：
 停车场剩余4个车位，那么即使同时来了四辆车也能停的下。如果此时来了五辆车，那么就有一辆需要等待。
 信号量的值（signal）就相当于剩余车位的数目，dispatch_semaphore_wait 函数就相当于来了一辆车，dispatch_semaphore_signal 就相当于走了一辆车。停车位的剩余数目在初始化的时候就已经指明了（dispatch_semaphore_create（long value）），调用一次 dispatch_semaphore_signal，剩余的车位就增加一个；调用一次dispatch_semaphore_wait 剩余车位就减少一个；当剩余车位为 0 时，再来车（即调用 dispatch_semaphore_wait）就只能等待。有可能同时有几辆车等待一个停车位。有些车主没有耐心，给自己设定了一段等待时间，这段时间内等不到停车位就走了，如果等到了就开进去停车。而有些车主就像把车停在这，所以就一直等下去。
 */
void functionTestDispatchSemphore(void) {
    dispatch_semaphore_t siganl = dispatch_semaphore_create(1);
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 3.0f * NSEC_PER_SEC);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 等待ing");
        dispatch_semaphore_wait(siganl, overTime);
        NSLog(@"线程1");
        dispatch_semaphore_signal(siganl);
        NSLog(@"线程1 发送信号");
        NSLog(@"--------------------------");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 等待ing");
        dispatch_semaphore_wait(siganl, overTime);
        NSLog(@"线程2");
        dispatch_semaphore_signal(siganl);
        NSLog(@"线程2 发送信号");
    });
}

#pragma mark - pthread_mutex 互斥锁,OSSpinLock 都替换成了 pthread_mutex
// ibireme 在《不再安全的 OSSpinLock》(https://blog.ibireme.com/)这篇文章中提到性能最好的 OSSpinLock 已经不再是线程安全的并把自己开源项目中的 OSSpinLock 都替换成了 pthread_mutex。
// pthread_mutex 中也有个pthread_mutex_trylock(&pLock)，和上面提到的 OSSpinLockTry(&oslock)区别在于，前者可以加锁时返回的是 0，否则返回一个错误提示码；后者返回的 YES和NO
#import <pthread.h>
void functionTestPthreadMutex(void) {
    static pthread_mutex_t pLock;
    pthread_mutex_init(&pLock, NULL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        pthread_mutex_lock(&pLock);
        sleep(3);
        NSLog(@"线程1");
        pthread_mutex_unlock(&pLock);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 准备上锁");
        pthread_mutex_lock(&pLock);
        NSLog(@"线程2");
        pthread_mutex_unlock(&pLock);
    });
}

#pragma mark - pthread_mutex(recursive) 递归锁
//经过上面几种例子，我们可以发现：加锁后只能有一个线程访问该对象，后面的线程需要排队，并且 lock 和 unlock 是对应出现的，同一线程多次 lock 是不允许的，而递归锁允许同一个线程在未释放其拥有的锁时反复对该锁进行加锁操作。
void functionTestPthreadMutexRecursive(void) {
    static pthread_mutex_t pLock;
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr); // 初始化attr并给它赋值默认
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE); // 设置锁类型，这边是设置为递归锁
    pthread_mutex_init(&pLock, &attr);
    pthread_mutexattr_destroy(&attr);
    
    // 线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void(^RecursiveBlock)(int);
        RecursiveBlock = ^(int value) {
            pthread_mutex_lock(&pLock);
            if (value > 0) {
                NSLog(@"value: %d", value);
                RecursiveBlock(value - 1);
            }
            pthread_mutex_unlock(&pLock);
        };
        RecursiveBlock(5);
    });
}

#pragma mark - NSLock 普通锁
//lock、unlock：不多做解释，和上面一样
//trylock：能加锁返回 YES 并执行加锁操作，相当于 lock，反之返回 NO
//lockBeforeDate：这个方法表示会在传入的时间内尝试加锁，若能加锁则执行加锁操作并返回 YES，反之返回 NO
void functionTestNSLock(void) {
    NSLock *lock = [NSLock new];
    // 线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 尝试加速ing...");
        [lock lock];
        sleep(3);
        NSLog(@"线程1");
        [lock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    // 线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 尝试加速ing...");
        BOOL x = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:4]];
        if (x) {
            NSLog(@"线程2");
            [lock unlock];
        }else{
            NSLog(@"失败");
        }
    });
}

#pragma mark - NSCondition
//wait：进入等待状态
//waitUntilDate:：让一个线程等待一定的时间
//signal：唤醒一个等待的线程
//broadcast：唤醒所有等待的线程
void functionTestNSCondition1(void) //等待2秒
{
    NSCondition *clock = [NSCondition new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"start");
        [clock lock];
        [clock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        NSLog(@"线程1");
        [clock unlock];
    });
}

void functionTestNSCondition2(void) //唤醒一个等待线程
{
    NSCondition *clock = [NSCondition new];
    // 线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [clock lock];
        NSLog(@"线程1 加锁成功");
        [clock wait];
        NSLog(@"线程1");
        [clock unlock];
    });
    // 线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [clock lock];
        NSLog(@"线程2 加锁成功");
        [clock wait];
        NSLog(@"线程2");
        [clock unlock];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        NSLog(@"唤醒一个等待线程");
        [clock signal];
//        [clock broadcast]; // 唤醒所有线程
    });
}

#pragma mark - NSRecursiveLock 递归锁
/*
 NSRecursiveLock 方法里还提供了两个方法
- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;
 */
// 递归锁可以被同一线程多次请求，而不会引起死锁。这主要是用在循环或递归操作中。
void functionTestNSRecursiveLock(void) {
    /*
    // 下面代码是一个典型的死锁，在我们的线程中，RecursiveMethod 是递归调用的。所以每次进入这个 block 时，都会去加一次锁，而从第二次开始，由于锁已经被使用了且没有解锁，所以它需要等待锁被解除，这样就导致了死锁，线程被阻塞住了。
    NSLock *rLock = [NSLock new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value) {
            [rLock lock];
            if (value > 0) {
                NSLog(@"线程%d", value);
                RecursiveBlock(value - 1);
            }
            [rLock unlock];
        };
        RecursiveBlock(4);
    });
     */
    
    // 将 NSLock 替换为 NSRecursiveLock
    NSRecursiveLock *rLock = [NSRecursiveLock new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value) {
            [rLock lock];
            if (value > 0) {
                NSLog(@"线程%d", value);
                RecursiveBlock(value - 1);
            }
            [rLock unlock];
        };
        RecursiveBlock(4);
    });
}

#pragma mark - NSConditionLock 条件锁
// NSConditionLock相比于 NSLock 多了个 condition 参数，我们可以理解为一个条件标示。
void functionTestNSConditionLock(void) {
    NSConditionLock *clock = [[NSConditionLock alloc] initWithCondition:0];
    
    // 线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([clock tryLockWhenCondition:0]) {
            NSLog(@"线程1");
            [clock unlockWithCondition:1];
        } else {
            NSLog(@"失败");
        }
    });
    
    // 线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [clock lockWhenCondition:3];
        NSLog(@"线程2");
        [clock unlockWithCondition:2];
    });
    
    // 线程3
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [clock lockWhenCondition:1];
        NSLog(@"线程3");
        [clock unlockWithCondition:3];
    });
    /*
    .我们在初始化 NSConditionLock 对象时，给了他的标示为 0
    .执行 tryLockWhenCondition:时，我们传入的条件标示也是 0,所 以线程1 加锁成功
    .执行 unlockWithCondition:时，这时候会把condition由 0 修改为 1
    .因为condition 修改为了 1， 会先走到 线程3，然后 线程3 又将 condition 修改为 3
    .最后 走了 线程2 的流程
    从上面的结果我们可以发现，NSConditionLock 还可以实现任务之间的依赖。
     */
}













