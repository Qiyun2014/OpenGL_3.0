//
//  QYImageTransitionViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYImageTransitionViewController.h"
#import "QYGLUtils.h"

@interface QYImageTransitionViewController ()

@end

@implementation QYImageTransitionViewController
{
    GLuint  _textureId, _chatrletUniform;
    GLuint  _timeUniform;
    NSTimeInterval timeElapsed;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"yourname" ofType:@"png"];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:imagePath
                                                                      options:@{GLKTextureLoaderOriginBottomLeft : @true, GLKTextureLoaderGenerateMipmaps : @true}
                                                                        error:NULL];
    self.mTextureId = textureInfo.name;
    _imageSize = CGSizeMake(textureInfo.width, textureInfo.height);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_textureId) {
        glDeleteTextures(1, &_textureId);
        _textureId = 0;
    }
    self.completion = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"tulip" ofType:@"png"];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:imagePath
                                                                      options:@{GLKTextureLoaderOriginBottomLeft : @true, GLKTextureLoaderGenerateMipmaps : @true}
                                                                        error:NULL];
    _textureId = textureInfo.name;
    _imageSize = CGSizeMake(textureInfo.width, textureInfo.height);

    
    OBJC_WEAK(self);
    self.completion = ^{
        OBJC_STRONG(weak_self);
        strong_weak_self->_timeUniform = glGetUniformLocation(strong_weak_self.mProgram, "mTime");
        strong_weak_self->_chatrletUniform = glGetUniformLocation(strong_weak_self.mProgram, "chatrlet");
    };
}



- (void)redrawTexture
{
    timeElapsed += [[NSString stringWithFormat:@"%f", self.timeSinceLastDraw] doubleValue];
    glUniform1f(_timeUniform, timeElapsed);
    glUniform1f(_chatrletUniform, 1.0);
    if (_textureId)
    {
         glActiveTexture(GL_TEXTURE3);
         glBindTexture(GL_TEXTURE_2D, _textureId);
         glUniform1i(_textureUniform, 3);
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glUniform1f(_chatrletUniform, 0.0);
}

@end
