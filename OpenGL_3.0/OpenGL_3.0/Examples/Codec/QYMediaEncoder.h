//
//  QYMediaEncoder.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/23.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, QYEncoderType)
{
    QYEncoderTypeRecording,
    QYEncoderTypeExporting,
};

@interface QYMediaEncoder : NSObject

// 初始化，默认是录制模式
- (id)initWithOutputURL:(NSURL *)outputUrl resolution:(CGSize)resolution encoderType:(QYEncoderType)type;


// 解码线程回调
@property(nonatomic, copy) BOOL (^videoInputReadyCallback) (void);
@property(nonatomic, copy) BOOL (^audioInputReadyCallback) (void);


// 编码输入的图像数据，带入相对时间戳
- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)ts;

// 编码相机生成的实时源数据
- (void)inputSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType;

// 完成编码，释放内存
- (void)finishedEncoder;

// 停止编码
- (void)stopEncoder;

// 开始解码
- (void)startAsyncEncoderAtTime:(CMTime)time;

// 开始读取音视频线程
- (void)enableSynchronizationCallbacks;


@end

NS_ASSUME_NONNULL_END
