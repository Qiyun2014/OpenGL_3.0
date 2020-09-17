//
//  QYGLUtils.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <UIKit/UIKit.h>


#define OBJC_WEAK(_instance_)            __weak typeof(_instance_) weak_##_instance_ = _instance_;
#define OBJC_STRONG(_weakinstance_)      __strong typeof(_weakinstance_) strong_##_weakinstance_ = _weakinstance_;



NS_ASSUME_NONNULL_BEGIN

@interface QYGLUtils : NSObject

+ (void)gl_programAndCompileShader:(NSString *)vSource
                          fragment:(NSString *)fSource
           untilBindAttributeBlock:(void (^) (GLuint program))bindBlock
            complileCompletedBlcok:(void (^) (GLuint program))completedBlock;

@end

NS_ASSUME_NONNULL_END
