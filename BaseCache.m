//
//  BaseCache.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "BaseCache.h"
#import "BDiCloudManager.h"
#import "WorkoutAppSetting.h"
#import "BDiCloudModel.h"
#import <TMCache.h>
#import <EXTScope.h>

@implementation BaseCache

- (instancetype)init{
    if (self = [super init]) {
        _cloudManager = [[BDiCloudManager alloc] init];
        _cloudManager.delegate = self;
        _appSetting = [WorkoutAppSetting sharedInstance];
        _internalObjects = [NSMutableArray arrayWithCapacity:12];
    }
    
    return self;
}

// 对 useICloud 属性添加一层易于访问的封装
- (BOOL)useICloudSchema{
    return [self.appSetting.useICloud boolValue];
}

- (void)load{
    if ([self useICloudSchema]) {
        [self queryFromICloud];
    }else{
        [self loadFromDisk];
    }
}

- (void)queryFromICloud{
    @weakify(self);
    [self.cloudManager queryRecordsWithCompletionBlock:^(NSArray * records){
        @strongify(self);
        // 缓存 iCloud 中查询到的所有记录
        self.cloudRecords = records;
        
        // 将 iCloud 记录转换成 WorkoutPlan 实例对象
        for (CKRecord * record in records) {
            BDiCloudModel * model = [self newCacheObjectWithICloudRecord:record];
            [self cacheObject:model];
        }
    }];
}

// 删除本地旧的 iCloud 记录：一般用在删除训练方案、单元、结果后
- (BOOL)removeICloudRecord:(CKRecordID *)recordID{
    if (_cloudRecords && _cloudRecords.count > 0) {
        NSMutableArray * records = [_cloudRecords mutableCopy];
        for (CKRecord * record in records) {
            if (record.recordID == recordID) {
                [records removeObject:record];
                _cloudRecords = [records copy];
                return YES;
            }
        }
    }
    
    return NO;
}

// 添加新的 iCloud 记录到本地：一般用在新建训练方案、单元、结果时
- (void)insertNewICloudRecord:(CKRecord *)record{
    if (_cloudRecords) {
        NSMutableArray * mutable = [_cloudRecords mutableCopy];
        [mutable addObject:record];
        _cloudRecords = [mutable copy];
    }else{
        _cloudRecords = [NSArray arrayWithObject:record];
    }
}

// 从本地加载自定义训练方案
- (void)loadFromDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    // 初始化训练记录数据
    NSArray * temp = (NSArray *)[cache objectForKey:[self cacheKey]];
    if (temp) {
        _internalObjects = [temp mutableCopy];
    }else{
        _internalObjects = [[NSMutableArray alloc] init];
    }    
}

// 数据缓存到本地
- (void)saveToDisk{
    TMDiskCache * cache = [TMDiskCache sharedCache];
    [cache setObject:_internalObjects forKey:[self cacheKey]];
}

// 返回内部存储对象数组的不可修改版本
- (NSArray *)cachedObjects{
    return [_internalObjects copy];
}

// 将新建的对象添加到内存缓存中
- (BOOL)cacheObject:(BDiCloudModel *)newObject{
    for (id obj in _internalObjects) {
        if ([obj isEqual:newObject]) {
            return NO;
        }
    }
    
    [self.internalObjects addObject:newObject];
    return true;
}

- (BOOL)addObject:(BDiCloudModel *)newObject{
    if ([self useICloudSchema]) {
        CKRecord * record = [newObject newICloudRecord:[self recordType]];
        @weakify(self);
        [self.cloudManager addRecord:record withCompletionBlock:^(CKRecord * record){
            @strongify(self);
            [self cacheObject:newObject];
            [self insertNewICloudRecord:record];
        }];
    }else{
        [self cacheObject:newObject];
        [self saveToDisk];
    }
    
    return YES;
}

- (BOOL)containsObject:(BDiCloudModel *)object{
    if ([_internalObjects containsObject:object]) {
        return YES;
    }else{
        return NO;
    }
}

// 删除训练方案入口
- (BOOL)deleteObject:(BDiCloudModel *)object{    
    if(! [self containsObject:object]){
        return NO;
    }

    if ([self useICloudSchema]) {
        @weakify(self);
        NSArray * recordsId = @[object.cloudRecord.recordID];
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:recordsId];
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecord, NSArray * deletedRecordIds, NSError * operationError){
            @strongify(self);
            if (! operationError) {
                [self.internalObjects removeObject:object];
                // 从 cloudRecords 中删除
                [self removeICloudRecord:deletedRecordIds[0]];
            }

            [self objectDeleted:object withError:operationError];
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        [self.internalObjects removeObject:object];
        [self saveToDisk];

        [self objectDeleted:object withError:nil];
    }
    
    return YES;
}

- (BOOL)updateObject:(BDiCloudModel *)object{
    if (! [self containsObject:object]){
        return NO;
    }
    
    if ([self useICloudSchema]) {
        // 将内存数据的修改同步到 iCloud 对象上
        [object updateICloudRecord:object.cloudRecord];
        NSArray * recordsId = @[object.cloudRecord];
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordsId recordIDsToDelete:nil];
        modifyRecord.savePolicy = CKRecordSaveAllKeys;
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
            [self objectUpdated:object withError:operationError];
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        [self saveToDisk];
        [self objectUpdated:object withError:nil];
    }
    
    return YES;
}

// 派生类必须重载的接口

- (void)objectDeleted:(BDiCloudModel *)object withError:(NSError *)operationError{
}

- (void)objectUpdated:(BDiCloudModel *)object withError:(NSError *)error{
}

- (NSString *)cacheKey{
    @throw [NSException exceptionWithName:NSGenericException 
        reason:@"派生类必须重载 BaseCache 中声明的 cacheKey 函数" 
        userInfo:nil];   
}

- (BDiCloudModel *)newCacheObjectWithICloudRecord:(CKRecord *)record{
    @throw [NSException exceptionWithName:NSGenericException 
        reason:@"派生类必须重载 BaseCache 中声明的 newCacheObjectWithICloudRecord 函数" 
        userInfo:nil];       
}

#pragma mark - BDiCloudManagerDelegate
- (NSString *)recordType{
    @throw [NSException exceptionWithName:NSGenericException 
        reason:@"派生类必须重载 BaseCache 中声明的 recordType 函数" 
        userInfo:nil];
}


@end
