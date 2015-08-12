//
//  Workout.m
//  7MinutesWorkout
//
//  Created by maoyu on 15/7/10.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "Workout.h"

@implementation Workout

- (UIImage *)workoutPreviewImage{
    if (_profileBundleImage.length > 0) {
        UIImage * image = [UIImage imageNamed:_profileBundleImage];
        if (image == nil) {
            NSLog(@"训练单元图片不存在：%@, %@", _title, _profileBundleImage);
        }
        
        return image;
    }else{
        NSLog(@"训练单元图片未设置：%@", _title);
        return nil;
    }
}

- (NSString *)detailsContent{
    if (_detailsBundleFile.length > 0) {
        NSString * details = nil;
        
        NSString * dataFilePath = [[NSBundle mainBundle] pathForResource:_detailsBundleFile ofType:nil];
        if (dataFilePath) {
            details = [NSString stringWithContentsOfFile:dataFilePath encoding:NSUTF8StringEncoding error:NULL];
        }else{
            NSLog(@"训练单元描述文件不存在：%@, %@", _title, _detailsBundleFile);
        }
        
        return details;

    }else{
        NSLog(@"训练单元描述文件未设置：%@", _title);
        return nil;
    }
}

@end
