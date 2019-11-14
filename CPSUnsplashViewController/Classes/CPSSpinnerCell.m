/*
 Copyright (c) 2016 Chad Podoski <chadpod@me.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

//
//  CPSSpinnerCell.m
//  unsplash-search
//
//  Created by Chad Podoski on 11/7/16.
//

#import "CPSSpinnerCell.h"

@interface CPSSpinnerCell ()

@property (nonatomic) UIActivityIndicatorView *activityView;

@end

@implementation CPSSpinnerCell

+ (IGListSingleSectionController *)spinnerSectionController {
    return [[IGListSingleSectionController alloc] initWithCellClass:[CPSSpinnerCell class]
                                                     configureBlock:^(id  _Nonnull item, __kindof UICollectionViewCell * _Nonnull cell) {
                                                         if (cell && [cell isKindOfClass:[CPSSpinnerCell class]])
                                                             [[(CPSSpinnerCell *)cell activityView] startAnimating];
                                                     } sizeBlock:^CGSize(id  _Nonnull item, id<IGListCollectionContext>  _Nullable collectionContext) {
                                                         return (collectionContext ?
                                                                 CGSizeMake(collectionContext.containerSize.width, 100.f) :
                                                                 CGSizeZero);
                                                     }];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {        
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:_activityView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;
    _activityView.center = CGPointMake(bounds.size.width/2.f, bounds.size.height/2.f);
}

@end
