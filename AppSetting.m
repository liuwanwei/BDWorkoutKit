//
//  AppSetting.m
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/11.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "AppSetting.h"
#import "WorkoutNotificationManager.h"
#import <TMCache.h>

static NSString * const AppSettingKey = @"AppSettingKey";

static NSString * const NotificationOn = @"notificationOn";
static NSString * const NotificationText = @"notificationText";
static NSString * const NotificationTime = @"notificationTime";
static NSString * const MuteSwitchOn = @"muteSwitchOn";
static NSString * const VoiceType = @"voiceType";
static NSString * const MusicName = @"musicName";
static NSString * const HiitType = @"hiitType";

@implementation AppSetting

+ (instancetype)sharedInstance{
    static AppSetting * sSharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sSharedInstance == nil) {
            TMDiskCache * cache = [TMDiskCache sharedCache];
            AppSetting * object = (AppSetting *)[cache objectForKey:AppSettingKey];
            if (object) {
                sSharedInstance = object;
            }else{
                sSharedInstance = [[AppSetting alloc] init];
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
        _hiitType = @(HiitTypeFemaleElementary);
    }
    
    return self;
}

- (void)registeriCloudSynchronizeService{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudStoreDidChange:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:[NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

/**
 *  处理 iCloud 的通知消息，更新 Key-Value 数据
 *
 *  @param notification 系统推送过来的 iCloud 数据变化通知，使用 userInfo 来判断哪个有修改
 */
- (void)iCloudStoreDidChange:(NSNotification *)notification{
    NSDictionary * userInfo = notification.userInfo;
    if (userInfo == nil) {
        return;
    }
    
    BOOL resetNotification = NO;
    id value;
    if (( value = [userInfo valueForKey:NotificationOn]) != nil) {
        if (![self.notificationOn isEqualToValue:value]) {
            self.notificationOn = (NSNumber *)value;
            resetNotification = YES;
        }
        
    }else if(( value = [userInfo valueForKey:NotificationText]) != nil){
        if (![self.notificationText isEqualToString:value]) {
            self.notificationText = (NSString *)value;
            resetNotification = YES;
        }
        
    }else if(( value = [userInfo valueForKey:NotificationTime]) != nil){
        if (![self.notificationTime isEqualToDate:value]) {
            self.notificationTime = (NSDate *)value;
            resetNotification = YES;
        }
        
    }else if(( value = [userInfo valueForKey:MuteSwitchOn]) != nil){
        self.muteSwitchOn = (NSNumber *)value;
    }else if(( value = [userInfo valueForKey:VoiceType]) != nil){
        self.voiceType = (NSNumber *)value;
    }else if(( value = [userInfo valueForKey:MusicName]) != nil){
        self.musicName = (NSString *)value;
    }else if ((value = [userInfo valueForKey:HiitType]) != nil){
        self.hiitType = (NSNumber *)value;
    }
    
    if (resetNotification) {
        [self startNotification];
    }
    
    NSLog(@"收到 iCloud 数据更新消息");
}

- (void)syncDataToDisk{
    [[TMDiskCache sharedCache] setObject:self forKey:AppSettingKey];
    
    // 存储到 iCloud 中
//    NSUbiquitousKeyValueStore * store = [NSUbiquitousKeyValueStore defaultStore];
//    [store setValue:_notificationOn forKey:NotificationOn];
//    [store setValue:_notificationText forKey:NotificationText];
//    [store setValue:_notificationTime forKey:NotificationTime];
//    [store setValue:_muteSwitchOn forKey:MuteSwitchOn];
//    [store setValue:_voiceType forKey:VoiceType];
//    [store setValue:_musicName forKey:MusicName];
//    [store setValue:_hiitType forKey:HiitType];
}

- (void)startNotification{
    [[WorkoutNotificationManager sharedInstance] deployLocalNotification:_notificationTime];
}

- (void)stopNotification{
    [[WorkoutNotificationManager sharedInstance] cancelAllNotifications];
}

@end
