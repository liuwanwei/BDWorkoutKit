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

// App 内部保留的记录 Id
@property (nonatomic, strong, nullable) NSNumber * objectId;

// App 本地对象对应的 iCloud 对象指针, weak 类型，所以指针的本体必须 Hold 住
// 用在 BaseCache 衍生类时，指针的本体一般放在 cloudRecords 数组中。
@property (nonatomic, weak, nullable) CKRecord * cloudRecord;

// 内存和本地缓存属性，不保存到 iCloud
@property (nonnull, strong) NSNumber * savedToICloud;

// iCloud/CloudKit 的 CKRecord 对象之间互相转换
- (nullable instancetype)initWithICloudRecord:(nonnull CKRecord *)record;

// 将需要上传到 iCloud 的属性更新到 CKRecord 对象里
- (void)updateICloudRecord:(nonnull CKRecord *)record;

// 将当前对象转换成 CKRecord 对象并返回
- (nullable CKRecord *)newICloudRecord:(nonnull NSString *)type;

// 派生类创建对象时绑定跟原始 CKRecord 指针的接口
- (nonnull CKRecord *)baseICloudRecordWithType:(nonnull NSString *)recordType;

//- (BOOL)isEqual:(nonnull id)object;

@end
