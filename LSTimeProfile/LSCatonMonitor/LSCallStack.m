//
//  LSCallStack.m
//  LSTimeProfile
//
//  Created by demo on 2020/5/14.
//  Copyright © 2020 ls. All rights reserved.
//

#import "LSCallStack.h"
#import <mach/mach.h>
#import <sys/types.h>
#import <pthread.h>

#define MAX_FRAME_NUMBER 30

//存储 thread 信息的结构体
typedef struct LSThreadInfo {
    double cpuUsage;
    integer_t userTime;
} LSThreadInfo;

static mach_port_t main_thread_id;//主线程id
static mach_port_t task_id;//本进程id
@implementation LSCallStack

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //在load方法中获取主线程标记 方便之后在所有线程中比对出主线程
        main_thread_id = mach_thread_self();
        
        task_id = mach_task_self();
    });
}

+ (NSString *)callStackWithType:(LSCallStackType)callStackType {
    NSString *stackResult = @"";
    switch (callStackType) {
        case LSCallStackTypeAll:
            stackResult = [self allCallStack];
            break;
        case LSCallStackTypeMain:
            stackResult = [self mainCallStack];
        break;
        case LSCallStackTypeCurrent:
            stackResult = [self currentCallStack];
        break; 
        default:
            break;
    }
    return stackResult;
}

+ (NSString *)allCallStack {
    thread_act_array_t threads;//存放线程的数组
    mach_msg_type_number_t count;//unsigned int 线程数量
    
    //获取本进程的所有线程及数量
    kern_return_t kr = task_threads(task_id, &threads, &count);
    if (kr != KERN_SUCCESS) {//获取线程信息失败
        NSLog(@"Failed to get thread info");
    }
    
    NSMutableString *result = [[NSMutableString alloc] init];
    //遍历线程数组 拼凑线程信息
    for (int i = 0; i < count; i++) {
        [result appendString:ls_backtraceOfThread(threads[i])];
    }
    return [result copy];
}

+ (NSString *)mainCallStack {
    return @"";
}

+ (NSString *)currentCallStack {
    [NSThread callStackSymbols];
    return @"";
}

//从NSSthread获取mach_threadif ([nsthread isMainThread]) { return (thread_t)main_thread_id; }
thread_t ls_machThreadFromNSThread(NSThread *nsthread) {
    char name[256];
    thread_act_array_t list;
    mach_msg_type_number_t count;
    task_threads(mach_task_self(), &list, &count);
    
    //将线程名称设置为时间戳
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString * originName = nsthread.name;
    [nsthread setName: [NSString stringWithFormat: @"%f", timeStamp]];
    
    if ([nsthread isMainThread]) { return (thread_t)main_thread_id; }
    for (int i = 0; i < count; i++) {
        //将mach_thread转成pthread
        pthread_t pthread = pthread_from_mach_thread_np(list[i]);
        if (pthread) {
            name[0] = '\0';
            //获取pthread的线程名称和nNSThread的名称比较
            pthread_getname_np(pthread, name, sizeof(name));
            //strcmp返回值为0 则两个字符串相等
            //若pthread 的name和nsthread name不相等
            if (!strcmp(name, [nsthread name].UTF8String)) {
                //给nsthread名称赋值为当前时间戳
                [nsthread setName:originName];
                return list[i];
            }
        }
    }
    [nsthread setName:originName];
    return mach_thread_self();
}

//拼凑某个线程信息
NSString *ls_backtraceOfThread(thread_t thread) {
    uintptr_t backtraceBuffer[30];
    int idx = 0;
    NSMutableString *result = [NSMutableString stringWithFormat:@"Backtrace of thread %u:\n===========================\n", thread];
    
    //_STRUCT_MCONTEXT 类型的结构体中，存储了当前线程的SP和最顶部栈帧的FP
    _STRUCT_MCONTEXT machineContext;
    if (!ls_machineContextWithThread(thread, &machineContext)) {
        NSLog(@"Failed to get machineContext info");
    }
    //抄不下去了 实在看不懂
    return @"";
}

//根据线程获取machineContext
bool ls_machineContextWithThread(thread_t thread, _STRUCT_MCONTEXT *machineContext) {
    mach_msg_type_number_t state_count = MACHINE_THREAD_STATE_COUNT;
    kern_return_t kr = thread_get_state(thread, MACHINE_THREAD_STATE, (thread_state_t)&machineContext->__ss, &state_count);
    return (kr == KERN_SUCCESS);
}

@end
