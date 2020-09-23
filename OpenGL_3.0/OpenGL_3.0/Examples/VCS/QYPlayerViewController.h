//
//  QYPlayerViewController.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/22.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QYGLRenderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYPlayerViewController : UIViewController

@property (strong, nonatomic) QYGLRenderView    *renderView;

@end

NS_ASSUME_NONNULL_END
