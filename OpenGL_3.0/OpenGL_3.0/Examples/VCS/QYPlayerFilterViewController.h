//
//  QYPlayerFilterViewController.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPlayerViewController.h"
#import "QYGLRenderTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYPlayerFilterViewController : QYPlayerViewController

@property (strong, nonatomic, nullable) QYGLRenderTexture *renderTexture;

@end

NS_ASSUME_NONNULL_END
