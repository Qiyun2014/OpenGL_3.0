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

NSString *kObserverReaderOutputStatus = @"assetReader.status";


@interface QYMediaDecoder ()

@property (assign, nonatomic) BOOL isBackground;
@property (nonatomic, strong) AVAsset   *asset;
@property (strong, nonatomic) CADisplayLink *displayLink;

@end

@implementation QYMediaDecoder

- (id)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        [self assetWithURL:URL];
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.displayLink setPaused:YES];
    }
    return self;
}


#pragma mark    -   get method

- (AVAssetReader *)reader
{
    if (!_reader) {
        NSError *error;
        _reader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
        if (error) {
            NSLog(@"AssetReader create failed, error is %@", error);
            return nil;
        }
        [self addObserver:self forKeyPath:kObserverReaderOutputStatus options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        [self addAssetTracksToReader:_reader sourceAsset:self.asset];
    }
    return _reader;
}


- (AVAssetReaderOutput *)readerOutput
{
    if (!_readerOutput) {
        _readerOutput = [[AVAssetReaderOutput alloc] init];
    }
    return _readerOutput;
}


#pragma mark    -   public metho

- (void)startMediaDecoder
{
    if (self.reader && self.reader.status != AVAssetReaderStatusReading)
    {
        [self.reader startReading];
        [self.displayLink setPaused:NO];
    } else {
        NSLog(@"AssetReader status is %ld, current start error", (long)self.reader.status);
    }
}



#pragma mark    -   private method


- (void)displayLinkCallback:(CADisplayLink *)displayLink
{
    dispatch_async([QYGLContext shareImageContext].contextQueue, ^{
        
    });
}


- (void)assetWithURL:(NSURL *)url
{
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @true}];
    if (urlAsset) {
        OBJC_WEAK(self);
        [urlAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
            OBJC_STRONG(weak_self);
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [urlAsset statusOfValueForKey:@"tracks" error:&error];
            if (tracksStatus == AVKeyValueStatusLoaded) {
                strong_weak_self.asset = urlAsset;
            } else {
                NSLog(@"Asset loader failed, reason is %@", error.description);
            }
        }];
    }
}


- (void)addAssetTracksToReader:(AVAssetReader *)reader sourceAsset:(AVAsset *)asset
{
    if (asset)
    {
        [asset.tracks enumerateObjectsUsingBlock:^(AVAssetTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
        {
            AVAssetReaderTrackOutput *trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:obj outputSettings:[self outputSettingsWithMediaType:obj.mediaType]];
            if ([reader canAddOutput:trackOutput])
            {
                trackOutput.alwaysCopiesSampleData = NO;
                [reader addOutput:trackOutput];
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


@end
