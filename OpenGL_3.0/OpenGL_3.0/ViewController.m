//
//  ViewController.m
//  WDMediaKit
//
//  Created by 祁云 on 2020/6/17.
//  Copyright © 2020 祁云. All rights reserved.
//

#import "ViewController.h"


@implementation UIProgressView (customView)
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = CGSizeMake(self.frame.size.width, 10);
    return newSize;
}
@end

@interface ViewController () < UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView   *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    [self.view addSubview:self.tableView];
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}


- (NSArray *)controlNames {
    return @[@"QYImageRenderViewController",
             @"QYImageTransitionViewController",
             @"QYImageTransitionTypeViewController",
             @"QYPlayerViewController",
             @"QYPlayerRenderManagerViewController",
             @"QYPlayerRecordViewController",
             @"QYPlayerFilterViewController",
             @"QYPixelBufferWriterViewController",
             @"QYMediaCodecViewController",
             @"QYTNNPlayerViewController",
    ];
}


- (NSArray *)cellForTitles {
    return @[@"GLKit-单张图片",
             @"GLKit-图片转场",
             @"GLKit-图片多个转场切换",
             @"视频解码 + 播放",
             @"视频解码 + 播放 + 显示控制",
             @"视频播放 + 录制",
             @"视频播放 + 滤镜",
             @"视频播放 + 滤镜 + 录制",
             @"音视频 + 编解码",
             @"NCNN + 卷积神经网络",
    ];
}


#pragma mark    -   UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Class cls = NSClassFromString([self controlNames][indexPath.row]);
    if (cls) {
        UIViewController *obj = (UIViewController *)[[cls alloc] init];
        if (obj) {
            obj.title = [self cellForTitles][indexPath.row];
            [self.navigationController pushViewController:obj animated:YES];
        }
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self cellForTitles].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    if (cell) {
        cell.textLabel.text = [self cellForTitles][indexPath.row];
    }
    return cell;
}


@end
