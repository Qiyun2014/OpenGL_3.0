//
//  QTTNNFaceViewController.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/20.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QTTNNFaceViewController.h"
#import "QYTNNPredict.h"
#import "TNNBoundingBox.h"
#import "QYGLUtils.h"

@interface QTTNNFaceViewController ()

@property (strong, nonatomic) QYTNNPredict  *tnnPredict;
@property (nonatomic, strong) NSArray<TNNBoundingBox *> *boundingBoxes;

@end

@implementation QTTNNFaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _boundingBoxes = [NSArray array];
    // add the bounding box layers to the UI, on top of the video preview.
    [self setupBoundingBox:12];
    
    self.tnnPredict = [[QYTNNPredict alloc] initWithMaxinumFace:12 windowSize:self.renderView.bounds.size];
}


- (void)mediaDecoder:(QYMediaDecoder *)mediaDecoder timestamp:(CMTime)ts didOutputPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    [self.renderView displayPixelBuffer:pixelBuffer];
    
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

    OBJC_WEAK(self);
    [self.tnnPredict predictWithPixelBuffer:pixelBuffer completionHanlder:^(std::vector<std::pair<float, float> > keypoints, int face_id, bool has_found)
    {
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"----------------------------------->>   %f, 关键点个数 %lu", end - start, keypoints.size());

        OBJC_STRONG(weak_self);
        if (has_found)
        {
             [strong_weak_self.boundingBoxes[face_id] showMarkAtPoints:keypoints withColor:[UIColor greenColor]];
        } else {
             [strong_weak_self.boundingBoxes[face_id] hide];
        }
    }];
}



- (void)setupBoundingBox:(NSUInteger)maxNumber
{
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
