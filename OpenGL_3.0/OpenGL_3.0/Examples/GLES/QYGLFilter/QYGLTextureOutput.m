//
//  QYGLTextureOutput.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLTextureOutput.h"

@interface QYGLTextureOutput ()

@property (strong, nonatomic) NSMutableArray *outputTargets;

@end

@implementation QYGLTextureOutput


- (id)init
{
    if (self = [super init]) {
        
        self.outputTargets = [[NSMutableArray alloc] init];
        _lock_semaphore = dispatch_semaphore_create(0);
    }
    return self;;
}


- (void)setPixelBufferDelegate:(id<QYGLPixelBufferDelegate>)pixelBufferDelegate
{
    _pixelBufferDelegate = pixelBufferDelegate;
}


// 清理内存
- (void)cleanupMemory
{
    _lock_semaphore = nil;
    [self.targets enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cleanupMemory];
        obj = nil;
    }];
    [self setPixelBufferDelegate:nil];
}


// 新增
- (void)addTarget:(id<QYGLTextureInput>)target
{
    if (![_outputTargets containsObject:target]) {
        [_outputTargets addObject:target];
    }
}


// 移除
- (void)removeTargett:(id<QYGLTextureInput>)target
{
    if ([_outputTargets containsObject:target]) {
        [_outputTargets removeObject:target];
    }
}


// 所有输入源
- (NSArray<QYGLTextureInput> *)targets
{
    return [_outputTargets mutableCopy];
}


@end
