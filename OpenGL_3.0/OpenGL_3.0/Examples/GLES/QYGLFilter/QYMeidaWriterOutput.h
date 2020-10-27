//
//  QYMeidaWriterOutput.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/27.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QYMeidaWriterOutput : NSObject

@property(nonatomic, copy) BOOL(^videoInputReadyCallback)(void);
@property(nonatomic, copy) BOOL(^audioInputReadyCallback)(void);

@end

NS_ASSUME_NONNULL_END
