//
//  CPSConfigurationItem.m
//
//  Created by Chad Podoski on 11/13/19.
//

#import "CPSConfigurationItem.h"

@implementation CPSConfigurationItem

+ (instancetype)newWithTitle:(NSString *)title
                  searchTerm:(NSString *)searchTerm
                 relatedTags:(NSArray <NSString*> *)relatedTags
                   configure:(nullable void (^)(CPSConfigurationItem *item))configureBlock;
{
    CPSConfigurationItem *item = [CPSConfigurationItem new];
    item.title = title;
    item.searchTerm = searchTerm;
    item.relatedTags = relatedTags;
    
    if (configureBlock)
        configureBlock(item);
    
    return item;
}

+ (NSString *)endpointForSearchTerm:(NSString *)searchTerm;
{
    return ([searchTerm containsString:@"/"] ? searchTerm : nil);
}

- (NSString *)endpoint
{
    return [CPSConfigurationItem endpointForSearchTerm:self.searchTerm];
}

@end
