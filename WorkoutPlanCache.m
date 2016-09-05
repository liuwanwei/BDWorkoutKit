//
//  WorkoutPlanCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutPlanCache.h"
#import "WorkoutPlan.h"
#import "BDiCloudManager.h"
#import "BDFoundation.h"
#import <MJExtension.h>
#import <CloudKit/CloudKit.h>
#import <TMCache.h>

static NSString * const WorkoutPlansKey = @"WorkoutPlansKey";

@implementation WorkoutPlanCache{
    NSMutableArray * _internalWorkoutPlans;
    
    // TODO: 能否每个 WorkoutXXXCache 类实例都有一个独立的 _cloudManager ？
    __weak BDiCloudManager * _cloudManager;
}

+ (instancetype)sharedInstance{
    static WorkoutPlanCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[WorkoutPlanCache alloc] init];            
            [sSharedInstance loadDiskCache];
        }
    });
    
    return sSharedInstance;
}

// 获取 App 内置的 4 种固定训练方案
+ (NSArray *)builtInWorkoutPlans{
    NSDictionary * rootDict = [Utils loadJsonFileFromBundel:@"HiitTypes"];
    if (rootDict) {
        NSArray * dicts = rootDict[@"types"];
        return [WorkoutPlan objectArrayWithKeyValuesArray:dicts];
    }else{
        return nil;
    }
}

// 从本地加载自定义训练方案
- (void)loadDiskCache{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:WorkoutPlansKey];
    if (temp) {
        _internalWorkoutPlans = [temp mutableCopy];
    }else{
        _internalWorkoutPlans = [[NSMutableArray alloc] init];
    }
}


- (void)syncToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutPlans forKey:WorkoutPlansKey];
}


- (NSArray *)workoutPlans{
    return [_internalWorkoutPlans copy];
}

- (WorkoutPlan *)newWorkoutPlan:(WorkoutPlanType)type{
    NSInteger maxId = 10; // 自定义训练方案 Id 从 10 开始
    for (WorkoutPlan * plan in _internalWorkoutPlans) {
        if ([plan.objectId integerValue] > maxId) {
            maxId = [plan.objectId integerValue];
        }
    }
    
    // 取现有最大 Id + 1 作为下一个训练方案的 objectId
    WorkoutPlan * plan = [[WorkoutPlan alloc] init];
    plan.objectId = @(maxId + 1);
    plan.type = @(type);
    
    return plan;
}

- (BOOL)addWorkoutPlan:(WorkoutPlan *)workoutPlan{
    BOOL ret = [self cacheWorkoutPlan:workoutPlan];
    
    if (ret) {
        [_cloudManager addRecord:[workoutPlan iCloudRecordObject]];
    }
    
    return ret;
}

- (BOOL)cacheWorkoutPlan:(WorkoutPlan *)workoutPlan{
    for (WorkoutPlan * obj in _internalWorkoutPlans) {
        if ([obj.objectId isEqualToNumber:workoutPlan.objectId]) {
            return false;
        }
    }
    
    [_internalWorkoutPlans addObject:workoutPlan];
    return true;
}

- (BOOL)deleteWorkoutPlan:(WorkoutPlan *)plan{
    if (! [_internalWorkoutPlans containsObject:plan]) {
        return false;
    }
    
    [_internalWorkoutPlans removeObject:plan];
    
    // TODO: 从 iCloud 中删除
    
    [self syncToDisk];
    return true;
}

- (BOOL)updateWorkoutPlan:(WorkoutPlan *)plan{
    if (! [_internalWorkoutPlans containsObject:plan]) {
        return false;
    }
    
    // TODO: 修改后再添加会发生什么，请看代码学习
    [_cloudManager addRecord:[plan iCloudRecordObject]];
    
    [self syncToDisk];
    return true;
}

@end
