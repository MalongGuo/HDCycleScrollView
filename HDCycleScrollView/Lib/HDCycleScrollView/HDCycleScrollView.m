//
//  HDCycleScrollView.m
//  HDCycleScrollView
//
//  Created by Malong Guo on 26/08/2016.
//  Copyright © 2016 scat. All rights reserved.
//

#import "HDCycleScrollView.h"
#import "HDCycleLayout.h"

#import "SDCollectionViewCell.h"
#import "UIView+SDExtension.h"
#import "TAPageControl.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"

#define kCycleScrollViewInitialPageControlDotSize CGSizeMake(10, 10)

#define kMainScreenWidth     [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight     [UIScreen mainScreen].bounds.size.height
#define kItemsWidth     self.frame.size.width
#define kItemsHeight    self.frame.size.height

NSString * const cellID = @"cycleCell";

@interface HDCycleScrollView () <UICollectionViewDataSource, UICollectionViewDelegate> {
    UICollectionViewScrollPosition _kCollectionViewScrollPosition;
}


@property (nonatomic, weak) UICollectionView *mainView; // 显示图片的collectionView
@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray *imagePathsGroup;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalItemsCount;
@property (nonatomic, weak) UIControl *pageControl;

@property (nonatomic, strong) UIImageView *backgroundImageView; // 当imageURLs为空时的背景图

@property (nonatomic, assign) NSInteger networkFailedRetryCount;


@property (nonatomic, assign) NSInteger hdScreenCount;
@property (nonatomic, assign) NSInteger hdTotalItemsCount;
@property (nonatomic, weak) HDCycleLayout *menuLayout;

@end

@implementation HDCycleScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
        [self setupMainView];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialization];
    [self setupMainView];
}

- (void)initialization
{
    _pageControlAliment = SDCycleScrollViewPageContolAlimentCenter;
    _autoScrollTimeInterval = 2.0;
    _titleLabelTextColor = [UIColor whiteColor];
    _titleLabelTextFont= [UIFont systemFontOfSize:14];
    _titleLabelBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    _titleLabelHeight = 30;
    _autoScroll = YES;
    _infiniteLoop = YES;
    _showPageControl = YES;
    _pageControlDotSize = kCycleScrollViewInitialPageControlDotSize;
    _pageControlStyle = SDCycleScrollViewPageContolStyleClassic;
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [UIColor lightGrayColor];
    _bannerImageViewContentMode = UIViewContentModeScaleToFill;
    self.backgroundColor = [UIColor lightGrayColor];
    
    
    /**
     *  自定义方法
     */
    _colCount = 1;
    _rowCount = 1;
    _colMagrin = 0;
    _rowMagrin = 0;
    _pagingEnabled = YES;
    _kCollectionViewScrollPosition = UICollectionViewScrollPositionCenteredVertically;
    
    
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame imageNamesGroup:(NSArray *)imageNamesGroup
{
    HDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.localizationImageNamesGroup = [NSMutableArray arrayWithArray:imageNamesGroup];
    return cycleScrollView;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame shouldInfiniteLoop:(BOOL)infiniteLoop imageNamesGroup:(NSArray *)imageNamesGroup
{
    HDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.infiniteLoop = infiniteLoop;
    cycleScrollView.localizationImageNamesGroup = [NSMutableArray arrayWithArray:imageNamesGroup];
    return cycleScrollView;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame imageURLStringsGroup:(NSArray *)imageURLsGroup
{
    HDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.imageURLStringsGroup = [NSMutableArray arrayWithArray:imageURLsGroup];
    return cycleScrollView;
}

+ (instancetype)cycleScrollViewWithFrame:(CGRect)frame delegate:(id<HDCycleScrollViewDelegate>)delegate placeholderImage:(UIImage *)placeholderImage
{
    HDCycleScrollView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.delegate = delegate;
    cycleScrollView.placeholderImage = placeholderImage;
    
    return cycleScrollView;
}

// 设置显示图片的collectionView
- (void)setupMainView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout = flowLayout;
    
    HDCycleLayout *menuLayout = [[HDCycleLayout alloc] init];
    menuLayout.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    menuLayout.colCount = self.colCount;
    menuLayout.rowCount = self.rowCount;
    menuLayout.colMagrin = self.colMagrin;
    menuLayout.rowMagrin = self.rowMagrin;
    menuLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    menuLayout.infiniteLoop = self.infiniteLoop;
    _menuLayout = menuLayout;
    
    UICollectionView *mainView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:menuLayout];
    mainView.backgroundColor = [UIColor clearColor];
    mainView.pagingEnabled = self.pagingEnabled;
    mainView.showsHorizontalScrollIndicator = NO;
    mainView.showsVerticalScrollIndicator = NO;
    [mainView registerClass:[SDCollectionViewCell class] forCellWithReuseIdentifier:cellID];
    mainView.dataSource = self;
    mainView.delegate = self;
    mainView.scrollsToTop = NO;
    [self addSubview:mainView];
    _mainView = mainView;
}


#pragma mark - properties

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    
    if (!self.backgroundImageView) {
        UIImageView *bgImageView = [UIImageView new];
        bgImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self insertSubview:bgImageView belowSubview:self.mainView];
        self.backgroundImageView = bgImageView;
    }
    
    self.backgroundImageView.image = placeholderImage;
}

- (void)setPageControlDotSize:(CGSize)pageControlDotSize
{
    _pageControlDotSize = pageControlDotSize;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageContol = (TAPageControl *)_pageControl;
        pageContol.dotSize = pageControlDotSize;
    }
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    
    _pageControl.hidden = !showPageControl;
}

- (void)setCurrentPageDotColor:(UIColor *)currentPageDotColor
{
    _currentPageDotColor = currentPageDotColor;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        pageControl.dotColor = currentPageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    }
    
}

- (void)setPageDotColor:(UIColor *)pageDotColor
{
    _pageDotColor = pageDotColor;
    
    if ([self.pageControl isKindOfClass:[UIPageControl class]]) {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageDotColor;
    }
}

- (void)setCurrentPageDotImage:(UIImage *)currentPageDotImage
{
    _currentPageDotImage = currentPageDotImage;
    
    if (self.pageControlStyle != SDCycleScrollViewPageContolStyleAnimated) {
        self.pageControlStyle = SDCycleScrollViewPageContolStyleAnimated;
    }
    
    [self setCustomPageControlDotImage:currentPageDotImage isCurrentPageDot:YES];
}

- (void)setPageDotImage:(UIImage *)pageDotImage
{
    _pageDotImage = pageDotImage;
    
    if (self.pageControlStyle != SDCycleScrollViewPageContolStyleAnimated) {
        self.pageControlStyle = SDCycleScrollViewPageContolStyleAnimated;
    }
    
    [self setCustomPageControlDotImage:pageDotImage isCurrentPageDot:NO];
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot
{
    if (!image || !self.pageControl) return;
    
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    }
}

- (void)setInfiniteLoop:(BOOL)infiniteLoop
{
    _infiniteLoop = infiniteLoop;
    _menuLayout.infiniteLoop = NO;
    
    if (self.imagePathsGroup.count) {
        self.imagePathsGroup = self.imagePathsGroup;
    }
}

-(void)setAutoScroll:(BOOL)autoScroll{
    _autoScroll = autoScroll;
    
    [self invalidateTimer];
    
    if (_autoScroll) {
        [self setupTimer];
    }
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    _flowLayout.scrollDirection = scrollDirection;
    _menuLayout.scrollDirection = scrollDirection;
}

- (void)setAutoScrollTimeInterval:(CGFloat)autoScrollTimeInterval
{
    _autoScrollTimeInterval = autoScrollTimeInterval;
    
    [self setAutoScroll:self.autoScroll];
}

- (void)setPageControlStyle:(SDCycleScrollViewPageContolStyle)pageControlStyle
{
    _pageControlStyle = pageControlStyle;
    
    [self setupPageControl];
}

- (void)setImagePathsGroup:(NSArray *)imagePathsGroup
{
    if (imagePathsGroup.count < _imagePathsGroup.count) {
        [_mainView setContentOffset:CGPointZero animated:NO];
    }
    
    _imagePathsGroup = imagePathsGroup;
    
    _totalItemsCount = self.infiniteLoop ? self.imagePathsGroup.count * 100 : self.imagePathsGroup.count;
    
    _hdScreenCount = ceil(self.imagePathsGroup.count/(self.colCount * self.rowCount));
    _hdTotalItemsCount = self.infiniteLoop ? self.hdScreenCount * 100 : self.hdScreenCount;
    
    if (imagePathsGroup.count != 1) {
        self.mainView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        [self invalidateTimer];
        self.mainView.scrollEnabled = NO;
    }
    
    if (_hdScreenCount != 1) {
        self.mainView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        [self invalidateTimer];
        self.mainView.scrollEnabled = NO;
    }
    
    [self setupPageControl];
    [self.mainView reloadData];
    
    if (imagePathsGroup.count) {
        [self.backgroundImageView removeFromSuperview];
    } else {
        if (self.backgroundImageView && !self.backgroundImageView.superview) {
            [self insertSubview:self.backgroundImageView belowSubview:self.mainView];
        }
    }
}

- (void)setImageURLStringsGroup:(NSArray *)imageURLStringsGroup
{
    _imageURLStringsGroup = imageURLStringsGroup;
    
    NSMutableArray *temp = [NSMutableArray new];
    [_imageURLStringsGroup enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * stop) {
        NSString *urlString;
        if ([obj isKindOfClass:[NSString class]]) {
            urlString = obj;
        } else if ([obj isKindOfClass:[NSURL class]]) {
            NSURL *url = (NSURL *)obj;
            urlString = [url absoluteString];
        }
        if (urlString) {
            [temp addObject:urlString];
        }
    }];
    self.imagePathsGroup = [temp copy];
}

- (void)setLocalizationImageNamesGroup:(NSArray *)localizationImageNamesGroup
{
    _localizationImageNamesGroup = localizationImageNamesGroup;
    self.imagePathsGroup = [localizationImageNamesGroup copy];
}

- (void)setTitlesGroup:(NSArray *)titlesGroup
{
    _titlesGroup = titlesGroup;
    if (self.onlyDisplayText) {
        NSMutableArray *temp = [NSMutableArray new];
        for (int i = 0; i < _titlesGroup.count; i++) {
            [temp addObject:@""];
        }
        self.backgroundColor = [UIColor clearColor];
        self.imageURLStringsGroup = [temp copy];
    }
}

#pragma mark - actions

- (void)setupTimer
{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollTimeInterval target:self selector:@selector(automaticScroll) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)setupPageControl
{
    if (_pageControl) [_pageControl removeFromSuperview]; // 重新加载数据时调整
    
    if (self.hdScreenCount == 0 || self.onlyDisplayText) return;
    
    if ((self.hdScreenCount == 1) && self.hidesForSinglePage) return;
    
    int indexOnPageControl = [self currentIndex] % self.hdScreenCount;
    
    switch (self.pageControlStyle) {
        case SDCycleScrollViewPageContolStyleAnimated:
        {
            TAPageControl *pageControl = [[TAPageControl alloc] init];
            pageControl.numberOfPages = self.hdScreenCount;
            pageControl.dotColor = self.currentPageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        case SDCycleScrollViewPageContolStyleClassic:
        {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = self.hdScreenCount;
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor;
            pageControl.pageIndicatorTintColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        default:
            break;
    }
    
    // 重设pagecontroldot图片
    if (self.currentPageDotImage) {
        self.currentPageDotImage = self.currentPageDotImage;
    }
    if (self.pageDotImage) {
        self.pageDotImage = self.pageDotImage;
    }
}


- (void)automaticScroll
{
    if (0 == _hdTotalItemsCount) return;
    int currentIndex = [self currentIndex];
    int targetIndex = (currentIndex+1);
    if (targetIndex >= _hdTotalItemsCount) {
        if (self.infiniteLoop) {
            targetIndex = _hdTotalItemsCount / _hdScreenCount * 0.5;
//            [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:targetIndex] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
            [_mainView setContentOffset:CGPointMake(targetIndex*kMainScreenWidth, 0) animated:NO];

        }
        return;
    }
    
    NSLog(@"%d", targetIndex);
    int targetSection = targetIndex/ _hdScreenCount / self.colCount / self.rowCount;
    int targetItem = targetIndex % ((int)(self.colCount * self.rowCount)*_hdScreenCount);
    targetSection = targetIndex / _hdScreenCount;
    
    targetItem = (targetIndex % _hdScreenCount)*self.colCount* self.rowCount;
    
    NSLog(@"targetSection: %d, targetItem, %d", targetSection, targetItem);
    
//    [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetItem inSection:targetSection] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    [_mainView setContentOffset:CGPointMake(targetIndex*kMainScreenWidth, 0) animated:YES];

}

- (int)currentIndex
{
    if (_mainView.sd_width == 0 || _mainView.sd_height == 0) {
        return 0;
    }
    
    NSLog(@"First self->contentOffset.x: %f", _mainView.contentOffset.x);
    NSInteger index = 0;
    if (_menuLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        
        index = ((int)(_mainView.contentOffset.x + (_menuLayout.itemSize.width + self.colMagrin) *self.colCount * 0.5)) / ((int)(_menuLayout.itemSize.width + self.colMagrin)* self.colCount);
        index = ((int)(_mainView.contentOffset.x + kMainScreenWidth * 0.5)) / ((int)(kMainScreenWidth));
        
    } else {
        index = (_mainView.contentOffset.y + _flowLayout.itemSize.height * 0.5) / _flowLayout.itemSize.height;
    }
    
    NSLog(@"self->contentOffset.x: %f", _mainView.contentOffset.x);
    NSLog(@"self->index: %ld", (long)index);
    
    return MAX(0, (int)index);
}

- (void)clearCache
{
    [[self class] clearImagesCache];
}

+ (void)clearImagesCache
{
    [[[SDWebImageManager sharedManager] imageCache] clearDisk];
}

#pragma mark - life circles

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _flowLayout.itemSize = self.frame.size;
    
    _menuLayout.itemSize = CGSizeMake((kItemsWidth - (_menuLayout.colCount + 1) * _menuLayout.colMagrin)/_menuLayout.colCount, (kItemsHeight - (_menuLayout.rowCount + 1)*_menuLayout.rowMagrin)/_menuLayout.rowCount);
    
    _mainView.frame = self.bounds;
    NSLog(@"无限轮播 初始化前, contentOffset.x:%f, _hdTotalItemsCount:%ld", self.mainView.contentOffset.x, (long)self.hdTotalItemsCount);
    
    if (_mainView.contentOffset.x == 0 &&  _hdTotalItemsCount) {
        NSInteger targetIndex = 0;
        if (self.infiniteLoop) {
            targetIndex = _hdTotalItemsCount / _hdScreenCount * 0.5;
        }else{
            targetIndex = 0;
        }
        NSLog(@"%ld", (long)targetIndex);
//        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:targetIndex] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
        [_mainView setContentOffset:CGPointMake(targetIndex*kMainScreenWidth, 0) animated:NO];
        NSLog(@"layout targetIndex : %f", self.mainView.contentOffset.x);
        
    }
    
    
    
    CGSize size = CGSizeZero;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        if (!(self.pageDotImage && self.currentPageDotImage && CGSizeEqualToSize(kCycleScrollViewInitialPageControlDotSize, self.pageControlDotSize))) {
            pageControl.dotSize = self.pageControlDotSize;
        }
        size = [pageControl sizeForNumberOfPages:self.imagePathsGroup.count];
        size = [pageControl sizeForNumberOfPages:self.hdScreenCount];
        
        
    } else {
        size = CGSizeMake(self.imagePathsGroup.count * self.pageControlDotSize.width * 1.2, self.pageControlDotSize.height);
        size = CGSizeMake(self.hdScreenCount * self.pageControlDotSize.width * 1.2, self.pageControlDotSize.height);
        
    }
    CGFloat x = (self.sd_width - size.width) * 0.5;
    if (self.pageControlAliment == SDCycleScrollViewPageContolAlimentRight) {
        x = self.mainView.sd_width - size.width - 10;
    }
    CGFloat y = self.mainView.sd_height - size.height - 10;
    
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    
    self.pageControl.frame = CGRectMake(x, y, size.width, size.height);
    self.pageControl.hidden = !_showPageControl;
    
    if (self.backgroundImageView) {
        self.backgroundImageView.frame = self.bounds;
    }
    
}

//解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self invalidateTimer];
    }
}

//解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
- (void)dealloc {
    _mainView.delegate = nil;
    _mainView.dataSource = nil;
}

#pragma mark - public actions

- (void)adjustWhenControllerViewWillAppera
{
    long targetIndex = [self currentIndex];
    if (targetIndex < _totalItemsCount) {
//        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        [_mainView setContentOffset:CGPointMake(targetIndex*kMainScreenWidth, 0) animated:NO];

    }
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.imagePathsGroup.count != 0) {
        return _hdTotalItemsCount/_hdScreenCount;
    } else {
        return 0;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.imagePathsGroup.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    long itemIndex = indexPath.item % self.imagePathsGroup.count;
    
    NSString *imagePath = self.imagePathsGroup[itemIndex];
    
    if (!self.onlyDisplayText && [imagePath isKindOfClass:[NSString class]]) {
        if ([imagePath hasPrefix:@"http"]) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:self.placeholderImage];
        } else {
            UIImage *image = [UIImage imageNamed:imagePath];
            if (!image) {
                [UIImage imageWithContentsOfFile:imagePath];
            }
            cell.imageView.image = image;
        }
    } else if (!self.onlyDisplayText && [imagePath isKindOfClass:[UIImage class]]) {
        cell.imageView.image = (UIImage *)imagePath;
    }
    
    if (_titlesGroup.count && itemIndex < _titlesGroup.count) {
        cell.title = _titlesGroup[itemIndex];
    }
    
    if (!cell.hasConfigured) {
        cell.titleLabelBackgroundColor = self.titleLabelBackgroundColor;
        cell.titleLabelHeight = self.titleLabelHeight;
        cell.titleLabelTextColor = self.titleLabelTextColor;
        cell.titleLabelTextFont = self.titleLabelTextFont;
        cell.hasConfigured = YES;
        cell.imageView.contentMode = self.bannerImageViewContentMode;
        cell.clipsToBounds = YES;
        cell.onlyDisplayText = self.onlyDisplayText;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(hdCycleScrollView:didSelectItemAtIndex:)]) {
        [self.delegate hdCycleScrollView:self didSelectItemAtIndex:indexPath.item % ((int)(self.hdScreenCount * self.rowCount * self.colCount))];
    }
    if (self.clickItemOperationBlock) {
        self.clickItemOperationBlock(indexPath.item % ((int)(self.hdScreenCount * self.rowCount * self.colCount)));
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    NSLog(@"scrollViewDidScroll %lf", self.mainView.contentOffset.x);
    
    if (!self.hdScreenCount) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self currentIndex];
    
    int indexOnPageControl = itemIndex % self.hdScreenCount;
    
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.autoScroll) {
        [self setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidEndScrollingAnimation:self.mainView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (!self.hdScreenCount) return; // 解决清除timer时偶尔会出现的问题
    int indexOnPageControl = [self currentIndex] % self.hdScreenCount;
    
    if ([self.delegate respondsToSelector:@selector(hdCycleScrollView:didScrollToIndex:)]) {
        [self.delegate hdCycleScrollView:self didScrollToIndex:indexOnPageControl];
    } else if (self.itemDidScrollOperationBlock) {
        self.itemDidScrollOperationBlock(indexOnPageControl);
    }
}


/**
 *  自定义方法
 */
- (void)setRowMagrin:(CGFloat)rowMagrin {
    _rowMagrin = rowMagrin;
    _menuLayout.rowMagrin = rowMagrin;
}

- (void)setColMagrin:(CGFloat)colMagrin {
    _colMagrin = colMagrin;
    _menuLayout.colMagrin = colMagrin;
}

- (void)setColCount:(CGFloat)colCount {
    _colCount = colCount;
    _menuLayout.colCount = colCount;
}

- (void)setRowCount:(CGFloat)rowCount {
    _rowCount = rowCount;
    _menuLayout.rowCount = rowCount;
}

- (void)setPagingEnabled:(BOOL)pagingEnabled {
    _pagingEnabled = pagingEnabled;
    _mainView.pagingEnabled = pagingEnabled;
}

@end
