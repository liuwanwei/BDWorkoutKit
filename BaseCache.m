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
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 loadFromDisk 函数" userInfo:nil];
}

- (void)saveToDisk{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 saveToDisk 函数" userInfo:nil];
}

- (void)queryFromICloud{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 queryFromICloud 函数" userInfo:nil];
}

- (BOOL)removeICloudRecord:(CKRecordID *)recordID{
    if (_cloudRecords && _cloudRecords.count > 0) {
        NSMutableArray * records = [_cloudRecords mutableCopy];
        for (CKRecord * record in records) {
            if (record.recordID == recordID) {
                [records removeObject:record];
                _cloudRecords = [records copy];
                return YES;
            }
        }
    }
    
    return NO;
}

@end
