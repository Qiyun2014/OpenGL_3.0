//
//  QYPlayerViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/22.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPlayerViewController.h"
#import "QYMediaDecoder.h"

@interface QYPlayerViewController () <QYMediaDecoderDelegate>

@property (strong, nonatomic) QYMediaDecoder    *mediaDecoder;

@end

@implementation QYPlayerViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_mediaDecoder cleanup];
    _mediaDecoder = nil;
    [_renderView removeFromSuperview];
    _renderView = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"JJTM2837" ofType:@"mov"]];
    self.mediaDecoder = [[QYMediaDecoder alloc] initWithURL:url];
    self.mediaDecoder.delegate = self;
    [self.mediaDecoder startFrameRateDecoder];
    
    self.renderView = [[QYGLRenderView alloc] init];
    self.renderView.frame = self.view.bounds;
    [self.view addSubview:self.renderView];
}


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    [self.renderView displayPixelBuffer:pixelBuffer];
}


@end
