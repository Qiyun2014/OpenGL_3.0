//
//  QYGLViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLViewController.h"
#import <AVFoundation/AVUtilities.h>

enum
{
    UNIFORM_PIXEL_SIZE,
    UNIFORM_ZOOM,
    UNIFORM_OFFSET,
    UNIFORM_ANGLE_X,
    UNIFORM_ANGLE_Y,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];


@interface QYGLViewController ()

@end

@implementation QYGLViewController


- (id)init {
    if (self = [super init]) {
        
        [QYGLContext setCurrentContext];
        
        GLKView *view = (GLKView *)self.view;
        view.context = [QYGLContext shareImageContext].context;
        view.drawableDepthFormat = GLKViewDrawableColorFormatRGB565;
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
        
        const GLchar* atr[NUM_UNIFORMS] =
        {
            "pixelsize",
            "zoomValue",
            "offset",
            "angle_x",
            "angle_y",
        };
        
        NSLog(@"program is %d", program);
        OBJC_STRONG(weak_self);
        strong_weak_self->_positionAttribute    = glGetAttribLocation(program, "position");
        strong_weak_self->_textureUniform       = glGetUniformLocation(program, "inputImageTexture");
        strong_weak_self->_coordinateAttibute   = glGetAttribLocation(program, "inputTextureCoordinate");
        
        for (int i = 0; i < NUM_UNIFORMS; i ++) {
            uniforms[i] = glGetUniformLocation(program, atr[i]);
        }
        
        if (strong_weak_self.completion) {
            strong_weak_self.completion();
        }
        
        glUseProgram(strong_weak_self.mProgram);
        glEnableVertexAttribArray(strong_weak_self->_positionAttribute);
        glEnableVertexAttribArray(strong_weak_self->_coordinateAttibute);
        [self setZoom:1.0];
    }];
}

- (void)update
{

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUniform2f(uniforms[UNIFORM_PIXEL_SIZE],      _imageSize.width, _imageSize.height);
    glUniform1f(uniforms[UNIFORM_ZOOM],            _zoom);
    glUniform1f(uniforms[UNIFORM_ANGLE_X],         (_rotationAngle * M_PI) / 180.0);
    glUniform1f(uniforms[UNIFORM_ANGLE_Y],         (_verticalRotationAngle * M_PI) / 180.0);
    glUniform2f(uniforms[UNIFORM_OFFSET],          _offsetPoint.x, _offsetPoint.y);

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



- (void)setZoom:(float)zoom
{
    if (zoom >= 0) {
        glUniform1f(uniforms[UNIFORM_ZOOM], zoom);
        _zoom = zoom;
    }
}


- (void)setRotationAngle:(float)rotationAngle
{
    glUniform1f(uniforms[UNIFORM_ANGLE_X], (rotationAngle * M_PI) / 180.0);
    _rotationAngle = rotationAngle;
}


- (void)setOffsetPoint:(CGPoint)offsetPoint
{
    glUniform2f(uniforms[UNIFORM_OFFSET], offsetPoint.x, offsetPoint.y);
    _offsetPoint = offsetPoint;
}


- (void)setVerticalRotationAngle:(float)verticalRotationAngle
{
    glUniform1f(uniforms[UNIFORM_ANGLE_Y], (verticalRotationAngle * M_PI) / 180.0);
    _verticalRotationAngle = verticalRotationAngle;
}


@end
