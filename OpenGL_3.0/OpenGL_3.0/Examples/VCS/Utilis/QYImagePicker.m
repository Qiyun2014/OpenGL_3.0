//
//  QYImagePicker.m
//  OpenGL_3.0
//
//  Created by 祁云 on 2020/10/4.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "QYImagePicker.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>


@interface QYImagePicker ()

@property (nonatomic, strong) PHPickerFilter    *pickerFilter;

@end

@implementation QYImagePicker


- (PHPickerFilter *)pickerFilter
{
    if (!_pickerFilter) {
        _pickerFilter = [PHPickerFilter init];
    }
    return _pickerFilter;
}

@end
