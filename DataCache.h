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

//@property (nonatomic, strong, readonly) NSArray * daiylWeights;
@property (nonatomic, strong, readonly) NSArray * workoutResults;

/**
 *  健身单元描述信息，WorkoutUnit
 */
@property (nonatomic, strong, readonly) NSArray * workoutUnits;

/**
 * HIIT 训练方法
 */
@property (nonatomic, strong, readonly) WorkoutPlan * currentWorkoutPlan;

+ (instancetype)sharedInstance;

/**
 *  从 iCloud 服务器查询训练记录
 */
- (void)queryICloudWorkoutRecords;

/**
 *  将数据写入磁盘缓存
 */
- (void)syncDataToDisk;

/**
 *  添加训练记录，包括添加到本地缓存和 iCloud 两个步骤
 *
 *  @param workoutResult 最近锻炼情况记录对象
 */
- (BOOL)addWorkoutResult:(WorkoutResult *)workoutResult;

/**
 *  将训练记录添加到本地缓存中
 *
 *  @param workoutResult 从 iCloud 查询到的训练记录
 *
 *  @return BOOL YES，添加成功；NO，添加失败
 */
- (BOOL)cachingWorkoutResult:(WorkoutResult *)workoutResult;

- (void)makeTestWorkoutResults;
- (void)makeAndSaveWorkoutResultToCloud;

// HIIT 训练 App 使用
- (void)resetCurrentHittType;
- (void)resetWorkoutUnits;

@end
