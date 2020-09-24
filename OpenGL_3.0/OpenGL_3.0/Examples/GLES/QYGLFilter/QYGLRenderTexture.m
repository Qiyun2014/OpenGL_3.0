//
//  QYGLRenderTexture.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/23.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLRenderTexture.h"
#import "QYGLUtils.h"


static const GLfloat imageVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat textureCoordinates[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};

@implementation QYGLRenderTexture


- (id)init
{
    return [self initWithVertexShader:[self defalutShaderForSurfix:@"vsh"] fragmentShader:[self defalutShaderForSurfix:@"fsh"]];
}

- (NSString *)defalutShaderForSurfix:(NSString *)surfix
{
    return [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"default" ofType:surfix] encoding:NSUTF8StringEncoding error:nil];
}

- (id)initWithVertexShader:(NSString *)vShader fragmentShader:(NSString *)fShader
{
    if (self = [super init]) {

        OBJC_WEAK(self);
        [QYGLUtils gl_programAndCompileShader:vShader ?: [self defalutShaderForSurfix:@"vsh"]
                                     fragment:fShader ?: [self defalutShaderForSurfix:@"fsh"]
                      untilBindAttributeBlock:^(GLuint program)
        {
            glBindAttribLocation(program, 0, "position");
            glBindAttribLocation(program, 1, "inputTextureCoordinate");
        } complileCompletedBlcok:^(GLuint program)
        {
            OBJC_STRONG(weak_self);
            strong_weak_self->_mProgram = program;
            [strong_weak_self setupUniforms];
            [strong_weak_self bindAttributesAndUniforms];
        }];
    }
    return self;
}


- (BOOL)validate
{
    GLint logLength;
    
    glValidateProgram(_mProgram);
    glGetProgramiv(_mProgram, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_mProgram, logLength, &logLength, log);
        NSLog(@"QYGLRenderTexture  Program link log:\n%s", log);
        free(log);
        return false;
    }
    return true;
}


- (void)setupUniforms
{
    if ([self validate])
    {
        glUseProgram(_mProgram);
        
#if defined(DEBUG)
        GLint count;
        glGetProgramiv(_mProgram, GL_ACTIVE_UNIFORMS, &count);
        NSLog(@"QYGLRenderTexture  uniform count = %d", count);
        
        GLint size;                     // size of the variable
        GLenum type;                    // type of the variable (float, vec3 or mat4, etc)
        const GLsizei bufSize = 30;     // maximum name length
        GLchar name[bufSize];           // variable name in GLSL
        GLsizei length;                 // name length
        for (int i = 0; i < count; i ++) {
            glGetActiveUniform(_mProgram, (GLuint)i, bufSize, &length, &size, &type, name);
            NSLog(@"QYGLRenderTexture  uniform id = %d, name = %s, type = %u", i, name, type);
        }
        
        glGetProgramiv(_mProgram, GL_ACTIVE_ATTRIBUTES, &count);
        NSLog(@"QYGLRenderTexture  attribute count = %d", count);
        for (int i = 0; i < count; i ++) {
            glGetActiveAttrib(_mProgram, (GLuint)i, bufSize, &length, &size, &type, name);
            NSLog(@"QYGLRenderTexture  attribute id = %d, name = %s, type = %u", i, name, type);
        }
#endif
    } else
    {
        NSLog(@"QYGLRenderTexture validate failed, error is %d ...", glGetError());
    }
}


- (void)dealloc
{
    [self cleanupMemory];
}


- (void)cleanupMemory
{
    [super cleanupMemory];
    [self removeFrameBuffer];
    if (_mProgram) {
        glDeleteProgram(_mProgram);
        _mProgram = 0;
    }
}


- (void)removeFrameBuffer
{
    if (_mTextureId) {
        glDeleteTextures(1, &_mTextureId);
        _mTextureId = 0;
    }
    if (_mFrameBuffer) {
        glDeleteFramebuffers(1, &_mFrameBuffer);
        _mFrameBuffer = 0;
    }
}


#pragma mark    -   private method

- (void)bindAttributesAndUniforms
{
    glUseProgram(_mProgram);
    _mPositionAttribute             = glGetAttribLocation(_mProgram, "position");
    _mTextureCoordinatAttribute     = glGetAttribLocation(_mProgram, "inputTextureCoordinate");
    _mTextureUniform                = glGetUniformLocation(_mProgram, "inputImageTexture");
    glEnableVertexAttribArray(_mPositionAttribute);
    glEnableVertexAttribArray(_mTextureCoordinatAttribute);
}


- (void)setFrameBufferSize:(CGSize)size
{
    if (!CGSizeEqualToSize(size, _mTextureSize)) {
        [self removeFrameBuffer];
    }
    _mTextureSize = size;

    glBindFramebuffer(GL_FRAMEBUFFER, [self firstFrameBuffer]);
    glViewport(0, 0, size.width, size.height);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
}


#pragma mark    -   get method

- (GLuint)firstTexture
{
    if (_mTextureId <= 0)
    {
        glGenTextures(1, &_mTextureId);
        glBindTexture(GL_TEXTURE_2D, _mTextureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    return _mTextureId;
}


- (GLuint)firstFrameBuffer
{
    if (_mFrameBuffer <= 0)
    {
        glGenFramebuffers(1, &_mFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _mFrameBuffer);
        [self firstTexture];
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _mTextureSize.width, _mTextureSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _mTextureId, 0);
#ifndef NS_BLOCK_ASSERTIONS
        GLint params;
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, &params);
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
#endif
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    return _mFrameBuffer;
}


#pragma mark    -   public method

- (unsigned int)displayTexture:(unsigned int)texture size:(CGSize)size ts:(CMTime)ts
{
    __block GLuint srcTexture = texture;
    if (self.targets.count)
    {
        [self.targets enumerateObjectsUsingBlock:^(id<QYGLTextureInput>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
        {
            srcTexture = [obj inputTexture:srcTexture size:size ts:ts];
            if ((idx + 1) == self.targets.count)
            {
                dispatch_semaphore_signal(_lock_semaphore);
            }
        }];
        dispatch_semaphore_wait(_lock_semaphore, DISPATCH_TIME_FOREVER);
    }
    return [self inputTexture:srcTexture size:size ts:ts];
}


- (GLuint)inputTexture:(GLuint)texture size:(CGSize)size ts:(CMTime)ts
{
    glUseProgram(_mProgram);
    self.timestamp = ts;
    [self setFrameBufferSize:size];
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(_mTextureUniform, 2);
    
    [self useProgramAndSetUniforms];
    glVertexAttribPointer(_mPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer(_mTextureCoordinatAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self onCompletedScrrenRender];
    
    return _mTextureId ? : texture;
}

- (void)useProgramAndSetUniforms {}

- (void)onCompletedScrrenRender {}

@end
