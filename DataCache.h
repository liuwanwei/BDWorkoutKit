//
//  DataCache.h
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/10.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDiCloudManager.h"
#import "WorkoutPlan.h"

@class WorkoutResult;

@interface DataCache : NSObject

// 当前训练方案的训练单元数组(WorkoutUnit)
@property (nonatomic, strong, readonly) NSArray * workoutUnits;

// 当前训练方案对象（WorkoutPlan)
@property (nonatomic, strong, readonly) WorkoutPlan * currentWorkoutPlan;

+ (instancetype)sharedInstance;

// 根据用户选择，重置当前训练方案和训练计划指针
- (void)resetWorkoutPlan;
- (void)resetWorkoutUnits;

// 测试代码：制造训练结果
//- (void)makeTestWorkoutResults;
//- (void)makeAndSaveWorkoutResultToCloud;



@end
