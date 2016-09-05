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

@interface DataCache : NSObject <BDiCloudDelegate>


// 所有训练结果
@property (nonatomic, strong, readonly) NSArray * workoutResults;

// 当前训练方案的训练单元数组(WorkoutUnit)
@property (nonatomic, strong, readonly) NSArray * workoutUnits;

// 当前训练方案对象（WorkoutPlan)
@property (nonatomic, strong, readonly) WorkoutPlan * currentWorkoutPlan;

+ (instancetype)sharedInstance;

/**
 *  从 iCloud 服务器查询训练记录
 */
- (void)queryICloudWorkoutRecords;

- (void)syncWorkoutResultToDisk;

/**
 *  添加训练记录，包括添加到本地缓存和 iCloud 两个步骤
 *  @param workoutResult 最近锻炼情况记录对象
 */
- (BOOL)addWorkoutResult:(WorkoutResult *)workoutResult;

/**
 * 将训练记录添加到本地缓存中
 * @param workoutResult 从 iCloud 查询到的训练记录
 * @return BOOL YES，添加成功；NO，添加失败
 */
- (BOOL)cacheWorkoutResult:(WorkoutResult *)workoutResult;

// 根据用户选择，重置当前训练方案和训练计划指针
- (void)resetWorkoutPlan;
- (void)resetWorkoutUnits;

// 测试代码：制造训练结果
- (void)makeTestWorkoutResults;
- (void)makeAndSaveWorkoutResultToCloud;



@end
