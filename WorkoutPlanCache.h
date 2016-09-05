//
//  WorkoutPlanCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WorkoutPlan.h"

@interface WorkoutPlanCache : NSObject

// 自定义训练方案数组（WorkoutPlan）
@property (nonatomic, strong, readonly) NSArray * workoutPlans;

+ (instancetype)sharedInstance;

+ (NSArray *)builtInWorkoutPlans;

/**
 * 将训练数据写入磁盘缓存
 * 包括：训练方案、训练结果、训练单元
 */
- (void)syncToDisk;

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
