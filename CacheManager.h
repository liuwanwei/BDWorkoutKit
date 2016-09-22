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

- (void)showQuestionInViewController:(UIViewController *)vc;

- (void)askForStorageScheme:(UIViewController *)vc;

@end
