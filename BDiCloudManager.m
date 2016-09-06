//
//  WorkoutCloudManager.m
//  7MinutesWorkout
//
//  Created by sungeo on 15/8/5.
//  Copyright (c) 2015年 maoyu. All rights reserved.
//

#import "BDiCloudManager.h"
#import "WorkoutResult.h"
#import <EXTScope.h>

static NSString * const AllRecords = @"TRUEPREDICATE";

// 存储在本地用户信息中用到的 key
static NSString * iCloudTokenKey = @"cn.buddysoft.hiitrope.UbiquityIdentityToken";

@implementation BDiCloudManager{
    id _iCloudToken;
    
    __weak CKContainer * _container;
    __weak CKDatabase * _privateDatabase;
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
    }
    
    return self;
}

- (id)iCloudToken{
    NSData * data = [[NSUserDefaults standardUserDefaults] objectForKey:iCloudTokenKey];
    if (data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }else{
        return nil;
    }
}

- (void)setICloudToken:(id)token{
    if (token) {
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject: token];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData forKey: iCloudTokenKey];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:iCloudTokenKey];
    }
    
}

// 注意：必须在主线程中调用
- (void)fetchICloudToken{
    // 取出当前 iCloud Token
    NSFileManager* fileManager = [NSFileManager defaultManager];
    id currentiCloudToken = fileManager.ubiquityIdentityToken;
    
    if (currentiCloudToken) {
        id oldICloudToken = [self iCloudToken];
        if (oldICloudToken && [oldICloudToken isEqual:currentiCloudToken]) {
            // 有改变，需要清空旧的数据
        }
    }
    
    _iCloudToken = currentiCloudToken;
    
    [self setICloudToken:currentiCloudToken];
}

// 判断用户是否登录了 iCloud
// 并不意味用户已授权给我们使用 iCloud，也不意味我们必须用 iCloud 存储数据
- (BOOL)iCloudAvailable{
    return _iCloudToken == nil ? NO : YES;
}

// TODO: 提示用户 iCloud 没有打开，并引导用户打开
- (void)iCloudNotEnabledHandler{
    
}


/**
 *  从 iCloud CloudKit 服务查询所有训练结果
 */
- (void)queryRecordsWithType:(NSString *)recordType{
    @weakify(self);
    
    [_container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * error){
        @strongify(self);
        if (accountStatus == CKAccountStatusAvailable) {
            // 设备账号的 iCloud 服务可用，查询所有数据
            NSPredicate * predict = [NSPredicate predicateWithValue:YES];
            CKQuery * query = [[CKQuery alloc] initWithRecordType:recordType predicate:predict];
            
            [_privateDatabase performQuery:query  inZoneWithID:nil completionHandler:^(NSArray * results, NSError * error){
                
                if (error) {
                    NSLog(@"查询 iCloud 数据出现问题: %@ / %@", NSStringFromSelector(_cmd), error);
                }else{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveWorkoutResults:)]) {
                        [self.delegate performSelector:@selector(didReceiveWorkoutResults:) withObject:results];
                    }
                }
            }];
        }
    }];
}

/**
 *  从 iCloud CloudKit 服务查询所有训练结果
 */
- (void)recordsWithType:(NSString *)recordType from:(id)caller action:(SEL)sel{
    @weakify(self);
    
    [_container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * error){
        @strongify(self);
        if (accountStatus == CKAccountStatusAvailable) {
            // 设备账号的 iCloud 服务可用，查询所有数据
            NSPredicate * predict = [NSPredicate predicateWithValue:YES];
            CKQuery * query = [[CKQuery alloc] initWithRecordType:recordType predicate:predict];
            
            [_privateDatabase performQuery:query  inZoneWithID:nil completionHandler:^(NSArray * results, NSError * error){
                
                if (error) {
                    NSLog(@"查询 iCloud 数据出现问题: %@ / %@", NSStringFromSelector(_cmd), error);
                }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [caller performSelector:sel withObject:results];
#pragma clang diagnostic pop
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
    @weakify(self);
    
    // 先查用户是否有权限，再做后续动作
    [_container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * error){
        @strongify(self);
        
        if (accountStatus == CKAccountStatusAvailable) {
            [_privateDatabase saveRecord:record completionHandler:^(CKRecord * record, NSError * error){
                if (error) {
                    NSLog(@"iCloud/CKRecord 添加失败：An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                }else{
                    NSLog(@"添加训练结果（iCloud/CKRecord）数据成功");
                    if (self.delegate && [self.delegate respondsToSelector:@selector(successfullySavedRecord:)]) {
                        [self.delegate performSelector:@selector(successfullySavedRecord:) withObject:record];
                    }
                }
            }];
        }else{
            [self iCloudNotEnabledHandler];
        }
    }];
}


@end
