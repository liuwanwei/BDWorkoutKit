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

@implementation WorkoutResultCache{
    NSMutableArray * _internalWorkoutResults;
}

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

// 从本地加载训练结果
- (void)loadFromDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:WorkoutResultsKey];
    if (temp) {
        _internalWorkoutResults = [temp mutableCopy];
    }else{
        _internalWorkoutResults = [[NSMutableArray alloc] init];
    }
}

- (void)saveToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalWorkoutResults forKey:WorkoutResultsKey];
}


- (void)queryFromICloud{
    @weakify(self);
    [self.cloudManager queryRecordsWithCompletionBlock:^(NSArray * records){
        @strongify(self);
        // 缓存 iCloud 中查询到的所有记录
        self.cloudRecords = records;        
        for (CKRecord * ckRecord in records) {
            if ([ckRecord.recordType isEqualToString:RecordTypeWorkoutResult]) {
                WorkoutResult * workoutResult = [[WorkoutResult alloc] initWithICloudRecord:ckRecord];
                [self cacheWorkoutResult: workoutResult];
            }
        }
    }];
}

/**
 *  函数特点请参考 dailyWeights
 *
 *  @return 不可修改的训练结果数组
 */
- (NSArray *)workoutResults{
    return [_internalWorkoutResults copy];
}

- (BOOL)addWorkoutResult:(WorkoutResult *)result{
    if ([self useICloudSchema]) {
        @weakify(self);
        CKRecord * record = [result newICloudRecord:RecordTypeWorkoutResult];
        [self.cloudManager addRecord:record withCompletionBlock:^(CKRecord * record){
            @strongify(self);
            [self cacheWorkoutResult:result];
            [self insertNewICloudRecord:record];            
        }];
    }else{
        [self cacheWorkoutResult:result];
        [self saveToDisk];
    }
    
    return YES;
}

- (BOOL)cacheWorkoutResult:(WorkoutResult *)result{
    for (WorkoutResult * result in _internalWorkoutResults) {
        // 防止向缓存重复添加相同的记录
        if ([result.workoutTime isEqualToDate:result.workoutTime]) {
            return NO;
        }
    }
    
    [_internalWorkoutResults addObject:result];
    
    return YES;
}

#pragma mark - BDiCloudDelegate

- (NSString *)recordType{
    return RecordTypeWorkoutResult;
}

@end
