//
//  QYGLImageFilter.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLImageFilter.h"

@implementation QYGLImageFilter
{
    GLuint  _inputImageUniform, _intensityUniform, _inputImageTextureId, _textureIdUniform;
}

- (id)init
{
    NSString *fsh = [[NSBundle mainBundle] pathForResource:@"filter" ofType:@"fsh"];
    NSString *fSource = [NSString stringWithContentsOfFile:fsh encoding:NSUTF8StringEncoding error:nil];
    if (self = [super initWithVertexShader:nil fragmentShader:fSource])
    {
        glUseProgram(_mProgram);
        _inputImageUniform      = glGetUniformLocation(_mProgram, "inputImageTexture2");
        _intensityUniform       = glGetUniformLocation(_mProgram, "intensity");
        _textureIdUniform       = glGetUniformLocation(_mProgram, "texture2");
    }
    return self;
}


- (void)cleanupMemory
{
    [super cleanupMemory];
    if (_inputImageTextureId)
    {
        glDeleteTextures(1, &_inputImageTextureId);
        _inputImageTextureId = 0;
    }
}


- (void)useProgramAndSetUniforms
{
    glUniform1f(_intensityUniform, _intensity);
    glUniform1f(_textureIdUniform, _inputImageTextureId);
    if (_inputImageTextureId)
    {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, _inputImageTextureId);
        glUniform1i(_inputImageUniform, 3);
    }
}


- (void)setLutImage:(UIImage *)lutImage
{
    if ([_lutImage isEqual:lutImage]) {
        return;
    }
    dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
        if (_inputImageTextureId)
        {
            glDeleteTextures(1, &_inputImageTextureId);
            _inputImageTextureId = 0;
        }
        _inputImageTextureId = [QYGLUtils textureIdForImage:lutImage];
    });
    _lutImage = lutImage;
}


@end
