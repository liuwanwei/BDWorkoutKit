//
//  WorkoutUnitCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutUnitCache.h"
#import "WorkoutUnit.h"
#import "BDiCloudManager.h"
#import "WorkoutPlan.h"
#import <CloudKit/CloudKit.h>
#import <TMCache.h>

static NSString * const WorkoutUnitsKey = @"WorkoutUnitsKey";


@implementation WorkoutUnitCache{
    NSMutableArray * _internalWorkoutUnits;
    
    // TODO: 能否每个 WorkoutXXXCache 类实例都有一个独立的 _cloudManager ？
    __weak BDiCloudManager * _cloudManager;

}

+ (instancetype)sharedInstance{
    static WorkoutUnitCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[WorkoutUnitCache alloc] init];
            [sSharedInstance loadDiskCache];
        }
    });
    
    return sSharedInstance;

}

- (void)loadDiskCache{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:WorkoutUnitsKey];
    if (temp) {
        _internalWorkoutUnits = [temp mutableCopy];
    }else{
        _internalWorkoutUnits = [[NSMutableArray alloc] init];
    }
}

- (void)syncToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutUnits forKey:WorkoutUnitsKey];
}


- (WorkoutUnit *)newUnitForPlan:(NSNumber *)workoutPlanId{
    NSInteger maxId = 0;
    for (WorkoutUnit * unit in _internalWorkoutUnits) {
        if ([unit.workoutPlanId isEqualToNumber:workoutPlanId] &&
            [unit.objectId integerValue] > maxId) {
            maxId = [unit.workoutPlanId integerValue];
        }
    }
    
    WorkoutUnit * unit = [[WorkoutUnit alloc] init];
    unit.workoutPlanId = workoutPlanId;
    unit.objectId = @(maxId + 1);
    
    return unit;
}

- (BOOL)addWorkoutUnit:(WorkoutUnit *)unit{
    BOOL ret = [self cacheWorkoutUnit:unit];
    
    if (ret) {
        [_cloudManager addRecord:[unit iCloudRecord]];
    }
    
    return ret;
}

- (BOOL)cacheWorkoutUnit:(WorkoutUnit *)unit{
    for (WorkoutUnit * unit in _internalWorkoutUnits) {
        if ([unit.objectId isEqualToNumber:unit.objectId]) {
            return false;
        }
    }
    
    [_internalWorkoutUnits addObject:unit];
    return true;
}


- (BOOL)deleteWorkoutUnit:(WorkoutUnit *)unit{
    if (! [_internalWorkoutUnits containsObject:unit]) {
        return false;
    }
    
    [_internalWorkoutUnits removeObject:unit];
    
    // TODO: 从 iCloud 中删除
    
    [self syncToDisk];
    return true;
}

- (BOOL)updateWorkoutUnit:(WorkoutUnit *)unit{
    if (! [_internalWorkoutUnits containsObject:unit]) {
        return false;
    }
    
    // TODO: 修改后再添加会发生什么，请看代码学习
    [_cloudManager addRecord:[unit iCloudRecord]];
    
    [self syncToDisk];
    return true;
}

- (NSArray *)unitsForPlan:(WorkoutPlan *)plan{
    NSMutableArray * units = [[NSMutableArray alloc] init];
    for (WorkoutUnit * unit in _internalWorkoutUnits) {
        if ([unit.workoutPlanId isEqualToNumber:plan.objectId]) {
            [units addObject:unit];
        }
    }
    
    return [units copy];
}

@end
