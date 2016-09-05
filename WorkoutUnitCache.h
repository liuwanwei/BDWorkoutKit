//
//  WorkoutUnitCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WorkoutUnit;
@class WorkoutPlan;

@interface WorkoutUnitCache : NSObject

+ (instancetype)sharedInstance;

- (void)syncToDisk;

- (WorkoutUnit *)newUnitForPlan:(NSNumber *)workoutPlanId;
- (BOOL)addWorkoutUnit:(WorkoutUnit *)unit;
- (BOOL)deleteWorkoutUnit:(WorkoutUnit *)unit;
- (BOOL)updateWorkoutUnit:(WorkoutUnit *)unit;

- (NSArray *)unitsForPlan:(WorkoutPlan *)plan;

@end
