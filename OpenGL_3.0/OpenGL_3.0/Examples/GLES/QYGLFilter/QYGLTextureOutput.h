//
//  QYGLTextureOutput.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYGLUtils.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@class QYGLTextureOutput;
@protocol QYGLPixelBufferDelegate <NSObject>

// 纹理转换成PixelBuffer对象后输出
- (void)textureOutput:(QYGLTextureOutput *)textureOutput timestamp:(CMTime)ts didOutputSampleBuffer:(CVPixelBufferRef)pixelBuffer;

@end


@protocol QYGLTextureInput <NSObject>

@optional
// 绘制
- (GLuint)inputTexture:(GLuint)texture size:(CGSize)size ts:(CMTime)ts;

// 重置
- (void)resetProgramWithShader:(NSString *)vShader fragShader:(NSString *)fShader;

// 参数设置
- (void)useProgramAndSetUniforms;

// 屏幕渲染完成
- (void)onCompletedScrrenRender;

// 设置buffer尺寸
- (void)setFrameBufferSize:(CGSize)size;

// 创建FBO
- (GLuint)firstFrameBuffer;

@end


@interface QYGLTextureOutput : NSObject
{
    dispatch_semaphore_t    _lock_semaphore;
}

// 清理内存
- (void)cleanupMemory;

// 开关
@property (nonatomic, assign) BOOL enable;

// 时间戳
@property (nonatomic, assign) CMTime    timestamp;

// 输出pixelBuffer代理
@property (nonatomic, weak) id<QYGLPixelBufferDelegate> pixelBufferDelegate;

// 新增
- (void)addTarget:(id<QYGLTextureInput>)target;

// 移除
- (void)removeTargett:(id<QYGLTextureInput>)target;

// 所有输入源
- (NSArray <QYGLTextureInput> *)targets;

@end

NS_ASSUME_NONNULL_END
