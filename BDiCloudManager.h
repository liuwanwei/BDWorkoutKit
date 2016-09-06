//
//  WorkoutCloudManager.h
//  7MinutesWorkout
//
//  Created by sungeo on 15/8/5.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>

@protocol BDiCloudDelegate <NSObject>

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
- (void)addRecord:(CKRecord *)record;

// 直接通过传入 sel 处理接收到的数据，不用通过 delegate
- (void)recordsWithType:(NSString *)recordType from:(id)caller action:(SEL)sel;

@end
