//
//  QYMediaEncoder.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/23.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYMediaEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "QYGLUtils.h"
#import "QYGLContext.h"

NSString *kObserverWriterOutputStatus = @"mWriter.status";

@interface QYMediaEncoder ()

@property (nonatomic, copy) NSURL   *ouputUrl;
@property (nonatomic, assign) CGSize    resolution;

// AVAssetWriter provides services for writing media data to a new file,
@property (nonatomic, strong) AVAssetWriter     *mWriter;

// Defines an interface for appending video samples packaged as CVPixelBuffer objects to a single AVAssetWriterInput object.
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor  *mPixelBufferAdaptor;

@end

@implementation QYMediaEncoder


- (id)initWithOutputURL:(NSURL *)outputUrl resolution:(CGSize)resolution
{
    if (self = [super init])
    {
        self.ouputUrl = outputUrl;
        self.resolution = resolution;
        NSAssert(self.mWriter.status != AVAssetWriterStatusWriting, @"AssetWrite status counld not is writing ...");
    }
    return self;
}


- (void)dealloc
{
    [self stopEncoder];
    _mWriter = nil;
    _mPixelBufferAdaptor = nil;
    _ouputUrl = nil;
}


#pragma mark    -   public method

- (void)startAsyncEncoder
{
    if (self.mWriter.status != AVAssetWriterStatusWriting || self.mWriter.status != AVAssetWriterStatusCompleted)
    {
        dispatch_sync([QYGLContext shareImageContext].contextQueue, ^
        {
            NSAssert(self.mPixelBufferAdaptor != nil, @"Input pixelBuffer adaptor create failed ...");
            [self.mWriter startWriting];
            [self.mWriter startSessionAtSourceTime:kCMTimeZero];
        });
    }
    else
    {
        NSLog(@"AssetWriter already status is writing, error is %@ ...", self.mWriter.error);
    }
}


- (void)stopEncoder
{
    if (_mWriter == nil || _mWriter.status == AVAssetWriterStatusUnknown) {
        return;
    }
    [_mWriter.inputs enumerateObjectsUsingBlock:^(AVAssetWriterInput * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj markAsFinished];
        obj = nil;
    }];
    [self removeObserver:self forKeyPath:kObserverWriterOutputStatus];
    [_mWriter cancelWriting];
    _mWriter = nil;
}


- (void)finishedEncoder
{
    if (_mWriter == nil || _mWriter.status == AVAssetWriterStatusUnknown) {
        return;
    }
    dispatch_sync([QYGLContext shareImageContext].contextQueue, ^
    {
        if (self.mWriter.status == AVAssetWriterStatusWriting)
        {
            [self.mWriter.inputs enumerateObjectsUsingBlock:^(AVAssetWriterInput * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj markAsFinished];
                obj = nil;
            }];
            [self.mWriter finishWritingWithCompletionHandler:^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                 ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                 [library writeVideoAtPathToSavedPhotosAlbum:self.ouputUrl
                                             completionBlock:^(NSURL *assetURL, NSError *error) {
                     NSLog(@"%@ 保存到相册....  %@ ", error ? @"失败" : @"成功", self.ouputUrl);
                 }];
#pragma clang diagnostic pop
            }];
        }
    });
}


- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)ts
{
    AVAssetWriterInput *writerInput = self.mWriter.inputs.firstObject;
    if ((!CMTIME_IS_VALID(ts) || pixelBuffer == nil) || writerInput == nil) {
        return;
    }
    
    if (self.mWriter.status != AVAssetWriterStatusWriting) {
        [self startAsyncEncoder];
        return;
    }
    
    dispatch_async([QYGLContext shareImageContext].contextQueue, ^{
        if (!writerInput.readyForMoreMediaData) {
            NSLog(@"Had to drop an video frame: %@,  error is %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)), self.mWriter.error);
            return;
        }
        else if (self.mWriter.status == AVAssetWriterStatusWriting)
        {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            if (![self.mPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:ts])
            {
                NSLog(@"Problem appending video buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            } else{
                NSLog(@"Writing video pixel buffer ...  %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        }
    });
}



- (void)inputSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType
{
    if (self.mWriter.status != AVAssetWriterStatusWriting || self.mWriter.status != AVAssetWriterStatusCompleted)
    {
        [self.mWriter startWriting];
        [self.mWriter startSessionAtSourceTime:kCMTimeZero];
        return;
    }
    
    AVAssetWriterInput *writerInput = (mediaType == AVMediaTypeVideo) ? self.mWriter.inputs.firstObject : self.mWriter.inputs.lastObject;
    
    if ([writerInput isReadyForMoreMediaData])
    {
        [writerInput appendSampleBuffer:sampleBuffer];
    }
}


#pragma mark    -   get method

- (AVAssetWriter *)mWriter
{
    if (!_mWriter) {
        NSError *error;
        _mWriter = [AVAssetWriter assetWriterWithURL:self.ouputUrl fileType:AVFileTypeMPEG4 error:&error];
        if (error) {
            NSLog(@"AssetWriter create failed, error is %@", error);
            return nil;;
        }
        _mWriter.shouldOptimizeForNetworkUse = YES;
        [self addObserver:self
               forKeyPath:kObserverWriterOutputStatus
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:NULL];
        dispatch_sync([QYGLContext shareImageContext].contextQueue, ^
        {
            [self addInputToAssetWriter:_mWriter];
        });
    }
    return _mWriter;
}


- (AVAssetWriterInputPixelBufferAdaptor *)mPixelBufferAdaptor
{
    if (!_mPixelBufferAdaptor) {
        _mPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.mWriter.inputs.firstObject
                                                                                                sourcePixelBufferAttributes:[self pixelBufferAttributes]];
    }
    return _mPixelBufferAdaptor;
}


#pragma mark    -   kvo


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:kObserverWriterOutputStatus])
    {
        switch (self.mWriter.status)
        {
            case AVAssetWriterStatusWriting:
                NSLog(@"Encoder video of status is writing ...");
                break;
                
            case AVAssetWriterStatusCompleted:
                NSLog(@"Encoder video of status is completed ...");
                [self removeObserver:self forKeyPath:kObserverWriterOutputStatus];
                break;
                
            case AVAssetWriterStatusFailed:
                NSLog(@"Encoder video of status is failed ...");
                break;
                
            case AVAssetWriterStatusCancelled:
                NSLog(@"Encoder video of status is cancelled ...");
                break;
                
            default:
                break;
        }
    }
}


#pragma mark    -   private method


- (void)addInputToAssetWriter:(AVAssetWriter *)writer
{
    NSArray<NSString *> *inputTypes = @[AVMediaTypeVideo, AVMediaTypeAudio];
    [inputTypes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:obj outputSettings:[self outputSettingForMediaType:obj]];
        if ([writer canAddInput:writerInput])
        {
            writerInput.expectsMediaDataInRealTime = YES;
            [writer addInput:writerInput];
        }
    }];
}



- (NSDictionary<NSString *, id> *)outputSettingForMediaType:(AVMediaType)mediaType
{
    if ([mediaType isEqualToString:AVMediaTypeVideo])
    {
        // AVVideoSettings.h
        return @{AVVideoCodecKey                    : AVVideoCodecH264,
                 AVVideoWidthKey                    : @(self.resolution.width),
                 AVVideoHeightKey                   : @(self.resolution.height),
                 AVVideoScalingModeKey              : AVVideoScalingModeResizeAspectFill,
                 AVVideoCompressionPropertiesKey    : @{AVVideoAverageBitRateKey : @(self.resolution.width * self.resolution.height * 1.5)},
//                 AVVideoAllowFrameReorderingKey     : @true,
//                 AVVideoExpectedSourceFrameRateKey  : @(30)
        };
    }
    else if ([mediaType isEqualToString:AVMediaTypeAudio])
    {
        // AVAudioSettings.h、CoreAudioBaseTypes.h
        return @{AVFormatIDKey                      : @(kAudioFormatMPEG4AAC),
                 AVSampleRateKey                    : @(44100),
                 AVNumberOfChannelsKey              : @(2),
                 AVEncoderAudioQualityKey           : @(AVAudioQualityHigh),
//                 AVEncoderBitRateKey                : @(128 * 1000),
//                 AVEncoderBitRatePerChannelKey      : @(2)
        };
    }
    return nil;
}


- (NSDictionary *)pixelBufferAttributes
{
    return @{(NSString *)kCVPixelBufferPixelFormatTypeKey                   : @(kCVPixelFormatType_32BGRA),
             (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey      : @true,
             (NSString *)kCVPixelBufferBytesPerRowAlignmentKey              : @(self.resolution.width * 4),
             (NSString *)kCVPixelBufferWidthKey                             : @(self.resolution.width),
             (NSString *)kCVPixelBufferHeightKey                            : @(self.resolution.height),
    };
}

@end
