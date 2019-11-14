//
//  CPSViewController.m
//  CPSUnsplashViewController
//
//  Created by Chad Podoski on 11/13/2019.
//  Copyright (c) 2019 Chad Podoski. All rights reserved.
//

#import "CPSViewController.h"
#import "CPSUnsplashViewController.h"

@interface CPSViewController () <CPSUnsplashViewControllerDelegate>

@end

@implementation CPSViewController

- (IBAction)presentUnsplashSearch
{
    CPSUnsplashViewController *unsplashViewController = [CPSUnsplashViewController newWithClientId:_YOUR_UNSPLASH_ACCESS_KEY_ delegate:self];
    unsplashViewController.backgroundColor = [UIColor whiteColor];
    unsplashViewController.cropAspectRatio = CGSizeMake(320.f, 568.f);
    
    NSMutableArray *unsplashConfiguration = [self defaultConfiguration];
    [unsplashConfiguration insertObject:[CPSConfigurationItem newWithTitle:@"Phone Wallpapers"
                                                                searchTerm:@"collections/343012/photos"
                                                               relatedTags:nil
                                                                 configure:^(CPSConfigurationItem * _Nonnull item) {
        item.isDefault = YES;
        item.hideFromTagCloud = YES;
    }] atIndex:0];
    
    unsplashViewController.configuration = unsplashConfiguration;
    
    UINavigationController *viewController = [[UINavigationController alloc] initWithRootViewController:unsplashViewController];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)presentUnsplashSearchWithoutDefault;
{
    CPSUnsplashViewController *unsplashViewController = [CPSUnsplashViewController newWithClientId:_YOUR_UNSPLASH_ACCESS_KEY_ delegate:self];
    unsplashViewController.backgroundColor = [UIColor whiteColor];
    unsplashViewController.cropAspectRatio = CGSizeMake(320.f, 568.f);
    unsplashViewController.configuration = [self defaultConfiguration];
    
    UINavigationController *viewController = [[UINavigationController alloc] initWithRootViewController:unsplashViewController];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - CPSUnsplashViewControllerDelegate
- (void)unsplashViewController:(CPSUnsplashViewController *)viewController didSelectImage:(UIImage *)image
{
    NSLog(@"Did select image %@", image);
}

- (void)unsplashViewController:(CPSUnsplashViewController *)viewController didSelectImageAttributionURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

#pragma mark - Private
- (NSMutableArray *)defaultConfiguration
{
    return @[
        [CPSConfigurationItem newWithTitle:@"Surfing"
                                searchTerm:@"surfing"
                               relatedTags:@[@"Hawaii", @"Tahiti", @"Indonesia", @"Australia"]
                                 configure:nil],
        [CPSConfigurationItem newWithTitle:@"Bouldering"
                                searchTerm:@"bouldering"
                               relatedTags:@[@"Bishop", @"Squamish", @"Hueco", @"Joshua Tree", @"Yosemite"]
                                 configure:nil],
        [CPSConfigurationItem newWithTitle:@"Snowboarding"
                                searchTerm:@"snowboarding"
                               relatedTags:@[@"Whistler", @"Tahoe", @"Breckenridge", @"Vail", @"Jackson Hole"]
                                 configure:nil],
        [CPSConfigurationItem newWithTitle:@"Hawaii"
                                searchTerm:@"hawaii"
                               relatedTags:@[@"Oahu", @"Kauai", @"Big Island", @"Maui", @"Lanai"]
                                 configure:nil],
        [CPSConfigurationItem newWithTitle:@"Nature"
                                searchTerm:@"nature"
                               relatedTags:@[@"Forest", @"Ocean", @"Beach", @"Mountain", @"Desert", @"Everglades", @"River"]
                                 configure:nil],
        [CPSConfigurationItem newWithTitle:@"Nintendo"
                                searchTerm:@"nintendo"
                               relatedTags:@[@"Mario", @"Zelda"]
                                 configure:nil],
        [CPSConfigurationItem newWithTitle:@"Wallpaper"
                                searchTerm:@"wallpaper"
                               relatedTags:@[@"iOS", @"Android", @"Nature", @"Bright", @"Dark"]
                                 configure:nil]].mutableCopy;
}

@end
