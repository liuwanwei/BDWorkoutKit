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
#import "WorkoutPlanCache.h"
#import "WorkoutUnitCache.h"
#import <TMCache.h>
#import <DateTools.h>
#import <MJExtension.h>
#import <EXTScope.h>
#import <CloudKit/CloudKit.h>

@implementation DataCache

+ (instancetype)sharedInstance{
    static DataCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[DataCache alloc] init];
            
            // 初始化当前训练方案
            [sSharedInstance resetWorkoutPlan];
            
            // 初始化当前训练单元
            [sSharedInstance resetWorkoutUnits];
            
        }
    });
    
    return sSharedInstance;
}

- (void)resetWorkoutPlan {
    NSNumber * selectedWorkoutPlan = [WorkoutAppSetting sharedInstance].workoutPlanId;
    for (WorkoutPlan * plan in [WorkoutPlanCache builtInWorkoutPlans]) {
        if ([plan.objectId isEqualToNumber: selectedWorkoutPlan]) {
            _currentWorkoutPlan = plan;
            return;
        }
    }
    
    for (WorkoutPlan * plan in [[WorkoutPlanCache sharedInstance] workoutPlans]) {
        if ([plan.objectId isEqualToNumber: selectedWorkoutPlan]) {
            _currentWorkoutPlan = plan;
            return;
        }
    }
}

- (void)resetWorkoutUnits {
    if ([_currentWorkoutPlan isBuiltInPlan]) {
        NSDictionary * rootDict = [Utils loadJsonFileFromBundel:_currentWorkoutPlan.configFile];
        if (rootDict) {
            NSArray * dicts = rootDict[@"workouts"];
            _workoutUnits = [WorkoutUnit objectArrayWithKeyValuesArray:dicts];
        }
    }else{
        _workoutUnits = [[WorkoutUnitCache sharedInstance] unitsForPlan:_currentWorkoutPlan];
    }
}


#pragma mark - 测试数据生成接口
//- (void)makeTestWorkoutResults{
//    WorkoutResult * result = nil;
//    srandom((unsigned int)time(NULL));
//
//    // 今天两小时前数据
//    NSDate * today = [NSDate date];
//    result = [[WorkoutResult alloc] init];
//    result.workoutTime = [today dateBySubtractingHours:2];
//    result.consumedTime = @(620);
//    result.pausedTimes = 0;
//    [self addWorkoutResult:result];
//    for (int i = 0; i < MaxWorkoutUnitCount; i ++) {
//        [result addResult:(random() % 2 > 0) forUnit:i];
//    }

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
//}

// 测试用：制造一条测试数据，并保存到 iCloud 中
//- (void)makeAndSaveWorkoutResultToCloud{
//    WorkoutResult * result = nil;
//    srandom((unsigned int)time(NULL));
//    
//    // 今天两小时前数据
//    NSDate * today = [NSDate date];
//    result = [[WorkoutResult alloc] init];
//    result.workoutTime = [today dateBySubtractingHours:2];
//    result.consumedTime = @(620);
//    result.pausedTimes = @(0);
//
//    for (int i = 0; i < MaxWorkoutUnitCount; i ++) {
//        [result addResult:(random() % 2 > 0) forUnit:i];
//    }
//    
//    [self addWorkoutResult:result];
//}

@end
