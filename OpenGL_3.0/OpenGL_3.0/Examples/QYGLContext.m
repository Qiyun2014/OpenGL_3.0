//
//  QYGLContext.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYGLContext.h"
#import <OpenGLES/ES2/glext.h>

@implementation QYGLContext
{
    EAGLSharegroup *_sharegroup;
}

@synthesize context = _context;
@synthesize glTextureCache = _glTextureCache;
@synthesize contextQueue = _contextQueue;


static QYGLContext *glContext;
+ (QYGLContext *)shareImageContext {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        glContext = [[QYGLContext alloc] init];
        glContext->_sharegroup = [[EAGLContext currentContext] sharegroup];
    });
    return glContext;
}


- (id)init {
    if (self = [super init]) {
        _contextQueue = dispatch_queue_create("com.weidian.glcontext", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


+ (void)setCurrentContext
{
    [[self shareImageContext] updateCurrentContext];
}


+ (dispatch_queue_t)sharedContextQueue;
{
    return [[self shareImageContext] contextQueue];
}


- (void)updateCurrentContext
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}


- (void)cleanup {
    CVOpenGLESTextureCacheFlush([QYGLContext shareImageContext].glTextureCache, 0);
    [EAGLContext setCurrentContext:nil];
}


#pragma mark    -   get method

- (EAGLContext *)createContext;
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:_sharegroup];
    if (!context) {
        // Set the context into which the frames will be drawn.
        // All contexts associated with the same sharegroup must use the same version of the OpenGL ES API as the initial context.
        // https://developer.apple.com/library/content/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/WorkingwithOpenGLESContexts/WorkingwithOpenGLESContexts.html
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_sharegroup];
    }
    return context;
}


- (EAGLContext *)context;
{
    if (_context == nil)
    {
        _context = [self createContext];
        [EAGLContext setCurrentContext:_context];
        
        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }
    
    return _context;
}


- (CVOpenGLESTextureCacheRef)glTextureCache;
{
    if (_glTextureCache == NULL)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_glTextureCache);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return _glTextureCache;
}


@end
