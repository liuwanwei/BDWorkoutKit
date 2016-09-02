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

// 标题，如：开合跳
@property (nonatomic, copy) NSString * title;

// 动作封面图
@property (nonatomic, copy) NSString * profileBundleImage;
// 动作描述 HTML 代码
@property (nonatomic, copy) NSString * detailsBundleFile;

// 标题声音文件名，如：开合跳
@property (nonatomic, copy) NSString * sound;

// 休息中预报下节的声音文件名，如：下一个动作，俯卧撑
@property (nonatomic, copy) NSString * nextSound;

// 转个方向提醒时的声音文件，如：换个方向（侧身平板支撑中用到）
@property (nonatomic, copy) NSString * reverseSound;

// 视频文件名，带动作教学视频的会用到
@property (nonatomic, copy) NSString * video;

// 没用到（不是 HiitType 中的 Cover）
@property (nonatomic, copy) NSString * cover;

// 休息时长
@property (nonatomic, copy) NSString * restTimeLength;

// 锻炼时长
@property (nonatomic, copy) NSString * workoutTimeLength;

- (UIImage *)workoutPreviewImage;
- (NSString *)detailsContent;

@end
