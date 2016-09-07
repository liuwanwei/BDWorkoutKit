//
//  WorkoutResultCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutResultCache.h"
#import "WorkoutAppSetting.h"
#import "WorkoutResult.h"
#import <TMCache.h>
#import <objc/runtime.h>

static NSString * const WorkoutResultsKey = @"WorkoutResultsKey";

@implementation WorkoutResultCache{
    NSMutableArray * _internalWorkoutResults;
    
    __weak WorkoutAppSetting * _appSetting;
    __weak BDiCloudManager * _cloudManager;
}

+ (instancetype)sharedInstance{
    static WorkoutResultCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[WorkoutResultCache alloc] init];
        }
    });
    
    return sSharedInstance;
}

- (instancetype)init{
    if (self = [super init]) {
        _appSetting = [WorkoutAppSetting sharedInstance];
        _cloudManager = [BDiCloudManager sharedInstance];
        _cloudManager.delegate = self; // TODO: Deprecated
    }
    
    return self;
}

- (void)load{
    if ([_appSetting.useICloud boolValue]) {
        [self queryICloudWorkoutRecords];
    }else{
        [self loadFromDisk];
    }
}

// 从本地加载训练结果
- (void)loadFromDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:WorkoutResultsKey];
    if (temp) {
        _internalWorkoutResults = [temp mutableCopy];
    }else{
        _internalWorkoutResults = [[NSMutableArray alloc] init];
    }
}

- (void)saveToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutResults forKey:WorkoutResultsKey];
}


- (void)queryICloudWorkoutRecords{
    [_cloudManager queryRecordsWithType:RecordTypeWorkoutResult];
    
}

- (void)syncDataToIcloud{
    for (WorkoutResult * workoutResult in _internalWorkoutResults) {
        if (! [workoutResult.savedToICloud boolValue]) {
            [_cloudManager addRecord:[workoutResult iCloudRecordObject]];
        }
    }
}

/**
 *  函数特点请参考 dailyWeights
 *
 *  @return 不可修改的训练结果数组
 */
- (NSArray *)workoutResults{
    return [_internalWorkoutResults copy];
}

- (BOOL)addWorkoutResult:(WorkoutResult *)workoutResult{
    BOOL ret = [self cacheWorkoutResult:workoutResult];
    if (ret) {
        if ([_appSetting.useICloud  boolValue]) {
            [_cloudManager addRecord:[workoutResult iCloudRecordObject]];
        }else{
            [self saveToDisk];
        }
    }
    
    return ret;
}

- (BOOL)cacheWorkoutResult:(WorkoutResult *)workoutResult{
    for (WorkoutResult * result in _internalWorkoutResults) {
        // 防止向缓存重复添加相同的记录
        if ([result.workoutTime isEqualToDate:workoutResult.workoutTime]) {
            return NO;
        }
    }
    
    [_internalWorkoutResults addObject:workoutResult];
    
    return YES;
}

#pragma mark - BDiCloudDelegate

- (NSString *)recordType{
    return RecordTypeWorkoutResult;
}

- (void)didReceiveWorkoutResults:(NSArray *)results{
    if (results == nil || results.count <= 0) {
        return;
    }
    
    for (CKRecord * ckRecord in results) {
        if ([ckRecord.recordType isEqualToString:RecordTypeWorkoutResult]) {
            WorkoutResult * workoutResult = [[WorkoutResult alloc] initWithICloudRecord:ckRecord];
            [self cacheWorkoutResult: workoutResult];
        }
    }
    
    // 检查是否有未上传到 iCloud 中的数据
//    [self syncDataToIcloud];
}

/*
 * 训练结果添加到 iCloud 成功后，修改本地存储对象的同步状态
 */
- (void)successfullySavedRecord:(CKRecord *)record{
    id object = objc_getAssociatedObject(record, AssociatedWorkoutResult);
    if (object) {
        WorkoutResult * workoutResult = (WorkoutResult *)object;
        workoutResult.savedToICloud = @(YES);
    }
}


@end
