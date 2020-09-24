//
//  QYGLUtils.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLUtils.h"

@implementation QYGLUtils

void CheckGLError(const char *pGLOperation)
{
    for (GLint error = glGetError(); error; error = glGetError())
    {
        printf("WDGLUtils::CheckGLError GL Operation %s() glError (0x%x)\n", pGLOperation, error);
    }
}


+ (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}



+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)sourceString
{
    NSError *error;
    if (sourceString == nil) {
        NSLog(@"Failed to load vertex shader: %@", [error localizedDescription]);
        return NO;
    }
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}



+ (void)gl_programAndCompileShader:(NSString *)vSource
                          fragment:(NSString *)fSource
           untilBindAttributeBlock:(void (^) (GLuint program))bindBlock
            complileCompletedBlcok:(void (^) (GLuint program))completedBlock {
    
    GLuint vertShader, fragShader;
    
    // Create shader program.
    GLuint program = glCreateProgram();
    
    // Create and compile vertex shader.
    if (![QYGLUtils compileShader:&vertShader type:GL_VERTEX_SHADER source:vSource]) {
        NSLog(@"Failed to compile vertex shader");
    }
    
    // Create and compile fragment shader.
    if (![QYGLUtils compileShader:&fragShader type:GL_FRAGMENT_SHADER source:fSource]) {
        NSLog(@"Failed to compile fragment shader");
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    if (bindBlock) {
        bindBlock(program);
    }
    
    // Link program.
    if (![QYGLUtils linkProgram:program]) {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
    }
    
    // Get uniform locations.
    if (completedBlock) {
        completedBlock(program);
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
}


+ (GLuint)textureIdForImage:(UIImage *)image
{
    if (image == nil) {
        return 0;
    }
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
//    CGContextTranslateCTM(context, 0, height);
//    CGContextScaleCTM(context, 1.0f, -1.0f);
//    CGColorSpaceRelease(colorSpace);
//    CGContextClearRect(context, rect);
//    CGContextTranslateCTM(context, 0, height);
//    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextDrawImage(context, rect, cgImageRef);
    
    glEnable(GL_TEXTURE_2D);

    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    // 生成 Mipmap 是针对操作台 GL_TEXTURE_2D 上的选定漏斗 GL_TEXTURE1 所插在的瓶子里的酒的，即处理图片
    glGenerateMipmap(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    CGContextRelease(context);
//    CGImageRelease(cgImageRef);
    colorSpace = nil;
    free(imageData);
    
    return textureID;
}



@end
