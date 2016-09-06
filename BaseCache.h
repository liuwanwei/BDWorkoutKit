//
//  BaseCache.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/6.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WorkoutAppSetting;
@class BDiCloudManager;

@interface BaseCache : NSObject

@property (nonatomic, weak) WorkoutAppSetting * appSetting;
@property (nonatomic, weak) BDiCloudManager * cloudManager;

// 启动时加载数据
- (void)load;

// 从 iCloud 查询数据
- (void)queryFromICloud;

- (void)loadFromDisk;
- (void)saveToDisk;

@end
