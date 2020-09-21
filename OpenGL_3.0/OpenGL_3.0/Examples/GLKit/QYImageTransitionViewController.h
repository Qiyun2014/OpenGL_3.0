//
//  QYImageTransitionViewController.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLViewController.h"
#import "QYGLUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYImageTransitionViewController : QYGLViewController
{
    GLuint  _textureId, _chatrletUniform;
    GLuint  _timeUniform;
    NSTimeInterval timeElapsed;
    GLuint  _typeUniform;
}

@end

NS_ASSUME_NONNULL_END
