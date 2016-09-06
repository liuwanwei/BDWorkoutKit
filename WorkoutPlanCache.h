//
//  WorkoutPlanCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

/*
 * 获取内置训练方案（徒手初级、徒手中级，跳绳初级、跳绳中级）：
 *      [[WorkoutPlanCache sharedInstance] builtInWorkoutPlans];
 * 获取自定义训练方案：
 *      [[WorkoutPlanCache sharedInstance] workoutPlans];
 * 添加新的训练方案：
 *      WorkoutPlan * plan = [[WorkoutPlanCache sharedInstance] newWorkoutPlan:PlanTypeHIIT];
 *      ...
 *      [[WorkoutPlanCache sharedInstance] addWorkoutPlan:plan];
 *
 */

#import <Foundation/Foundation.h>
#import "BaseCache.h"
#import "WorkoutPlan.h"

@interface WorkoutPlanCache : BaseCache

// 自定义训练方案数组（WorkoutPlan）
@property (nonatomic, strong, readonly) NSArray * workoutPlans;

+ (instancetype)sharedInstance;

// 查询内置的训练方案
+ (NSArray *)builtInWorkoutPlans;

/**
 * 新建训练方案。
 * 注意：新建训练方案必须使用这个接口，接口内部会为训练方案创建唯一 Id；
 * 创建完成后，请调用 addWorkoutPlan 保存新的训练方案。
 */
- (WorkoutPlan *)newWorkoutPlan:(WorkoutPlanType)type;
- (BOOL)addWorkoutPlan:(WorkoutPlan *)plan;
- (BOOL)deleteWorkoutPlan:(WorkoutPlan *)plan;
- (BOOL)updateWorkoutPlan:(WorkoutPlan *)plan;

@end
