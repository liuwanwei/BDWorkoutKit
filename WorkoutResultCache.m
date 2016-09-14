//
//  WorkoutResultCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutResultCache.h"
#import "WorkoutResult.h"
#import <TMCache.h>
#import <EXTScope.h>

// iCloud 中使用的存储类型
static NSString * const RecordTypeWorkoutResult = @"WorkoutResult";
// TMCache 使用的存储键值
static NSString * const WorkoutResultsKey = @"WorkoutResultsKey";

@implementation WorkoutResultCache

+ (instancetype)sharedInstance{
    static WorkoutResultCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[WorkoutResultCache alloc] init];
        }
    });
    
    return sSharedInstance;
}

/**
 *  函数特点请参考 dailyWeights
 *
 *  @return 不可修改的训练结果数组
 */
- (NSArray *)workoutResults{
    return [self.internalObjects copy];
}

- (void)deleteWorkoutResult:(WorkoutResult *)result{
    if([self useICloudSchema]){
        // TODO: 从 iCloud 删除训练结果
    }else{
        [self.internalObjects removeObject:result];
        [self saveToDisk];
    }
}

- (NSString *)cacheKey{
    return WorkoutResultsKey;
}

- (BDiCloudModel *)newCacheObjectWithICloudRecord:(CKRecord *)record{
    WorkoutResult * result = [[WorkoutResult alloc] initWithICloudRecord:record];    
    return result;
}

- (NSString *)recordType{
    return RecordTypeWorkoutResult;
}

@end
