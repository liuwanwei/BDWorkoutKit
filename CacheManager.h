//
//  CacheManager.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/22.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CacheManager : NSObject

+ (instancetype)sharedInstance;

- (void)chooseStorageScheme;

- (void)showChooseStorageSchemeView;

// 清空缓存的数据
- (void)cleanAll;

// 加载（查询）所有数据
- (void)loadAll;

@end
