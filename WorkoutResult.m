//
//  WorkoutResult.m
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/9.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "WorkoutResult.h"
#import <objc/runtime.h>

NSInteger MaxWorkoutUnitCount = 128;

static NSString * const WorkoutTime = @"workoutTime";
static NSString * const ConsumedTime = @"consumedTime";
static NSString * const PausedTimes = @"pausedTimes";
static NSString * const UnitResults = @"unitResults";
static NSString * const GroupNumber = @"groupNumber";
static NSString * const TotalNumber = @"totalNumber";

@implementation WorkoutResult

- (instancetype)init{
    if (self = [super initWithUUID]) {
        // 初始化训练单元完成状态
        _unitResults = [[NSMutableData alloc] initWithLength:MaxWorkoutUnitCount];
    }
    
    return self;
}


- (instancetype)initWithICloudRecord:(CKRecord *)record{
    if (self = [super initWithICloudRecord:record]) {
        // 从 CKRecord 生成数据
        _workoutTime = [record objectForKey:WorkoutTime];
        _consumedTime = [record objectForKey:ConsumedTime];
        _pausedTimes = [record objectForKey:PausedTimes];
        _unitResults = [record objectForKey:UnitResults];
        _totalNumber = [record objectForKey:TotalNumber];
        _groupNumber = [record objectForKey:GroupNumber];
        // _savedToICloud = @(YES);
    }
    
    return self;
}

- (void)updateICloudRecord:(CKRecord *)record{
    [record setObject:self.workoutTime forKey:WorkoutTime];
    [record setObject:self.consumedTime forKey:ConsumedTime];
    [record setObject:self.pausedTimes forKey:PausedTimes];
    [record setObject:self.unitResults forKey:UnitResults];
    [record setObject:self.totalNumber forKey:TotalNumber];
    [record setObject:self.groupNumber forKey:GroupNumber];
}

// @Deprecated: 每个训练单元是否完成这个不需要统计
- (BOOL)addResult:(BOOL)result forUnit:(NSInteger)unitIndex{
    if (unitIndex < MaxWorkoutUnitCount) {
        uint8_t * bytes = (uint8_t *)_unitResults.bytes;
        bytes[unitIndex] = (uint8_t)result;
        
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)resultForUnit:(NSInteger)unitIndex{
    if (unitIndex < MaxWorkoutUnitCount) {
        uint8_t * bytes = (uint8_t *)_unitResults.bytes;
        return (BOOL)bytes[unitIndex];
    }else{
        [NSException raise:@"获取训练单元结果失败" format:@"训练单元序号越界 %@", @(unitIndex)];
        return NO;
    }
}

@end
