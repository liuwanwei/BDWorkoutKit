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
    
    for (WorkoutPlan * plan in [[WorkoutPlanCache sharedInstance] cachedObjects]) {
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

@end
