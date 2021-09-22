//
//  Monitor.h
//  RunloopMonitor
//
//  Created by 李宝 on 2021/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Monitor : NSObject

+ (instancetype)shareInstance;

- (void)startMonitor;

@end

NS_ASSUME_NONNULL_END
