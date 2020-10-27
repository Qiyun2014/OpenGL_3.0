//
//  QYMediaCodecViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/28.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYMediaCodecViewController.h"
#import "QYMediaEncoder.h"
#import "QYPixelBufferConverter.h"
#import "QYGLOutputPixelBuffer.h"
#import "QYMediaDecoder.h"
#import "QYGLRenderTexture.h"
#import "QYGLImageFilter.h"

@interface QYMediaCodecViewController () <QYConverterDelegate, QYGLPixelBufferDelegate, QYMediaDecoderDelegate>

@property (strong, nonatomic, nullable) QYGLRenderTexture *renderTexture;
@property (strong, nonatomic, nullable) QYGLImageFilter *imageFilter;

@property (strong, nonatomic) QYMediaDecoder    *mediaDecoder;
@property (nonatomic, strong) QYMediaEncoder    *mEncoder;
@property (nonatomic, strong) QYPixelBufferConverter *converter;
@property (strong, nonatomic) QYGLOutputPixelBuffer *outputPixelBuffer;

@end

@implementation QYMediaCodecViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 渲染器
    self.renderTexture = [[QYGLRenderTexture alloc] init];
    self.imageFilter = [[QYGLImageFilter alloc] init];
    self.outputPixelBuffer = [[QYGLOutputPixelBuffer alloc] init];

    self.imageFilter.intensity = 1.0;
    [self.renderTexture addTarget:self.imageFilter];
    
    // 渲染输出
    self.outputPixelBuffer.pixelBufferDelegate = self;
    [self.renderTexture addTarget:self.outputPixelBuffer];

    
    // 转换器
    self.converter = [[QYPixelBufferConverter alloc] initWithDelegate:self renderSize:CGSizeMake(720, 1280)];
    
    // 编码器
    self.mEncoder = [[QYMediaEncoder alloc] initWithOutputURL:[NSURL fileURLWithPath:[self createTempFileWithFormat:@"mp4"]] resolution:CGSizeMake(720, 1280) encoderType:QYEncoderTypeExporting];
    
    // 开始解码
    [self.mediaDecoder startAsyncDecoder];
    
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFilterAction:)];
    self.navigationItem.rightBarButtonItem = save;
}


- (QYMediaDecoder *)mediaDecoder
{
    if (!_mediaDecoder) {
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"XFXM8486" ofType:@"mp4"]];
        _mediaDecoder = [[QYMediaDecoder alloc] initWithURL:url];
        _mediaDecoder.delegate = self;
    }
    return _mediaDecoder;
}



- (NSArray *)filters {
    return @[@"LUT-原图", @"LUT-冷酷", @"LUT-城市01", @"LUT-城市02",
             @"LUT-平衡", @"LUT-鲜艳", @"LUT-高亮",   @"LUT-深秋",
             @"LUT-日落", @"LUT-明亮", @"LUT-樱花",   @"LUT-橘色",
             @"LUT-温暖", @"LUT-相机", @"LUT-绿色",   @"LUT-全彩",
             @"LUT-古典", @"LUT-寒冬", @"LUT-恐怖红", @"LUT-恐怖蓝",
             @"LUT-真实", @"LUT-深蓝", @"LUT-淡蓝",   @"LUT-照明"];
}


- (void)addFilterAction:(UIBarButtonItem *)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择一种效果"
                                                                             message:@"实时作用到当前画面"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    [[self filters] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIAlertAction *elementAction = [UIAlertAction actionWithTitle:obj style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"LUTSource.bundle"];
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            NSString *name = [self filters][idx];
            self.imageFilter.lutImage = [UIImage imageWithContentsOfFile:[bundle pathForResource:name ofType:@"png"]];
            NSLog(@"滤镜名  %@", name);
        }];
        [alertController addAction:elementAction];
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"OK Action");
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}



#pragma mark    -   QYMediaDecoderDelegate


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder mediaType:(AVMediaType)mediaType didOutputSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    if ([mediaType isEqualToString:AVMediaTypeVideo])
    {
        CVImageBufferRef movieFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(movieFrame,0);
        [self.converter renderImagePixelBuffer:movieFrame timestamp:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
    }
    else {
        [self.mEncoder inputSampleBuffer:sampleBuffer mediaType:mediaType];
    }
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


#pragma mark    -   QYConverterDelegate

- (GLuint)textureWithSize:(CGSize)size textureId:(GLuint)texId timestamp:(CMTime)ts
{
    return [self.renderTexture displayTexture:texId size:size ts:ts];
}



#pragma mark    -   QYGLPixelBufferDelegate

- (void)textureOutput:(QYGLTextureOutput *)textureOutput timestamp:(CMTime)ts didOutputSampleBuffer:(CVPixelBufferRef)pixelBuffer
{
//    NSLog(@"textureOutput pixel buffer ....... %lld", ts.value / ts.timescale);
    [self.mEncoder inputPixelBuffer:pixelBuffer timestamp:ts];
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
