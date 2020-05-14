//
//  LSCatonMonitor.h
//  LSTimeProfile
//
//  Created by demo on 2020/5/13.
//  Copyright © 2020 ls. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LSCatonMonitor : NSObject

//通过修改卡顿次数和单次卡顿时长来 进行卡顿判断

//卡顿次数
@property (nonatomic, assign) int waitCount;

//单次卡顿时长
@property (nonatomic, assign) double waitInterval;

+ (instancetype)shareInstance;

- (void)startMonitor;

- (void)stopMonitor;

@end

NS_ASSUME_NONNULL_END
