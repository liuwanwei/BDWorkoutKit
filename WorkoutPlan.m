//
//  HiitType.m
//  HiitWorkout
//
//  Created by maoyu on 15/7/29.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "WorkoutPlan.h"

// iCloud 上数据表名字
static NSString * const RecordTypeWorkoutPlan = @"WorkoutPlan";

// iCloud 上数据表字段名字
//static NSString * const ObjectId = @"objectId";
static NSString * const Title = @"title";
static NSString * const Type = @"type";
static NSString * const Cover = @"cover";
static NSString * const HeaderImage = @"headerImage";

@implementation WorkoutPlan

- (instancetype)initWithICloudRecord:(CKRecord *)record{
    if (self = [super initWithICloudRecord:record]) {
        // 从 CKRecord 生成数据
        _title = [record objectForKey:Title];
        _type = [record objectForKey:Type];
        _cover = [record objectForKey:Cover];
        _headerImage = [record objectForKey:HeaderImage];
    }
    
    return self;
}

- (CKRecord *)iCloudRecord{
    CKRecord * record = [super baseICloudRecordWithType:RecordTypeWorkoutPlan];

    [record setObject:self.type forKey:Type];
    [record setObject:self.title forKey:Title];
    [record setObject:self.cover forKey:Cover];
    [record setObject:self.headerImage forKey:HeaderImage];
    
    return record;
}

- (BOOL)isBuiltInPlan{
    NSInteger type = [self.type integerValue];
    if (type != PlanTypeHIIT) {
        return true;
    }
    
    return false;
}

@end
