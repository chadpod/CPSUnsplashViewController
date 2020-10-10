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
//  CPSImageCell.m
//  unsplash-search
//
//  Created by Chad Podoski on 11/5/16.
//

#import "CPSImageCell.h"

@interface CPSImageCell () <UIGestureRecognizerDelegate>

@property (nonatomic) UIButton *attributionButton;
@property (nonatomic, readwrite) UIImageView *imageView;
@property (nonatomic) UIActivityIndicatorView *activityView;
@property (nonatomic) NSShadow *textShadow;
@property (nonatomic) UIView *selectionView;

@property (nonatomic) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic) UILongPressGestureRecognizer *longPressGesture;

@end

@implementation CPSImageCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clipsToBounds = YES;
        
        _displayed = YES;
        
        _textShadow = [[NSShadow alloc] init];
        _textShadow.shadowBlurRadius = 0.5f;
        _textShadow.shadowOffset = CGSizeZero;
        
        _imageView = [UIImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = NO;
        _imageView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.f];
        [self addSubview:_imageView];
        
        _selectionView = [UIView new];
        _selectionView.contentMode = UIViewContentModeScaleAspectFill;
        _selectionView.clipsToBounds = NO;
        _selectionView.userInteractionEnabled = NO;
        [self addSubview:_selectionView];
        
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_activityView startAnimating];
        [self addSubview:_activityView];
        
        _attributionButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _attributionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _attributionButton.titleLabel.minimumScaleFactor = 0.2f;
        _attributionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _attributionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_attributionButton addTarget:self action:@selector(attributionTouched) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_attributionButton];
        
        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        _doubleTapGesture.numberOfTapsRequired = 2;
        [self addGestureRecognizer:_doubleTapGesture];
        
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:_longPressGesture];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
        [self addGestureRecognizer:_panGesture];
    }
    return self;
}

- (void)prepareForReuse {
    self.selected = NO;
    [self.thumbTask cancel];
    self.thumbTask = nil;
    [self.fullTask cancel];
    self.fullTask = nil;
    self.image = nil;
    self.imageView.image = nil;
    self.imageView.layer.affineTransform = CGAffineTransformIdentity;
    [self setAttributionText:nil];
    self.displayed = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    
    [_attributionButton sizeToFit];
    _attributionButton.frame = CGRectMake(10.f, bounds.size.height - 20.f, bounds.size.width - 20.f, _attributionButton.bounds.size.height);
    _activityView.center = CGPointMake(bounds.size.width/2.f, bounds.size.height/2.f);
    
    if (bounds.size.width != _imageView.bounds.size.width || bounds.size.height != _imageView.bounds.size.height) {
        _imageView.frame = bounds;
        _selectionView.frame = bounds;
    }
    
//    _attributionButton.hidden = (self.bounds.size.width != [UIScreen mainScreen].bounds.size.width);
//    NSString *attribution = [_attributionButton titleForState:UIControlStateNormal];
//    _attributionButton.hidden = (!attribution || [attribution length] == 0);
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    self.selectionView.layer.borderColor = self.tintColor.CGColor;
    self.selectionView.layer.borderWidth = (self.selected ? 3.f : 0.f);
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    
    if (image && image.size.width > self.bounds.size.width)
        [self.activityView stopAnimating];
    else
        [self.activityView startAnimating];
}

- (void)setThumbImage:(UIImage *)image;
{
    if (self.fullTask.state != NSURLSessionTaskStateCompleted && self.displayed)
        [self setImage:image];
}

- (void)setAttributionText:(NSString *)attribution {
    if (attribution != nil)
    {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:attribution
                                                                               attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10.f],
                                                                                            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid),
                                                                                            NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                            NSShadowAttributeName : _textShadow}];
        [_attributionButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    }
    else
        [_attributionButton setAttributedTitle:nil forState:UIControlStateNormal];
    
    [self setNeedsLayout];
}

- (void)attributionTouched {
    if (_delegate && [_delegate respondsToSelector:@selector(attributionTouchedForImageCell:)])
        [_delegate performSelector:@selector(attributionTouchedForImageCell:) withObject:self];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(doubleTapForImageCell:)])
            [_delegate performSelector:@selector(doubleTapForImageCell:) withObject:self];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(longPressForImageCell:)])
            [_delegate performSelector:@selector(longPressForImageCell:) withObject:self];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGSize sizeBeingScaledTo = CGSizeAspectFill(_imageView.image.size, _imageView.bounds.size);
        
        CGPoint translation = [recognizer translationInView:self];
        CGFloat maxOffset = (sizeBeingScaledTo.width - self.bounds.size.width)/2.f;
        
        CGAffineTransform transform = CGAffineTransformTranslate(_imageView.layer.affineTransform, translation.x, 0.f);
        
        if (transform.tx > -maxOffset && transform.tx < maxOffset)
            _imageView.layer.affineTransform = transform;
        
        [recognizer setTranslation:CGPointZero inView:self];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGesture)
    {
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self];
        return (fabs(translation.y) < 1.f); // && self.bounds.size.width == [UIScreen mainScreen].bounds.size.width);
    }
    
    return YES;
}

CGSize CGSizeAspectFit(const CGSize aspectRatio, const CGSize boundingSize)
{
    CGSize aspectFitSize = CGSizeMake(boundingSize.width, boundingSize.height);
    float mW = boundingSize.width / aspectRatio.width;
    float mH = boundingSize.height / aspectRatio.height;
    if( mH < mW )
        aspectFitSize.width = mH * aspectRatio.width;
    else if( mW < mH )
        aspectFitSize.height = mW * aspectRatio.height;
    return aspectFitSize;
}

CGSize CGSizeAspectFill(const CGSize aspectRatio, const CGSize minimumSize)
{
    CGSize aspectFillSize = CGSizeMake(minimumSize.width, minimumSize.height);
    float mW = minimumSize.width / aspectRatio.width;
    float mH = minimumSize.height / aspectRatio.height;
    if( mH > mW )
        aspectFillSize.width = mH * aspectRatio.width;
    else if( mW > mH )
        aspectFillSize.height = mW * aspectRatio.height;
    return aspectFillSize;
}

@end
