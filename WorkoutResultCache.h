//
//  WorkoutResultCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDiCloudManager.h"
#import "BaseCache.h"

@class WorkoutResult;

@interface WorkoutResultCache : BaseCache

// 所有训练结果
@property (nonatomic, strong, readonly) NSArray * workoutResults;

+ (instancetype)sharedInstance;

/**
 *  添加训练记录，包括添加到本地缓存和 iCloud 两个步骤
 *  @param workoutResult 最近锻炼情况记录对象
 */
- (BOOL)addWorkoutResult:(WorkoutResult *)workoutResult;
- (void)deleteWorkoutResult:(WorkoutResult *)result;

@end
