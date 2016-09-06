//
//  iCloudModel.h
//  HiitWorkout
//
//  Created by sungeo on 16/9/5.
//  Copyright © 2016年 maoyu. All rights reserved.
//

#import "BaseModel.h"
#import <CloudKit/CloudKit.h>

@interface BDiCloudModel : BaseModel

@property (nonatomic, strong, nullable) NSNumber * objectId;

// 内存和本地缓存属性，不保存到 iCloud
@property (nonnull, strong) NSNumber * savedToICloud;

// iCloud/CloudKit 的 CKRecord 对象之间互相转换
- (nullable instancetype)initWithICloudRecord:(nonnull CKRecord *)record;

// 将当前对象转换成 CKRecord 对象并返回
- (nullable CKRecord *)iCloudRecord;

- (nonnull CKRecord *)baseICloudRecordWithType:(nonnull NSString *)recordType;

@end
