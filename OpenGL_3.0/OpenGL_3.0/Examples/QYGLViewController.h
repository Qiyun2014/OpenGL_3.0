//
//  QYGLViewController.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import "QYGLContext.h"
#import "QYGLUtils.h"

typedef void (^QYGLPragramCompletion) (void);

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


NS_ASSUME_NONNULL_BEGIN

@interface QYGLViewController : GLKViewController
{
    GLuint  _positionAttribute, _coordinateAttibute, _textureUniform;
    CGSize  _imageSize;
    GLfloat _texturePosition[8];
}

@property (assign, nonatomic) GLuint    mProgram;
@property (assign, nonatomic) GLuint    mTextureId;
@property (copy, nonatomic, nullable) QYGLPragramCompletion   completion;


// rotation angle (0 ~ 360)
@property (nonatomic, assign) float rotationAngle;
// vertical rotation angle (0 ~ 360)
@property (nonatomic, assign) float verticalRotationAngle;
// zoom vale, default value is 1.0
@property (nonatomic, assign) float zoom;
// draw position offset
@property (nonatomic, assign) CGPoint offsetPoint;


- (void)redrawTexture;
- (void)cropTextureCoordinateForRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
