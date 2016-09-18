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
    [self loadFromDisk];

    if ([self useICloudSchema]) {
        [self queryFromICloud];
    }
}

- (void)queryFromICloud{    
    @weakify(self);
    [self.cloudManager queryRecordsWithCompletionBlock:^(NSArray * records){
        @strongify(self);

        NSInteger count = [records count];
        NSLog(@"查询到 %@ 条 %@ 记录", @(count), [self recordType]);

        // 缓存 iCloud 中查询到的所有记录
        self.cloudRecords = records;
        
        BOOL dirty = NO;
        // 将 iCloud 记录转换成 WorkoutPlan 实例对象
        for (CKRecord * record in records) {
            BDiCloudModel * model = [self newCacheObjectWithICloudRecord:record];
            if([self cacheObject:model]){
                dirty = YES;
            }
        }
        
        if (dirty) {
            [self saveToDisk];
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
    NSMutableArray * mutable = [NSMutableArray arrayWithCapacity:64];
    for(BDiCloudModel * model in _internalObjects){
        // 判断对象的删除标志，在 iCloud 环境下，排除需要从 iCloud 删除的数据
        if (model.needDeleteFromICloud == nil || ![model.needDeleteFromICloud boolValue]){
            [mutable addObject:model];
        }
    }
    return [mutable copy];
}

// 将新建的对象添加到内存中
- (BOOL)cacheObject:(BDiCloudModel *)newObject{
    for (id obj in _internalObjects) {
        if ([obj isEqual:newObject]) {
            NSLog(@"添加失败：重复的 %@ 记录 [%@]", [self recordType], newObject.objectId);
            return NO;
        }
    }
    
    [self.internalObjects addObject:newObject];
    return YES;
}

// 添加一个对象，会自动判断是否需要保存到 iCloud
- (BOOL)addObject:(BDiCloudModel *)newObject{
    [self cacheObject:newObject];
    [self saveToDisk];

    if ([self useICloudSchema]) {
        newObject.needSaveToICloud = @(YES);
        CKRecord * record = [newObject newICloudRecord:[self recordType]];
        @weakify(self);
        [self.cloudManager addRecord:record withCompletionBlock:^(CKRecord * record){
            @strongify(self);
            [self insertNewICloudRecord:record];
            newObject.needSaveToICloud = @(NO);
        }];
    }
    
    return YES;
}

// 检查内存中是否存在目标对象
- (BOOL)containsObject:(BDiCloudModel *)object{
    if ([_internalObjects containsObject:object]) {
        return YES;
    }else{
        return NO;
    }
}

// 批量删除内存数据
- (void)deleteInternalObjects:(NSArray *)objects{
    for(BDiCloudModel * object in objects){
        [self.internalObjects removeObject:object];
    }                
}

// 批量删除 iCloud 数据缓存
- (void)deleteICloudRecords:(NSArray *)recordIds{
    for(CKRecordID * recordId in recordIds){
        [self removeICloudRecord:recordId];
    }             
}

// 删除训练方案入口
- (BOOL)deleteObjects:(NSArray *)objects{
    NSMutableArray * deleteObjects = [NSMutableArray arrayWithCapacity:8];
    NSMutableArray * deleteRecordIds = [NSMutableArray arrayWithCapacity:8];
    for(BDiCloudModel * object in objects){
        if ([self.internalObjects containsObject:object]) {                
            if ([self useICloudSchema]){
                // 给内存对象打上需要删除标记，后续查询将不会返回已删除的数据
                object.needDeleteFromICloud = @(YES);
                [deleteRecordIds addObject:object.cloudRecord.recordID];
            }else{
                [deleteObjects addObject:object];
            }            
        }
    }

    if ([self useICloudSchema]) {
        @weakify(self);
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:deleteRecordIds];
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecord, NSArray * deletedRecordIds, NSError * operationError){
            @strongify(self);
            if (! operationError) {
                // 从内存中删除
                [self deleteInternalObjects:deleteObjects];

                // 从 cloudRecords 中删除
                [self deleteICloudRecords:deleteRecordIds];
            }

            [self objectsDeleted:objects withError:operationError];
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        // 从内存中删除
        [self deleteInternalObjects:deleteObjects];
        [self saveToDisk];
        [self objectsDeleted:deleteObjects withError:nil];
    }
    
    return YES;
}

- (BOOL)updateObject:(BDiCloudModel *)object{
    if (! [self containsObject:object]){
        return NO;
    }

    object.needSaveToICloud = @(YES);
    
    if ([self useICloudSchema]) {
        // 将内存数据的修改同步到 iCloud 对象上
        [object updateICloudRecord:object.cloudRecord];
        NSArray * recordsId = @[object.cloudRecord];
        CKModifyRecordsOperation * modifyRecord = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordsId recordIDsToDelete:nil];
        modifyRecord.savePolicy = CKRecordSaveAllKeys;
        modifyRecord.qualityOfService = NSQualityOfServiceUserInitiated;
        modifyRecord.modifyRecordsCompletionBlock = ^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){

            if (! operationError){
                // iCLoud 更新成功，更新内存标志
                object.needSaveToICloud = @(NO);
            }

            [self objectUpdated:object withError:operationError];
        };
        [self.cloudManager.privateDatabase addOperation:modifyRecord];
    }else{
        // 直接同步到磁盘上
        [self saveToDisk];
        [self objectUpdated:object withError:nil];
    }
    
    return YES;
}

- (void)showAlertWithMessage:(NSString *)message{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"错误"
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * action;
    action = [UIAlertAction actionWithTitle:@"确定"
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action){
                                    }];
    [alert addAction:action];

    // TODO: 看怎么在主 UI 线程显示出来    
}

// 派生类必须重载的接口

- (void)objectsDeleted:(NSArray *)objects withError:(NSError *)operationError{
}

- (void)objectUpdated:(BDiCloudModel *)object withError:(NSError *)error{
}

- (NSString *)cacheKey{
    @throw [NSException exceptionWithName:NSGenericException 
        reason:@"派生类必须重载 BaseCache 中声明的 cacheKey 函数" 
        userInfo:nil];   
}

// 从 iCloud 查询到的 CKRecord 中提取数据，转化成对应内存对象
// TODO: 理应有动态创建的方法，直接知道子类的名字，直接初始化对象
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
