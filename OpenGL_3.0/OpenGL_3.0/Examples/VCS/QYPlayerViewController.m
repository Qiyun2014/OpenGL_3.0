//
//  QYPlayerViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/22.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPlayerViewController.h"

@interface QYPlayerViewController () <QYMediaDecoderDelegate>


@end

@implementation QYPlayerViewController

- (id)init
{
    if (self = [super init]) {
        
        
    }
    return self;
}

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
    
    [self.mediaDecoder startFrameRateDecoder];
    [self.view addSubview:self.renderView];
}


- (QYGLRenderView *)renderView
{
    if (!_renderView) {
        _renderView = [[QYGLRenderView alloc] init];
        _renderView.frame = self.view.bounds;
    }
    return _renderView;
}

- (QYMediaDecoder *)mediaDecoder
{
    if (!_mediaDecoder) {
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"rowing" ofType:@"mp4"]];
        _mediaDecoder = [[QYMediaDecoder alloc] initWithURL:url];
        _mediaDecoder.delegate = self;
    }
    return _mediaDecoder;
}


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    [self.renderView displayPixelBuffer:pixelBuffer];
}


- (NSString *)createTempFileWithFormat:(NSString *)format
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", dateTime, format];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *file = [paths.firstObject stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    }
    return file;
}


@end
