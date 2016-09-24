//
//  CacheManager.m
//  HiitWorkout
//
//  Created by sungeo on 16/9/22.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "CacheManager.h"
#import "WorkoutAppSetting.h"
#import "WorkoutPlanCache.h"
#import "WorkoutUnitCache.h"
#import "WorkoutResultCache.h"
#import <EXTScope.h>
#import <UIAlertController+Window.h>

@implementation CacheManager

+ (instancetype)sharedInstance{
    static CacheManager * sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            sSharedInstance = [[CacheManager alloc] init];
        }
    });
    
    return sSharedInstance;
}


- (void)loadAll{
    [[WorkoutResultCache sharedInstance] load];
    [[WorkoutUnitCache sharedInstance] load];
    [[WorkoutPlanCache sharedInstance] load];        
}

- (void)cleanAll{
    [[WorkoutResultCache sharedInstance] clean];
    [[WorkoutUnitCache sharedInstance] clean];
    [[WorkoutPlanCache sharedInstance] clean];
}

- (void)load{
    if ([[WorkoutAppSetting sharedInstance] useICloudSchema]){
        CKContainer * container = [[BDiCloudManager sharedInstance] container];
        [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * error){
            if (accountStatus == CKAccountStatusAvailable) {
                [self loadAll];
            }else{
                // TODO: 记录下面描述的情况
                // 并行查询时（plan，unit，result），很大几率会有 1-2 次失败在 accountStatusWithCompletionHandler 里            
                // accountStatus 会等于 CKAccountStatusNoAccount
                NSLog(@"查询数据出现 iCloud 账户不可用: %@", @(accountStatus));
            }
        }];
    }else{
        [self loadAll];
    }
}

// 判断 App 是否安装后首次运行
- (BOOL)firstLaunchFlag{
	static NSString * LaunchKey = @"firstLaunch";
	BOOL firstLaunch = NO;
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:LaunchKey];
    if (! value) {
        firstLaunch = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:LaunchKey];
    }	

    return firstLaunch;
}

// App 首次运行时，提示用户选择数据存储方案
- (void)chooseStorageScheme{
	
	BOOL firstLaunch = [self firstLaunchFlag];
    
    // 首次打开 App，并且 iCloud 可用时，提示用户是否使用 iCloud 存储数据
    if (firstLaunch && [[BDiCloudManager sharedInstance] iCloudAvailable]) {
		[self showChooseStorageSchemeView];
    }else{
        [self load];        
    }
}

// 显示对话框，让用户选择数据存储方案
- (void)showChooseStorageSchemeView{
    @weakify(self);
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择数据存储方案"
                                                                    message:@"建议您将数据保存在 iCloud 中，这样可以在每一台设备上访问到您的数据。"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * confirmAction = [UIAlertAction actionWithTitle:@"保存在 iCloud 上"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action){
                                                               @strongify(self);
                                                               [WorkoutAppSetting sharedInstance].useICloud = @(YES);
                                                               [self load];
                                                           }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"只保存在本机"
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action){
                                                              @strongify(self);
                                                              [WorkoutAppSetting sharedInstance].useICloud = @(NO);
                                                              [self load];
                                                          }];
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [alert show];
}

@end
