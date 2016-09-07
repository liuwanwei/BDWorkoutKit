//
//  WorkoutCloudManager.h
//  7MinutesWorkout
//
//  Created by sungeo on 15/8/5.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>

// 查询对象成功后执行的 block
typedef void (^RecordsReceivedBLock)(NSArray * records);

// 保存对象到 iCloud 成功后执行的 block
typedef void (^RecordSavedBlock)(CKRecord * record);

@protocol BDiCloudDelegate <NSObject>

@required
- (NSString *)recordType;

@optional
- (void)successfullySavedRecord:(CKRecord *)record;
- (void)didReceiveWorkoutResults:(NSArray *)results;

@end

@interface BDiCloudManager : NSObject

@property (nonatomic, assign) id<BDiCloudDelegate> delegate;

+ (instancetype)sharedInstance;

// 获取设备的 iCloud 可用状态，必须在主线程中调用
- (void)fetchICloudToken;

// 返回设备的 iCloud 可用状态
- (BOOL)iCloudAvailable;

- (void)queryRecordsWithType:(NSString *)recordType;
// 用 delete 方式的添加记录
- (void)addRecord:(CKRecord *)record;
// 用 block 方式添加记录
- (void)addRecord:(CKRecord *)record withCompletionBlock:(RecordSavedBlock)block;
// 用 block 方式查询数据
- (void)queryRecordsWithCompletionBlock:(RecordsReceivedBLock)block;

@end
