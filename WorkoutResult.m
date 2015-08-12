//
//  WorkoutResult.m
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/9.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "WorkoutResult.h"
#import <objc/runtime.h>

NSInteger MaxWorkoutUnitCount = 12;

NSString * const RecordTypeWorkoutResult = @"WorkoutResult";
const void * AssociatedWorkoutResult = "AssociatedWorkoutResult";

static NSString * const WorkoutTime = @"workoutTime";
static NSString * const ConsumedTime = @"consumedTime";
static NSString * const PausedTimes = @"PausedTimes";
static NSString * const UnitResults = @"unitResults";

@implementation WorkoutResult

- (instancetype)init{
    if (self = [super initWithUUID]) {
        // 初始化训练单元完成状态
        _unitResults = [[NSMutableData alloc] initWithLength:MaxWorkoutUnitCount];
    }
    
    return self;
}


- (instancetype)initWithICloudRecord:(CKRecord *)record{
    if (self = [self init]) {
        // 从 CKRecord 生成数据
//        self.iid = record.recordID.recordName;
        _workoutTime = [record objectForKey:WorkoutTime];
        _consumedTime = [record objectForKey:ConsumedTime];
        _pausedTimes = [record objectForKey:PausedTimes];
        _unitResults = [record objectForKey:UnitResults];
        _savedToICloud = @(YES);
    }
    
    return self;
}

- (CKRecord *)iCloudRecordObject{
    CKRecordZone * zone = [CKRecordZone defaultRecordZone];
    CKRecord * record = [[CKRecord alloc] initWithRecordType:RecordTypeWorkoutResult zoneID:zone.zoneID];
    [record setObject:self.workoutTime forKey:WorkoutTime];
    [record setObject:self.consumedTime forKey:ConsumedTime];
    [record setObject:self.pausedTimes forKey:PausedTimes];
    [record setObject:self.unitResults forKey:UnitResults];
    
    objc_setAssociatedObject(record, AssociatedWorkoutResult, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return record;
}


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
