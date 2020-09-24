//
//  QYGLRenderTexture.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/23.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYGLContext.h"
#import <CoreMedia/CoreMedia.h>
#import "QYGLTextureOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYGLRenderTexture : QYGLTextureOutput <QYGLTextureInput>
{
    GLuint  _mProgram, _mTextureId;
    GLuint  _mTextureUniform;
    GLuint  _mPositionAttribute;
    GLuint  _mTextureCoordinatAttribute;
    CGSize  _mTextureSize;
    GLuint  _mFrameBuffer;
}

// 初始化
- (id)initWithVertexShader:(nullable NSString *)vShader fragmentShader:(nullable NSString *)fShader;

// 绘制纹理图像
- (unsigned int)displayTexture:(unsigned int)texture size:(CGSize)size ts:(CMTime)ts;


@end

NS_ASSUME_NONNULL_END
