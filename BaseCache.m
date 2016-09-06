//
//  BaseCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "BaseCache.h"
#import "BDiCloudManager.h"
#import "WorkoutAppSetting.h"

@implementation BaseCache

- (instancetype)init{
    if (self = [super init]) {
        self.cloudManager = [BDiCloudManager sharedInstance];
        self.appSetting = [WorkoutAppSetting sharedInstance];
    }
    
    return self;
}

- (void)load{
    if ([self.appSetting.useICloud boolValue]) {
        [self queryFromICloud];
    }else{
        [self loadFromDisk];
    }
}

- (void)loadFromDisk{
    
}

- (void)saveToDisk{
    
}

- (void)queryFromICloud{
    
}

@end
