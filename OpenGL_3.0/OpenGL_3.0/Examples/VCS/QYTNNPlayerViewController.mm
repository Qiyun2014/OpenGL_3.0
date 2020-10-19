//
//  QYTNNPlayerViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/19.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYTNNPlayerViewController.h"
#import <Metal/Metal.h>
#import <CoreMedia/CoreMedia.h>
#import <tnn/tnn.h>
#include "tnn_fps_counter.h"
#import "tnn_sdk_sample.h"
#import "tnn_fps_counter.h"
#import "TNNBoundingBox.h"
#import "UIImage+Utility.h"
#import "QYTNNFaceAlignerModel.h"

using namespace std;
using namespace TNN_NS;

#define kMaxBuffersInFlight 1
typedef void(^CommonCallback)(Status);

@interface QYTNNPlayerViewController (){
    std::vector<std::shared_ptr<ObjectInfo> > _object_list_last;
    std::shared_ptr<TNNFPSCounter> _fps_counter;
}

@property (nonatomic, strong) NSArray<TNNBoundingBox *> *boundingBoxes;
@property (nonatomic, strong) dispatch_semaphore_t inflightSemaphore;
@property (nonatomic, strong) NSArray<UIColor *> *colors;
@property (nonatomic, strong) QYTNNFaceAlignerModel *viewModel;

@end

@implementation QYTNNPlayerViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.viewModel = [[QYTNNFaceAlignerModel alloc] init];
    
    //colors for each class
    auto colors = [NSMutableArray array];
    for (NSNumber *r in @[@(0.2), @(0.4), @(0.6), @(0.8), @(1.0)]) {
        for (NSNumber *g in @[@(0.3), @(0.7)]) {
            for (NSNumber *b in @[@(0.4), @(0.8)]) {
                [colors addObject:[UIColor colorWithRed:[r floatValue]
                                                  green:[g floatValue]
                                                   blue:[b floatValue]
                                                  alpha:1]];
            }
        }
    }
    self.colors = colors;

    _object_list_last = {};
    _fps_counter = std::make_shared<TNNFPSCounter>();
    _boundingBoxes = [NSArray array];
    _inflightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
    
    
    // add the bounding box layers to the UI, on top of the video preview.
    [self setupBoundingBox:12];
    
    //init network
    auto units = TNNComputeUnitsCPU;
    [self loadNeuralNetwork:units callback:^(Status status) {
        if (status != TNN_OK) {
            //刷新界面
            [self showSDKOutput:nullptr withOriginImageSize:CGSizeZero withStatus:status];
        }
    }];
}



- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    [self.renderView displayPixelBuffer:pixelBuffer];
    
    
    if (!self.viewModel || !self.viewModel.predictor) return;
    
    const auto target_dims = self.viewModel.predictor->GetInputShape();
    // block until the next GPU buffer is available.
    dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_FOREVER);
    
    //for muti-thread safety, increase ref count, to insure predictor is not released while detecting object
    auto fps_counter_async_thread = _fps_counter;
    auto predictor_async_thread = self.viewModel.predictor;
    auto compute_units = self.viewModel.predictor->GetComputeUnits();
    
    
    int origin_width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int origin_height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CGSize origin_image_size = CGSizeMake(origin_width, origin_height);
    
    
    Status status = TNN_OK;
    std::map<std::string, double> map_fps;

    //Note：智能指针必须在resize后才能释放
    std::shared_ptr<char> image_data = nullptr;
    std::shared_ptr<TNN_NS::Mat> image_mat = nullptr;
    auto origin_dims = {1, 3, origin_height, origin_width};
    if (compute_units == TNNComputeUnitsCPU) {
        image_data = utility::CVImageBuffRefGetData(pixelBuffer);
        image_mat = std::make_shared<TNN_NS::Mat>(DEVICE_ARM, TNN_NS::N8UC4, origin_dims, image_data.get());
    } else {
        // image_mat = std::make_shared<TNN_NS::Mat>(DEVICE_METAL, TNN_NS::N8UC4, origin_dims, (void *)image_texture_ref);
    }
    
    
    std::shared_ptr<TNNSDKOutput> sdk_output = nullptr;
    do {
        if (image_mat->GetData() != nullptr && image_mat->GetWidth() > 0) {
            fps_counter_async_thread->Begin("detect");
            status = predictor_async_thread->Predict(std::make_shared<TNNSDKInput>(image_mat), sdk_output);
            fps_counter_async_thread->End("detect");
        }
    } while (0);
            
    map_fps = fps_counter_async_thread->GetAllFPS();
    //auto time = fps_counter_async_thread->GetAllTime();

    [self showSDKOutput:sdk_output
    withOriginImageSize:origin_image_size
             withStatus:status];
    
    dispatch_semaphore_signal(self.inflightSemaphore);
}




- (void)setupBoundingBox:(NSUInteger)maxNumber {
    // Set up the bounding boxes.
    auto boundingBoxes = [NSMutableArray arrayWithArray:_boundingBoxes];
    for (NSUInteger i=_boundingBoxes.count; i<maxNumber; i++) {
        [boundingBoxes addObject:[[TNNBoundingBox alloc] init]];
    }
    
    for (TNNBoundingBox *iter in boundingBoxes) {
        [iter hide];
        [iter removeFromSuperLayer];
        
        [iter addToLayer:self.renderView.layer];
    }
    self.boundingBoxes = boundingBoxes;
}


- (void)showSDKOutput:(std::shared_ptr<TNNSDKOutput>)output
       withOriginImageSize:(CGSize)size
           withStatus:(Status)status {
    auto object_list = [self.viewModel getObjectList:output];
    [self showObjectInfo:object_list withOriginImageSize:size withStatus:status];
}


- (void)showObjectInfo:(std::vector<std::shared_ptr<ObjectInfo> >)object_list
            withOriginImageSize:(CGSize)origin_size
            withStatus:(Status)status {
    //status
    if (status != TNN_OK) {
//        self.labelResult.text = [NSString stringWithFormat:@"%s", status.description().c_str()];
        
        for (int i=0; i<_boundingBoxes.count; i++) {
            [_boundingBoxes[i] hide];
        }
    } else {
        object_list = [self reorder:object_list];
        
        //Object
//        auto camera_pos = [self.cameraDevice cameraPosition];
//        auto camera_gravity = [self.cameraDevice.videoPreviewLayer videoGravity];
        int video_gravity = 2;
//        if (camera_gravity == AVLayerVideoGravityResizeAspectFill) {
//            video_gravity = 2;
//        } else if(camera_gravity == AVLayerVideoGravityResizeAspect) {
//            video_gravity = 1;
//        }
        for (int i=0; i<_boundingBoxes.count; i++) {
            if ( i < object_list.size()) {
                auto object = object_list[i];
                auto view_width = self.renderView.bounds.size.width;
                auto view_height = self.renderView.bounds.size.height;
                auto label = [self.viewModel labelForObject:object];
                auto view_face = object->AdjustToImageSize(origin_size.height, origin_size.width);
                view_face = view_face.AdjustToViewSize(view_height, view_width, video_gravity);
//                if (camera_pos == AVCaptureDevicePositionFront) {
//                    view_face = view_face.FlipX();
//                }
                [_boundingBoxes[i] showText:label
                                  withColor:self.colors[i]
                                    atFrame:CGRectMake(view_face.x1, view_face.y1,
                                                       view_face.x2-view_face.x1,
                                                       view_face.y2-view_face.y1)];
    //            [_boundingBoxes[i] showMarkAtPoints:{{(view_face.x1+view_face.x2)/2, (view_face.y1+view_face.y2)/2}} withColor:[UIColor redColor]];
                [_boundingBoxes[i] showMarkAtPoints:view_face.key_points withColor:[UIColor greenColor]];
            } else {
                [_boundingBoxes[i] hide];
            }
        }
    }
}



- (std::vector<std::shared_ptr<ObjectInfo> >)reorder:(std::vector<std::shared_ptr<ObjectInfo> >) object_list {
    if (_object_list_last.size() > 0 && object_list.size() > 0) {
        std::vector<std::shared_ptr<ObjectInfo> > object_list_reorder;
        //按照原有排序插入object_list中原先有的元素
        for (int index_last = 0; index_last < _object_list_last.size(); index_last++) {
            auto object_last = _object_list_last[index_last];
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

        _object_list_last = object_list_reorder;
        return object_list_reorder;
    } else{
        _object_list_last = object_list;
        return object_list;
    }
}


- (void)loadNeuralNetwork:(TNNComputeUnits)units
                 callback:(CommonCallback)callback {
    //异步加载模型
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Status status = [self.viewModel loadNeuralNetworkModel:units];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(status);
            }
        });
    });
}

@end
