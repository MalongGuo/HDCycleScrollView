//
//  ViewController.m
//  HDCycleScrollView
//
//  Created by Malong Guo on 27/08/2016.
//  Copyright © 2016 scat. All rights reserved.
//

#import "ViewController.h"
#import "HDCycleScrollView.h"

@interface ViewController () <HDCycleScrollViewDelegate>
@property (nonatomic, weak) IBOutlet HDCycleScrollView *cycleView;
@property (nonatomic, weak) IBOutlet HDCycleScrollView *recommendView;
@property (nonatomic, weak) IBOutlet HDCycleScrollView *menuView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray *imagesURLStrings = @[
                                  @"https://ss2.baidu.com/-vo3dSag_xI4khGko9WTAnF6hhy/super/whfpf%3D425%2C260%2C50/sign=a4b3d7085dee3d6d2293d48b252b5910/0e2442a7d933c89524cd5cd4d51373f0830200ea.jpg",
                                  @"https://ss0.baidu.com/-Po3dSag_xI4khGko9WTAnF6hhy/super/whfpf%3D425%2C260%2C50/sign=a41eb338dd33c895a62bcb3bb72e47c2/5fdf8db1cb134954a2192ccb524e9258d1094a1e.jpg",
                                  @"http://c.hiphotos.baidu.com/image/w%3D400/sign=c2318ff84334970a4773112fa5c8d1c0/b7fd5266d0160924c1fae5ccd60735fae7cd340d.jpg",
                                  @"http://img.taopic.com/uploads/allimg/130220/234624-1302201I45253.jpg",
                                  @"http://img.taopic.com/uploads/allimg/140401/234776-14040122422787.jpg"
                                  ];
    // 图片配文字
    NSArray *titles = @[@"感谢您的支持，如果下载的",
                        @"如果代码在使用过程中出现问题",
                        @"您可以发邮件到linuxc2012@163.com",
                        @"我会尽快回复",
                        @"感谢您的支持"
                        ];
    // 菜单文字
    NSArray *menuTitles = @[@"1",
                        @"2",
                        @"3",
                        @"4",
                        @"5"
                        ];
    
    // 轮播图片
    self.cycleView.titlesGroup = titles;
    self.cycleView.pageControlAliment = SDCycleScrollViewPageContolAlimentCenter;
    self.cycleView.currentPageDotColor = [UIColor whiteColor]; // 自定义分页控件小圆标颜色
    self.cycleView.delegate = self;
    self.cycleView.autoScrollTimeInterval = 2.0;
    
    // 推荐图片
    self.recommendView.titlesGroup = titles;
    self.recommendView.delegate = self;
    self.recommendView.autoScroll = NO;
    self.recommendView.infiniteLoop = NO;
    self.recommendView.pagingEnabled = NO;
    self.recommendView.colCount = 4;
    self.recommendView.colMagrin = 5;
    self.recommendView.showPageControl = NO;
    
    // 菜单栏
    self.menuView.titlesGroup = menuTitles;
    self.menuView.delegate = self;
    self.menuView.autoScroll = NO;
    self.menuView.infiniteLoop = YES;
    self.menuView.pagingEnabled = YES;
    self.menuView.colCount = 2;
    self.menuView.rowCount = 2;
    self.menuView.colMagrin = 1;

    //         --- 模拟加载延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.cycleView.imageURLStringsGroup = imagesURLStrings;
        self.recommendView.imageURLStringsGroup = imagesURLStrings;
        self.menuView.imageURLStringsGroup = imagesURLStrings;
    });


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)hdCycleScrollView:(HDCycleScrollView *)cycleScrollView didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"您点击了第 %ld 张图片", (long)index);
}

@end
