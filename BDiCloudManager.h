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

- (void)queryRecordsWithType:(NSString *)recordType;
- (void)addRecord:(CKRecord *)record;

@end
