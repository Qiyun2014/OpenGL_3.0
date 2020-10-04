//
//  QYPlayerRecordViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/23.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPlayerRecordViewController.h"
#import "QYMediaEncoder.h"
#import "QYMediaDecoder.h"

@interface QYPlayerRecordViewController ()

@property (nonatomic, strong) QYMediaEncoder    *mEncoder;

@end

@implementation QYPlayerRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.mEncoder = [[QYMediaEncoder alloc] initWithOutputURL:[NSURL fileURLWithPath:[self createTempFileWithFormat:@"mp4"]] resolution:CGSizeMake(960, 540) encoderType:QYEncoderTypeRecording];
//    [self.mediaDecoder startAsyncDecoder];
}


//- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder mediaType:(AVMediaType)mediaType didOutputSampleBufferRef:(CMSampleBufferRef)sampleBuffer
//{
//    NSLog(@"~~~~~~~~  %@", mediaType);
//    [self.mEncoder inputSampleBuffer:sampleBuffer mediaType:mediaType];
//}



- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    [self.renderView displayPixelBuffer:pixelBuffer timestamp:ts];
    [self.mEncoder inputPixelBuffer:pixelBuffer timestamp:ts];
}


- (void)didDecoderFinished
{
    NSLog(@"解码完成");
    
    [self.mEncoder finishedEncoder];
}



@end
