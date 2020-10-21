//
//  QYTNNPredict.h
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/20.
//  Copyright © 2020 祁云. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#include <vector>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, QYTNNComputeUnitType) {
    QYComputeUnit_CPU,
    QYComputeUnit_GPU,
    QYComputeUnit_HUAWEI_NPU,
};

@interface QYTNNPredict : NSObject

// 初始化
- (id)initWithMaxinumFace:(NSInteger)maxinum windowSize:(CGSize)windowSize;


// 是否需要进行镜像视频
@property (nonatomic, assign) BOOL  mirror;

// 计算方式
@property (nonatomic, assign) QYTNNComputeUnitType computeUnit;


// 开始预测人脸关键点
- (void)predictWithPixelBuffer:(CVPixelBufferRef)pixelBuffer completionHanlder:(void (^) (std::vector<std::pair<float, float>>, int face_id, bool has_found))hanlder;


// 读取RGBA数据
std::shared_ptr<char> CVImageBuffRefGetData(CVImageBufferRef image_buffer);

@end


/*
 
 鼻子:
 8(鼻尖)、9(最上)、10(最左)、11(最右)
 
 人脸轮廓：
 19(最左)  ~  24(最下)  ~  28(最右)
 
 眉毛：
 29 ~ 32 (左眉), 33 ~ 36 (右眉)
 
 眼睛：
 37 ~ 42 (左眼), 43 ~ 48 (右眼)
 
 嘴巴：
 49 ~ 54 (下嘴唇轮廓), 55 ~  ~ 66
 
 */

NS_ASSUME_NONNULL_END
