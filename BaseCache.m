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
#import <TMCache.h>

@implementation BaseCache

- (instancetype)init{
    if (self = [super init]) {
        _cloudManager = [[BDiCloudManager alloc] init];
        _cloudManager.delegate = self;
        _appSetting = [WorkoutAppSetting sharedInstance];
        _internalObjects = [NSMutableArray arrayWithCapacity:12];
    }
    
    return self;
}

// 对 useICloud 属性添加一层易于访问的封装
- (BOOL)useICloudSchema{
    return [self.appSetting.useICloud boolValue];
}

- (void)load{
    if ([self useICloudSchema]) {
        [self queryFromICloud];
    }else{
        [self loadFromDisk];
    }
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

// 从本地加载自定义训练方案
- (void)loadFromDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:[self cacheKey]];
    if (temp) {
        _internalObjects = [temp mutableCopy];
    }else{
        _internalObjects = [[NSMutableArray alloc] init];
    }    
}

// 数据缓存到本地
- (void)saveToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalObjects forKey:[self cacheKey]];
}

// 派生类必须重载的两个接口

#pragma mark - BDiCloudManagerDelegate
- (NSString *)recordType{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 recordType 函数" userInfo:nil];
}

- (NSString *)cacheKey{
    @throw [NSException exceptionWithName:NSGenericException reason:@"派生类必须重载 BaseCache 中声明的 cacheKey 函数" userInfo:nil];   
}


@end
