//
//  QYMediaTextureExport.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/27.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLRenderTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface QYMediaTextureExport : QYGLRenderTexture

- (id)initWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
