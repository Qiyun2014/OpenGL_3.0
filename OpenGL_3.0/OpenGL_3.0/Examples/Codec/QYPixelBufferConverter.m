//
//  QYPixelBufferConverter.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/27.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYPixelBufferConverter.h"
#import "QYGLContext.h"

@implementation QYPixelBufferConverter
{
    CVOpenGLESTextureRef _glTexture;
}

- (id)initWithDelegate:(id <QYConverterDelegate>)delegate renderSize:(CGSize)size
{
    if (self = [super init]) {
        self.delegate = delegate;
        self.size = size;
    }
    return self;
}

- (void)dealloc
{
    [self cleanUpTextures];
    _delegate = nil;
}

- (void)cleanUpTextures
{
    if (_glTexture) {
        CFRelease(_glTexture);
        _glTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush([QYGLContext shareImageContext].glTextureCache, 0);
}


- (void)renderImagePixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp
{
    int w = (int)CVPixelBufferGetWidth(pixelBuffer);
    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    GLuint texture = 0;
    CVReturn err;
    if (pixelBuffer != NULL) {
        if (![QYGLContext shareImageContext].glTextureCache) {
            NSLog(@"No video texture cache");
            return;
        }
        
        [self cleanUpTextures];
        
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          [QYGLContext shareImageContext].glTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RGBA,
                                                          (int32_t)w,
                                                          (int32_t)h,
                                                          GL_BGRA,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &_glTexture);
        if (err) {
           NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        texture = CVOpenGLESTextureGetName(_glTexture);
        glBindTexture(CVOpenGLESTextureGetTarget(_glTexture), texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textureWithSize:textureId:timestamp:)]) {
//            dispatch_sync([QYGLContext shareImageContext].contextQueue, ^{
                glBindTexture(GL_TEXTURE_2D, texture);
                [self.delegate textureWithSize:CGSizeMake(w, h) textureId:texture timestamp:timestamp];
//            });
        }
    }
}



@end
