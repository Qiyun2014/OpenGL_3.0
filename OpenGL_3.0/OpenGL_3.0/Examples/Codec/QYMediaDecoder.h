//
//  QYMediaDecoder.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/9/21.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QYMediaDecoder : NSObject

- (id)initWithURL:(NSURL *)URL;

@property (strong, nonatomic, nullable) AVAssetReader *reader;
@property (strong, nonatomic, nullable) AVAssetReaderOutput *readerOutput;

@end

NS_ASSUME_NONNULL_END
