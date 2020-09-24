//
//  QYGLImageFilter.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/24.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLRenderTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYGLImageFilter : QYGLRenderTexture

// 强度（0 ~ 1）
@property (nonatomic, assign) float  intensity;

// LUT image
@property (nonatomic, strong, nullable) UIImage   *lutImage;

@end

NS_ASSUME_NONNULL_END
