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
//  UNSectionController.m
//  unsplash-search
//
//  Created by Chad Podoski on 11/5/16.
//

#import "CPSImageSectionController.h"
#import "CPSUnsplashViewController.h"
#import "CPSImageCell.h"
#import <CommonCrypto/CommonDigest.h>

@import Photos;

@interface CPSImageSectionController () <CPSImageCellDelegate, IGListWorkingRangeDelegate, IGListDisplayDelegate>

@property BOOL fullScreenMode;
@property id imageItemData;
@property NSMutableArray *imageItemTasks;

@end

@implementation CPSImageSectionController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inset = UIEdgeInsetsMake(2.f, 0.f, 0.f, 0.f);
        self.minimumLineSpacing = 2.f;
        self.minimumInteritemSpacing = 2.f;
        self.imageItemData = [NSNull null];
        self.imageItemTasks = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    for (NSURLSessionDataTask *task in self.imageItemTasks)
        [task cancel];
    
    [self.imageItemTasks removeAllObjects];
}

- (void)setImageItem:(NSDictionary *)imageItem
{
    _imageItem = imageItem;
    
    self.imageItemData = [NSNull null];
}

- (NSUInteger)numberOfImagesPerRow {
    return (self.fullScreenMode ? 1 : self.numberOfImagesPerSection);
}

- (NSInteger)numberOfItems {
    return 1;
}

- (CGSize)sizeForItemAtIndex:(NSInteger)index {
    CGFloat numberOfImagesPerRow = (CGFloat)[self numberOfImagesPerRow];
    CGFloat interItemSpace = (numberOfImagesPerRow - 1) * self.minimumInteritemSpacing;
    CGFloat width = floor((self.collectionContext.containerSize.width - interItemSpace)/numberOfImagesPerRow);
    CGFloat height = floor(width * (self.viewController.view.bounds.size.height/self.viewController.view.bounds.size.width));
    
    if (!CGSizeEqualToSize(self.searchViewController.cropAspectRatio, CGSizeZero))
        height = floor(width * (self.searchViewController.cropAspectRatio.height/self.searchViewController.cropAspectRatio.width));
    
    return  CGSizeMake(width, height);
}

- (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index {
    CPSImageCell *cell = [self.collectionContext dequeueReusableCellOfClass:[CPSImageCell class] forSectionController:self atIndex:index];
    cell.delegate = self;
    cell.tintColor = self.searchViewController.tintColor;
    cell.selected = [[self.imageItem objectForKey:@"id"] isEqual:self.searchViewController.selectedImageId];
    
    NSURL *url = [NSURL URLWithString:[self.imageItem valueForKeyPath:self.thumbnailKeyPath]];
    NSString *attribution = [self.imageItem valueForKeyPath:self.attributionTextKeyPath];
    
    [cell setAttributionText:attribution];
    
    id data = self.imageItemData;
    if (data != [NSNull null])
        [self setThumbImageData:data forCell:cell];
    else {
        NSURLSessionDataTask *thumbTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data && !error)
                [self setThumbImageData:data forCell:cell];
        }];
        
        cell.thumbTask = thumbTask;
        [self.imageItemTasks addObject:thumbTask];
        [thumbTask resume];
    }
    
    /* Since we want the full size if they save, we always fetch it layzily */
    url = [NSURL URLWithString:[self.imageItem valueForKeyPath:self.imageKeyPath]];
    NSURLSessionDataTask *fullTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error)
            [self setImageData:data forCell:cell];
    }];
    
    cell.fullTask = fullTask;
    [self.imageItemTasks addObject:fullTask];
    [fullTask resume];
    
    return cell;
}

- (void)setImageData:(NSData *)data forCell:(CPSImageCell *)cell
{
    if (cell.displayed) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            UIImage *image = [UIImage imageWithData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell setImage:image];
            });
        });
    }
}

- (void)setThumbImageData:(NSData *)data forCell:(CPSImageCell *)cell
{
    if (cell.displayed) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            UIImage *image = [UIImage imageWithData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell setThumbImage:image];
            });
        });
    }
}

- (void)didUpdateToObject:(id)object {
    
}

- (void)didSelectItemAtIndex:(NSInteger)index {
    CPSImageCell *cell = (CPSImageCell*)[self.collectionContext cellForItemAtIndex:index sectionController:self];
    
    NSDictionary *result = self.imageItem;
    NSString *imageId = [result objectForKey:@"id"];
    
    if ([self.searchViewController.selectedImageId isEqual:imageId]) {
        [self.collectionContext deselectItemAtIndex:index sectionController:self animated:YES];
        
        if ([self.searchViewController respondsToSelector:@selector(didSelectImage:imageId:)])
            [self.searchViewController didSelectImage:nil imageId:nil];
    }
    else {
        UIImage *image = [self wallpaperImageForCell:cell];
        
        if ([self.searchViewController respondsToSelector:@selector(didSelectImage:imageId:)])
            [self.searchViewController didSelectImage:image imageId:imageId];
    }
}

#pragma mark - CPSImageCellDelegate -
- (void)attributionTouchedForImageCell:(CPSImageCell *)cell {
    NSDictionary *imageItemDict = self.imageItem;
    NSString *attribution = [imageItemDict valueForKeyPath:self.attributionKeyPath];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://unsplash.com/%@", attribution]];
    
    if ([self.searchViewController respondsToSelector:@selector(didSelectImageAtributionURL:)])
        [self.searchViewController didSelectImageAtributionURL:url];
    else if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)doubleTapForImageCell:(CPSImageCell *)cell; {
    
}

- (void)longPressForImageCell:(CPSImageCell *)cell; {
    
}

- (UIImage *)wallpaperImageForCell:(CPSImageCell *)cell
{
    __block UIImage *croppedImage;
    
    void (^generateImage)(void) = ^void(void) {
        UIImage *image = cell.imageView.image;
        CGAffineTransform transform = cell.imageView.layer.affineTransform;
        
        CGRect originalFrame = AVMakeRectWithAspectRatioInsideRect([UIScreen mainScreen].bounds.size, CGRectMake(0.f, 0.f, image.size.width, image.size.height));
        if (!CGSizeEqualToSize(self.searchViewController.cropAspectRatio, CGSizeZero))
            originalFrame = AVMakeRectWithAspectRatioInsideRect(self.searchViewController.cropAspectRatio, CGRectMake(0.f, 0.f, image.size.width, image.size.height));
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(originalFrame.origin.x - (transform.tx * originalFrame.size.width/cell.bounds.size.width),
                                                                                       originalFrame.origin.y - (transform.ty * originalFrame.size.height/cell.bounds.size.height),
                                                                                       originalFrame.size.width,
                                                                                       originalFrame.size.height));
        croppedImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    };
    
    if ([NSThread isMainThread])
        generateImage();
    else
        dispatch_sync(dispatch_get_main_queue(), ^{
            generateImage();
        });
    
    return croppedImage;
}

+ (NSString *)MD5HexDigest:(NSData *)input
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(input.bytes, (CC_LONG)input.length, result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

#pragma mark - Working Range Delegate -
- (id <IGListWorkingRangeDelegate>)workingRangeDelegate
{
    return self;
}

- (void)listAdapter:(IGListAdapter *)listAdapter sectionControllerWillEnterWorkingRange:(IGListSectionController *)sectionController
{
    CPSImageSectionController *viewController = (CPSImageSectionController *)sectionController;
    NSDictionary *item = viewController.imageItem;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        NSURL *url = [NSURL URLWithString:[(NSDictionary *)item valueForKeyPath:self.thumbnailKeyPath]];
        NSURLSessionDataTask *thumbTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data && !error)
                self.imageItemData = data;
        }];
        
        [thumbTask resume];
        [self.imageItemTasks addObject:thumbTask];
    }
}


- (void)listAdapter:(IGListAdapter *)listAdapter sectionControllerDidExitWorkingRange:(IGListSectionController *)sectionController
{

}

#pragma mark - IGListDisplayDelegate -
- (id <IGListDisplayDelegate>)displayDelegate
{
    return self;
}

- (void)listAdapter:(IGListAdapter *)listAdapter willDisplaySectionController:(IGListSectionController *)sectionController;
{
    
}

- (void)listAdapter:(IGListAdapter *)listAdapter didEndDisplayingSectionController:(IGListSectionController *)sectionController;
{
    
}

- (void)listAdapter:(IGListAdapter *)listAdapter willDisplaySectionController:(IGListSectionController *)sectionController
               cell:(UICollectionViewCell *)cell
            atIndex:(NSInteger)index;
{
    CPSImageCell *imageCell = (CPSImageCell *)cell;
    imageCell.displayed = YES;
    imageCell.selected = [[self.imageItem objectForKey:@"id"] isEqual:self.searchViewController.selectedImageId];
}

- (void)listAdapter:(IGListAdapter *)listAdapter didEndDisplayingSectionController:(IGListSectionController *)sectionController
               cell:(UICollectionViewCell *)cell
            atIndex:(NSInteger)index;
{
    CPSImageCell *imageCell = (CPSImageCell *)cell;
    imageCell.displayed = NO;
}

@end
