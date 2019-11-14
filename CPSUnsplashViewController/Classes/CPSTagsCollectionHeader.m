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
//  CPSTagsCollectionHeader.m
//  unsplash-search
//
//  Created by Chad Podoski on 12/14/16.
//

#import "CPSTagsCollectionHeader.h"
#import "CPSTagsView.h"

@interface CPSTagsCollectionHeader () <CPSTagsViewDelegate>

@property (nonatomic) CPSTagsView *tagsView;

@end

@implementation CPSTagsCollectionHeader

+ (instancetype)newWithFont:(UIFont *)font normalTintColor:(UIColor *)normalTintColor selectedTintColor:(UIColor *)selectedTintColor {
    CPSTagsCollectionHeader *view = [[CPSTagsCollectionHeader alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    
    if (view) {
        CPSTagsView *tagsView = [CPSTagsView new];
        tagsView.translatesAutoresizingMaskIntoConstraints = NO;
        tagsView.delegate = view;
        tagsView.font = [font fontWithSize:12.f];
        tagsView.editable = NO;
        tagsView.selectable = YES;
        tagsView.allowsMultipleSelection = NO;
        tagsView.scrollsHorizontally = YES;
        tagsView.interitemSpacing = 10.f;
        tagsView.tagButtonHeight = 25.f;
        tagsView.normalTintColor = normalTintColor;
        tagsView.selectedTintColor = selectedTintColor;
        
        [view addSubview:tagsView];
        [view addConstraints:@[[NSLayoutConstraint constraintWithItem:tagsView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f],
                               [tagsView.leftAnchor constraintEqualToAnchor:view.leftAnchor],
                               [tagsView.rightAnchor constraintEqualToAnchor:view.rightAnchor],
                               [NSLayoutConstraint constraintWithItem:tagsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:25.f]]];
        
        view.tagsView = tagsView;
    }
    
    return view;
}

- (void)scrollToTop
{
    [self.tagsView.scrollView setContentOffset:CGPointZero animated:YES];
}

#pragma mark - Private
- (void)setTags:(NSArray<NSString *> *)tags
{
    _tags = tags;
    
    [self.tagsView removeAllTags];
    for (NSString *tag in tags) {
        [self.tagsView addTag:tag];
     
        if ([tag isEqual:self.selectedTag])
            [self.tagsView selectTagAtIndex:(self.tagsView.tags.count - 1)];
    }
}

#pragma mark - CPSTagsViewDelegate Methods
- (void)notifyDelegate
{
    if ([self.delegate respondsToSelector:@selector(tagsChanged:)]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray<NSNumber *> *indexes = [self.tagsView selectedTagIndexes];
            NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
            
            for (NSNumber *index in indexes)
                [indexSet addIndex:index.unsignedIntegerValue];

            [self.delegate tagsChanged:[[self.tags objectsAtIndexes:indexSet] componentsJoinedByString:@" "]];
        });
    }
}

- (BOOL)tagsView:(CPSTagsView *)tagsView shouldSelectTagAtIndex:(NSInteger)index;
{
    [self notifyDelegate];
    return YES;
}

- (BOOL)tagsView:(CPSTagsView *)tagsView shouldDeselectTagAtIndex:(NSInteger)index;
{
    [self notifyDelegate];
    return YES;
}

@end
