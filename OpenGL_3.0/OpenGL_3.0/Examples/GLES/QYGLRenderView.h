//
//  QYGLRenderView.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QYGLRenderView : UIView


// Presentation
@property CGSize presentationRect;


// rotation angle (0 ~ 360)
@property (nonatomic, assign) float rotationAngle;
// vertical rotation angle (0 ~ 360)
@property (nonatomic, assign) float verticalRotationAngle;
// zoom vale, default value is 1.0
@property (nonatomic, assign) float zoom;
// draw position offset
@property (nonatomic, assign) CGPoint offsetPoint;
// some effect of indensity, such as zoom blur, anging from 0.0 on up, with a default of 0.0
@property (nonatomic, assign) float  indensity;

// Display object for UIImage
@property (nonatomic, strong) UIImage   *displayImage;


// Display texture
- (void)displayTexture:(unsigned int)texture size:(CGSize)size;

// Display pixelbuffer
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end

NS_ASSUME_NONNULL_END
