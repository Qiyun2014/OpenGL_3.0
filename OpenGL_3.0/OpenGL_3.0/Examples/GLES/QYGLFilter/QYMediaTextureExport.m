//
//  QYMediaTextureExport.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/27.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYMediaTextureExport.h"
#import <AVFoundation/AVFoundation.h>
#import "QYMeidaWriterOutput.h"
#import "QYGLContext.h"

@interface QYMediaTextureExport ()

@property (strong, nonatomic, nullable) NSURL   *url;
@property (strong, nonatomic, nullable) AVAsset *asset;
@property (strong, nonatomic, nullable) AVAssetReader *reader;
@property (strong, nonatomic, nullable) QYMeidaWriterOutput *writerOutput;


@end

@implementation QYMediaTextureExport
{
    dispatch_semaphore_t _transcode, _lock_semaphore;
}

- (id)initWithURL:(NSURL *)url
{
    if (self = [super initWithVertexShader:nil fragmentShader:nil]) {

        _transcode = dispatch_semaphore_create(0);
        _lock_semaphore = dispatch_semaphore_create(1);
        [self assetWithURL:url];
    }
    return self;
}



#pragma mark    -   private method


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
    } else {
        NSLog(@"文件不存在，读取失败...   url = %@", url);
        dispatch_semaphore_signal(_transcode);
    }
    dispatch_semaphore_wait(_transcode, DISPATCH_TIME_FOREVER);
}


- (AVAssetReader *)reader
{
    if (!_reader) {
        NSError *error = nil;
        _reader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];

        // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
        AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        readerVideoTrackOutput.alwaysCopiesSampleData = NO;
        if ([_reader canAddOutput:readerVideoTrackOutput]) [_reader addOutput:readerVideoTrackOutput];
        
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        BOOL shouldRecordAudioTrack = ([audioTracks count] > 0);
        if (shouldRecordAudioTrack) {
            AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
            AVAssetReaderAudioMixOutput *audioMixOutput = nil;
            audioMixOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:@[audioTrack] audioSettings:nil];
            audioMixOutput.alwaysCopiesSampleData = NO;
            if ([_reader canAddOutput:audioMixOutput]) [_reader addOutput:audioMixOutput];
        }
    }
    return _reader;
}


- (void)startProcessAsset {
    
    AVAssetReaderOutput *readerVideoTrackOutput = nil;
    AVAssetReaderOutput *readerAudioTrackOutput = nil;
    
    for( AVAssetReaderOutput *output in self.reader.outputs ) {
        if( [output.mediaType isEqualToString:AVMediaTypeAudio] ) {
            readerAudioTrackOutput = output;
        }
        else if( [output.mediaType isEqualToString:AVMediaTypeVideo] ) {
            readerVideoTrackOutput = output;
        }
    }
    
    if ([self.reader startReading] == NO)
    {
        NSLog(@"Error reading from file at URL: %@", self.url);
        return;
    }
    
    __weak typeof(self) weakSelf = self;

    if (_writerOutput != nil)
    {
        [_writerOutput setVideoInputReadyCallback:^{
            __strong typeof(self) strongSelf = weakSelf;
            BOOL success = [strongSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
            return success;
        }];
        
        [_writerOutput setAudioInputReadyCallback:^{
            __strong typeof(self) strongSelf = weakSelf;
            BOOL success = [strongSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
            return success;
        }];
    }
    else
    {
        while (self.reader.status == AVAssetReaderStatusReading) {
            
        }
        
        if (self.reader.status == AVAssetReaderStatusCompleted) {
            
            [self.reader cancelReading];
        
        }
    }
}


- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerVideoTrackOutput;
{
    if (self.reader.status == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
        if (sampleBufferRef && CMTimeCompare(CMSampleBufferGetOutputDuration(sampleBufferRef), kCMTimeZero))
        {
            //NSLog(@"read a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferRef))));
            
            __weak typeof(self) weakSelf = self;
            dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
                __strong typeof(self) strongSelf = weakSelf;
                //[strongSelf processMovieFrame:sampleBufferRef];
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
            });
            
            return YES;
        }
    }
    else if (_writerOutput != nil)
    {
        if (self.reader.status == AVAssetReaderStatusCompleted)
        {
//            [self endProcessing];
        }
    }
    return NO;
}


- (BOOL)readNextAudioSampleFromOutput:(AVAssetReaderOutput *)readerAudioTrackOutput;
{
    if (self.reader.status == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef audioSampleBufferRef = [readerAudioTrackOutput copyNextSampleBuffer];
        if (audioSampleBufferRef)
        {
            //NSLog(@"read an audio frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, CMSampleBufferGetOutputPresentationTimeStamp(audioSampleBufferRef))));
            // [self.audioEncodingTarget processAudioBuffer:audioSampleBufferRef];
            CFRelease(audioSampleBufferRef);
            return YES;
        }
    }
    else if (_writerOutput != nil)
    {
        if (self.reader.status == AVAssetReaderStatusCompleted || self.reader.status == AVAssetReaderStatusFailed ||
            self.reader.status == AVAssetReaderStatusCancelled)
        {
            // [self endProcessing];
        }
    }
    return NO;
}


- (void)endProcessing
{
    if (_writerOutput != nil) {
        [_writerOutput setVideoInputReadyCallback:^BOOL{
            return NO;
        }];
        [_writerOutput setAudioInputReadyCallback:^BOOL{
            return NO;
        }];
    }
}


- (void)cancelProcessing
{
    if (_reader) {
        [_reader cancelReading];
    }
    [self endProcessing];
}


@end
