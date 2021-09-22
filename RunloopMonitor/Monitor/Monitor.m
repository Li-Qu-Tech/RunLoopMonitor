//
//  Monitor.m
//  RunloopMonitor
//
//  Created by 李宝 on 2021/9/22.
//

#import "Monitor.h"

@interface Monitor ()

@property(nonatomic,strong) NSThread *monitorThread;

@property(nonatomic,strong) NSDate *startDate;

@property(nonatomic,assign,getter=isExcuting) BOOL excuting;//是否正在执行任务

@end

@implementation Monitor {

    CFRunLoopObserverRef _observer;
    CFRunLoopTimerRef _timer;
}

+ (instancetype)shareInstance {
    
    static Monitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [Monitor new];
        instance.monitorThread = [[NSThread alloc] initWithTarget:self selector:@selector(monitorThreadEntryPoint) object:nil];
        [instance.monitorThread start];
    });
    return instance;
}

//在线程启动时，启动其RunLoop
+ (void)monitorThreadEntryPoint {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"Monitor"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

//在开始检测时，往主线程的RunLoop中添加一个observer，并往子线程中添加一个定时器，每0.1s检测一次耗时的时长
- (void)startMonitor {
    if (_observer) {
        return;
    }
    
    //创建observer
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL, NULL};

    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    
    //将observer添加到主线程的runloop中
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    //创建一个timer，添加到子线程的runloop中
    [self performSelector:@selector(addTimerToMonitorThread) onThread:_monitorThread withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

/**
 observer回调
因为主线程中的block，交互事件，以及其他任务都是在kCFRunLoopBeforeSources到kCFRunLoopBeforeWaiting之前执行.
所以在开始执行Sources时，即kCFRunLoopBeforeSources状态时，记录一下时间，并把正在执行任务的标记设置为YES.
将要进入睡眠状态时，即kCFRunLoopBeforeWaiting状态时，将正在执行任务的标记设置为NO.
*/
static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    
    Monitor *monitor = (__bridge  Monitor *)info;
    
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources");
            monitor.startDate = [NSDate date];
            monitor.excuting = YES;
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting");
            monitor.excuting = NO;
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting ");
            break;
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit");
            break;
        default:
            break;
    }
}

//添加定时器到子线程runloop中
- (void)addTimerToMonitorThread {
    if (_timer) return;
    
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    
    CFRunLoopTimerContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    _timer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                  0.01,
                                  0.01,
                                  0,
                                  0,
                                  &runLoopTimerCallBack,
                                  &context);
    
    CFRunLoopAddTimer(currentRunLoop, _timer, kCFRunLoopCommonModes);
}

static void runLoopTimerCallBack(CFRunLoopTimerRef timer , void *info) {
 
    Monitor *monitor = (__bridge  Monitor *)info;
    
    if (!monitor.isExcuting) {//runloop已经进入休眠
        return;
    }
    
    //如果主线程正在执行任务，并且这一次loop执行到现在还没执行完，那就需要计算时间差
    //即从kCFRunLoopBeforeSources状态到当前时间的时间差excuteTime
    NSTimeInterval excuteTime = [[NSDate date] timeIntervalSinceDate:monitor.startDate];
    
    NSLog(@"定时器：当前线程：%@，主线程执行时间：%f秒",[NSThread currentThread], excuteTime);
    
    //Timer每0.01S执行一次，如果当前正在执行任务的状态为YES，并且从开始执行到现在的时间大于阀值，则把堆栈信息保存下来，便于后面处理。
    if (excuteTime >= 0.01) {
        NSLog(@"线程卡顿了%f秒",excuteTime);
        //打印堆栈信息 PLCrashReporter
    }
}

@end
