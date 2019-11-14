/*
 Copyright (c) 2016 Roman Kulesha <kulesha.r@gmail.com>
 
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

/* Based off RKTagsView, with a few small layout tweaks */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN const CGFloat CPSTagsViewAutomaticDimension; // use sizeToFit

typedef NS_ENUM(NSInteger, CPSTagsViewTextFieldAlign) { // align is relative to a last tag
    CPSTagsViewTextFieldAlignTop,
    CPSTagsViewTextFieldAlignCenter,
    CPSTagsViewTextFieldAlignBottom,
};

@class CPSTagsView;

@protocol CPSTagsViewDelegate <NSObject>

@optional

- (UIButton *)tagsView:(CPSTagsView *)tagsView buttonForTagAtIndex:(NSInteger)index; // used default tag button if not implemented
- (BOOL)tagsView:(CPSTagsView *)tagsView shouldAddTagWithText:(NSString *)text; // called when 'space' key pressed. return NO to ignore tag
- (BOOL)tagsView:(CPSTagsView *)tagsView shouldSelectTagAtIndex:(NSInteger)index; // called when tag pressed. return NO to disallow selecting tag
- (BOOL)tagsView:(CPSTagsView *)tagsView shouldDeselectTagAtIndex:(NSInteger)index; // called when selected tag pressed. return NO to disallow deselecting tag
- (BOOL)tagsView:(CPSTagsView *)tagsView shouldRemoveTagAtIndex:(NSInteger)index; // called when 'backspace' key pressed. return NO to disallow removing tag

- (void)tagsViewDidChange:(CPSTagsView *)tagsView; // called when tag was added or removed by user
- (void)tagsViewContentSizeDidChange:(CPSTagsView *)tagsView;

@end

IB_DESIGNABLE
@interface CPSTagsView: UIView

@property (nonatomic, strong, readonly) UIScrollView *scrollView; // scrollView delegate is not used
@property (nonatomic, strong, readonly) UITextField *textField; // textfield delegate is not used
@property (nonatomic, copy, readonly) NSArray<NSString *> *tags;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *selectedTagIndexes;
@property (nonatomic, weak, nullable) IBOutlet id<CPSTagsViewDelegate> delegate;
@property (nonatomic, readonly) CGSize contentSize;

@property (nonatomic, strong) UIFont *font; // default is font from textfield
@property (nonatomic) IBInspectable BOOL editable; // default is YES
@property (nonatomic) IBInspectable BOOL selectable; // default is YES
@property (nonatomic) IBInspectable BOOL allowsMultipleSelection; // default is YES
@property (nonatomic) IBInspectable BOOL selectBeforeRemoveOnDeleteBackward; // default is YES
@property (nonatomic) IBInspectable BOOL deselectAllOnEdit; // default is YES
@property (nonatomic) IBInspectable BOOL deselectAllOnEndEditing; // default is YES
@property (nonatomic) IBInspectable BOOL scrollsHorizontally; // default is NO

@property (nonatomic) IBInspectable CGFloat lineSpacing; // default is 2
@property (nonatomic) IBInspectable CGFloat interitemSpacing; // default is 2
@property (nonatomic) IBInspectable CGFloat tagButtonHeight; // default is auto
@property (nonatomic) IBInspectable CGFloat textFieldHeight; // default is auto
@property (nonatomic) CPSTagsViewTextFieldAlign textFieldAlign; // default is center

@property (nonatomic) IBInspectable UIColor *normalTintColor; // default is auto
@property (nonatomic) IBInspectable UIColor *selectedTintColor; // default is auto

@property (nonatomic, strong) NSCharacterSet* deliminater; // defailt is [NSCharacterSet whitespaceCharacterSet]

- (NSInteger)indexForTagAtScrollViewPoint:(CGPoint)point; // NSNotFound if not found
- (nullable __kindof UIButton *)buttonForTagAtIndex:(NSInteger)index;
- (void)reloadButtons;

- (void)addTag:(NSString *)tag;
- (void)insertTag:(NSString *)tag atIndex:(NSInteger)index;
- (void)moveTagAtIndex:(NSInteger)index toIndex:(NSInteger)newIndex; // can be animated
- (void)removeTagAtIndex:(NSInteger)index;
- (void)removeAllTags;

- (void)selectTagAtIndex:(NSInteger)index;
- (void)deselectTagAtIndex:(NSInteger)index;
- (void)selectAll;
- (void)deselectAll;

@end

NS_ASSUME_NONNULL_END
