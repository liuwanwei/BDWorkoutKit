//
//  WorkoutPlanCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutPlanCache.h"
#import "WorkoutPlan.h"
#import "WorkoutUnitCache.h"
#import "WorkoutAppSetting.h"
#import "BDiCloudManager.h"
#import "BDFoundation.h"
#import <MJExtension.h>
#import <CloudKit/CloudKit.h>
#import <TMCache.h>
#import <EXTScope.h>

// iCloud 中使用的存储类型
static NSString * const RecordTypeWorkoutPlan = @"WorkoutPlan";
// TMCache 使用的存储键值
static NSString * const WorkoutPlansKey = @"WorkoutPlansKey";

@implementation WorkoutPlanCache

+ (instancetype)sharedInstance{
    static WorkoutPlanCache * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[WorkoutPlanCache alloc] init];
        }
    });
    
    return sSharedInstance;
}

// 获取 App 内置的 4 种固定训练方案
+ (NSArray *)builtInWorkoutPlans{
    NSDictionary * rootDict = [Utils loadJsonFileFromBundel:@"HiitTypes"];
    if (rootDict) {
        NSArray * dicts = rootDict[@"types"];
        return [WorkoutPlan objectArrayWithKeyValuesArray:dicts];
    }else{
        return nil;
    }
}

- (void)loadFromDisk{
    [super loadFromDisk];

    // 计算动态属性：运动总时间、休息总时间、动作次数、动作组数
    NSArray * plans = [self cachedObjects];
    for(WorkoutPlan * plan in plans){
        [plan updateDynamicProperties];
    }
}

- (WorkoutPlan *)newWorkoutPlan:(WorkoutPlanType)type{
    NSInteger maxId = 10; // 自定义训练方案 Id 从 10 开始
    NSArray * plans = [self cachedObjects];
    for (WorkoutPlan * plan in plans) {
        if ([plan.objectId integerValue] > maxId) {
            maxId = [plan.objectId integerValue];
        }
    }
    
    // 取现有最大 Id + 1 作为下一个训练方案的 objectId
    WorkoutPlan * plan = [[WorkoutPlan alloc] init];
    plan.objectId = @(maxId + 1);
    plan.type = @(type);
    
    return plan;
}

- (void)objectsDeleted:(NSArray *)objects withError:(NSError *)operationError{
    if (!operationError){
        // 删除训练方案下属训练单元
        for(BDiCloudModel * object in objects){
            [self deleteUnitsForPlan:(WorkoutPlan *)object];
        }        
        
        // TODO: 提示删除成功
        NSLog(@"删除 iCloud 记录成功");        
    }else{
        // TODO: 提示删除失败
        NSLog(@"删除 iCloud 记录失败");
    }   
}

- (void)objectUpdated:(BDiCloudModel *)object withError:(NSError *)error{
    if (! error) {
        // TODO: 提示修改成功
        NSLog(@"修改 iCloud 记录成功");
    }else{
        // TODO: 提示修改失败
        NSLog(@"修改 iCloud 记录失败");
    }
}

// 删除训练方案的所有训练单元，用于删除训练方案时
- (void)deleteUnitsForPlan:(WorkoutPlan *)plan{
    WorkoutUnitCache * unitCache = [WorkoutUnitCache sharedInstance];
    NSArray * units = [unitCache unitsForPlan:plan];
    [unitCache deleteObjects:units];
}

// 查询 Id 对应的训练方案对象
- (WorkoutPlan *)workoutPlanWithId:(NSNumber *)objectId{
    NSArray * plans = [self cachedObjects];
    for (WorkoutPlan * plan in plans){
        if ([plan.objectId isEqualToNumber:objectId]){
            return plan;
        }
    }

    return nil;
}

// 重载关键函数

- (NSString *)cacheKey{
    return WorkoutPlansKey;
}

- (BDiCloudModel *)newCacheObjectWithICloudRecord:(CKRecord *)record{
    WorkoutPlan * plan = [[WorkoutPlan alloc] initWithICloudRecord:record];
    return plan;
}

- (NSString *)recordType{
    return RecordTypeWorkoutPlan;
}

@end
