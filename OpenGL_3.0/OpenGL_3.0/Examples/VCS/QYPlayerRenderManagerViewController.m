//
//  QYPlayerRenderManagerViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/22.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPlayerRenderManagerViewController.h"

@interface QYPlayerRenderManagerViewController ()

@end

@implementation QYPlayerRenderManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
            [self.renderView setZoom:slider.value];
        }
            break;
            
        case 2:
        {
            [self.renderView setRotationAngle:slider.value];
        }
            break;
            
        case 3:
        {
            [self.renderView setVerticalRotationAngle:slider.value];
        }
            break;
            
        case 4:
        {
            [self.renderView setOffsetPoint:CGPointMake(slider.value, self.renderView.offsetPoint.y)];
        }
            break;
            
        case 5:
        {
            [self.renderView setOffsetPoint:CGPointMake(self.renderView.offsetPoint.x, slider.value)];
        }
            break;
            
        case 6:
        {
            [self.renderView setIndensity:slider.value];
        }
            break;
            
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
