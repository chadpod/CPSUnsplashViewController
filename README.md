# CPSUnsplashViewController

[![Version](https://img.shields.io/cocoapods/v/CPSUnsplashViewController.svg?style=flat)](https://cocoapods.org/pods/CPSUnsplashViewController)
[![License](https://img.shields.io/cocoapods/l/CPSUnsplashViewController.svg?style=flat)](https://cocoapods.org/pods/CPSUnsplashViewController)
[![Platform](https://img.shields.io/cocoapods/p/CPSUnsplashViewController.svg?style=flat)](https://cocoapods.org/pods/CPSUnsplashViewController)

CPSUnsplashViewController is a simple, fast image search component for iOS written in Objective-C. It's built on top of the [Unsplash API](https://unsplash.com/documentation) and provides some optional advanced features like customizable search term suggestions and Unsplash related tags support.

<p align="center" >
  <img src="https://github.com/chadpod/CPSUnsplashViewController/blob/master/Example/Screenshots/unsplash-photo-grid.jpg" height="487" width="225" alt="Photo Grid" title="Photo Grid">
  <img src="https://github.com/chadpod/CPSUnsplashViewController/blob/master/Example/Screenshots/unsplash-keyword-cloud.jpg" height="487" width="225" alt="Search Suggestions Cloud" title="Search Suggestions Cloud">
</p>

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 11+

## Installation

CPSUnsplashViewController is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile (not published yet):

```ruby
pod 'CPSUnsplashViewController', :git => "https://github.com/chadpod/CPSUnsplashViewController.git"
```

## Usage

```
- (void)showUnsplashSearch 
{
  CPSUnsplashViewController *unsplashViewController = [CPSUnsplashViewController newWithClientId:@"<YOUR_USPLASH_API_KEY>" delegate:self];
  unsplashViewController.backgroundColor = [UIColor whiteColor];
  unsplashViewController.cropAspectRatio = CGSizeMake(320.f, 568.f);

  UINavigationController *viewController = [[UINavigationController alloc] initWithRootViewController:self.unsplashViewController];
  viewController.modalPresentationStyle = UIModalPresentationFullScreen;

  [self presentViewController:viewController animated:YES completion:nil];
}
```

```
#pragma mark - CPSUnsplashViewController Delegate Methods

- (void)unsplashViewController:(CPSUnsplashViewController *)viewController didSelectImage:(UIImage *)image;
{
  // Use image that matches configured aspect ratio
}

- (void)unsplashViewController:(CPSUnsplashViewController *)viewController didSelectImageAttributionURL:(NSURL *)url;
{
  // Open image attribution URL, per Unsplash API terms, either in-app or kick out to Safari
}
```

### Optional Configuration

```
NSMutableArray *unsplashConfiguration = @[
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
                                 
[unsplashConfiguration insertObject:[CPSConfigurationItem newWithTitle:@"Phone Wallpapers"
                                                            searchTerm:@"collections/343012/photos"
                                                           relatedTags:nil
                                                             configure:^(CPSConfigurationItem * _Nonnull item) {
    item.isDefault = YES;
    item.hideFromTagCloud = YES;
}] atIndex:0];

unsplashViewController.configuration = unsplashConfiguration;
```

## Author

Chad Podoski, [@chadpod](http://twitter.com/chadpod)

## Apps

[Hobnob](https://hobnob.io)

## Dependencies

[IGLiskit](https://github.com/Instagram/IGListKit)

[DBSphereTagCloud](https://github.com/dongxinb/DBSphereTagCloud)

## License

CPSUnsplashViewController is available under the MIT license. See the LICENSE file for more info.

## Todo

* Add optional multiple image select support
