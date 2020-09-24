//
//  QYImageTransitionTypeViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYImageTransitionTypeViewController.h"

@interface QYImageTransitionTypeViewController ()

@end

@implementation QYImageTransitionTypeViewController
{
    float   _transitionType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"转场" style:UIBarButtonItemStylePlain target:self action:@selector(switchTransition:)];
    self.navigationItem.rightBarButtonItem = buttonItem;
}


- (NSArray *)transitions {
    return @[@"无",
             @"动画1", @"动画2", @"百叶窗", @"漩涡"];
}

- (void)switchTransition:(UIBarButtonItem *)item {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择一种效果"
                                                                             message:@"实时作用到当前画面"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    OBJC_WEAK(self);
    [[self transitions] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        OBJC_STRONG(weak_self);
        UIAlertAction *elementAction = [UIAlertAction actionWithTitle:obj style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            strong_weak_self->_transitionType = (float)idx;
        }];
        [alertController addAction:elementAction];
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
    {
        NSLog(@"OK Action");
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)redrawTexture
{
    glUniform1f(_typeUniform, _transitionType);
    [super redrawTexture];
}

@end
