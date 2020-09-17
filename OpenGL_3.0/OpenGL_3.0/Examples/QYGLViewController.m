//
//  QYGLViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLViewController.h"
#import "QYGLContext.h"
#import "QYGLUtils.h"
 #import <AVFoundation/AVUtilities.h>


@interface QYGLViewController ()

@end

@implementation QYGLViewController


- (id)init {
    if (self = [super init]) {
        
        [QYGLContext setCurrentContext];
        
        GLKView *view = (GLKView *)self.view;
        view.context = [QYGLContext shareImageContext].context;
        view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        self.preferredFramesPerSecond = 10;
        
        [self loadShaders];
    }
    return self;;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_mTextureId)
    {
        glDeleteTextures(1, &_mTextureId);
        _mTextureId = 0;
    }
    if (_mProgram)
    {
        glDeleteProgram(_mProgram);
        _mProgram = 0;
    }
    [EAGLContext setCurrentContext:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}


- (void)loadShaders
{
    NSString *fsh = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"fsh"];
    NSString *vsh = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"vsh"];
    NSString *fSource = [NSString stringWithContentsOfFile:fsh encoding:NSUTF8StringEncoding error:nil];
    NSString *vSource = [NSString stringWithContentsOfFile:vsh encoding:NSUTF8StringEncoding error:nil];
    
    OBJC_WEAK(self);
    [QYGLUtils gl_programAndCompileShader:vSource
                                 fragment:fSource
                                untilBindAttributeBlock:^(GLuint program) {
        OBJC_STRONG(weak_self);
        strong_weak_self.mProgram = program;
    } complileCompletedBlcok:^(GLuint program) {
        NSLog(@"program is %d", program);
        OBJC_STRONG(weak_self);

        strong_weak_self->_positionAttribute = glGetAttribLocation(program, "position");
        strong_weak_self->_coordinateAttibute = glGetAttribLocation(program, "inputTextureCoordinate");
        strong_weak_self->_textureUniform = glGetUniformLocation(program, "inputImageTexture");
        
        glEnableVertexAttribArray(strong_weak_self->_positionAttribute);
        glEnableVertexAttribArray(strong_weak_self->_coordinateAttibute);
        
        if (strong_weak_self.completion) {
            strong_weak_self.completion();
        }
        glUseProgram(strong_weak_self.mProgram);
    }];
}

- (void)update
{
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_mTextureId) {
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _mTextureId);
        glUniform1i(_textureUniform, 2);
    }
    [self cropTextureCoordinateForRect:rect];

    glVertexAttribPointer(_positionAttribute, 2, GL_FLOAT, 0, 0, _texturePosition);
    glVertexAttribPointer(_coordinateAttibute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self redrawTexture];
}

- (void)redrawTexture {}


- (void)cropTextureCoordinateForRect:(CGRect)rect
{
    // Set up the quad vertices with respect to the orientation and aspect ratio of the video.
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(_imageSize, rect);
    
    // Compute normalized quad coordinates to draw the frame into.
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width / rect.size.width, vertexSamplingRect.size.height / rect.size.height);
    
    // Normalize the quad vertices.
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    } else {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
    }
    
    _texturePosition[0] = -1 * normalizedSamplingSize.width;
    _texturePosition[1] = -1 * normalizedSamplingSize.height;
    _texturePosition[2] = normalizedSamplingSize.width;
    _texturePosition[3] = -1 * normalizedSamplingSize.height;
    _texturePosition[4] = -1 * normalizedSamplingSize.width;
    _texturePosition[5] = normalizedSamplingSize.height;
    _texturePosition[6] = normalizedSamplingSize.width;
    _texturePosition[7] = normalizedSamplingSize.height;
}

@end
