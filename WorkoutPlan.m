//
//  HiitType.m
//  HiitWorkout
//
//  Created by maoyu on 15/7/29.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "WorkoutPlan.h"

@implementation WorkoutPlan

- (CKRecord *)iCloudRecordObject{
    // TODO: 返回桥梁性质的 CKRecord 对象
    return nil;
}

- (BOOL)isBuiltInPlan{
    NSInteger type = [self.type integerValue];
    if (type != PlanTypeHIIT) {
        return true;
    }
    
    return false;
}

@end
