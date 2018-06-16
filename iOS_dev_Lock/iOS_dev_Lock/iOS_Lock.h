//
//  iOS_Lock.h
//  iOS_dev_Lock
//
//  Created by 侯博野 on 2018/6/11.
//  Copyright © 2018 satelens. All rights reserved.
//

#import <Foundation/Foundation.h>

// 自旋锁，已弃用，一般都用os_unfair_lock代替
void functionTestOSSpinLock(void);
// os_unfair_lock,用来代替OSSpinLock
void functionTestOSUnfairLock(void);
// dispatch_semaphore 信号量
void functionTestDispatchSemphore(void);
// pthread_mutex 互斥锁
void functionTestPthreadMutex(void);
// pthread_mutex(recursive) 递归锁
void functionTestPthreadMutexRecursive(void);
// NSLock 普通锁
void functionTestNSLock(void);
// NSCondition
void functionTestNSCondition1(void);
void functionTestNSCondition2(void);
// NSRecursiveLock
void functionTestNSRecursiveLock(void);
// NSConditionLock 条件锁
void functionTestNSConditionLock(void);

