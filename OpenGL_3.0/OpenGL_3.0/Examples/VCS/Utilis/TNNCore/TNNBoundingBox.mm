//  Copyright © 2020 tencent. All rights reserved.

#import "TNNBoundingBox.h"

@interface  TNNBoundingBox ()
@property (nonatomic, strong) CAShapeLayer *boxLayer;
@property (nonatomic, strong) CATextLayer *textLayer;

@property (nonatomic, strong) NSArray<CAShapeLayer *> *markLayers;
@end

@implementation TNNBoundingBox


- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _boxLayer = [[CAShapeLayer alloc] init];
        _boxLayer.fillColor = [UIColor clearColor].CGColor;
        _boxLayer.lineWidth = 2;
        _boxLayer.hidden = YES;

        _textLayer =[[CATextLayer alloc] init];
        _textLayer.foregroundColor = [UIColor blackColor].CGColor;
        _textLayer.hidden = YES;
        _textLayer.contentsScale = [UIScreen mainScreen].scale;
        _textLayer.fontSize = 14;
        {
            UIFont *font = [UIFont systemFontOfSize:14];
            CFStringRef fontName = (__bridge CFStringRef)font.fontName;
            CGFontRef fontRef = CGFontCreateWithFontName(fontName);
            _textLayer.font = fontRef;
            CGFontRelease(fontRef);
        }
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _markLayers = [NSArray array];
    }
    return self;
}

- (void)addToLayer:(CALayer *)layer {
    [layer addSublayer:_boxLayer];
    [layer addSublayer:_textLayer];
    
    NSArray *markLayers = _markLayers;
    for (CAShapeLayer * item in markLayers) {
        [layer addSublayer:item];
    }
}

-(void)removeFromSuperLayer {
    [_boxLayer removeFromSuperlayer];
    [_textLayer removeFromSuperlayer];
    
    NSArray *markLayers = _markLayers;
    for (CAShapeLayer * item in markLayers) {
        [item removeFromSuperlayer];
    }
}

- (void)showText:(NSString *)text withColor:(UIColor *)color atFrame:(CGRect)frame {
    [CATransaction setDisableActions:YES];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];
    _boxLayer.path = path.CGPath;
    _boxLayer.strokeColor = color.CGColor;
    _boxLayer.hidden = NO;

    _textLayer.string = text;
    _textLayer.backgroundColor = color.CGColor;
    _textLayer.hidden = NO;

    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14]};

    CGRect textRect = [text boundingRectWithSize:CGSizeMake(400, 100)
                                       options:NSStringDrawingTruncatesLastVisibleLine
                                    attributes:attributes
                                       context:nil];
    
    _textLayer.frame = CGRectMake(frame.origin.x - 1,
                                  frame.origin.y - textRect.size.height,
                                  textRect.size.width + 10,
                                  textRect.size.height);
    
    [CATransaction setDisableActions:NO];
}

- (void)showMarkAtPoints:(std::vector<std::pair<float, float>>)points withColor:(UIColor *)color
{
    [CATransaction setDisableActions:YES];
    NSMutableArray<CAShapeLayer *> *newMarkLayers = [NSMutableArray arrayWithArray:_markLayers];
    
    //add more layers if need
    for (NSInteger i=_markLayers.count; i<points.size(); i++)
    {
        CAShapeLayer *boxLayer = [[CAShapeLayer alloc] init];
        boxLayer.fillColor = [UIColor clearColor].CGColor;
        boxLayer.lineWidth = 1;
        boxLayer.hidden = YES;
        
        [newMarkLayers addObject:boxLayer];
    }
    
    CALayer *super_layer = _boxLayer.superlayer;
    for (NSInteger i=0; i<newMarkLayers.count; i++) {
        CAShapeLayer *layer = newMarkLayers[i];
        if (layer.superlayer != super_layer) {
            [layer removeFromSuperlayer];
            [super_layer addSublayer:layer];
        }
        
        if (i < points.size()) {
            auto point = points[i];
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(point.first-2, point.second)];
            [path addLineToPoint:CGPointMake(point.first+2, point.second)];
            [path moveToPoint:CGPointMake(point.first, point.second-2)];
            [path addLineToPoint:CGPointMake(point.first, point.second+2)];
            [path closePath];
            
            layer.path = path.CGPath;
            layer.strokeColor = color.CGColor;
            layer.hidden = NO;
        } else {
            layer.hidden = YES;
        }
    }
    _markLayers = newMarkLayers;
    
    [CATransaction setDisableActions:NO];
}

- (void)hide
{
    [CATransaction setDisableActions:YES];
    _boxLayer.hidden = YES;
    _textLayer.hidden = YES;
    
    NSArray<CAShapeLayer *>  *markLayers = _markLayers;
    for (CAShapeLayer * item in markLayers) {
        item.hidden = YES;
    }
    [CATransaction setDisableActions:NO];
}
@end
