//
//  QYImageRenderViewController.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYImageRenderViewController : QYGLViewController
{
    GLuint  _blurIndensity;
}

@property (nonatomic, assign) float indensity;


@end

NS_ASSUME_NONNULL_END
