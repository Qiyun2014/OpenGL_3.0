//
//  QYTNNPredict.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/20.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYTNNPredict.h"
#import <tnn/tnn.h>
#import "QYTNNFaceAlignerModel.h"
#import <UIKit/UIKit.h>

using namespace std;
using namespace TNN_NS;

@interface QYTNNPredict ()
{
    vector<shared_ptr<ObjectInfo>>  _object_list;
}

// 模型加载
@property (nonatomic, strong) QYTNNFaceAlignerModel *faceModel;
@property (nonatomic, assign) CGSize previewSize;
@property (nonatomic, assign) NSInteger maxinumFace;
@property (nonatomic, strong) dispatch_semaphore_t inflightSemaphore;

@end

@implementation QYTNNPredict

- (id)initWithMaxinumFace:(NSInteger)maxinum windowSize:(CGSize)windowSize
{
    if (self = [super init])
    {
        self.maxinumFace = maxinum;
        self.previewSize = windowSize;
        _inflightSemaphore = dispatch_semaphore_create(1);
        self.faceModel = [[QYTNNFaceAlignerModel alloc] init];
        _object_list = {};

        // 初始化网络
        auto compute_units = TNNComputeUnitsCPU;
        [self loadNeuralNetwork:compute_units callback:^(Status status) {
            if (status != TNN_OK) {
                NSLog(@"加载模型失败, 错误详情:  %s", status.description().c_str());
            }
        }];
    }
    return self;
}


- (void)loadNeuralNetwork:(TNNComputeUnits)units callback:(void (^) (Status status))callback {
    //异步加载模型
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Status status = [self.faceModel loadNeuralNetworkModel:units];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(status);
            }
        });
    });
}


- (void)predictWithPixelBuffer:(CVPixelBufferRef)pixelBuffer completionHanlder:(void (^) (vector<pair<float, float>>, int, _Bool))hanlder
{
    if (!self.faceModel || !self.faceModel.predictor || !pixelBuffer) {
        return;
    }
    
    const auto target_dims = self.faceModel.predictor->GetInputShape();
    
    dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_FOREVER);
    
    //for muti-thread safety, increase ref count, to insure predictor is not released while detecting object
    auto predictor_async_thread = self.faceModel.predictor;
    auto compute_units = self.faceModel.predictor->GetComputeUnits();
    
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CGSize imageSize = CGSizeMake(width, height);
    
    
    CVBufferRetain(pixelBuffer);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        Status status = TNN_OK;
        shared_ptr<char> image_data = nullptr;
        shared_ptr<Mat> image_mat = nullptr;
        auto origin_dims = {1, 3, height, width};
        
        // 是否启用GPU计算数据
        if (compute_units == TNNComputeUnitsCPU) {
            image_data = CVImageBuffRefGetData(pixelBuffer);
            image_mat = make_shared<Mat>(DEVICE_ARM, N8UC4, origin_dims, image_data.get());
        } else {
//            id<MTLTexture> image_texture = nil;
//            if (compute_units == TNNComputeUnitsGPU) {
//                image_texture = [camera getMTLTextureFromImageBuffer:image_buffer];
//            }
//            auto image_texture_ref = CFBridgingRetain(image_texture);
//            image_mat = std::make_shared<TNN_NS::Mat>(DEVICE_METAL, TNN_NS::N8UC4, origin_dims, (void *)image_texture_ref);
        }
        
        // 开始预测人脸
        shared_ptr<TNNSDKOutput> output = nullptr;
        if (image_mat->GetData() != nullptr && image_mat->GetWidth() > 0) {
            status = predictor_async_thread->Predict(make_shared<TNNSDKInput>(image_mat), output);
        }
        
        CVBufferRelease(pixelBuffer);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self outputFaceInfo:output imageSize:imageSize status:status completionHanlder:hanlder];
        });
        dispatch_semaphore_signal(self.inflightSemaphore);
    });

}


vector<pair<float, float>> key_points = {};

- (void)outputFaceInfo:(shared_ptr<TNNSDKOutput>)output imageSize:(CGSize)size status:(Status)status completionHanlder:(void (^) (vector<pair<float, float>>, int, _Bool))hanlder
{
    auto face_info = [self.faceModel getObjectList:output];
    if (status != TNN_OK) {
        NSLog(@"未识别到人脸位置, 详情: %s", status.description().c_str());
        return;
    }
    
    face_info = [self reorder:face_info];
    if (face_info.size() > 0)
    {
        for (int i = 0; i < MIN(face_info.size(), self.maxinumFace); i ++)
        {
            auto object = face_info[i];
            auto view_width = self.previewSize.width;
            auto view_height = self.previewSize.height;
            auto view_face = object->AdjustToImageSize(size.height, size.width);
            view_face = view_face.AdjustToViewSize(view_height, view_width, 1);
            if (self.mirror) {
                view_face = view_face.FlipX();
            }
            if (hanlder) {
                hanlder(view_face.key_points, i, true);
            }
        }
    }
    else {
        if (hanlder) {
            vector<pair<float, float>> key_points = {};
            hanlder(key_points, -1,  false);
        }
    }
}



- (std::vector<std::shared_ptr<ObjectInfo> >)reorder:(std::vector<std::shared_ptr<ObjectInfo> >) object_list
{
    if (_object_list.size() > 0 && object_list.size() > 0)
    {
        std::vector<std::shared_ptr<ObjectInfo> > object_list_reorder;
        //按照原有排序插入object_list中原先有的元素
        for (int index_last = 0; index_last < _object_list.size(); index_last++)
        {
            auto object_last = _object_list[index_last];
            //寻找最匹配元素
            int index_target = 0;
            float area_target = -1;
            for (int index=0; index<object_list.size(); index++) {
                auto object = object_list[index];
                auto area = object_last->IntersectionRatio(object.get());
                if (area > area_target) {
                    area_target = area;
                    index_target = index;
                }
            }

            if (area_target > 0) {
                object_list_reorder.push_back(object_list[index_target]);
                //删除指定下标元素
                object_list.erase(object_list.begin() + index_target);
            }
        }

        //插入原先没有的元素
        if (object_list.size() > 0) {
            object_list_reorder.insert(object_list_reorder.end(), object_list.begin(), object_list.end());
        }

        _object_list = object_list_reorder;
        return object_list_reorder;
    } else{
        _object_list = object_list;
        return object_list;
    }
}


std::shared_ptr<char> CVImageBuffRefGetData(CVImageBufferRef image_buffer) {
    
    CGSize size = CVImageBufferGetDisplaySize(image_buffer);
    
    int target_height = size.height;
    int target_width = size.width;
    
    std::shared_ptr<char> data = nullptr;
    if (image_buffer == nil){
        return data;
    }
    if (size.height <= 0 || size.width <= 0) {
        return data;
    }
    
    data = std::shared_ptr<char>(new char[target_height * target_width * 4], [](char* p) { delete[] p; });

    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    
    
    CVPixelBufferLockBaseAddress(image_buffer, 0);
    void *base_address = CVPixelBufferGetBaseAddress(image_buffer);
    size_t bytes_per_row = CVPixelBufferGetBytesPerRow(image_buffer);
    size_t width = CVPixelBufferGetWidth(image_buffer);
    size_t height = CVPixelBufferGetHeight(image_buffer);
    CGContextRef context_orig = CGBitmapContextCreate(base_address, width, height, 8,
                                                 bytes_per_row, color_space,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef cgmage_orig = CGBitmapContextCreateImage(context_orig);
    //resize
    CGContextRef context_target = CGBitmapContextCreate(data.get(),
                                                    target_width,
                                                    target_height,
                                                    8,
                                                    target_width * 4,
                                                    color_space,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);

    CGContextSetInterpolationQuality(context_target, kCGInterpolationHigh);
    CGContextDrawImage(context_target, CGRectMake(0, 0, target_width, target_height), cgmage_orig);
    CGContextRelease(context_target);
    CVPixelBufferUnlockBaseAddress(image_buffer,0);

    CGContextRelease(context_orig);
    CGColorSpaceRelease(color_space);
    CGImageRelease(cgmage_orig);
    return data;
}


@end
