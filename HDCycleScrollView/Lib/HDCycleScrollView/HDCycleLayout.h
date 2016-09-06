//
//  HDCycleLayout.h
//  HDCycleScrollView
//
//  Created by Malong Guo on 26/08/2016.
//  Copyright © 2016 scat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HDCycleLayout : UICollectionViewLayout

// Item大小
@property (nonatomic, assign) CGSize itemSize;

// section四周边距
@property(nonatomic,assign)UIEdgeInsets sectionInset;

// Item四周边距
@property (nonatomic, assign) UIEdgeInsets contentInset;

// 每行间距
@property(nonatomic,assign)CGFloat rowMagrin;

// 每列间距
@property(nonatomic,assign)CGFloat colMagrin;

// 列数
@property(nonatomic,assign)CGFloat colCount;

// 行数
@property (nonatomic,assign) CGFloat rowCount;

// 滚动方向
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

/**
 *  是否开启轮播，默认为YES
 */
@property (nonatomic,assign) BOOL infiniteLoop;

@end
