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
//  CPSUnsplashViewController.h
//  unsplash-search
//
//  Created by Chad Podoski on 11/5/16.
//

#import <UIKit/UIKit.h>
#import <IGListKit/IGListKit.h>
#import "CPSConfigurationItem.h"

@class CPSUnsplashViewController;

@protocol CPSUnsplashViewControllerDelegate <NSObject>

@optional

- (void)unsplashViewController:(CPSUnsplashViewController *)viewController didSelectImage:(UIImage *)image;
- (void)unsplashViewController:(CPSUnsplashViewController *)viewController didSelectImageAttributionURL:(NSURL *)url;

@end

@interface CPSUnsplashViewController : UIViewController <IGListAdapterDataSource>

@property (nonatomic, weak) id<CPSUnsplashViewControllerDelegate> delegate;
@property (nonatomic) NSArray <CPSConfigurationItem*> *configuration;
@property (nonatomic) UIFont *font;
@property (nonatomic) UIColor *tintColor;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) NSUInteger *imagesPerRow;
@property (nonatomic) CGSize cropAspectRatio;
@property (nonatomic) NSString *selectedImageId;

+ (instancetype)newWithClientId:(NSString *)clientId delegate:(id<CPSUnsplashViewControllerDelegate>)delegate;

@end

