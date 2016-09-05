//
//  DataCache.m
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/10.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "DataCache.h"
#import "WorkoutUnit.h"
#import "WorkoutResult.h"
#import "BDFoundation.h"
#import "BDiCloudManager.h"
#import "WorkoutAppSetting.h"
#import <TMCache.h>
#import <DateTools.h>
#import <MJExtension.h>
#import <EXTScope.h>
#import <CloudKit/CloudKit.h>


static NSString * const WorkoutResultsKey = @"WorkoutResultsKey";

@implementation DataCache{
    NSMutableArray * _internalWorkoutResults;
    __weak BDiCloudManager * _cloudManager;
}

+ (instancetype)sharedInstance{
    static DataCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[DataCache alloc] init];
            
            // 初始化数据
            TMDiskCache * cache = [TMDiskCache sharedCache];
            
            // 初始化训练记录数据
            NSArray * temp = (NSArray *)[cache objectForKey:WorkoutResultsKey];
            if (temp) {
                sSharedInstance->_internalWorkoutResults = [temp mutableCopy];
            }else{
                sSharedInstance->_internalWorkoutResults = [[NSMutableArray alloc] init];
            }
            
            sSharedInstance->_cloudManager = [BDiCloudManager sharedInstance];
            sSharedInstance->_cloudManager.delegate = sSharedInstance;
            
            // 初始化默认训练方案
            [sSharedInstance resetCurrentHittType];
            
            // 初始化训练单元描述信息
            [sSharedInstance resetWorkoutUnits];
            
        }
    });
    
    return sSharedInstance;
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

- (void)syncDataToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutResults forKey:WorkoutResultsKey];
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
    BOOL ret = [self cachingWorkoutResult:workoutResult];
    if (ret) {
        [_cloudManager addRecord:[workoutResult iCloudRecordObject]];
    }
    
    return ret;
}

- (BOOL)cachingWorkoutResult:(WorkoutResult *)workoutResult{
    for (WorkoutResult * result in _internalWorkoutResults) {
        // 防止向缓存重复添加相同的记录
        if ([result.workoutTime isEqualToDate:workoutResult.workoutTime]) {
            return NO;
        }
    }
    
    [_internalWorkoutResults addObject:workoutResult];
    
    return YES;
}

#pragma mark - 测试数据生成接口
- (void)makeTestWorkoutResults{
    WorkoutResult * result = nil;
    srandom((unsigned int)time(NULL));

    // 今天两小时前数据
    NSDate * today = [NSDate date];
    result = [[WorkoutResult alloc] init];
    result.workoutTime = [today dateBySubtractingHours:2];
    result.consumedTime = @(620);
    result.pausedTimes = 0;
    [self addWorkoutResult:result];
    for (int i = 0; i < MaxWorkoutUnitCount; i ++) {
        [result addResult:(random() % 2 > 0) forUnit:i];
    }
    
    // 昨天此刻数据
//    NSDate * yesterday = [today dateBySubtractingDays:1];
//    
//    result = [[WorkoutResult alloc] init];
//    result.workoutTime = [yesterday dateBySubtractingHours:2];
//    result.consumedTime = @(720);
//    result.pausedTimes = 0;
//    [self addWorkoutResult:result];
//    for (int i = 0; i < MaxWorkoutUnitCount; i ++) {
//        [result addResult:(random() % 2 > 0) forUnit:i];
//    }
    
    // 昨天四小时前数据
//    result = [[WorkoutResult alloc] init];
//    result.workoutTime = [yesterday dateBySubtractingHours:4];
//    result.consumedTime = @(800);
//    result.pausedTimes = @(2);
//    [self addWorkoutResult:result];
//    for (int i = 0; i < MaxWorkoutUnitCount; i ++) {
//        [result addResult:(random() % 2 > 0) forUnit:i];
//    }
}

// 测试用：制造一条测试数据，并保存到 iCloud 中
- (void)makeAndSaveWorkoutResultToCloud{
    WorkoutResult * result = nil;
    srandom((unsigned int)time(NULL));
    
    // 今天两小时前数据
    NSDate * today = [NSDate date];
    result = [[WorkoutResult alloc] init];
    result.workoutTime = [today dateBySubtractingHours:2];
    result.consumedTime = @(620);
    result.pausedTimes = @(0);

    for (int i = 0; i < MaxWorkoutUnitCount; i ++) {
        [result addResult:(random() % 2 > 0) forUnit:i];
    }
    
    [self addWorkoutResult:result];
}

#pragma mark - iCloud 存储管理器托管协议处理
- (void)didReceiveWorkoutResults:(NSArray *)results{
    if (results == nil || results.count <= 0) {
        return;
    }
    
    BOOL changed = NO;
    for (CKRecord * ckRecord in results) {
        if ([ckRecord.recordType isEqualToString:RecordTypeWorkoutResult]) {
            WorkoutResult * workoutResult = [[WorkoutResult alloc] initWithICloudRecord:ckRecord];
            if([self cachingWorkoutResult: workoutResult]){
                changed = YES;
            }
        }
    }
    
    if (changed) {
        [self syncDataToDisk];
    }
    
    // 检查是否有未上传到 iCloud 中的数据
    [self syncDataToIcloud];
}

/*
 * 训练结果添加到 iCloud 成功后，修改本地存储对象的同步状态
 */
- (void)successfullySavedRecord:(CKRecord *)record{
    id object = objc_getAssociatedObject(record, AssociatedWorkoutResult);
    if (object) {
        WorkoutResult * workoutResult = (WorkoutResult *)object;
        workoutResult.savedToICloud = @(YES);
        
        [self syncDataToDisk];
    }
}

- (void)resetCurrentHittType {
    NSArray * types;
    
    NSDictionary * rootDict = [Utils loadJsonFileFromBundel:@"HiitTypes"];
    if (rootDict) {
        NSArray * dicts = rootDict[@"types"];
        types = [WorkoutPlan objectArrayWithKeyValuesArray:dicts];
    }
    
    NSNumber * selectedWorkoutPlan = [WorkoutAppSetting sharedInstance].workoutPlanId;
    for (WorkoutPlan * type in types) {
        if ([type.objectId isEqualToNumber: selectedWorkoutPlan]) {
            _currentWorkoutPlan = type;
            break;
        }
    }
}

- (void)resetWorkoutUnits {
    NSDictionary * rootDict = [Utils loadJsonFileFromBundel:_currentWorkoutPlan.configFile];
    if (rootDict) {
        NSArray * dicts = rootDict[@"workouts"];
        _workoutUnits = [WorkoutUnit objectArrayWithKeyValuesArray:dicts];
    }
}

@end
