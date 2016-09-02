//
//  WorkoutResult.h
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/9.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "BaseModel.h"
#import <CloudKit/CloudKit.h>

extern NSInteger MaxWorkoutUnitCount;
extern NSString * const RecordTypeWorkoutResult;
extern const void *  AssociatedWorkoutResult;

@interface WorkoutResult : BaseModel

/**
 *  锻炼开始时间
 */
@property (nonatomic, strong) NSDate * workoutTime;

/**
 *  完成整个训练的总时间，从训练开始计时，到训练结束的总时间，包括暂停时间，单位 “秒”
 */
@property (nonatomic, strong) NSNumber * consumedTime;

@property (nonatomic, strong) NSString * workoutTitle;

/**
 *  训练过程中总共暂停了几次，不计时间，只要按下暂停就算一次
 */
@property (nonatomic, strong) NSNumber * pausedTimes;

/**
 *  每个训练单元是否完成标记数组，跳过某个训练单元时，标记为未完成
 */
@property (nonatomic, strong, readonly) NSData * unitResults;

/**
 *  是否已经成功保存到了 iCloud 上
 */
@property (nonatomic, strong) NSNumber * savedToICloud;


/**
 *  添加一个训练单元完成标志。未添加的训练单元，默认状态都是未完成。
 *
 *  @param result    单元是否完成：YES，完成；NO，未完成
 *  @param unitIndex 训练单元序号，从 0 开始，最大值 12
 *
 *  @return 添加结果，YES 成功，NO 失败
 */
- (BOOL)addResult:(BOOL)result forUnit:(NSInteger)unitIndex;

- (BOOL)resultForUnit:(NSInteger)unitIndex;


// iCloud/CloudKit 的 CKRecord 对象之间互相转换
- (instancetype)initWithICloudRecord:(CKRecord *)record;
- (CKRecord *)iCloudRecordObject;

@end