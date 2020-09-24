//
//  QYGLRenderView.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
NS_ASSUME_NONNULL_BEGIN

@protocol
QYGLTextureDelegate <NSObject>

// 自定义纹理处理，用于离屏渲染或多纹理绘制(支持后台处理)
- (unsigned int)offscreenRenderWithTexture:(unsigned int)texture size:(CGSize)size ts:(CMTime)ts;

@end

@interface
QYGLRenderView : UIView

// 自定义纹理代理
@property (nonatomic, weak) id <QYGLTextureDelegate> delegate;

// 绘制画板范围
@property CGSize presentationRect;


// 水平旋转角度
@property (nonatomic, assign) float rotationAngle;

// 垂直旋转角度
@property (nonatomic, assign) float verticalRotationAngle;

// 缩放系数（0 ~ 1， 1 ~ +∞），默认是1.0
@property (nonatomic, assign) float zoom;

// 移动距离，默认是0，适用范围（-2 ~ 2）
@property (nonatomic, assign) CGPoint offsetPoint;

// 一些相关效果的强度，如模糊效果，透明度，滤镜混合比例，美颜强度等
@property (nonatomic, assign) float  indensity;

// 绘制图片，用于图片生成视频
@property (nonatomic, strong) UIImage   *displayImage;


// 绘制纹理
- (void)displayTexture:(unsigned int)texture size:(CGSize)size;

// 绘制图片像素缓存对象，支持时间戳
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)ts;

@end

NS_ASSUME_NONNULL_END
