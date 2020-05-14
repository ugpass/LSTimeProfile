//
//  LSCatonMonitor.m
//  LSTimeProfile
//
//  Created by demo on 2020/5/13.
//  Copyright © 2020 ls. All rights reserved.
//

/**
 学习自：https://juejin.im/post/5cacb2baf265da03904bf93b
        https://time.geekbang.org/column/article/89494
 监控卡顿原理
 监控main runloop各个状态间的持续时间来判断是否发生了卡顿
 N次卡顿超过阈值T
 举例：
 N=1，T=500ms，1次卡顿超过500ms
 N=5，T=50ms，一段时间内，累计5次卡顿超过50ms
 
 */
#import "LSCatonMonitor.h"
#import "LXDBacktraceLogger.h"

/*CFRunLoopObserverContext
typedef struct {
    CFIndex    version;
    void *    info;
    const void *(*retain)(const void *info);
    void    (*release)(const void *info);
    CFStringRef    (*copyDescription)(const void *info);
} CFRunLoopObserverContext;
*/

/**
 NSEC_PER_SEC 单位是秒
 触发卡顿的阈值可以根据WatchDog的机制来设置
 启动(Launch)：20s
 恢复(Resume)：10s
 挂起(Suspend)：10s
 退出(Quit)：6s
 后台(Background)：3min(iOS 7之前每次申请10min；之后改为每次申请3min，可连续申请，最多申请到10min)
 */

@interface LSCatonMonitor()

//是否正在检测
@property (nonatomic, assign) BOOL isMonitoring;

//用于添加到main runloop的observer，监听main runloop的activity状态变化
@property (nonatomic, assign) CFRunLoopObserverRef observer;

//子线程中实时计算activity间隔的并行队列
@property (nonatomic, strong) dispatch_queue_t cartonQueue;

//用来发送信号 监听runloop 状态变化是否超过 卡顿阈值
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

//记录当前acitvity状态
@property (nonatomic, assign) CFRunLoopActivity currentActivity;

@end

static int timeoutCount = 0;//超过卡顿阈值次数
static LSCatonMonitor *instance;
@implementation LSCatonMonitor

#define LogTag 0
//添加observer的回调函数
void ls_runloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    //记录当前acitivity
    instance.currentActivity = activity;
    dispatch_semaphore_signal(instance.semaphore);
#if LogTag
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
        break;
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources");
        break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting");
        break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting");
        break;
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit");
        break;
        default:
            break;
    }
#endif
}

- (void)initEnv {
    self.waitCount = 1;
    self.waitInterval = 1 * NSEC_PER_SEC;
    self.semaphore = dispatch_semaphore_create(0);
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LSCatonMonitor alloc] init];
        [instance initEnv];
    });
    return instance;
}

- (void)startMonitor {
    if (self.isMonitoring) {
        return;
    }
    self.isMonitoring = YES;
    
    //CFRunLoopObserverContext结构体有5个元素，不知道为什么很多人省略掉最后一个也可以？
    CFRunLoopObserverContext ctx = {0, (__bridge void*)self, NULL, NULL, NULL};
    
    //添加observer到main runloop，用来监听main runloop状态
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &ls_runloopObserverCallback, &ctx);
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    _cartonQueue = dispatch_queue_create("ls_carton_monitor_queue", DISPATCH_QUEUE_CONCURRENT);
    //在子线程中 持续对runloop进行监控
    __weak typeof(self) weakSelf = self;
    dispatch_async(_cartonQueue, ^{
        //while循环中 return跳出循环，continue跳出本次循环
        while (weakSelf.isMonitoring) {
            //如果发送信号 时间超过阈值 则认为卡顿需要记录
            long semaphoreWait = dispatch_semaphore_wait(weakSelf.semaphore, dispatch_time(DISPATCH_TIME_NOW, weakSelf.waitInterval));
            if (semaphoreWait != 0) {
                if (!weakSelf.observer) {//如果observer不存在，则停止检测，跳出循环
                    timeoutCount = 0;
                    [weakSelf stopMonitor];
                    continue;
                }
                
                if (weakSelf.currentActivity == kCFRunLoopBeforeSources || weakSelf.currentActivity == kCFRunLoopAfterWaiting) { 
                    if (++timeoutCount < weakSelf.waitCount) {
                        continue;
                    }
                    //抓取堆栈信息
                    [LXDBacktraceLogger lxd_logMain];
                    sleep(5);
                }
            }
            timeoutCount = 0;
        }
    });
}

- (void)stopMonitor {
    if (!self.isMonitoring) {
        return;
    }
    self.isMonitoring = NO;
    
    //移除observer并释放
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = nil;
}

@end
