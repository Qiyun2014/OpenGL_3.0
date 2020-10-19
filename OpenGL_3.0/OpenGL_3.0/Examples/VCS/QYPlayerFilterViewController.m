//
//  QYPlayerFilterViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPlayerFilterViewController.h"
#import "QYGLImageFilter.h"

@interface QYPlayerFilterViewController () <QYGLTextureDelegate>

@property (strong, nonatomic, nullable) QYGLImageFilter *imageFilter;


@end

@implementation QYPlayerFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.renderView.delegate = self;
    self.renderTexture = [[QYGLRenderTexture alloc] init];
    
    self.imageFilter = [[QYGLImageFilter alloc] init];
    self.imageFilter.intensity = 1.0;
    [self.renderTexture addTarget:self.imageFilter];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFilterAction:)];
    self.navigationItem.rightBarButtonItem = save;
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


#pragma mark    -   delegate


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    [self.renderView displayPixelBuffer:pixelBuffer timestamp:ts];
}

- (unsigned int)offscreenRenderWithTexture:(unsigned int)texture size:(CGSize)size ts:(CMTime)ts
{
    return [self.renderTexture displayTexture:texture size:size ts:ts];
}

- (void)didDecoderFinished
{
    NSLog(@"解码完成");
    [self.imageFilter cleanupMemory];
    self.imageFilter = nil;
}




@end
