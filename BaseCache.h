//
//  BaseCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WorkoutAppSetting;
@class BDiCloudManager;
@class CKRecordID;

@interface BaseCache : NSObject

@property (nonatomic, weak) WorkoutAppSetting * appSetting;
@property (nonatomic, weak) BDiCloudManager * cloudManager;

// 从 iCloud 查询到的数据
@property (nonatomic, strong) NSArray * cloudRecords;

// 启动时加载数据
- (void)load;

// 从 iCloud 查询数据
- (void)queryFromICloud;
- (BOOL)removeICloudRecord:(CKRecordID *)recordID;

// 从磁盘加载数据
- (void)loadFromDisk;
// 保存数据到磁盘
- (void)saveToDisk;

@end
