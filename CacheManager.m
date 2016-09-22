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


- (void)loadAllTypeOfRecords{
    [[WorkoutResultCache sharedInstance] load];
    [[WorkoutUnitCache sharedInstance] load];
    [[WorkoutPlanCache sharedInstance] load];        
}

- (void)load{
    if ([[WorkoutAppSetting sharedInstance] useICloudSchema]){
        CKContainer * container = [[BDiCloudManager sharedInstance] container];
        [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * error){
            if (accountStatus == CKAccountStatusAvailable) {
                [self loadAllTypeOfRecords];
            }else{
                // TODO: 记录下面描述的情况
                // 并行查询时（plan，unit，result），很大几率会有 1-2 次失败在 accountStatusWithCompletionHandler 里            
                // accountStatus 会等于 CKAccountStatusNoAccount
                NSLog(@"查询数据出现 iCloud 账户不可用: %@", @(accountStatus));
            }
        }];
    }else{
        [self loadAllTypeOfRecords];
    }
}

/**
 *
 * 检查 App 是否安装后首次运行
 *
 */

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

- (void)showQuestionInViewController:(UIViewController *)vc{
	@weakify(self);
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择数据存储方案"
	                                                                message:@"建议您将数据保存在 iCloud 中，这样可以在每一台设备上访问到您的数据。"
	                                                         preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction * confirmAction = [UIAlertAction actionWithTitle:@"保存在 iCloud 上"
	                                                         style:UIAlertActionStyleDefault
	                                                       handler:^(UIAlertAction * action){
	                                                           @strongify(self);
	                                                           WorkoutAppSetting * setting = [WorkoutAppSetting sharedInstance];
	                                                           setting.useICloud = @(YES);
	                                                           [self load];
	                                                       }];
	UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"只保存在本机"
	                                                        style:UIAlertActionStyleCancel
	                                                      handler:^(UIAlertAction * action){
	                                                          @strongify(self);
	                                                          WorkoutAppSetting * setting = [WorkoutAppSetting sharedInstance];
	                                                          setting.useICloud = @(NO);
	                                                          [self load];
	                                                      }];
	[alert addAction:confirmAction];
	[alert addAction:cancelAction];
	
	[vc presentViewController:alert animated:YES completion:nil];
}

- (void)askForStorageScheme:(UIViewController *)vc{
	
	BOOL firstLaunch = [self firstLaunchFlag];
    
    // 首次打开 App，并且 iCloud 可用时，提示用户是否使用 iCloud 存储数据
    if (firstLaunch && [[BDiCloudManager sharedInstance] iCloudAvailable]) {
		[self showQuestionInViewController:vc];
    }else{
        [self load];        
    }
}

@end
