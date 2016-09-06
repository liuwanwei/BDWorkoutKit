//
//  WorkoutResultCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDiCloudManager.h"

@class WorkoutResult;

@interface WorkoutResultCache : NSObject <BDiCloudDelegate>

// 所有训练结果
@property (nonatomic, strong, readonly) NSArray * workoutResults;

+ (instancetype)sharedInstance;

// 加载训练结果数据
- (void)load;

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

@end
