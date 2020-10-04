//
//  QYImageRenderViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYImageRenderViewController.h"

@interface QYImageRenderViewController ()

@end

@implementation QYImageRenderViewController


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"yourname" ofType:@"png"];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:imagePath
                                                                      options:@{GLKTextureLoaderOriginBottomLeft : @true, GLKTextureLoaderGenerateMipmaps : @true}
                                                                        error:NULL];
    self.mTextureId = textureInfo.name;
    _imageSize = CGSizeMake(textureInfo.width, textureInfo.height);
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    OBJC_WEAK(self);
    self.completion = ^{
        OBJC_STRONG(weak_self);
        strong_weak_self->_blurIndensity = glGetUniformLocation(strong_weak_self.mProgram, "indensity");
    };
    
    [[self labelTitles] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(80, CGRectGetHeight(self.view.bounds) - 60 - 45 * idx, CGRectGetWidth(self.view.bounds) - 100, 20)];
        switch (idx) {
            case 0:
                {
                    slider.minimumValue = 0.0;
                    slider.maximumValue = 2.0;
                    slider.value = 1.0;
                }
                break;
                
            case 1:
            case 2:
            {
                slider.minimumValue = 0.0;
                slider.maximumValue = 360;
                slider.value = 0;
            }
                break;
                
            case 3:
            case 4:
            {
                slider.minimumValue = -2;
                slider.maximumValue = 2;
                slider.value = 0;
            }
                break;
                
            case 5:
            {
                slider.minimumValue = 0;
                slider.maximumValue = 15;
                slider.value = 0;
            }
                break;
                
            default:
                break;
        }
        slider.tag = idx + 1;
        [slider addTarget:self action:@selector(zoomAction:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:slider];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, CGRectGetHeight(self.view.bounds) - 60 - 45 * idx, 70, 20)];
        label.text = obj;
        label.textColor = [UIColor redColor];
        label.font = [UIFont systemFontOfSize:14];
        [self.view addSubview:label];
    }];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glUniform1f(_blurIndensity, _indensity);
    [super glkView:view drawInRect:rect];
}


- (void)setIndensity:(float)indensity {
    
    glUniform1f(_blurIndensity, indensity);
    _indensity = indensity;
}


- (NSArray *)labelTitles
{
    return @[@"缩放", @"X轴-旋转",@"Y轴-旋转", @"X轴移动", @"Y轴移动", @"模糊强度"];
}


- (void)zoomAction:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    switch (slider.tag) {
        case 1:
        {
            [self setZoom:slider.value];
        }
            break;
            
        case 2:
        {
            [self setRotationAngle:slider.value];
        }
            break;
            
        case 3:
        {
            [self setVerticalRotationAngle:slider.value];
        }
            break;
            
        case 4:
        {
            [self setOffsetPoint:CGPointMake(slider.value, self.offsetPoint.y)];
        }
            break;
            
        case 5:
        {
            [self setOffsetPoint:CGPointMake(self.offsetPoint.x, slider.value)];
        }
            break;
            
        case 6:
        {
            [self setIndensity:slider.value];
            NSLog(@"indensity = %.2f", slider.value);
        }
            break;
            
        default:
            break;
    }
}



@end
