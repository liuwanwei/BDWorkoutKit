//
//  HiitType.h
//  HiitWorkout
//
//  属性跟 HiitTypes.json 文件中的数组元素相对应
//  Created by maoyu on 15/7/29.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "BaseModel.h"

@interface WorkoutPlan : BaseModel

@property (nonatomic, copy) NSNumber * objectId;

// 训练方案的名字，如：徒手训练·初级
@property (nonatomic, copy) NSString * title;
// 训练方案名字简介，显示在运动主页，如：徒手·初级
@property (nonatomic, copy) NSString * briefDescription;
// 是否需要器材，显示在训练方案列表中，如：无限器材，约7分钟
@property (nonatomic, copy) NSString * equipment;

// 显示在显示方案列表中的封面图
@property (nonatomic, copy) NSString * cover;
// 训练方案详情页顶部的背景图，如：hiit_intro_bg.jpg
@property (nonatomic, copy) NSString * headerImage;

// 训练单元定义文件名字，如：Workouts-Girl-Primary
@property (nonatomic, copy) NSString * configFile;

// 训练方案的整体描述文件名字，如：desc-hiit-girl-primary.txt
@property (nonatomic, copy) NSString * detailsBundleFile;

@end
