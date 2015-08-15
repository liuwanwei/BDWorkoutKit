//
//  HiitType.h
//  HiitWorkout
//
//  Created by maoyu on 15/7/29.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "BaseModel.h"

@interface HiitType : BaseModel

@property (nonatomic, copy) NSNumber * objectId;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * cover;
@property (nonatomic, copy) NSString * configFile;
@property (nonatomic, copy) NSString * equipment;
@property (nonatomic, copy) NSString * detailsBundleFile;
@property (nonatomic, copy) NSString * headerImage;
@property (nonatomic, copy) NSString * briefDescription;

@end
