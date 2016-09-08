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

@implementation WorkoutUnitCache{
    NSMutableArray * _internalWorkoutUnits;
}

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

- (void)loadFromDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:WorkoutUnitsKey];
    if (temp) {
        _internalWorkoutUnits = [temp mutableCopy];
    }else{
        _internalWorkoutUnits = [[NSMutableArray alloc] init];
    }
}

- (void)saveToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutUnits forKey:WorkoutUnitsKey];
}


- (WorkoutUnit *)newUnitForPlan:(NSNumber *)workoutPlanId{
    NSInteger maxId = 0;
    for (WorkoutUnit * unit in _internalWorkoutUnits) {
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
    if ([self.appSetting useICloudSchema]){
        @weakify(self);
        CKRecord * record = [unit newICloudRecord:RecordTypeWorkoutUnit];
        [self.cloudManager addRecord:record withCompletionBlock:^(CKRecord * record){
            @strongify(self);
            [self cacheWorkoutUnit:unit];
            [self insertNewICloudRecord:record];

            [[unit workoutPlan] updateDynamicProperties];
        }];
    }else{
        [self cacheWorkoutUnit:unit];
        [self saveToDisk];
    }
    
    return YES;
}

- (BOOL)cacheWorkoutUnit:(WorkoutUnit *)newUnit{
    for (WorkoutUnit * unit in _internalWorkoutUnits) {
        if ([unit.workoutPlanId isEqualToNumber:newUnit.workoutPlanId] &&
            [unit.objectId isEqualToNumber:newUnit.objectId]) {
            return NO;
        }
    }
    
    [_internalWorkoutUnits addObject:newUnit];
    return YES;
}


- (BOOL)deleteWorkoutUnits:(NSArray *)units{
    NSMutableArray * deleteUnits = [NSMutableArray arrayWithCapacity:8];
    NSMutableArray * deleteRecordIds = [NSMutableArray arrayWithCapacity:8];
    for(WorkoutUnit * unit in units){
        if ([_internalWorkoutUnits containsObject:unit]) {    
            [deleteUnits addObject:unit];

            if(unit.cloudRecord != nil){
                [deleteRecordIds addObject:unit.cloudRecord.recordID];
            }
        }
    }

    if (deleteUnits.count == 0) {
        return NO;
    }

    if ([self.appSetting useICloudSchema]){
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
                    [_internalWorkoutUnits removeObject:unit];
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
        [_internalWorkoutUnits removeObject:deleteUnits];
        [self saveToDisk];
    }    
    
    return YES;
}

// 更新
- (BOOL)updateWorkoutUnit:(WorkoutUnit *)unit{
    if (! [_internalWorkoutUnits containsObject:unit]) {
        return NO;
    }
    
    if ([self.appSetting useICloudSchema]) {

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

// 向服务器查询训练方案
- (void)queryFromICloud{    
    @weakify(self);
    [self.cloudManager queryRecordsWithCompletionBlock:^(NSArray * records){
        @strongify(self);
        // 缓存 iCloud 中查询到的所有记录
        self.cloudRecords = records;
        
        // 将 iCloud 记录转换成 WorkoutPlan 实例对象
        for (CKRecord * record in records) {
            WorkoutUnit * plan = [[WorkoutUnit alloc] initWithICloudRecord:record];
            [self cacheWorkoutUnit:plan];
        }
    }];
}

// 查询训练方案下属的所有训练单元
- (NSArray *)unitsForPlan:(WorkoutPlan *)plan{
    NSMutableArray * units = [[NSMutableArray alloc] init];
    for (WorkoutUnit * unit in _internalWorkoutUnits) {
        if ([unit.workoutPlanId isEqualToNumber:plan.objectId]) {
            [units addObject:unit];
        }
    }
    
    return [units copy];
}

- (NSInteger)totalUnitNumber{
    return _internalWorkoutUnits.count;
}

#pragma mark - BDiCloudDelegate
- (NSString *)recordType{
    return RecordTypeWorkoutUnit;
}

@end
