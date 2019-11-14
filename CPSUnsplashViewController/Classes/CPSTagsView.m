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

#import "CPSTagsView.h"

#define DEFAULT_BUTTON_TAG -9999
#define DEFAULT_BUTTON_HORIZONTAL_PADDING 6
#define DEFAULT_BUTTON_VERTICAL_PADDING 2
#define DEFAULT_BUTTON_CORNER_RADIUS 6
#define DEFAULT_BUTTON_BORDER_WIDTH 1

const CGFloat CPSTagsViewAutomaticDimension = -0.0001;

@interface __UNInputTextField: UITextField
@property (nonatomic, weak) CPSTagsView *tagsView;
@end

@interface CPSTagsView()
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableTags;
@property (nonatomic, strong) NSMutableArray<UIButton *> *mutableTagButtons;
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;
@property (nonatomic, strong) __UNInputTextField *inputTextField;
@property (nonatomic, strong) UIButton *becomeFirstResponderButton;
@property (nonatomic) BOOL needScrollToBottomAfterLayout;
- (BOOL)shouldInputTextDeleteBackward;
@end

#pragma mark - UNInputTextField

@implementation __UNInputTextField
- (void)deleteBackward {
    if ([self.tagsView shouldInputTextDeleteBackward]) {
        [super deleteBackward];
    }
}
@end

#pragma mark - CPSTagsView

@implementation CPSTagsView

#pragma mark Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup {
    self.mutableTags = [NSMutableArray new];
    self.mutableTagButtons = [NSMutableArray new];
    //
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.backgroundColor = nil;
    [self addSubview:self.scrollView];
    //
    self.inputTextField = [__UNInputTextField new];
    self.inputTextField.tagsView = self;
    self.inputTextField.tintColor = self.tintColor;
    self.inputTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.inputTextField addTarget:self action:@selector(inputTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
    [self.inputTextField addTarget:self action:@selector(inputTextFieldEditingDidBegin) forControlEvents:UIControlEventEditingDidBegin];
    [self.inputTextField addTarget:self action:@selector(inputTextFieldEditingDidEnd) forControlEvents:UIControlEventEditingDidEnd];
    [self.scrollView addSubview:self.inputTextField];
    //
    self.becomeFirstResponderButton = [[UIButton alloc] initWithFrame:self.bounds];
    self.becomeFirstResponderButton.backgroundColor = nil;
    [self.becomeFirstResponderButton addTarget:self.inputTextField action:@selector(becomeFirstResponder) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.becomeFirstResponderButton];
    //
    _editable = YES;
    _selectable = YES;
    _allowsMultipleSelection = YES;
    _selectBeforeRemoveOnDeleteBackward = YES;
    _deselectAllOnEdit = YES;
    _deselectAllOnEndEditing = YES;
    _lineSpacing = 2;
    _interitemSpacing = 2;
    _tagButtonHeight = CPSTagsViewAutomaticDimension;
    _textFieldHeight = CPSTagsViewAutomaticDimension;
    _textFieldAlign = CPSTagsViewTextFieldAlignCenter;
    _deliminater = [NSCharacterSet whitespaceCharacterSet];
    _scrollsHorizontally = NO;
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat contentWidth = self.bounds.size.width - self.scrollView.contentInset.left - self.scrollView.contentInset.right;
    CGRect lowerFrame = CGRectZero;
    // layout tags buttons
    CGRect previousButtonFrame = CGRectMake(0.f, 0.f, self.interitemSpacing, 0.f);
    for (UIButton *button in self.mutableTagButtons) {
        CGRect buttonFrame = [self originalFrameForView:button];
        
        if (_scrollsHorizontally || (CGRectGetMaxX(previousButtonFrame) + self.interitemSpacing + buttonFrame.size.width <= contentWidth)) {
            buttonFrame.origin.x = CGRectGetMaxX(previousButtonFrame);
            if (buttonFrame.origin.x > 0) {
                buttonFrame.origin.x += self.interitemSpacing;
            }
            buttonFrame.origin.y = CGRectGetMinY(previousButtonFrame);
            if (_scrollsHorizontally && CGRectGetMaxX(buttonFrame) > self.bounds.size.width) {
                contentWidth = CGRectGetMaxX(buttonFrame) + self.interitemSpacing;
            }
        } else {
            buttonFrame.origin.x = 0;
            buttonFrame.origin.y = MAX(CGRectGetMaxY(lowerFrame), CGRectGetMaxY(previousButtonFrame));
            if (buttonFrame.origin.y > 0) {
                buttonFrame.origin.y += self.lineSpacing;
            }
            if (buttonFrame.size.width > contentWidth) {
                buttonFrame.size.width = contentWidth;
            }
        }
        if (self.tagButtonHeight > CPSTagsViewAutomaticDimension) {
            buttonFrame.size.height = self.tagButtonHeight;
        }
        [self setOriginalFrame:buttonFrame forView:button];
        previousButtonFrame = buttonFrame;
        if (CGRectGetMaxY(lowerFrame) < CGRectGetMaxY(buttonFrame)) {
            lowerFrame = buttonFrame;
        }
    }
    // layout textfield if needed
    if (self.editable) {
        [self.inputTextField sizeToFit];
        CGRect textfieldFrame = [self originalFrameForView:self.inputTextField];
        if (self.textFieldHeight > CPSTagsViewAutomaticDimension) {
            textfieldFrame.size.height = self.textFieldHeight;
        }
        if (self.mutableTagButtons.count == 0) {
            textfieldFrame.origin.x = 0;
            textfieldFrame.origin.y = 0;
            textfieldFrame.size.width = contentWidth;
            lowerFrame = textfieldFrame;
        } else if (_scrollsHorizontally || (CGRectGetMaxX(previousButtonFrame) + self.interitemSpacing + textfieldFrame.size.width <= contentWidth)) {
            textfieldFrame.origin.x = self.interitemSpacing + CGRectGetMaxX(previousButtonFrame);
            switch (self.textFieldAlign) {
                case CPSTagsViewTextFieldAlignTop:
                    textfieldFrame.origin.y = CGRectGetMinY(previousButtonFrame);
                    break;
                case CPSTagsViewTextFieldAlignCenter:
                    textfieldFrame.origin.y = CGRectGetMinY(previousButtonFrame) + (previousButtonFrame.size.height - textfieldFrame.size.height) / 2;
                    break;
                case CPSTagsViewTextFieldAlignBottom:
                    textfieldFrame.origin.y = CGRectGetMinY(previousButtonFrame) + (previousButtonFrame.size.height - textfieldFrame.size.height);
            }
            if (_scrollsHorizontally) {
                textfieldFrame.size.width = self.inputTextField.bounds.size.width;
                if (CGRectGetMaxX(textfieldFrame) > self.bounds.size.width) {
                    contentWidth += textfieldFrame.size.width;
                }
            } else {
                textfieldFrame.size.width = contentWidth - textfieldFrame.origin.x;
            }
            if (CGRectGetMaxY(lowerFrame) < CGRectGetMaxY(textfieldFrame)) {
                lowerFrame = textfieldFrame;
            }
        } else {
            textfieldFrame.origin.x = 0;
            switch (self.textFieldAlign) {
                case CPSTagsViewTextFieldAlignTop:
                    textfieldFrame.origin.y = CGRectGetMaxY(previousButtonFrame) + self.lineSpacing;
                    break;
                case CPSTagsViewTextFieldAlignCenter:
                    textfieldFrame.origin.y = CGRectGetMaxY(previousButtonFrame) + self.lineSpacing + (previousButtonFrame.size.height - textfieldFrame.size.height) / 2;
                    break;
                case CPSTagsViewTextFieldAlignBottom:
                    textfieldFrame.origin.y = CGRectGetMaxY(previousButtonFrame) + self.lineSpacing + (previousButtonFrame.size.height - textfieldFrame.size.height);
            }
            textfieldFrame.size.width = contentWidth;
            CGRect nextButtonFrame = CGRectMake(0, CGRectGetMaxY(previousButtonFrame) + self.lineSpacing, 0, previousButtonFrame.size.height);
            lowerFrame = (CGRectGetMaxY(textfieldFrame) < CGRectGetMaxY(nextButtonFrame)) ?  nextButtonFrame : textfieldFrame;
        }
        [self setOriginalFrame:textfieldFrame forView:self.inputTextField];
    }
    // set content size
    CGSize oldContentSize = self.contentSize;
    self.scrollView.contentSize = CGSizeMake(contentWidth, CGRectGetMaxY(lowerFrame));
    if ((_scrollsHorizontally && contentWidth > self.bounds.size.width) || (!_scrollsHorizontally && oldContentSize.height != self.contentSize.height)) {
        [self invalidateIntrinsicContentSize];
        if ([self.delegate respondsToSelector:@selector(tagsViewContentSizeDidChange:)]) {
            [self.delegate tagsViewContentSizeDidChange:self];
        }
    }
    // layout becomeFirstResponder button
    self.becomeFirstResponderButton.frame = CGRectMake(-self.scrollView.contentInset.left, -self.scrollView.contentInset.top, self.contentSize.width, self.contentSize.height);
    [self.scrollView bringSubviewToFront:self.becomeFirstResponderButton];
}

- (CGSize)intrinsicContentSize {
    return self.contentSize;
}

#pragma mark Property Accessors

- (UITextField *)textField {
    return self.inputTextField;
}

- (NSArray<NSString *> *)tags {
    return self.mutableTags.copy;
}

- (NSArray<NSNumber *> *)selectedTagIndexes {
    NSMutableArray *mutableIndexes = [NSMutableArray new];
    for (int index = 0; index < self.mutableTagButtons.count; index++) {
        if (self.mutableTagButtons[index].selected) {
            [mutableIndexes addObject:@(index)];
        }
    }
    return mutableIndexes.copy;
}

- (void)setFont:(UIFont *)font {
    if (self.inputTextField.font == font) {
        return;
    }
    self.inputTextField.font = font;
    for (UIButton *button in self.mutableTagButtons) {
        if (button.tag == DEFAULT_BUTTON_TAG) {
            button.titleLabel.font = font;
            [button sizeToFit];
            button.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y, button.frame.size.width + 5.f, button.frame.size.height);
            [self setNeedsLayout];
        }
    }
}

- (UIFont *)font {
    return self.inputTextField.font;
}

- (CGSize)contentSize {
    return CGSizeMake(_scrollsHorizontally ? (self.scrollView.contentSize.width + self.scrollView.contentInset.left + self.scrollView.contentInset.right) : self.bounds.size.width, self.scrollView.contentSize.height + self.scrollView.contentInset.top + self.scrollView.contentInset.bottom);
}

- (void)setEditable:(BOOL)editable {
    if (_editable == editable) {
        return;
    }
    _editable = editable;
    if (editable) {
        self.inputTextField.hidden = NO;
        self.becomeFirstResponderButton.hidden = self.inputTextField.isFirstResponder;
    } else {
        [self endEditing:YES];
        self.inputTextField.text = @"";
        self.inputTextField.hidden = YES;
        self.becomeFirstResponderButton.hidden = YES;
    }
    [self setNeedsLayout];
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    if (_lineSpacing != lineSpacing) {
        _lineSpacing = lineSpacing;
        [self setNeedsLayout];
    }
}

- (void)setScrollsHorizontally:(BOOL)scrollsHorizontally {
    if (_scrollsHorizontally != scrollsHorizontally) {
        _scrollsHorizontally = scrollsHorizontally;
        [self setNeedsLayout];
    }
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing {
    if (_interitemSpacing != interitemSpacing) {
        _interitemSpacing = interitemSpacing;
        [self setNeedsLayout];
    }
}

- (void)setTagButtonHeight:(CGFloat)tagButtonHeight {
    if (_tagButtonHeight != tagButtonHeight) {
        _tagButtonHeight = tagButtonHeight;
        [self setNeedsLayout];
    }
}

- (void)setTextFieldHeight:(CGFloat)textFieldHeight {
    if (_textFieldHeight != textFieldHeight) {
        _textFieldHeight = textFieldHeight;
        [self setNeedsLayout];
    }
}

- (void)setTextFieldAlign:(CPSTagsViewTextFieldAlign)textFieldAlign {
    if (_textFieldAlign != textFieldAlign) {
        _textFieldAlign = textFieldAlign;
        [self setNeedsLayout];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    if (super.tintColor == tintColor) {
        return;
    }
    super.tintColor = tintColor;
    self.inputTextField.tintColor = tintColor;
    for (UIButton *button in self.mutableTagButtons) {
        if (button.tag == DEFAULT_BUTTON_TAG) {
            button.tintColor = tintColor;
            button.layer.borderColor = tintColor.CGColor;
            button.backgroundColor = button.selected ? tintColor : nil;
            [button setTitleColor:tintColor forState:UIControlStateNormal];
        }
    }
}

#pragma mark Public

- (NSInteger)indexForTagAtScrollViewPoint:(CGPoint)point {
    for (int index = 0; index < self.mutableTagButtons.count; index++) {
        if (CGRectContainsPoint(self.mutableTagButtons[index].frame, point)) {
            return index;
        }
    }
    return NSNotFound;
}

- (nullable __kindof UIButton *)buttonForTagAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.mutableTagButtons.count) {
        return self.mutableTagButtons[index];
    } else {
        return nil;
    }
}

- (void)reloadButtons {
    NSArray *tags = self.tags;
    [self removeAllTags];
    for (NSString *tag in tags) {
        [self addTag:tag];
    }
}

- (void)addTag:(NSString *)tag {
    [self insertTag:tag atIndex:self.mutableTags.count];
}

- (void)insertTag:(NSString *)tag atIndex:(NSInteger)index {
    if (index >= 0 && index <= self.mutableTags.count) {
        [self.mutableTags insertObject:tag atIndex:index];
        UIButton *tagButton;
        if ([self.delegate respondsToSelector:@selector(tagsView:buttonForTagAtIndex:)]) {
            tagButton = [self.delegate tagsView:self buttonForTagAtIndex:index];
        } else {
            tagButton = [UIButton new];
            tagButton.layer.cornerRadius = DEFAULT_BUTTON_CORNER_RADIUS;
            tagButton.layer.borderWidth = DEFAULT_BUTTON_BORDER_WIDTH;
            tagButton.layer.borderColor = self.normalTintColor.CGColor;
            tagButton.titleLabel.font = self.font;
            tagButton.tintColor = self.tintColor;
            tagButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            [tagButton setTitle:tag forState:UIControlStateNormal];
            [tagButton setTitleColor:self.normalTintColor forState:UIControlStateNormal];
            [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            tagButton.contentEdgeInsets = UIEdgeInsetsMake(DEFAULT_BUTTON_VERTICAL_PADDING, DEFAULT_BUTTON_HORIZONTAL_PADDING, DEFAULT_BUTTON_VERTICAL_PADDING, DEFAULT_BUTTON_HORIZONTAL_PADDING);
            tagButton.tag = DEFAULT_BUTTON_TAG;
        }
        [tagButton sizeToFit];
        tagButton.frame = CGRectMake(tagButton.frame.origin.x, tagButton.frame.origin.y, tagButton.frame.size.width + 5.f, tagButton.frame.size.height);
        tagButton.exclusiveTouch = YES;
        [tagButton addTarget:self action:@selector(tagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.mutableTagButtons insertObject:tagButton atIndex:index];
        [self.scrollView addSubview:tagButton];
        [self setNeedsLayout];
    }
}

- (void)moveTagAtIndex:(NSInteger)index toIndex:(NSInteger)newIndex {
    if (index >= 0 && index <= self.mutableTags.count
        && newIndex >= 0 && newIndex <= self.mutableTags.count
        && index != newIndex) {
        NSString *tag = self.mutableTags[index];
        UIButton *button = self.mutableTagButtons[index];
        [self.mutableTags removeObjectAtIndex:index];
        [self.mutableTagButtons removeObjectAtIndex:index];
        [self.mutableTags insertObject:tag atIndex:newIndex];
        [self.mutableTagButtons insertObject:button atIndex:newIndex];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)removeTagAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.mutableTags.count) {
        [self.mutableTags removeObjectAtIndex:index];
        [self.mutableTagButtons[index] removeFromSuperview];
        [self.mutableTagButtons removeObjectAtIndex:index];
        [self setNeedsLayout];
    }
}

- (void)removeAllTags {
    [self.mutableTags removeAllObjects];
    [self.mutableTagButtons makeObjectsPerformSelector:@selector(removeFromSuperview) withObject:nil];
    [self.mutableTagButtons removeAllObjects];
    [self setNeedsLayout];
}

- (void)selectTagAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.mutableTagButtons.count) {
        if (!self.allowsMultipleSelection) {
            [self deselectAll];
        }
        self.mutableTagButtons[index].selected = YES;
        if (self.mutableTagButtons[index].tag == DEFAULT_BUTTON_TAG) {
            self.mutableTagButtons[index].backgroundColor = self.selectedTintColor;
            self.mutableTagButtons[index].layer.borderColor = self.selectedTintColor.CGColor;
        }
    }
}

- (void)deselectTagAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.mutableTagButtons.count) {
        self.mutableTagButtons[index].selected = NO;
        if (self.mutableTagButtons[index].tag == DEFAULT_BUTTON_TAG) {
            self.mutableTagButtons[index].backgroundColor = nil;
            self.mutableTagButtons[index].layer.borderColor = self.normalTintColor.CGColor;
        }
    }
}

- (void)selectAll {
    for (int index = 0; index < self.mutableTagButtons.count; index++) {
        [self selectTagAtIndex:index];
    }
}

- (void)deselectAll {
    for (int index = 0; index < self.mutableTagButtons.count; index++) {
        [self deselectTagAtIndex:index];
    }
}

#pragma mark Handlers

- (void)inputTextFieldChanged {
    if (self.deselectAllOnEdit) {
        [self deselectAll];
    }
    NSMutableArray *tags = [[(self.inputTextField.text ?: @"") componentsSeparatedByCharactersInSet:self.deliminater] mutableCopy];
    if (![_inputTextField.text isEqualToString:tags.lastObject]) // Fix for Korean language - https://github.com/kuler90/CPSTagsView/pull/19
        self.inputTextField.text = [tags lastObject];
    [tags removeLastObject];
    for (NSString *tag in tags) {
        if ([tag isEqualToString:@""] || ([self.delegate respondsToSelector:@selector(tagsView:shouldAddTagWithText:)] && ![self.delegate tagsView:self shouldAddTagWithText:tag])) {
            continue;
        }
        [self addTag:tag];
        if ([self.delegate respondsToSelector:@selector(tagsViewDidChange:)]) {
            [self.delegate tagsViewDidChange:self];
        }
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // scroll if needed
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.scrollsHorizontally) {
            if (self.scrollView.contentSize.width > self.bounds.size.width) {
                CGPoint leftOffset = CGPointMake(self.scrollView.contentSize.width - self.bounds.size.width, -self.scrollView.contentInset.top);
                [self.scrollView setContentOffset:leftOffset animated:YES];
            }
        } else {
            if (self.scrollView.contentInset.top + self.scrollView.contentSize.height > self.bounds.size.height) {
                CGPoint bottomOffset = CGPointMake(-self.scrollView.contentInset.left, self.scrollView.contentSize.height - self.bounds.size.height - (-self.scrollView.contentInset.top));
                [self.scrollView setContentOffset:bottomOffset animated:YES];
            }
        }
    });
}

- (void)inputTextFieldEditingDidBegin {
    self.becomeFirstResponderButton.hidden = YES;
}

- (void)inputTextFieldEditingDidEnd {
    if (self.inputTextField.text.length > 0) {
        self.inputTextField.text = [NSString stringWithFormat:@"%@ ", self.inputTextField.text];
        [self inputTextFieldChanged];
    }
    if (self.deselectAllOnEndEditing) {
        [self deselectAll];
    }
    self.becomeFirstResponderButton.hidden = !self.editable;
}

- (BOOL)shouldInputTextDeleteBackward {
    NSArray<NSNumber *> *tagIndexes = self.selectedTagIndexes;
    if (tagIndexes.count > 0) {
        for (NSInteger i = tagIndexes.count - 1; i >= 0; i--) {
            if ([self.delegate respondsToSelector:@selector(tagsView:shouldRemoveTagAtIndex:)] && ![self.delegate tagsView:self shouldRemoveTagAtIndex:tagIndexes[i].integerValue]) {
                continue;
            }
            [self removeTagAtIndex:tagIndexes[i].integerValue];
            if ([self.delegate respondsToSelector:@selector(tagsViewDidChange:)]) {
                [self.delegate tagsViewDidChange:self];
            }
        }
        return NO;
    } else if ([self.inputTextField.text isEqualToString:@""] && self.mutableTags.count > 0) {
        NSInteger lastTagIndex = self.mutableTags.count - 1;
        if (self.selectBeforeRemoveOnDeleteBackward) {
            if ([self.delegate respondsToSelector:@selector(tagsView:shouldSelectTagAtIndex:)] && ![self.delegate tagsView:self shouldSelectTagAtIndex:lastTagIndex]) {
                return NO;
            } else {
                [self selectTagAtIndex:lastTagIndex];
                return NO;
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(tagsView:shouldRemoveTagAtIndex:)] && ![self.delegate tagsView:self shouldRemoveTagAtIndex:lastTagIndex]) {
                return NO;
            } else {
                [self removeTagAtIndex:lastTagIndex];
                if ([self.delegate respondsToSelector:@selector(tagsViewDidChange:)]) {
                    [self.delegate tagsViewDidChange:self];
                }
                return NO;
            }
        }
        
    }
    else {
        return YES;
    }
}

- (void)tagButtonTapped:(UIButton *)button {
    if (self.selectable) {
        int buttonIndex = (int)[self.mutableTagButtons indexOfObject:button];
        if (button.selected) {
            if ([self.delegate respondsToSelector:@selector(tagsView:shouldDeselectTagAtIndex:)] && ![self.delegate tagsView:self shouldDeselectTagAtIndex:buttonIndex]) {
                return;
            }
            [self deselectTagAtIndex:buttonIndex];
        } else {
            if ([self.delegate respondsToSelector:@selector(tagsView:shouldSelectTagAtIndex:)] && ![self.delegate tagsView:self shouldSelectTagAtIndex:buttonIndex]) {
                return;
            }
            [self selectTagAtIndex:buttonIndex];
        }
    }
}

#pragma mark Internal Helpers

- (CGRect)originalFrameForView:(UIView *)view {
    if (CGAffineTransformIsIdentity(view.transform)) {
        return view.frame;
    } else {
        CGAffineTransform currentTransform = view.transform;
        view.transform = CGAffineTransformIdentity;
        CGRect originalFrame = view.frame;
        view.transform = currentTransform;
        return originalFrame;
    }
}

- (void)setOriginalFrame:(CGRect)originalFrame forView:(UIView *)view {
    if (CGAffineTransformIsIdentity(view.transform)) {
        view.frame = originalFrame;
    } else {
        CGAffineTransform currentTransform = view.transform;
        view.transform = CGAffineTransformIdentity;
        view.frame = originalFrame;
        view.transform = currentTransform;
    }
    
}

@end
