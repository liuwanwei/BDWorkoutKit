//
//  WorkoutCloudManager.h
//  7MinutesWorkout
//
//  Created by sungeo on 15/8/5.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>

@protocol WorkoutiCloudDelegate <NSObject>

- (void)successfullySavedRecord:(CKRecord *)record;
- (void)didReceiveWorkoutResults:(NSArray *)results;

@end

@interface WorkoutCloudManager : NSObject

@property (nonatomic, assign) id<WorkoutiCloudDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)queryAllRecords;
- (void)addRecord:(CKRecord *)record;

@end
