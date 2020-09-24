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

@interface QYMediaEncoder : NSObject

- (id)initWithOutputURL:(NSURL *)outputUrl resolution:(CGSize)resolution;


// 编码输入的图像数据，带入相对时间戳
- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)ts;

// 编码相机生成的实时源数据
- (void)inputSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType;

// 完成编码，释放内存
- (void)finishedEncoder;

// 停止编码
- (void)stopEncoder;

@end

NS_ASSUME_NONNULL_END
