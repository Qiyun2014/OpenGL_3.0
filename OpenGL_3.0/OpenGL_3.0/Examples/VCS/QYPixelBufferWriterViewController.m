//
//  QYPixelBufferWriterViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPixelBufferWriterViewController.h"
#import "QYGLOutputPixelBuffer.h"
#import "QYMediaEncoder.h"

@interface QYPixelBufferWriterViewController () <QYGLPixelBufferDelegate>

@property (strong, nonatomic) QYGLOutputPixelBuffer *outputPixelBuffer;
@property (nonatomic, strong) QYMediaEncoder    *mEncoder;

@end

@implementation QYPixelBufferWriterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.outputPixelBuffer = [[QYGLOutputPixelBuffer alloc] init];
    self.outputPixelBuffer.pixelBufferDelegate = self;
    [self.renderTexture addTarget:self.outputPixelBuffer];
    
    self.mEncoder = [[QYMediaEncoder alloc] initWithOutputURL:[NSURL fileURLWithPath:[self createTempFileWithFormat:@"mp4"]] resolution:CGSizeMake(960, 540)];

}


- (void)textureOutput:(QYGLTextureOutput *)textureOutput timestamp:(CMTime)ts didOutputSampleBuffer:(CVPixelBufferRef)pixelBuffer
{
    NSLog(@"textureOutput pixel buffer ....... %lld", ts.value / ts.timescale);
    [self.mEncoder inputPixelBuffer:pixelBuffer timestamp:ts];
}


- (void)didDecoderFinished
{    
    [self.mEncoder finishedEncoder];
}


@end
