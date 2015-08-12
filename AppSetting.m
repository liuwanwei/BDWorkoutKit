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
    }
    
    return self;
}

- (void)registeriCloudSynchronizeService{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudStoreDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:[NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] setString:@"fixed" forKey:@"testKey"];
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
    if (( value = [userInfo objectForKey:NotificationOn]) != nil) {
        if (![self.notificationOn isEqualToValue:value]) {
            self.notificationOn = (NSNumber *)value;
            resetNotification = YES;
        }
        
    }else if(( value = [userInfo objectForKey:NotificationText]) != nil){
        if (![self.notificationText isEqualToString:value]) {
            self.notificationText = (NSString *)value;
            resetNotification = YES;
        }
        
    }else if(( value = [userInfo objectForKey:NotificationTime]) != nil){
        if (![self.notificationTime isEqualToDate:value]) {
            self.notificationTime = (NSDate *)value;
            resetNotification = YES;
        }
        
    }else if(( value = [userInfo objectForKey:MuteSwitchOn]) != nil){
        self.muteSwitchOn = (NSNumber *)value;
    }else if(( value = [userInfo objectForKey:VoiceType]) != nil){
        self.voiceType = (NSNumber *)value;
    }else if(( value = [userInfo objectForKey:MusicName]) != nil){
        self.musicName = (NSString *)value;
    }
    
    if (resetNotification) {
        // 重新部署本地通知
        [self startNotification];
    }
    
    NSLog(@"收到 iCloud 数据更新消息");
}

- (void)syncDataToDisk{
    [[TMDiskCache sharedCache] setObject:self forKey:AppSettingKey];
    
    NSUbiquitousKeyValueStore * store = [NSUbiquitousKeyValueStore defaultStore];
    [self _safelysetObject:_notificationOn forKey:NotificationOn forStore:store];
    [self _safelysetObject:_notificationText forKey:NotificationText forStore:store];
    [self _safelysetObject:_notificationTime forKey:NotificationTime forStore:store];
    [self _safelysetObject:_muteSwitchOn forKey:MuteSwitchOn forStore:store];
    [self _safelysetObject:_voiceType forKey:VoiceType forStore:store];
    [self _safelysetObject:_musicName forKey:MusicName forStore:store];
}

- (void)_safelysetObject:(id)object forKey:(NSString *)key forStore:(NSUbiquitousKeyValueStore *)store{
    if (object && key && key.length > 0) {
        [store setObject:object forKey:key];
    }
}

- (void)startNotification{
    [[WorkoutNotificationManager sharedInstance] deployLocalNotification:_notificationTime];
}

- (void)stopNotification{
    [[WorkoutNotificationManager sharedInstance] cancelAllNotifications];
}

@end
