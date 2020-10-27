//
//  QYMediaDecoder.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYMediaDecoder.h"
#import "QYGLUtils.h"
#import "QYGLContext.h"

NSString *kObserverReaderOutputStatus = @"reader.status";
static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;


@interface
QYMediaDecoder ()<AVPlayerItemOutputPullDelegate>

@property (strong, nonatomic) AVPlayer      *player;
@property (strong, nonatomic) AVURLAsset    *asset;

// AVAssetReader provides services for obtaining media data from an asset.
@property (strong, nonatomic, nullable) AVAssetReader *reader;

// Class representing a timer bound to the display vsync.
@property (strong, nonatomic) CADisplayLink *displayLink;

// A concrete subclass of AVPlayerItemOutput that vends video images as CVPixelBuffers.
@property (strong, nonatomic) AVPlayerItemVideoOutput *videoOutput;

@end

@implementation QYMediaDecoder
{
    id _notificationToken;
    dispatch_semaphore_t _transcode, _lock_semaphore;
}

- (id)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        _transcode = dispatch_semaphore_create(0);
        _lock_semaphore = dispatch_semaphore_create(1);
        [self assetWithURL:URL];
    }
    return self;
}


- (void)dealloc
{
    _transcode = nil;
    [self cleanup];
}


- (void)cleanup
{
    if (_notificationToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:_notificationToken
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.player.currentItem];
        _notificationToken = nil;
    }
    if (_asset) {
        [_asset cancelLoading];
        _asset = nil;
    }
    if (_reader) {
        [_reader cancelReading];
        _reader = nil;
    }
    if (_displayLink) {
        [_displayLink setPaused:YES];
        [_displayLink invalidate];
        _displayLink = nil;
    }
    if (_videoOutput) {
        _videoOutput = nil;
    }
    if (_player) {
        [_player cancelPendingPrerolls];
        [_player pause];
        _player = nil;
    }
}


#pragma mark    -   get method

- (AVPlayer *)player
{
    if (!_player) {
        _player = [[AVPlayer alloc] initWithURL:self.asset.URL];
    }
    return _player;;
}


- (AVAssetReader *)reader
{
    if (!_reader) {
        NSError *error;
        _reader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
        if (error) {
            NSLog(@"AssetReader create failed, error is %@", error);
            return nil;
        }
        [self addObserver:self
               forKeyPath:kObserverReaderOutputStatus
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:NULL];
        [self addAssetTracksToReader:_reader sourceAsset:self.asset];
    }
    return _reader;
}


- (CADisplayLink *)displayLink
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink setPreferredFramesPerSecond:24];
        [_displayLink setPaused:YES];
    }
    return _displayLink;
}


- (AVPlayerItemVideoOutput *)videoOutput {
    if (!_videoOutput) {
        NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
#if (TARGET_IPHONE_SIMULATOR == 1 && TARGET_OS_IPHONE == 1)
#else
                                            (id)kCVPixelBufferOpenGLESTextureCacheCompatibilityKey : @(true),
                                            (id)kCVPixelBufferIOSurfacePropertiesKey: @{},
                                            (id)kCVPixelBufferOpenGLCompatibilityKey : @(true),
#endif
#if TARGET_OS_MAC
//                                            (id)kCVPixelBufferMetalCompatibilityKey : @(true),
#endif
        };
        _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
        // Sets the receiver's delegate and a dispatch queue on which the delegate will be called.
        [_videoOutput setDelegate:self queue:dispatch_queue_create("voe.output.pixelbuffer", DISPATCH_QUEUE_SERIAL)];
        // Message this method before you suspend your use of a CVDisplayLink or CADisplayLink
        [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.03];
    }
    return _videoOutput;
}

#pragma mark    -   public method


- (void)supportMediaEncoder:(QYMediaEncoder *)encoderTarget
{
    _writerTarget = encoderTarget;
    [_writerTarget startAsyncEncoderAtTime:kCMTimeZero];
}


- (void)startAsyncDecoder
{
    if (self.reader && self.reader.status != AVAssetReaderStatusReading)
    {
        if ([self.reader startReading] == NO)
        {
            NSLog(@"Error reading from file at URL: %@", self.asset.URL);
            return;
        }
        [self startMediaDecoder];
    } else {
        NSLog(@"AssetReader status is %ld, current error is %@", (long)self.reader.status, self.reader.error);
    }
}


- (void)startFrameRateDecoder
{
    if (self.reader && self.reader.status != AVAssetReaderStatusReading)
    {
        [self.reader startReading];
        [self preparePlayback];
        [self.displayLink setPaused:NO];
    } else {
        NSLog(@"AssetReader status is %ld, current error is %@", (long)self.reader.status, self.reader.error);
    }
}


- (void)updateURL:(NSURL *)URL
{
    dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
        [self cleanup];
        [self assetWithURL:URL];
    });
}


#pragma mark    -   private method

- (void)startMediaDecoder {
    
    if (_writerTarget)
    {
        __block AVAssetReaderOutput *videoReaderOutput, *audioReaderOutput;
        for (AVAssetReaderOutput *readerOutput in self.reader.outputs)
        {
            if ([readerOutput.mediaType isEqualToString:AVMediaTypeAudio])
            {
                audioReaderOutput = readerOutput;
            }
            else if ([readerOutput.mediaType isEqualToString:AVMediaTypeVideo]) {
                videoReaderOutput = readerOutput;
            }
        }
        
        OBJC_WEAK(self);
        [_writerTarget setVideoInputReadyCallback:^BOOL{
            OBJC_STRONG(weak_self);
            return [strong_weak_self readNextVideoFrameFromOutput:videoReaderOutput];
        }];
        
        [_writerTarget setAudioInputReadyCallback:^BOOL{
            OBJC_STRONG(weak_self);
            return [strong_weak_self readNextAudioFrameFromOutput:audioReaderOutput];
        }];
        
        [_writerTarget enableSynchronizationCallbacks];
    }
    else {
        [self loopCopyAllSamples];
    }
}


- (void)loopCopyAllSamples
{
    OBJC_WEAK(self);
    dispatch_async([QYGLContext shareImageContext].contextQueue, ^
    {
        OBJC_STRONG(weak_self);
        while (strong_weak_self.reader.status == AVAssetReaderStatusReading && strong_weak_self.reader.outputs.count > 0)
        {
            [strong_weak_self.reader.outputs enumerateObjectsUsingBlock:^(AVAssetReaderOutput * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
            {
                const CMSampleBufferRef sampleBuffer = [obj copyNextSampleBuffer];
                if (sampleBuffer) {
                    dispatch_semaphore_wait(strong_weak_self->_lock_semaphore, DISPATCH_TIME_FOREVER);
                    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaDecoder:mediaType:didOutputSampleBufferRef:)])
                    {
                        [self.delegate mediaDecoder:self mediaType:obj.mediaType didOutputSampleBufferRef:sampleBuffer];
                    }
                    dispatch_semaphore_signal(strong_weak_self->_lock_semaphore);
                    CMSampleBufferInvalidate(sampleBuffer);
                    CFRelease(sampleBuffer);
                }
                if (idx + 1 == strong_weak_self.reader.outputs.count) {
                    dispatch_semaphore_signal(strong_weak_self->_transcode);
                }
            }];
            dispatch_semaphore_wait(strong_weak_self->_transcode, DISPATCH_TIME_FOREVER);
        }
        
        dispatch_semaphore_wait(strong_weak_self->_lock_semaphore, DISPATCH_TIME_FOREVER);
        if ([self.delegate respondsToSelector:@selector(didDecoderFinished)]) {
            [self.delegate didDecoderFinished];
        }
        
        if (self.reader.status == AVAssetReaderStatusCompleted) {
            [self.reader cancelReading];
            [self cleanup];
        }
        dispatch_semaphore_signal(strong_weak_self->_lock_semaphore);
    });
}



- (void)displayLinkCallback:(CADisplayLink *)displayLink
{
    CMTime outputItemTime = kCMTimeInvalid;
    
    // Calculate the nextVsync time which is when the screen will be refreshed next.
    CFTimeInterval nextVSync = ([displayLink timestamp] + [displayLink duration]);
    outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
    
    if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime])
    {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        if (self.delegate && [self.delegate respondsToSelector:@selector(mediaDecoder:timestamp:didOutputPixelBufferRef:)])
        {
            [self.delegate mediaDecoder:self timestamp:outputItemTime didOutputPixelBufferRef:pixelBuffer];
        }
        // NSLog(@"PixelBuffer decode with ts = %lf", nextVSync);
        if (pixelBuffer != NULL) {
            CFRelease(pixelBuffer);
        }
    } else {
        NSLog(@"Unsupport format or application become backgroud ...  %lf", nextVSync);
    }
}


- (void)assetWithURL:(NSURL *)url
{
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @true}];
    if (urlAsset) {
        OBJC_WEAK(self);
        [urlAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^
        {
            OBJC_STRONG(weak_self);
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [urlAsset statusOfValueForKey:@"tracks" error:&error];
            if (tracksStatus == AVKeyValueStatusLoaded) {
                strong_weak_self.asset = urlAsset;
            } else {
                NSLog(@"Asset loader failed, reason is %@", error.description);
            }
            dispatch_semaphore_signal(strong_weak_self->_transcode);
        }];
    }
    dispatch_semaphore_wait(_transcode, DISPATCH_TIME_FOREVER);
}


- (void)preparePlayback
{
    OBJC_WEAK(self);
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.asset.URL];
    _notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:playerItem
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *note) {
        OBJC_STRONG(weak_self);
        if (strong_weak_self.delegate && [strong_weak_self.delegate respondsToSelector:@selector(didDecoderFinished)]) {
            [strong_weak_self.delegate didDecoderFinished];
        }
        NSLog(@"Deocder finished ...");
        [strong_weak_self.displayLink setPaused:YES];
        [strong_weak_self cleanup];
    }];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^
    {
        if ([self.asset statusOfValueForKey:@"tracks" error:nil] ==  AVKeyValueStatusLoaded)
        {
            NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
            if ([videoTracks count] > 0) {
                AVAssetTrack *videoTrack = videoTracks.firstObject;
                [videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^{
                    if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
                        // CGAffineTransform preferredTransform = [videoTrack preferredTransform];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            OBJC_STRONG(weak_self);
                            if (![playerItem.outputs containsObject:strong_weak_self.videoOutput]) {
                                [playerItem addOutput:strong_weak_self.videoOutput];
                            }
                            [strong_weak_self.player replaceCurrentItemWithPlayerItem:playerItem];
                            [strong_weak_self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.03];
                            [strong_weak_self.player play];
                        });
                    }
                }];
            }
        }
    }];
}


- (void)addAssetTracksToReader:(AVAssetReader *)reader sourceAsset:(AVAsset *)asset
{
    if (asset)
    {
        [asset.tracks enumerateObjectsUsingBlock:^(AVAssetTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
        {
            AVAssetReaderTrackOutput *trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:obj
                                                                                               outputSettings:[self outputSettingsWithMediaType:obj.mediaType]];
            if ([reader canAddOutput:trackOutput])
            {
                trackOutput.alwaysCopiesSampleData = NO;
                [reader addOutput:trackOutput];
                if ([obj.mediaType isEqualToString:AVMediaTypeAudio]) {
                    _hasAudioTrack = YES;
                }
            }
        }];
    }
}


- (NSDictionary *)outputSettingsWithMediaType:(AVMediaType)mediaType
{
    if ([mediaType isEqualToString:AVMediaTypeAudio])
    {
        return @{AVFormatIDKey                        : @(kAudioFormatLinearPCM),
                 AVLinearPCMIsBigEndianKey            : @NO,
                 AVLinearPCMIsFloatKey                : @YES,
                 AVLinearPCMBitDepthKey               : @(32),
        };
    }
    else if ([mediaType isEqualToString:AVMediaTypeVideo])
    {
        return @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    }
    return nil;
}



#pragma mark    -   reader next samplebuffer


- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerOutput
{
    if (self.reader.status == AVAssetReaderStatusReading && !_videoEncodingIsFinished) {
        
        const CMSampleBufferRef sampleBuffer = [readerOutput copyNextSampleBuffer];
        if (sampleBuffer && CMTimeCompare(CMSampleBufferGetOutputDuration(sampleBuffer), kCMTimeZero))
        {
            OBJC_WEAK(self);
            dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
                OBJC_STRONG(weak_self);
                // 拿到视频数据，转成纹理做预处理
                NSLog(@"---------------------------------------------------------------------------------  >>>>   video ");
//                [strong_weak_self->_writerTarget inputSampleBuffer:sampleBuffer mediaType:AVMediaTypeVideo];
                if (strong_weak_self.delegate && [strong_weak_self.delegate respondsToSelector:@selector(mediaDecoder:mediaType:didOutputSampleBufferRef:)])
                {
                    [strong_weak_self.delegate mediaDecoder:strong_weak_self mediaType:AVMediaTypeVideo didOutputSampleBufferRef:sampleBuffer];
                }
                CMSampleBufferInvalidate(sampleBuffer);
                CFRelease(sampleBuffer);
            });
            return YES;
        }
    }
    else if (_writerTarget != nil)
    {
        if (self.reader.status == AVAssetReaderStatusCompleted) {
            [self cleanup];
        }
    }
    return NO;
}


- (BOOL)readNextAudioFrameFromOutput:(AVAssetReaderOutput *)readerOutput
{
    if (self.reader.status == AVAssetReaderStatusReading && !_audioEncodingIsFinished)
    {
        CMSampleBufferRef audioSampleBufferRef = [readerOutput copyNextSampleBuffer];
        if (audioSampleBufferRef)
        {
            //NSLog(@"read an audio frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, CMSampleBufferGetOutputPresentationTimeStamp(audioSampleBufferRef))));
            NSLog(@"---------------------------------------------------------------------------------  ****   audio ");
             [_writerTarget inputSampleBuffer:audioSampleBufferRef mediaType:AVMediaTypeAudio];
            CFRelease(audioSampleBufferRef);
            return YES;
        }
    }
    else if (_writerTarget != nil)
    {
        if (self.reader.status == AVAssetReaderStatusCompleted ||
            self.reader.status == AVAssetReaderStatusFailed ||
            self.reader.status == AVAssetReaderStatusCancelled)
        {
            NSLog(@"结束编码");
            [_writerTarget finishedEncoder];
            [self cleanup];
        }
    }
    return NO;
}


#pragma mark    -   kvo


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:kObserverReaderOutputStatus])
    {
        switch (self.reader.status)
        {
            case AVAssetReaderStatusReading:
                NSLog(@"decode video of status is reading ...");
                break;
                
            case AVAssetReaderStatusCompleted:
                NSLog(@"decode video of status is completed ...");
                _videoEncodingIsFinished = YES;
                _audioEncodingIsFinished = YES;
                [self removeObserver:self forKeyPath:kObserverReaderOutputStatus];
                break;
                
            case AVAssetReaderStatusFailed:
                NSLog(@"decode video of status is failed ...");
                break;
                
            case AVAssetReaderStatusCancelled:
                NSLog(@"decode video of status is cancelled ...");
                break;
                
            default:
                break;
        }
    }
    else if (context == AVPlayerItemStatusContext) {
        
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerItemStatusUnknown:
                
                break;
            case AVPlayerItemStatusReadyToPlay:
                NSLog(@"Player of prepare to play ...");
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"Player item status failed, error is %@", self.player.currentItem.error);
                break;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}



#pragma mark    -   AVPlayerItemOutputPullDelegate

 /*!
    @method            outputMediaDataWillChange:
    @abstract        A method invoked once, prior to a new sample, if the AVPlayerItemOutput sender was previously messaged requestNotificationOfMediaDataChangeWithAdvanceInterval:.
    @discussion
        This method is invoked once after the sender is messaged requestNotificationOfMediaDataChangeWithAdvanceInterval:.
  */

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender API_AVAILABLE(macos(10.8), ios(6.0), tvos(9.0), watchos(1.0)) {
 
    NSLog(@"output media data will change ...");
    
    // Restart display link.
    [[self displayLink] setPaused:NO];
}


 /*!
    @method            outputSequenceWasFlushed:
    @abstract        A method invoked when the output is commencing a new sequence.
    @discussion
        This method is invoked after any seeking and change in playback direction. If you are maintaining any queued future samples, copied previously, you may want to discard these after receiving this message.
  */

- (void)outputSequenceWasFlushed:(AVPlayerItemOutput *)output API_AVAILABLE(macos(10.8), ios(6.0), tvos(9.0), watchos(1.0)) {
    
    NSLog(@"output sequence was flushed ...");
}

@end
