//
//  BaseCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDiCloudManager.h"

@class WorkoutAppSetting;
@class CKRecordID;
@class CKRecord;
@class BDiCloudModel;

@interface BaseCache : NSObject <BDiCloudManagerDelegate>

@property (nonatomic, weak) WorkoutAppSetting * appSetting;
@property (nonatomic, strong) BDiCloudManager * cloudManager;

// 内存对象存储位置（外部接口不要访问）
@property (nonatomic, strong) NSMutableArray * internalObjects;

// 内存中缓存的对象的不可修改版本
@property (nonatomic, strong, readonly) NSArray * cachedObjects;

// 从 iCloud 查询到的数据
@property (nonatomic, strong) NSArray * cloudRecords;

// 启动时加载数据
- (void)load;

// 虚函数，需要派生类重载
- (BDiCloudModel *)newCacheObjectWithICloudRecord:(CKRecord *)record;

// 添加新对象总入口
- (BOOL)addObject:(BDiCloudModel *)newObject;

// 将对象加入内存缓存
- (BOOL)cacheObject:(BDiCloudModel *)newObject;

// 保存数据到本地缓存时使用的键值，派生类必须重载该函数
- (NSString *)cacheKey;

// 判断是否启用了 iCloud 作为存储仓库
- (BOOL)useICloudSchema;

// 从 iCloud 查询数据
- (void)queryFromICloud;
- (void)insertNewICloudRecord:(CKRecord *)record;
- (BOOL)removeICloudRecord:(CKRecordID *)recordID;

// 从磁盘加载数据
- (void)loadFromDisk;
// 保存数据到磁盘
- (void)saveToDisk;

@end
