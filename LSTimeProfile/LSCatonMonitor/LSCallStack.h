//
//  LSCallStack.h
//  LSTimeProfile
//
//  Created by demo on 2020/5/14.
//  Copyright © 2020 ls. All rights reserved.
//  学习自
//https://github.com/ming1016/DecoupleDemo/blob/master/DecoupleDemo/SMCallStack.h
//https://www.cnblogs.com/LiLihongqiang/p/7645987.html
//https://juejin.im/post/5d81fac66fb9a06af7126a44

/**
 每一个线程都有自己的栈空间，线程中会有很多函数的调用，每个函数都有自己的栈帧，栈就是由一个一个栈帧组成的。
 
 线程获取思路及顺序
 mach_thread_t->p_thread
 p_thread->NSThread     threadName来转换
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LSCallStackType) {
    LSCallStackTypeAll,         //全部线程
    LSCallStackTypeMain,        //主线程
    LSCallStackTypeCurrent,     //当前线程
};

@interface LSCallStack : NSObject

+ (NSString *)callStackWithType:(LSCallStackType)callStackType;

@end

NS_ASSUME_NONNULL_END
