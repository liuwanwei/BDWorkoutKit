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

@interface BaseCache : NSObject <BDiCloudDelegate>

@property (nonatomic, weak) WorkoutAppSetting * appSetting;
@property (nonatomic, strong) BDiCloudManager * cloudManager;

// 从 iCloud 查询到的数据
@property (nonatomic, strong) NSArray * cloudRecords;

// 启动时加载数据
- (void)load;

// 从 iCloud 查询数据
- (void)queryFromICloud;
- (BOOL)removeICloudRecord:(CKRecordID *)recordID;

- (void)insertNewICloudRecord:(CKRecord *)record;

// 从磁盘加载数据
- (void)loadFromDisk;
// 保存数据到磁盘
- (void)saveToDisk;

@end
