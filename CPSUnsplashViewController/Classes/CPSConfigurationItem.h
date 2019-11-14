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
//  CPSConfigurationItem.h
//
//  Created by Chad Podoski on 11/13/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPSConfigurationItem : NSObject

@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL hideFromTagCloud;
@property (nonatomic, readonly) NSString *endpoint;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *searchTerm;
@property (nonatomic) NSArray <NSString*> *relatedTags;
@property (nonatomic) NSString *selectedTag;

+ (instancetype)newWithTitle:(NSString *)title
                  searchTerm:(NSString *)searchTerm
                 relatedTags:(nullable NSArray <NSString*> *)relatedTags
                   configure:(nullable void (^)(CPSConfigurationItem *item))configureBlock;

+ (NSString *)endpointForSearchTerm:(NSString *)searchTerm;

@end

NS_ASSUME_NONNULL_END
