//
//  HDCycleLayout.m
//  HDCycleScrollView
//
//  Created by Malong Guo on 26/08/2016.
//  Copyright © 2016 scat. All rights reserved.
//

#define kMainScreenWidth     [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight     [UIScreen mainScreen].bounds.size.height

#import "HDCycleLayout.h"


@interface HDCycleLayout() {
}

// 布局信息数组
@property (nonatomic, strong) NSArray *layoutInfoArr;

// 内容尺寸
@property (nonatomic, assign) CGSize contentSize;

@end

@implementation HDCycleLayout

- (void)prepareLayout{
    [super prepareLayout];
    NSMutableArray *layoutInfoArr = [NSMutableArray array];
    NSInteger maxNumberOfItems = 0;
    //获取布局信息
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < numberOfSections; section++){
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        NSMutableArray *subArr = [NSMutableArray arrayWithCapacity:numberOfItems];
        for (NSInteger item = 0; item < numberOfItems; item++){
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            [subArr addObject:attributes];
        }
        if(maxNumberOfItems < numberOfItems){
            maxNumberOfItems = numberOfItems;
        }
        //添加到二维数组
        [layoutInfoArr addObject:[subArr copy]];
    }
    //存储布局信息
    self.layoutInfoArr = [layoutInfoArr copy];
    //保存内容尺寸
    
    NSLog(@"debug %f", kMainScreenWidth);
    
    int screenTotalItem =  [[NSString stringWithFormat:@"%f", self.colCount * self.rowCount] intValue];
    int screenCount = 0;
    float recommendScreenCount = 0;
    NSLog(@"%ld,%d", (long)maxNumberOfItems, screenTotalItem);
    if (maxNumberOfItems % screenTotalItem == 0) {
        screenCount = maxNumberOfItems/(self.rowCount*self.colCount);
    }else {
        NSLog(@"%@,%f", self.infiniteLoop?@"YES":@"NO", self.rowCount);
        if (!self.infiniteLoop && self.rowCount == 1) {
            recommendScreenCount = (CGFloat)maxNumberOfItems/(self.rowCount*self.colCount);
        }else {
            screenCount = maxNumberOfItems/(self.rowCount*self.colCount) +1;
        }
    }
    
    CGFloat sizeWidth;
    if (recommendScreenCount > 0) {
        sizeWidth = (kMainScreenWidth)*(recommendScreenCount);
        sizeWidth += self.colMagrin;
    } else {
        sizeWidth = (kMainScreenWidth)*(screenCount);
    }
    CGFloat sizeHeight = (self.rowMagrin + self.itemSize.height) * self.rowCount + self.rowMagrin;
    NSLog(@"=============%f, %f", sizeWidth, sizeHeight);
    self.contentSize = CGSizeMake(sizeWidth * numberOfSections, sizeHeight);
}


- (CGSize)collectionViewContentSize{
    return self.contentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    NSMutableArray *layoutAttributesArr = [NSMutableArray array];
    [self.layoutInfoArr enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger i, BOOL * _Nonnull stop) {
        [array enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(CGRectIntersectsRect(obj.frame, rect)) {
                [layoutAttributesArr addObject:obj];
            }
        }];
    }];
    return layoutAttributesArr;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    //每一组cell为一行
    
    int colCountInt = [[NSString stringWithFormat:@"%f", self.colCount] intValue];
    int rowCountInt = [[NSString stringWithFormat:@"%f", self.rowCount] intValue];
    
    
    int firstItem = indexPath.row % colCountInt ;
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:indexPath.section];
    NSInteger rowTotalIndex = ceil( (indexPath.section + 1)*numberOfItems/colCountInt );
    
    NSLog(@"%ld", (long)rowTotalIndex);
    
    long firstLine =   ceil(indexPath.row / colCountInt);
    long firstScreen = firstLine / rowCountInt;
    long lineIndex = firstLine % rowCountInt;
    
    NSInteger screenCountInSection = ceil(numberOfItems/(self.colCount*self.rowCount));
    firstScreen = firstScreen + screenCountInSection * indexPath.section;
    
    NSLog(@"第%ld个，第%ld屏, 第%ld行，第%d列", (long)indexPath.row, firstScreen, lineIndex, firstItem);
    
    
    CGFloat frameX = self.colMagrin + (self.itemSize.width + self.colMagrin) * firstItem + kMainScreenWidth * firstScreen;
    CGFloat frameY = self.rowMagrin + (self.rowMagrin + self.itemSize.height) * lineIndex;
    
    CGFloat frameW = self.itemSize.width;
    CGFloat frameH = self.itemSize.height;
    
    attributes.frame = CGRectMake(frameX, frameY, frameW, frameH);
    
    NSLog(@"HDMenuLayout Frame: %@", NSStringFromCGRect(attributes.frame));
    //    attributes.frame = CGRectMake(self.contentInset.left + (self.itemSize.width + self.colMagrin) * indexPath.row + self.colMagrin, self.contentInset.top + (self.itemSize.height + self.rowMagrin) * indexPath.section + self.rowMagrin, self.itemSize.width, self.itemSize.height);
    return attributes;
}

#pragma mark - set method
- (void)setItemSize:(CGSize)itemSize{
    _itemSize = itemSize;
    [self invalidateLayout];
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing{
    _colMagrin = interitemSpacing;
    [self invalidateLayout];
}

- (void)setLineSpacing:(CGFloat)lineSpacing{
    _rowMagrin = lineSpacing;
    [self invalidateLayout];
}

@end
