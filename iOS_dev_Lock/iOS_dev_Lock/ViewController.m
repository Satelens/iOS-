//
//  ViewController.m
//  iOS_dev_Lock
//
//  Created by 侯博野 on 2018/6/11.
//  Copyright © 2018 satelens. All rights reserved.
//

#import "ViewController.h"
#import "iOS_Lock.h"
#import "Test_Synchronized.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    functionTestOSSpinLock();
//    functionTestOSUnfairLock();
//    functionTestDispatchSemphore();
//    functionTestPthreadMutex();
//    functionTestPthreadMutexRecursive();
//    functionTestNSLock();
//    functionTestNSCondition1();
//    functionTestNSCondition2();
//    functionTestNSRecursiveLock();
    
//    Test_Synchronized *test_S = [Test_Synchronized new];
//    [test_S testSynchronized];
    
    functionTestNSConditionLock();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
