//
//  Workout.h
//  7MinutesWorkout
//
//  Created by maoyu on 15/7/10.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "BaseModel.h"
#import <UIKit/UIKit.h>

@interface Workout : BaseModel

@property (nonatomic, copy) NSString * objectId;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * profileBundleImage;
@property (nonatomic, copy) NSString * detailsBundleFile;
@property (nonatomic, copy) NSString * sound;   // 标题声音文件名
@property (nonatomic, copy) NSString * nextSound;   // 休息中预报下节的声音文件名
@property (nonatomic, copy) NSString * reverseSound; // 反向提醒时的声音文件
@property (nonatomic, copy) NSString * video;   // 视频文件名
@property (nonatomic, copy) NSString * cover;   // 封面图片名字
@property (nonatomic, copy) NSString * restTimeLength;  // 休息时长
@property (nonatomic, copy) NSString * workoutTimeLength;   // 锻炼时长

- (UIImage *)workoutPreviewImage;
- (NSString *)detailsContent;

@end
