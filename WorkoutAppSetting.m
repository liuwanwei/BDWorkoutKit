//
//  AppSetting.m
//  7分钟和 HIIT 用到的配置信息
//
//  自 “HIIT有氧训练” 1.3 版起，用户的配置信息不再保存到 iCloud，为的是降低软件复杂度
//  iCloud 只保存最重要的数据
//
//  Created by sungeo on 15/7/11.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "WorkoutAppSetting.h"
#import "WorkoutNotificationManager.h"
#import <TMCache.h>

static NSString * const AppSettingKey = @"AppSettingKey";

//static NSString * const NotificationOn = @"notificationOn";
//static NSString * const NotificationText = @"notificationText";
//static NSString * const NotificationTime = @"notificationTime";
//static NSString * const MuteSwitchOn = @"muteSwitchOn";
//static NSString * const VoiceType = @"voiceType";
//static NSString * const MusicName = @"musicName";
//static NSString * const useICloud = @"useICloud";

//static NSString * const WorkoutPlanId = @"workoutPlanId";
// Deprecated：从 1.3 版开始修改成 WorkoutPlanId
//static NSString * const HiitType = @"hiitType";

@implementation WorkoutAppSetting

+ (instancetype)sharedInstance{
    static WorkoutAppSetting * sSharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            TMDiskCache * cache = [TMDiskCache sharedCache];
            WorkoutAppSetting * object = (WorkoutAppSetting *)[cache objectForKey:AppSettingKey];
            if (object) {
                sSharedInstance = object;
                if (sSharedInstance.workoutPlanId == nil) {
                    // 1.3 将 hiitType 改为 workoutPlanId，缓存中如果存的是旧属性名字，赋值给新的
                    sSharedInstance.workoutPlanId = sSharedInstance.hiitType;
                }
                
                if (sSharedInstance.useICloud == nil) {
                    // 1.3 新增数据是否保存到 iCloud 标志（通过界面让用户选择的结果）
                    sSharedInstance.useICloud = @(NO);
                }
                
            }else{
                sSharedInstance = [[WorkoutAppSetting alloc] init];
            }
        }
    });
    
    return sSharedInstance;
}

- (instancetype)init{
    if (self = [super init]){
        _notificationOn = @(NO);
        _notificationTime = [NSDate date];
        _muteSwitchOn = @(NO);
        _voiceType = @(PromptVoiceTypeGirl);
        _musicName = @"轻快.mp3";
        _workoutPlanId = @(HiitTypeGirlElementary);
        _useICloud = @(NO);
    }
    
    return self;
}

- (void)syncDataToDisk{
    [[TMDiskCache sharedCache] setObject:self forKey:AppSettingKey];
}

- (void)startNotification{
    [[WorkoutNotificationManager sharedInstance] deployLocalNotification:_notificationTime];
}

- (void)stopNotification{
    [[WorkoutNotificationManager sharedInstance] cancelAllNotifications];
}


//- (void)registeriCloudSynchronizeService{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudStoreDidChange:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:[NSUbiquitousKeyValueStore defaultStore]];
//    
//    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
//}

/**
 *  处理 iCloud 的通知消息，更新 Key-Value 数据
 *
 *  @param notification 系统推送过来的 iCloud 数据变化通知，使用 userInfo 来判断哪个有修改
 */
//- (void)iCloudStoreDidChange:(NSNotification *)notification{
//    NSDictionary * userInfo = notification.userInfo;
//    if (userInfo == nil) {
//        return;
//    }
//    
//    BOOL resetNotification = NO;
//    id value;
//    if (( value = [userInfo valueForKey:NotificationOn]) != nil) {
//        if (![self.notificationOn isEqualToValue:value]) {
//            self.notificationOn = (NSNumber *)value;
//            resetNotification = YES;
//        }
//        
//    }else if(( value = [userInfo valueForKey:NotificationText]) != nil){
//        if (![self.notificationText isEqualToString:value]) {
//            self.notificationText = (NSString *)value;
//            resetNotification = YES;
//        }
//        
//    }else if(( value = [userInfo valueForKey:NotificationTime]) != nil){
//        if (![self.notificationTime isEqualToDate:value]) {
//            self.notificationTime = (NSDate *)value;
//            resetNotification = YES;
//        }
//        
//    }else if(( value = [userInfo valueForKey:MuteSwitchOn]) != nil){
//        self.muteSwitchOn = (NSNumber *)value;
//    }else if(( value = [userInfo valueForKey:VoiceType]) != nil){
//        self.voiceType = (NSNumber *)value;
//    }else if(( value = [userInfo valueForKey:MusicName]) != nil){
//        self.musicName = (NSString *)value;
//    }else if ((value = [userInfo valueForKey:WorkoutPlanId]) != nil){
//        self.workoutPlanId = (NSNumber *)value;
//    }else if((value = [userInfo valueForKey:HiitType]) != nil){
//        self.workoutPlanId = (NSNumber *)value;
//    }
//    
//    if (resetNotification) {
//        [self startNotification];
//    }
//    
//    NSLog(@"收到 iCloud 数据更新消息");
//}
@end
