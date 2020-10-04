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

// Export media of type
@property (nonatomic, assign) QYEncoderType encoderType;

// Export new media of url
@property (nonatomic, copy) NSURL   *ouputUrl;

// For Video pixle resolution
@property (nonatomic, assign) CGSize    resolution;

// AVAssetWriter provides services for writing media data to a new file,
@property (nonatomic, strong) AVAssetWriter     *mWriter;

// Defines an interface for appending video samples packaged as CVPixelBuffer objects to a single AVAssetWriterInput object.
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor  *mPixelBufferAdaptor;

@end

@implementation QYMediaEncoder
{
    BOOL    _isStarting;
}


- (id)initWithOutputURL:(NSURL *)outputUrl resolution:(CGSize)resolution encoderType:(QYEncoderType)type
{
    if (self = [super init])
    {
        self.encoderType = type;
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
        if ([self.mWriter.inputs.firstObject.mediaType isEqualToString:AVMediaTypeVideo])
        {
            NSAssert(self.mPixelBufferAdaptor != nil, @"Input pixelBuffer adaptor create failed ...");
        }
        [self.mWriter startWriting];
        [self.mWriter startSessionAtSourceTime:kCMTimeZero];
        _isStarting = true;
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
    if (self.mWriter.status == AVAssetWriterStatusWriting)
    {
        [self.mWriter.inputs enumerateObjectsUsingBlock:^(AVAssetWriterInput * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj markAsFinished];
            obj = nil;
        }];
        [self.mWriter finishWritingWithCompletionHandler:^{
            if (self.mWriter.status != AVAssetWriterStatusFailed && self.mWriter.status == AVAssetWriterStatusCompleted)
            {
                NSLog(@"Video writing succeeded.");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                 ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                 [library writeVideoAtPathToSavedPhotosAlbum:self.ouputUrl
                                             completionBlock:^(NSURL *assetURL, NSError *error) {
                     NSLog(@"%@ 保存到相册....  %@ ", error ? @"失败" : @"成功", self.ouputUrl);
                 }];
#pragma clang diagnostic pop
            } else
            {
                [self.mWriter cancelWriting];
                NSLog(@"Video writing failed: %@", self.mWriter.error);
            }
        }];
        if (_mPixelBufferAdaptor) {
            CVPixelBufferPoolRelease(_mPixelBufferAdaptor.pixelBufferPool);
        }
    }
}


- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)ts
{
    AVAssetWriterInput *writerInput = self.mWriter.inputs.firstObject;
    if ((!CMTIME_IS_VALID(ts) || pixelBuffer == nil) || writerInput == nil) {
        NSLog(@"PixelBuffer of invalid pts ...");
        return;
    }
    
    if (self.mWriter.status != AVAssetWriterStatusWriting && !_isStarting) {
        [self startAsyncEncoder];
        NSLog(@"Start writing ...");
    }
        
    void (^writer) (void) = ^()
    {
        if (!writerInput.readyForMoreMediaData)
        {
            NSLog(@"Had to drop an video frame: %@,  error is %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)), self.mWriter.error);
            return;
        }
        else if (self.mWriter.status == AVAssetWriterStatusWriting)
        {
            if (![self.mPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:ts])
            {
                NSLog(@"Problem appending video buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            } else{
                NSLog(@"Writing video pixel buffer ...  %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            }
        } else
        {
            NSLog(@"Write status not is writing ...");
        }
    };
    
    if (self.encoderType != QYEncoderTypeExporting)
    {
        while (!writerInput.readyForMoreMediaData) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        writer();
    } else
    {
        writer();
    }
}


// https://www.osstatus.com/search/results?platform=all&framework=all&search=
- (void)inputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer timestamp:(CMTime)ts
{
    if ((CMTIME_IS_INVALID(ts) || self.mWriter.error) && CMSampleBufferIsValid(sampleBuffer)) {
        return;
    }
    
    if (self.mWriter.status != AVAssetWriterStatusWriting && !_isStarting) {
        [self startAsyncEncoder];
        NSLog(@"1: Start writing ...");
        return;
    }
    
    void (^audioWriter) (AVAssetWriterInput *writerInput) = ^(AVAssetWriterInput *writerInput)
    {
        if (!writerInput.readyForMoreMediaData)
        {
            NSLog(@"2: Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            return;
        }
        
        if (self.mWriter.status == AVAssetWriterStatusWriting)
        {
            if (![writerInput appendSampleBuffer:sampleBuffer])
            {
                NSLog(@"3: Problem appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            } else {
                NSLog(@"Writing audio buffer ...  %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, ts)));
            }
        } else {
            NSLog(@"Asset writing audio status error, %ld, error = %@", (long)self.mWriter.status, self.mWriter.error);
        }
    };
    
    AVAssetWriterInput *input = self.mWriter.inputs.lastObject;
    if (self.encoderType != QYEncoderTypeExporting)
    {
        while (!input.readyForMoreMediaData) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        audioWriter(input);
    } else
    {
        audioWriter(input);
    }
}


- (void)inputSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType
{
    CMTime  pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if ([mediaType isEqualToString:AVMediaTypeVideo])
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (pixelBuffer == nil) {
            return;
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        [self inputPixelBuffer:pixelBuffer timestamp:pts];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    else
    {
        [self inputAudioSampleBuffer:sampleBuffer timestamp:pts];
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
                //[self removeObserver:self forKeyPath:kObserverWriterOutputStatus];
                break;
                
            case AVAssetWriterStatusFailed:
                NSLog(@"Encoder video of status is failed ... %@", self.mWriter.error);
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
            writerInput.performsMultiPassEncodingIfSupported = YES;
            [writer addInput:writerInput];
        }
        writerInput.expectsMediaDataInRealTime = (self.encoderType == QYEncoderTypeRecording) ? YES : NO;
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
                 AVVideoCompressionPropertiesKey    : @{AVVideoAverageBitRateKey : @(self.resolution.width * self.resolution.height * 4)},
//                 AVVideoAllowFrameReorderingKey     : @true,
//                 AVVideoExpectedSourceFrameRateKey  : @(30)
        };
    }
    else if ([mediaType isEqualToString:AVMediaTypeAudio])
    {
        // AVAudioSettings.h、CoreAudioBaseTypes.h
        return (self.encoderType == QYEncoderTypeRecording) ? [self audioCompressionOutputSetting] : [self audioCompressionOutputSetting];
    }
    return nil;
}



- (NSDictionary *)audioCompressionOutputSetting
{
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    return @{AVFormatIDKey                      : @(kAudioFormatMPEG4AAC),
             AVNumberOfChannelsKey              : @(2),
             AVSampleRateKey                    : @(44100),
             AVChannelLayoutKey                 : channelLayoutAsData,
             AVEncoderBitRateKey                : @(128000),
             AVEncoderAudioQualityKey           : @(AVAudioQualityHigh),
    };
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
