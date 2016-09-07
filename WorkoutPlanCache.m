//
//  WorkoutPlanCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "WorkoutPlanCache.h"
#import "WorkoutPlan.h"
#import "WorkoutAppSetting.h"
#import "BDiCloudManager.h"
#import "BDFoundation.h"
#import <MJExtension.h>
#import <CloudKit/CloudKit.h>
#import <TMCache.h>

// iCloud 中使用的训练方案存储类型
static NSString * const RecordTypeWorkoutPlan = @"WorkoutPlan";
// TMCache 使用的训练方案存储键值
static NSString * const WorkoutPlansKey = @"WorkoutPlansKey";

@implementation WorkoutPlanCache{
    NSMutableArray * _internalWorkoutPlans;
}

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

// 从本地加载自定义训练方案
- (void)loadFromDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:WorkoutPlansKey];
    if (temp) {
        _internalWorkoutPlans = [temp mutableCopy];
    }else{
        _internalWorkoutPlans = [[NSMutableArray alloc] init];
    }
}

// 数据缓存到本地
- (void)saveToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutPlans forKey:WorkoutPlansKey];
}

- (NSArray *)workoutPlans{
    return [_internalWorkoutPlans copy];
}

- (WorkoutPlan *)newWorkoutPlan:(WorkoutPlanType)type{
    NSInteger maxId = 10; // 自定义训练方案 Id 从 10 开始
    for (WorkoutPlan * plan in _internalWorkoutPlans) {
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

- (BOOL)addWorkoutPlan:(WorkoutPlan *)workoutPlan{
    if ([self.appSetting useICloudSchema]) {
        [self.cloudManager addRecord:[workoutPlan iCloudRecord]];
    }else{
        [self cacheWorkoutPlan:workoutPlan];
    }
    
    return YES;
}

- (BOOL)cacheWorkoutPlan:(WorkoutPlan *)workoutPlan{
    for (WorkoutPlan * obj in _internalWorkoutPlans) {
        if ([obj.objectId isEqualToNumber:workoutPlan.objectId]) {
            return NO;
        }
    }
    
    [_internalWorkoutPlans addObject:workoutPlan];
    return true;
}

- (BOOL)deleteWorkoutPlan:(WorkoutPlan *)plan{
    if (! [_internalWorkoutPlans containsObject:plan]) {
        return NO;
    }
    
    if ([self.appSetting useICloudSchema]) {
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:@[plan.cloudRecord.recordID]];
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecord, NSArray * deletedRecordIds, NSError * operationError){
            if (! operationError) {
                [_internalWorkoutPlans removeObject:plan];
                // 从 cloudRecords 中删除
                [self removeICloudRecord:deletedRecordIds[0]];
                
                // TODO: 提示删除成功
                NSLog(@"删除 iCloud 记录成功");
            }else{
                // TODO: 提示删除失败
                NSLog(@"删除 iCloud 记录失败");
            }
        };
        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:modifyRecord];
    }else{
        [_internalWorkoutPlans removeObject:plan];
        [self saveToDisk];
    }
    
    return YES;
}

- (BOOL)updateWorkoutPlan:(WorkoutPlan *)plan{
    if (! [_internalWorkoutPlans containsObject:plan]) {
        return false;
    }
    
    if ([self.appSetting useICloudSchema]) {
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
        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:modifyRecord];
    }else{
        [self saveToDisk];
    }
    
    return true;
}

// 向服务器查询训练方案
- (void)queryFromICloud{
    [self.cloudManager recordsWithType:RecordTypeWorkoutPlan from:self action:@selector(handleReceivedRecords:)];
}

// 处理查询到的数据
- (void)handleReceivedRecords:(NSArray *)records{
    // 缓存 iCloud 中查询到的所有记录
    self.cloudRecords = records;
    
    // 将 iCloud 记录转换成 WorkoutPlan 实例对象
    for (CKRecord * record in records) {
        WorkoutPlan * plan = [[WorkoutPlan alloc] initWithICloudRecord:record];
        [[WorkoutPlanCache sharedInstance] cacheWorkoutPlan:plan];
    }
}


@end
