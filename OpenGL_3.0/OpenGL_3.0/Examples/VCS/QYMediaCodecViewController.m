//
//  QYMediaCodecViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/28.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYMediaCodecViewController.h"
#import "QYMediaEncoder.h"

@interface QYMediaCodecViewController ()

@property (nonatomic, strong) QYMediaEncoder    *mEncoder;

@end

@implementation QYMediaCodecViewController

- (void)viewDidLoad {
//    [super viewDidLoad];

    self.mEncoder = [[QYMediaEncoder alloc] initWithOutputURL:[NSURL fileURLWithPath:[self createTempFileWithFormat:@"mp4"]] resolution:CGSizeMake(960, 540) encoderType:QYEncoderTypeExporting];

    [self addChildElements];
    [self.mediaDecoder startAsyncDecoder];
}


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    
}


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder mediaType:(AVMediaType)mediaType didOutputSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    [self.mEncoder inputSampleBuffer:sampleBuffer mediaType:mediaType];
}


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder didOccurError:(MediaError)error
{
    
}


- (void)didDecoderFinished
{
    NSLog(@"解码完成");
    [self.mediaDecoder cleanup];
    [self.mEncoder finishedEncoder];
}

@end
