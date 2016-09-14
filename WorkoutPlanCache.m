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
    for(WorkoutPlan * plan in self.internalObjects){
        [plan updateDynamicProperties];
    }
}

- (NSArray *)workoutPlans{
    return [self.internalObjects copy];
}

- (WorkoutPlan *)newWorkoutPlan:(WorkoutPlanType)type{
    NSInteger maxId = 10; // 自定义训练方案 Id 从 10 开始
    for (WorkoutPlan * plan in self.internalObjects) {
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

- (BOOL)addWorkoutPlan:(WorkoutPlan *)plan{
    if ([self useICloudSchema]) {
        @weakify(self);
        CKRecord * record = [plan newICloudRecord:RecordTypeWorkoutPlan];
        [self.cloudManager addRecord:record withCompletionBlock:^(CKRecord * record){
            @strongify(self);
            [self cacheObject:plan];
            [self insertNewICloudRecord:record];            
        }];
    }else{
        [self cacheObject:plan];
        [self saveToDisk];
    }
    
    return YES;
}

// 删除训练方案入口
- (BOOL)deleteWorkoutPlan:(WorkoutPlan *)plan{
    if (! [self.internalObjects containsObject:plan]) {
        return NO;
    }
    
    if ([self useICloudSchema]) {
        @weakify(self);
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:@[plan.cloudRecord.recordID]];
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecord, NSArray * deletedRecordIds, NSError * operationError){
            @strongify(self);
            if (! operationError) {
                [self.internalObjects removeObject:plan];
                // 从 cloudRecords 中删除
                [self removeICloudRecord:deletedRecordIds[0]];
                
                // TODO: 提示删除成功
                NSLog(@"删除 iCloud 记录成功");
                
                // 删除对应的训练单元
                [self deleteUnitsForPlan:plan];                

            }else{
                // TODO: 提示删除失败
                NSLog(@"删除 iCloud 记录失败");
            }
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        [self.internalObjects removeObject:plan];        
        [self saveToDisk];

        [self deleteUnitsForPlan:plan];
    }
    
    return YES;
}

- (BOOL)updateWorkoutPlan:(WorkoutPlan *)plan{
    if (! [self.internalObjects containsObject:plan]) {
        return NO;
    }
    
    if ([self useICloudSchema]) {
        // 将内存数据的修改同步到 iCloud 对象上
        [plan updateICloudRecord:plan.cloudRecord];
        
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[plan.cloudRecord] recordIDsToDelete:nil];
        modifyRecord.savePolicy = CKRecordSaveAllKeys;
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
            if (! operationError) {
                // TODO: 提示修改成功
                NSLog(@"修改 iCloud 记录成功");
            }else{
                // TODO: 提示修改失败
                NSLog(@"修改 iCloud 记录失败");
            }
            
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        [self saveToDisk];
    }
    
    return YES;
}

// 删除训练方案的所有训练单元，用于删除训练方案时
- (void)deleteUnitsForPlan:(WorkoutPlan *)plan{
    WorkoutUnitCache * unitCache = [WorkoutUnitCache sharedInstance];
    NSArray * units = [unitCache unitsForPlan:plan];
    [unitCache deleteWorkoutUnits:units];
}

// 向服务器查询训练方案
// - (void)queryFromICloud{    
//     @weakify(self);
//     [self.cloudManager queryRecordsWithCompletionBlock:^(NSArray * records){
//         @strongify(self);
//         // 缓存 iCloud 中查询到的所有记录
//         self.cloudRecords = records;
        
//         // 将 iCloud 记录转换成 WorkoutPlan 实例对象
//         for (CKRecord * record in records) {
//             WorkoutPlan * plan = [[WorkoutPlan alloc] initWithICloudRecord:record];
//             [self cacheWorkoutPlan:plan];
//         }
//     }];
// }

// 查询 Id 对应的训练方案对象
- (WorkoutPlan *)workoutPlanWithId:(NSNumber *)objectId{
    for (WorkoutPlan * plan in self.internalObjects){
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
