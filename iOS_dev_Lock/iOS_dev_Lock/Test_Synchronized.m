//
//  Test_Synchronized.m
//  iOS_dev_Lock
//
//  Created by 侯博野 on 2018/6/16.
//  Copyright © 2018 satelens. All rights reserved.
//

#import "Test_Synchronized.h"

@implementation Test_Synchronized

- (void)testSynchronized {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self) {
            sleep(2);
            NSLog(@"线程1");
            sleep(3);
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self) {
            NSLog(@"线程2");
        }
    });
}

@end
