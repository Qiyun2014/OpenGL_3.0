//
//  QYGLOutputPixelBuffer.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLOutputPixelBuffer.h"
#import "QYGLContext.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)


NSString *const kOutputVertexString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;

 varying vec2 textureCoordinate;

 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kOutputFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    // BGRA  -->  RGBA
//    float r = textureColor.b;
//    float b = textureColor.r;
//    gl_FragColor = vec4(r, textureColor.g, b, textureColor.a);
    
    gl_FragColor = textureColor;
 }
);


@implementation QYGLOutputPixelBuffer
{
    CVPixelBufferRef    _pixelBuffer;
    CVOpenGLESTextureRef _renderTexture;
}


- (id)init {
    if (self = [super initWithVertexShader:kOutputVertexString fragmentShader:kOutputFragmentShaderString]) {
        
    }
    return self;
}

- (void)cleanupMemory
{
    if ([QYGLContext shareImageContext].glTextureCache) {
        CVOpenGLESTextureCacheFlush([QYGLContext shareImageContext].glTextureCache, 0);
    }

    if (_renderTexture) {
        CFRelease(_renderTexture);
        _renderTexture = NULL;
    }
    
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
    
    [super cleanupMemory];
}


- (void)onCompletedScrrenRender
{
    if (kCVReturnSuccess == CVPixelBufferLockBaseAddress(_pixelBuffer, kCVPixelBufferLock_ReadOnly))
    {
        glFinish();
        if (self.pixelBufferDelegate && [self.pixelBufferDelegate respondsToSelector:@selector(textureOutput:timestamp:didOutputSampleBuffer:)]) {
            [self.pixelBufferDelegate textureOutput:self timestamp:self.timestamp didOutputSampleBuffer:_pixelBuffer];
        }
        CVPixelBufferUnlockBaseAddress(_pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
}


- (GLuint)firstFrameBuffer
{
    if (_mFrameBuffer <= 0)
    {
        glActiveTexture(GL_TEXTURE1);
        glGenFramebuffers(1, &_mFrameBuffer);

        if (_pixelBuffer == nil) {
            
            CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
           
            CVReturn error;
            error = CVPixelBufferCreate(kCFAllocatorDefault, _mTextureSize.width, _mTextureSize.height, kCVPixelFormatType_32BGRA, attrs, &_pixelBuffer);
            if (error)
            {
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", error);
            }

            CVBufferSetAttachment(_pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
            CVBufferSetAttachment(_pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
            CVBufferSetAttachment(_pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);

            error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                 [QYGLContext shareImageContext].glTextureCache,
                                                                 _pixelBuffer,
                                                                 NULL,
                                                                 GL_TEXTURE_2D,
                                                                 GL_RGBA,
                                                                 _mTextureSize.width,
                                                                 _mTextureSize.height,
                                                                 GL_BGRA,
                                                                 GL_UNSIGNED_BYTE,
                                                                 0,
                                                                 &_renderTexture);
            if (error)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
            }
            
            
            // set the texture up like any other texture
            glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            // bind the texture to the framebuffer you're going to render to
            // (boilerplate code to make a framebuffer not shown)
            glBindFramebuffer(GL_FRAMEBUFFER, _mFrameBuffer);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);
            
            __unused GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
            NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        }
        
        glViewport(0, 0, _mTextureSize.width, _mTextureSize.height);
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    return _mFrameBuffer;
}

@end
