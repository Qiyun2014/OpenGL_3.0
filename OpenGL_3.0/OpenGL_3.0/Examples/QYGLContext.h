//
//  QYGLContext.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface QYGLContext : NSObject

+ (QYGLContext *)shareImageContext;

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef glTextureCache;


+ (void)setCurrentContext;

- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
