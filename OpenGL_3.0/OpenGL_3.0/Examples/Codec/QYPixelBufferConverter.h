//
//  QYPixelBufferConverter.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/27.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import "QYGLUtils.h"

NS_ASSUME_NONNULL_BEGIN

@protocol QYConverterDelegate <NSObject>

- (GLuint)textureWithSize:(CGSize)size textureId:(GLuint)texId timestamp:(CMTime)ts;

@end


@interface QYPixelBufferConverter : NSObject


// Instance
- (id)initWithDelegate:(id <QYConverterDelegate>)delegate renderSize:(CGSize)size;


// Texture size
@property (assign, nonatomic) CGSize size;


// For delegate (use offscrren render)
@property (weak, nonatomic) id <QYConverterDelegate> delegate;


// Support input pixelbuffer, convert it to rgb texture
- (void)renderImagePixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp;



@end

NS_ASSUME_NONNULL_END
