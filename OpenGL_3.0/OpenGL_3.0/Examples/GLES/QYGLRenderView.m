//
//  QYGLRenderView.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLRenderView.h"
#import "QYGLContext.h"
#import "QYGLUtils.h"
#import <AVFoundation/AVUtilities.h>

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

enum
{
    GL_SAMPLE,
    GL_ANGLE_X,
    GL_ANGLE_Y,
    GL_ZOOM,
    GL_SIZE,
    GL_RATIO,
    GL_OFFSET,
    GL_TRANSITION_TYPE,
    GL_INTENSITY,
    GL_UNIFORMS
};
GLint gl_uniforms[GL_UNIFORMS];

@interface QYGLRenderView ()

@property (nonatomic, assign) NSInteger pixelWidth;
@property (nonatomic, assign) NSInteger pixelHeight;

@property (nonatomic, assign) NSTimeInterval beforeTime;
@property (nonatomic, assign) double currentTime;

@property GLuint program;
@property (strong, nonatomic, nonnull) dispatch_semaphore_t callbacksLock;

@end

@implementation QYGLRenderView
{
    // The pixel dimensions of the CAEAGLLayer.
    GLint _backingWidth;
    GLint _backingHeight;

    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    
    const GLfloat *_preferredConversion;
    CGRect  _layerBounds;
    GLuint  _beforeTexture;
    float   _timeValue;
    
    GLuint  _imageTextureId;
}


+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)init
{
    if (self = [super init])
    {
        // Use 2x scale factor on Retina displays.
        self.contentScaleFactor = [[UIScreen mainScreen] scale];

        // Get and configure the layer.
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking : [NSNumber numberWithBool:NO],
                                          kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
        [QYGLContext setCurrentContext];
        [self compileShaders];
        self.zoom = 1.0;
        _callbacksLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark    -   private method

- (void)compileShaders
{
    [QYGLUtils gl_programAndCompileShader:@""
                                 fragment:@""
                  untilBindAttributeBlock:^(GLuint program){
        // Bind attribute locations. This needs to be done prior to linking.
        glBindAttribLocation(program, ATTRIB_VERTEX, "position");
        glBindAttribLocation(program, ATTRIB_TEXCOORD, "inputTextureCoordinate");
    } complileCompletedBlcok:^(GLuint program) {
        
        self.program = program;
        
        // Get uniform locations.
        const GLchar* atr[GL_UNIFORMS] =
        {
            "inputImageTexture",
            "angle_x",
            "angle_y",
            "zoomValue",
            "pixelsize",
            "ratio",
            "offset",
            "transitionType",
            "intensity",
        };
        
        for (int i = 0; i < GL_UNIFORMS; i ++) {
            gl_uniforms[i] = glGetUniformLocation(program, atr[i]);
        }
        
        glUseProgram(self.program);
        [self setZoom:0.0];
        [self setRotationAngle:0];
        [self setOffsetPoint:CGPointZero];
    }];
}

- (void)setupGL
{
    [QYGLContext setCurrentContext];
    glUseProgram(self.program);
    
    glUniform1i(gl_uniforms[GL_SAMPLE], 0);

    // Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (!_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [QYGLContext shareImageContext].context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
    [self setupBuffers];
}

- (void)setupBuffers
{
    glDisable(GL_DEPTH_TEST);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    [[QYGLContext shareImageContext].context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark    -   get method

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    _layerBounds = self.layer.bounds;
    if (!CGRectEqualToRect(_layerBounds, CGRectZero) && !_videoTextureCache) {
        [self setupGL];
    }
}


- (void)setZoom:(float)zoom
{
    if (zoom >= 0) {
        glUniform1f(gl_uniforms[GL_ZOOM], zoom);
        _zoom = zoom;
    }
}


- (void)setRotationAngle:(float)rotationAngle
{
    glUniform1f(gl_uniforms[GL_ANGLE_X], (rotationAngle * M_PI) / 180.0);
    _rotationAngle = rotationAngle;
}


- (void)setOffsetPoint:(CGPoint)offsetPoint
{
    glUniform2f(gl_uniforms[GL_OFFSET], offsetPoint.x, offsetPoint.y);
    _offsetPoint = offsetPoint;
}


- (void)setVerticalRotationAngle:(float)verticalRotationAngle
{
    glUniform1f(gl_uniforms[GL_ANGLE_Y], (verticalRotationAngle * M_PI) / 180.0);
    _verticalRotationAngle = verticalRotationAngle;
}


- (void)setIntensity:(float)intensity
{
    glUniform1f(gl_uniforms[GL_INTENSITY], intensity);
    _intensity = intensity;
}


- (void)setDisplayImage:(UIImage *)displayImage
{
    if ([_displayImage isEqual:displayImage] || displayImage == nil)
    {
        [self displayTexture:_imageTextureId size:displayImage.size];
        return;
    }
    
    if (_imageTextureId > 0) {
        glDeleteTextures(1, &_imageTextureId);
        _imageTextureId = 0;
    }
    _imageTextureId = [QYGLUtils textureIdForImage:displayImage];
    if (_imageTextureId > 0) {
        [self displayTexture:_imageTextureId size:displayImage.size];
    }
    _displayImage = displayImage;
}


#pragma mark - OpenGLES drawing


- (void)displayTexture:(unsigned int)texture size:(CGSize)size
{
    dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
        
        self.pixelWidth = size.width;
        self.pixelHeight = size.height;
        
        if (texture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, texture);
            
            glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
            
            // Set the view port to the entire view.
            glViewport(0, 0, _backingWidth, _backingHeight);
            
            glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            // Use shader program.
            glUseProgram(self.program);
            glUniform1f(gl_uniforms[GL_ZOOM], _zoom);
            glUniform1f(gl_uniforms[GL_ANGLE_X], (_rotationAngle * M_PI) / 180.0);
            glUniform1f(gl_uniforms[GL_ANGLE_Y], (_verticalRotationAngle * M_PI) / 180.0);
            glUniform2f(gl_uniforms[GL_OFFSET], _offsetPoint.x, _offsetPoint.y);
            glUniform1f(gl_uniforms[GL_INTENSITY], _intensity);
            
            glUniform1f(gl_uniforms[GL_RATIO], size.width / size.height);
            glUniform2f(gl_uniforms[GL_SIZE], size.width, size.height);
            

            [self drawTexture];
            
            // reset
            glUniform1f(gl_uniforms[GL_ZOOM], 1.0);
            glUniform1f(gl_uniforms[GL_ANGLE_X], 0.0);
            glUniform1f(gl_uniforms[GL_ANGLE_Y], 0.0);
            glUniform2f(gl_uniforms[GL_OFFSET], 0.0, 0.0);
            glUniform1f(gl_uniforms[GL_INTENSITY], 0.0);
            glUniform1f(gl_uniforms[GL_TRANSITION_TYPE], 0.0);
        }
    });
}


- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
        
        self.pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        self.pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        CVReturn err;
        if (pixelBuffer != NULL) {
            if (!_videoTextureCache) {
                NSLog(@"No video texture cache");
                return;
            }
            
            [self cleanUpTextures];

            glActiveTexture(GL_TEXTURE0);
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               _videoTextureCache,
                                                               pixelBuffer,
                                                               NULL,
                                                               GL_TEXTURE_2D,
                                                               GL_RGBA,
                                                               (int32_t)self.pixelWidth,
                                                               (int32_t)self.pixelHeight,
                                                               GL_BGRA,
                                                               GL_UNSIGNED_BYTE,
                                                               0,
                                                               &_lumaTexture);
            if (err) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

            glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
            
            // Set the view port to the entire view.
            glViewport(0, 0, _backingWidth, _backingHeight);
        }
        
        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // Use shader program.
        glUseProgram(self.program);
        // reset
        glUniform1f(gl_uniforms[GL_ZOOM], 1.0);
        glUniform1f(gl_uniforms[GL_ANGLE_X], 0.0);
        glUniform1f(gl_uniforms[GL_ANGLE_Y], 0.0);
        glUniform2f(gl_uniforms[GL_OFFSET], 0.0, 0.0);
        glUniform1f(gl_uniforms[GL_INTENSITY], 0.0);
        glUniform1f(gl_uniforms[GL_TRANSITION_TYPE], 0.0);
        
        [self drawTexture];
    });
}


- (void)drawTexture {
    
    // Set up the quad vertices with respect to the orientation and aspect ratio of the video.
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(self.presentationRect, _layerBounds);
    
       // Compute normalized quad coordinates to draw the frame into.
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width / _layerBounds.size.width, vertexSamplingRect.size.height / _layerBounds.size.height);
    
    // Normalize the quad vertices.
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    } else {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
    }
    
    /*
     The quad vertex data defines the region of 2D plane onto which we draw our pixel buffers.
     Vertex data formed using (-1,-1) and (1,1) as the bottom left and top right coordinates respectively, covers the entire screen.
     */
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
             normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
             normalizedSamplingSize.width, normalizedSamplingSize.height,
    };
    
    // Update attribute values.
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(ATTRIB_VERTEX);

    /*
     The texture vertices are set up such that we flip the texture vertically. This is so that our top left origin buffers match OpenGL's bottom left texture coordinate system.
     */
    CGRect textureSamplingRect = CGRectMake(0, 0, 1, 1);
    GLfloat quadTextureData[] =  {
        CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect)
    };
    
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    [[QYGLContext shareImageContext].context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
