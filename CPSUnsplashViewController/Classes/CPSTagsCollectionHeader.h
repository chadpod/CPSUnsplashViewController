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
//  CPSTagsCollectionHeader.h
//  unsplash-search
//
//  Created by Chad Podoski on 12/14/16.
//

#import <UIKit/UIKit.h>

@protocol UNTagsCollectionHeaderDelegate <NSObject>

- (void)tagsChanged:(NSString *)tags;

@end

@interface CPSTagsCollectionHeader : UICollectionReusableView

@property (nonatomic, weak) id <UNTagsCollectionHeaderDelegate> delegate;
@property (nonatomic) NSArray <NSString*> *tags;
@property (nonatomic) NSString *selectedTag;

+ (instancetype)newWithFont:(UIFont *)font normalTintColor:(UIColor *)normalTintColor selectedTintColor:(UIColor *)selectedTintColor;
    
- (void)scrollToTop;

@end
