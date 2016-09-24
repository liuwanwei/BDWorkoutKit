//
//  WorkoutCloudManager.m
//  7MinutesWorkout
//
//  Created by sungeo on 15/8/5.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "BDiCloudManager.h"
#import "WorkoutResult.h"
#import "WorkoutAppSetting.h"
#import "CacheManager.h"
#import <EXTScope.h>
#import <UIAlertController+window.h>

static NSString * const AllRecords = @"TRUEPREDICATE";

// 存储在本地用户信息中用到的 key
static NSString * iCloudTokenKey = @"cn.buddysoft.hiitrope.UbiquityIdentityToken";

@implementation BDiCloudManager{
    id _iCloudToken;
    
    RecordsReceivedBLock _recordsReceivedBlock;
    RecordSavedBlock _recordSavedBlock;
}

+ (instancetype)sharedInstance{
    static BDiCloudManager * sInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sInstance == nil) {
            sInstance = [[BDiCloudManager alloc] init];
        }
    });
    
    return sInstance;
}

- (instancetype)init{
    if (self = [super init]) {
        _container = [CKContainer defaultContainer];
        _privateDatabase = [_container privateCloudDatabase];
        // [self registerIdentityChangeCustomNotification];
    }
    
    return self;
}

// 注册系统级的 iCloud 可用状态改变事件处理
- (void)registerIdentityChangeNotification{
    // 只让 sharedInstance 实例侦听这个消息
    if (self != [BDiCloudManager sharedInstance]){
        @throw [NSException exceptionWithName:NSGenericException reason:@"只能有一个实例侦听这个消息" userInfo:nil];
    }

    [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(iCloudAccountAvailablityChanged:)
        name: NSUbiquityIdentityDidChangeNotification
        object: nil
    ];
}

// iCloud 身份信息改变消息处理
- (void)iCloudAccountAvailablityChanged:(NSNotification *)notification{
    WorkoutAppSetting * setting = [WorkoutAppSetting sharedInstance];
    if (! [setting useICloudSchema]){
        // 如果用户没有选择使用 iCloud，就不做处理
        return;
    }

    CacheManager * cm = [CacheManager sharedInstance];

    id currentToken = [self currentiCloudToken];
    id oldToken = [self loadICloudToken];    
    if (currentToken) {        
        if (oldToken && ![oldToken isEqual:currentToken]) {
            // 切换了 iCloud 用户，清空旧数据，查询新数据
            [cm cleanAll];            
            [cm loadAll];
        }else if(nil == oldToken){
            // iCloud 由不可用变为可用，再次提示用户选择存储方案
            [cm showChooseStorageSchemeView];
        }
    }else{
        // 关闭了 iCloud 服务
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"iCloud 服务被关闭" 
            message:@"后序产生的训练数据将会保存在手机中。"
            preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction * action = [UIAlertAction actionWithTitle:@"确定" 
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action){
            }];
        [alert addAction: action];
        [alert show];

        // 修改 App 内的 iCloud 可用标志
        [WorkoutAppSetting sharedInstance].useICloud = @(NO);
    }
}

// 取出缓存在本地的 iCloud token
- (id)loadICloudToken{
    NSData * data = [[NSUserDefaults standardUserDefaults] objectForKey:iCloudTokenKey];
    if (data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }else{
        return nil;
    }
}

// 将 iCloud token 缓存在本地
- (void)syncICloudTokenToDisk:(id)token{
    if (token) {
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject: token];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData forKey: iCloudTokenKey];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:iCloudTokenKey];
    }
}

// 取出当前 iCloud Token
- (id)currentiCloudToken{
    return [[NSFileManager defaultManager] ubiquityIdentityToken];
}

// 更新 iCloud Token
- (void)fetchICloudToken{
    // 取出当前 iCloud Token
    id currentToken = [self currentiCloudToken];
    _iCloudToken = currentToken;    
    [self syncICloudTokenToDisk:currentToken];
}

// 判断用户是否登录了 iCloud
// 并不意味用户已授权给我们使用 iCloud，也不意味我们必须用 iCloud 存储数据
- (BOOL)iCloudAvailable{
    return _iCloudToken == nil ? NO : YES;
}

// 当前账户的 iCloud 不可用
- (void)iCloudNotEnabledHandler{
    NSLog(@"调用 accountStatusWithCompletionHandler 失败");
}

// 查询数据最终实现代码
- (void)finalQueryRecord{
    // 获取要查询的记录类型
    NSString * type = (NSString *)[self.delegate performSelector:@selector(recordType)];
    // 设备账号的 iCloud 服务可用，查询所有数据
    NSPredicate * predict = [NSPredicate predicateWithValue:YES];
    CKQuery * query = [[CKQuery alloc] initWithRecordType:type predicate:predict];
    
    [_privateDatabase performQuery:query  inZoneWithID:nil completionHandler:^(NSArray * results, NSError * error){        
        if (error) {
            NSLog(@"查询 %@ 出现问题: %@", type, error);
        }else{
            NSLog(@"查询 %@ 数据成功", type);
            if (_recordsReceivedBlock) {
                _recordsReceivedBlock(results);
            }
        }
    }];
}

- (void)queryRecordsWithCompletionBlock:(RecordsReceivedBLock)block{
    _recordsReceivedBlock = block;
    [self finalQueryRecord];
}

- (void)finalAddRecord:(CKRecord *)record{
    @weakify(self);
    
    // 先查用户是否有权限，再做后续动作
    [_container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * error){
        @strongify(self);
        
        if (accountStatus == CKAccountStatusAvailable) {
            [_privateDatabase saveRecord:record completionHandler:^(CKRecord * record, NSError * error){
                if (error) {
                    NSLog(@"iCloud/CKRecord 添加失败：An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                }else{
                    NSLog(@"添加数据（iCloud/CKRecord）数据成功");                    
                    if (_recordSavedBlock) {
                        _recordSavedBlock(record);
                    }
                }
            }];
        }else{
            [self iCloudNotEnabledHandler];
        }
    }];
}

/**
 *  将新的训练结果保存到 iCloud 中去
 *
 *  @param result WorkoutResult object
 */
- (void)addRecord:(CKRecord *)record{
    [self finalAddRecord:record];
}

- (void)addRecord:(CKRecord *)record withCompletionBlock:(RecordSavedBlock)block{
    _recordSavedBlock = block;
    [self finalAddRecord:record];
}


@end
