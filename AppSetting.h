//
//  AppSetting.h
//  7MinutesWorkout
//
//  Created by sungeo on 15/7/11.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFoundation.h"

typedef enum{
    PromptVoiceTypeGirl = 0,
    PromptVoiceTypeBoy,
}PromptVoiceType;


@interface AppSetting : BaseModel

/**
 *  本地提醒配置信息
 */
@property (nonatomic, strong) NSNumber * notificationOn;    // 是否打开提醒
@property (nonatomic, copy) NSString * notificationText;    // 提醒文字
@property (nonatomic, strong) NSDate * notificationTime;    // 提醒时间：几点几分

@property (nonatomic, strong) NSNumber * muteSwitchOn;     // 声效开关（界面显示静音）
@property (nonatomic, copy) NSNumber * voiceType;           // 提示音枚举类型 PromptVoiceType
@property (nonatomic, copy) NSString * musicName;           // 背景音乐，音频文件在 MainBundle 中的名字


+ (instancetype)sharedInstance;

- (void)syncDataToDisk;

/**
 *  注册 iCloud 消息通知 Handler
 */
- (void)registeriCloudSynchronizeService;

/**
 *  本地通知时间快速访问函数，将 _fireHour 和 _fireMinute 封装到一个 NSDate 对象中
 *
 *  @return 只包含小时和分钟属性的 NSDate 对象
 */
//- (NSDate *)notificationFireDate;


- (void)startNotification;
- (void)stopNotification;

@end
