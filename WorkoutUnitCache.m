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

- (BOOL)addWorkoutUnit:(WorkoutUnit *)unit{
    if ([self useICloudSchema]){
        @weakify(self);
        CKRecord * record = [unit newICloudRecord:RecordTypeWorkoutUnit];
        [self.cloudManager addRecord:record withCompletionBlock:^(CKRecord * record){
            @strongify(self);
            [self cacheObject:unit];
            [self insertNewICloudRecord:record];
        }];
    }else{
        [self cacheObject:unit];
        [self saveToDisk];
    }
    
    return YES;
}

- (BOOL)deleteWorkoutUnits:(NSArray *)units{
    NSMutableArray * deleteUnits = [NSMutableArray arrayWithCapacity:8];
    NSMutableArray * deleteRecordIds = [NSMutableArray arrayWithCapacity:8];
    for(WorkoutUnit * unit in units){
        if ([self.internalObjects containsObject:unit]) {    
            [deleteUnits addObject:unit];

            if(unit.cloudRecord != nil){
                [deleteRecordIds addObject:unit.cloudRecord.recordID];
            }
        }
    }

    if (deleteUnits.count == 0) {
        return NO;
    }

    if ([self useICloudSchema]){
        @weakify(self);
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:deleteRecordIds];
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecord, NSArray * deletedRecordIds, NSError * operationError){
            @strongify(self);
            if (! operationError) {
                // 从 cloudRecords 中删除
                for(CKRecordID * recordId in deletedRecordIds){
                    [self removeICloudRecord:recordId];
                }                

                for(WorkoutUnit * unit in deleteUnits){
                    [self.internalObjects removeObject:unit];
                    [[unit workoutPlan] updateDynamicProperties];
                }                
                
                // TODO: 提示删除成功
                NSLog(@"删除 iCloud 记录成功");
            }else{
                // TODO: 提示删除失败
                NSLog(@"删除 iCloud 记录失败");
            }
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        [self.internalObjects removeObjectsInArray:deleteUnits];
        [self saveToDisk];

        // 更新动态信息
        for(WorkoutUnit * unit in deleteUnits){
            [[unit workoutPlan] updateDynamicProperties];
        }
    }    
    
    return YES;
}

// 更新
- (BOOL)updateWorkoutUnit:(WorkoutUnit *)unit{
    if (! [self.internalObjects containsObject:unit]) {
        return NO;
    }
    
    if ([self useICloudSchema]) {

        // 将内存数据的修改同步到 iCloud 对象上
        [unit updateICloudRecord:unit.cloudRecord];

        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[unit.cloudRecord] recordIDsToDelete:nil];
        modifyRecord.savePolicy = CKRecordSaveAllKeys;
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
            if (! operationError) {
                // TODO: 提示修改成功
                NSLog(@"修改 iCloud 记录成功");
                [[unit workoutPlan] updateDynamicProperties];
            }else{
                // TODO: 提示修改失败
                NSLog(@"修改 iCloud 记录失败");
            }
            
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{        
        [self saveToDisk];
        [[unit workoutPlan] updateDynamicProperties];
    }
    
    return YES;
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
