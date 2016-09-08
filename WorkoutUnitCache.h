//
//  WorkoutUnitCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

/*
 * 添加新的训练单元：
 *      // 注意：添加时必须指定训练方案的 objectId
 *      WorkoutUnit * unit = [[WorkoutUnitCache sharedInstance] newUnitForPlan:workoutPlanObjectId];
 *      [[WorkoutUnitCache sharedInstance] addWorkoutUnit:unit];
 *
 */

#import <Foundation/Foundation.h>
#import "BaseCache.h"

@class WorkoutUnit;
@class WorkoutPlan;

@interface WorkoutUnitCache : BaseCache

+ (instancetype)sharedInstance;

- (WorkoutUnit *)newUnitForPlan:(NSNumber *)workoutPlanId;
- (BOOL)addWorkoutUnit:(WorkoutUnit *)unit;
- (BOOL)deleteWorkoutUnit:(WorkoutUnit *)unit;
- (BOOL)updateWorkoutUnit:(WorkoutUnit *)unit;

- (NSArray *)unitsForPlan:(WorkoutPlan *)plan;

@end
