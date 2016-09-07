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
        self.cloudManager = [[BDiCloudManager alloc] init];
        self.cloudManager.delegate = self;
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
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 LoadFromDisk 函数" userInfo:nil];
}

- (void)saveToDisk{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 SaveToDisk 函数" userInfo:nil];
}

- (void)queryFromICloud{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 QueryFromICloud 函数" userInfo:nil];
}

// 删除本地旧的 iCloud 记录：一般用在删除训练方案、单元、结果后
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

// 添加新的 iCloud 记录到本地：一般用在新建训练方案、单元、结果时
- (void)insertNewICloudRecord:(CKRecord *)record{
    if (_cloudRecords) {
        NSMutableArray * mutable = [_cloudRecords mutableCopy];
        [mutable addObject:record];
        _cloudRecords = [mutable copy];
    }else{
        _cloudRecords = [NSArray arrayWithObject:record];
    }
}

- (NSString *)recordType{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 RecordType 函数" userInfo:nil];
}

@end
