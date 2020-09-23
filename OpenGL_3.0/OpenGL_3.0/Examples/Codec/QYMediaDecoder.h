//
//  QYMediaDecoder.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


enum QYMediaStatusError {
    MediaStatusNone = 0,
    MediaStatusFileNotExist,
    MediaStatusOperationError,
};
typedef enum QYMediaStatusError MediaError;


@class QYMediaDecoder;
@protocol QYMediaDecoderDelegate <NSObject>

@optional
- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer;
- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder mediaType:(AVMediaType)mediaType didOutputSampleBufferRef:(CMSampleBufferRef)sampleBuffer;
- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder didOccurError:(MediaError)error;
- (void)didDecoderFinished;

@end


@interface QYMediaDecoder : NSObject

- (id)initWithURL:(NSURL *)URL;

// 代理,监听播放状态及数据回调
@property (weak, nonatomic, nullable) id <QYMediaDecoderDelegate> delegate;

// 异步线程解码，不阻碍主线程，用于离屏渲染及后台处理
- (void)startAsyncDecoder;

// 同步帧率解码，用于播放或渲染视频帧（最高帧率60fps）
- (void)startFrameRateDecoder;

// 更新视频源
- (void)updateURL:(NSURL *)URL;

// 清理资源并停止解码
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
