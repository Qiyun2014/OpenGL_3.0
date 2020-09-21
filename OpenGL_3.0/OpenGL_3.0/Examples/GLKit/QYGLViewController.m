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
    UNIFORM_RATIO,
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
    
    // 释放资源，会从显存销毁存储的纹理缓存对象
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
    // 清理GL上下文，不再申请资源等操作
    [EAGLContext setCurrentContext:nil];
}


- (void)loadShaders
{
    NSString *fsh = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"fsh"];
    NSString *vsh = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"vsh"];
    NSString *fSource = [NSString stringWithContentsOfFile:fsh encoding:NSUTF8StringEncoding error:nil];
    NSString *vSource = [NSString stringWithContentsOfFile:vsh encoding:NSUTF8StringEncoding error:nil];
    
    
    // 创建GL_Program,用于执行GL函数程序(编译着色器、分配Uniform及Attribute变量等)
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
            "ratio",
        };
        
        NSLog(@"program is %d", program);
        OBJC_STRONG(weak_self);
        
        // 绑定顶点着色器中的成员变量名，用于我们传入指定的数据,并同步传入给片元着色器
        strong_weak_self->_positionAttribute    = glGetAttribLocation(program, "position");
        strong_weak_self->_textureUniform       = glGetUniformLocation(program, "inputImageTexture");
        strong_weak_self->_coordinateAttibute   = glGetAttribLocation(program, "inputTextureCoordinate");
        
        // 绑定成员变量，在绘制的时候可以进行更改数值，得到想要的效果
        for (int i = 0; i < NUM_UNIFORMS; i ++) {
            uniforms[i] = glGetUniformLocation(program, atr[i]);
        }
        
        // 当前Porgram创建完成，可以自定义其他变量
        if (strong_weak_self.completion) {
            strong_weak_self.completion();
        }
        
        // 激活当前程序，可以传入数据以及启用VAO
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

    // 清理颜色缓冲区，防止渲染花屏不同步导致撕裂等问题
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 自定义参数传入
    glUniform2f(uniforms[UNIFORM_PIXEL_SIZE],      _imageSize.width, _imageSize.height);
    glUniform1f(uniforms[UNIFORM_ZOOM],            _zoom);
    glUniform1f(uniforms[UNIFORM_ANGLE_X],         (_rotationAngle * M_PI) / 180.0);
    glUniform1f(uniforms[UNIFORM_ANGLE_Y],         (_verticalRotationAngle * M_PI) / 180.0);
    glUniform2f(uniforms[UNIFORM_OFFSET],          _offsetPoint.x, _offsetPoint.y);

    // 激活纹理标号绑定到当前纹理ID，会将当前纹理对象传入shader中的inputImageTexture，此处使用的是2D图像，只包含x、y轴
    if (_mTextureId) {
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _mTextureId);
        glUniform1i(_textureUniform, 2);
    }
    
    // 进行等比例裁剪显示，防止图像填充到屏幕出现拉伸现象
    [self cropTextureCoordinateForRect:rect];

    // 传入VAO数据，用于显示指定的顶点坐标以及纹素数据提取位置信息
    glVertexAttribPointer(_positionAttribute, 2, GL_FLOAT, 0, 0, _texturePosition);
    glVertexAttribPointer(_coordinateAttibute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    // 同步绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self redrawTexture];
}


- (void)redrawTexture {}


- (void)cropTextureCoordinateForRect:(CGRect)rect
{
    glUniform1f(uniforms[UNIFORM_RATIO], rect.size.width / rect.size.height);
    
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
