//
//  WorkoutUnitCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutUnitCache.h"
#import "WorkoutUnit.h"
#import "WorkoutAppSetting.h"
#import "BDiCloudManager.h"
#import "WorkoutPlan.h"
#import <CloudKit/CloudKit.h>
#import <TMCache.h>
#import <EXTScope.h>

// iCloud 中使用的训练单元存储类型
static NSString * const RecordTypeWorkoutUnit = @"WorkoutUnit";

// TMCache 用到的存储所有训练单元的 Key
static NSString * const WorkoutUnitsKey = @"WorkoutUnitsKey";

@implementation WorkoutUnitCache

+ (instancetype)sharedInstance{
    static WorkoutUnitCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[WorkoutUnitCache alloc] init];
        }
    });
    
    return sSharedInstance;
}

- (WorkoutUnit *)newUnitForPlan:(NSNumber *)workoutPlanId{
    NSInteger maxId = 0;
    for (WorkoutUnit * unit in self.internalObjects) {
        if ([unit.workoutPlanId isEqualToNumber:workoutPlanId] &&
            [unit.objectId integerValue] > maxId) {
            maxId = [unit.objectId integerValue];
        }
    }
    
    WorkoutUnit * unit = [[WorkoutUnit alloc] init];
    unit.workoutPlanId = workoutPlanId;
    unit.objectId = @(maxId + 1);
    
    return unit;
}

// 查询训练方案下属的所有训练单元
- (NSArray *)unitsForPlan:(WorkoutPlan *)plan{
    NSMutableArray * units = [[NSMutableArray alloc] init];
    for (WorkoutUnit * unit in self.internalObjects) {
        if ([unit.workoutPlanId isEqualToNumber:plan.objectId]) {
            [units addObject:unit];
        }
    }
    
    return [units copy];
}

// 测试用，显示在菜单上，看缓存中总数变化是否正确
- (NSInteger)totalUnitNumber{
    return self.internalObjects.count;
}

// 需要重载的函数

- (void)objectsDeleted:(NSArray *)objects withError:(NSError *)error{
    if (!error){
        // TODO: 提示删除成功
    }else{
        // TODO: 提示删除失败
    }
}

- (void)objectUpdated:(BDiCloudModel *)object withError:(NSError *)error{
    if (!error){
        WorkoutUnit * unit = (WorkoutUnit *)object;
        [[unit workoutPlan] updateDynamicProperties];
    }else{
        // TODO: 提示修改失败
    }
}

- (NSString *)cacheKey{
    return WorkoutUnitsKey;
}

- (BDiCloudModel *)newCacheObjectWithICloudRecord:(CKRecord *)record{
    WorkoutUnit * object = [[WorkoutUnit alloc] initWithICloudRecord:record];
    return object;
}

- (NSString *)recordType{
    return RecordTypeWorkoutUnit;
}

@end
