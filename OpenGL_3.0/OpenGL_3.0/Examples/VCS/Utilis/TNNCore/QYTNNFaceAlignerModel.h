//
//  QYTNNFaceAlignerModel.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/19.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "tnn_sdk_sample.h"

NS_ASSUME_NONNULL_BEGIN

using namespace::TNN_NS;

@interface QYTNNFaceAlignerModel : NSObject

@property bool prev_face;
@property (nonatomic, assign) std::shared_ptr<TNNSDKSample> predictor;

- (Status)loadNeuralNetworkModel:(TNNComputeUnits)units;

// Object Detection
- (std::vector<std::shared_ptr<ObjectInfo> >)getObjectList:(std::shared_ptr<TNNSDKOutput>)output;
- (NSString*)labelForObject:(std::shared_ptr<ObjectInfo>)object;

@end

NS_ASSUME_NONNULL_END
