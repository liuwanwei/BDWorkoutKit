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
        }
    });
    
    return sSharedInstance;
}

// 发送消息，通知界面更新
- (void)postNotification{    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUPDATE_WORKOUT_MODE_MESSAGE object:nil];
}

- (void)resetWorkoutPlan {
    NSNumber * workoutPlanId = [WorkoutAppSetting sharedInstance].workoutPlanId;
    
    // 在内置训练方案中查询    
    for (WorkoutPlan * plan in [WorkoutPlanCache builtInWorkoutPlans]) {
        if ([plan.objectId isEqualToNumber: workoutPlanId]) {
            _currentWorkoutPlan = plan;
            NSDictionary * rootDict = [Utils loadJsonFileFromBundel:_currentWorkoutPlan.configFile];
            if (rootDict) {
                NSArray * dicts = rootDict[@"workouts"];
                _workoutUnits = [WorkoutUnit objectArrayWithKeyValuesArray:dicts];
            }
            [self postNotification];
            return;
        }
    }
    
    // 在自定义训练方案中查询
    for (WorkoutPlan * plan in [[WorkoutPlanCache sharedInstance] cachedObjects]) {
        if ([plan.objectId isEqualToNumber: workoutPlanId]) {
            _currentWorkoutPlan = plan;
            _workoutUnits = [[WorkoutUnitCache sharedInstance] unitsForPlan:_currentWorkoutPlan];
            [self postNotification];
            return;
        }
    }

    @throw [NSException exceptionWithName:NSGenericException 
        reason:[NSString stringWithFormat:@"没有找到对应的训练方案：%@", workoutPlanId]
        userInfo:nil];
}

// - (void)resetWorkoutUnits {
//     if ([_currentWorkoutPlan isBuiltInPlan]) {
//         NSDictionary * rootDict = [Utils loadJsonFileFromBundel:_currentWorkoutPlan.configFile];
//         if (rootDict) {
//             NSArray * dicts = rootDict[@"workouts"];
//             _workoutUnits = [WorkoutUnit objectArrayWithKeyValuesArray:dicts];
//         }
//     }else{
//         _workoutUnits = [[WorkoutUnitCache sharedInstance] unitsForPlan:_currentWorkoutPlan];
//     }
// }

@end
