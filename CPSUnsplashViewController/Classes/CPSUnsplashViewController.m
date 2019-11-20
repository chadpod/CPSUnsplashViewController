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
//  CPSUnsplashViewController.m
//  unsplash-search
//
//  Created by Chad Podoski on 11/5/16.
//

#import "CPSUnsplashViewController.h"
#import "CPSTagsCollectionHeader.h"
#import "CPSImageSectionController.h"
#import "CPSSpinnerCell.h"
#import "NSObject+IGListDiffable.h"
#import "NSDictionary+IGListDiffable.h"
#import "DBSphereView.h"

#define UD_IMAGES_PER_SECTION @"UD_IMAGES_PER_SECTION"

@interface CPSUnsplashViewController () <UNTagsCollectionHeaderDelegate, CPSImageSectionControllerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>

@property (nonatomic) NSString *clientId;

@property (nonatomic) CPSTagsCollectionHeader *tagsView;
@property (nonatomic) NSLayoutConstraint *tagsHeightConstraint;

@property (nonatomic) IGListCollectionView *collectionView;
@property (nonatomic) IGListAdapter *adapter;
@property (nonatomic) IGListAdapterUpdater *updater;

@property (nonatomic) UISearchController *searchController;
@property (nonatomic) UIButton *searchBarCancelButton;
@property (nonatomic) NSTimer *searchTimer;

@property (nonatomic) UIView *emptyView;
@property (nonatomic) UIView *emptySearchResultsView;
@property (nonatomic) DBSphereView *sphereView;

@property (nonatomic) NSMutableArray *objects;
@property (nonatomic) NSObject *spinner;

@property BOOL loading;
@property (nonatomic) NSString *searchTerm;
@property (nonatomic) NSUInteger page;
@property (nonatomic) NSUInteger totalPages;
@property (nonatomic) NSMutableArray *searchResults;

@property (nonatomic) NSURLSessionDataTask *searchTask;

@property (nonatomic) CPSConfigurationItem *filter;
@property (nonatomic) NSString *defaultTag;
@property (nonatomic) UIImage *selectedImage;

@property (nonatomic) NSMutableDictionary *cachedResponses;

@end

@implementation CPSUnsplashViewController

+ (instancetype)newWithClientId:(NSString *)clientId delegate:(id<CPSUnsplashViewControllerDelegate>)delegate;
{
    CPSUnsplashViewController *viewController = [CPSUnsplashViewController new];
    viewController.clientId = clientId;
    viewController.cachedResponses = [NSMutableDictionary new];
    viewController.font = [UIFont systemFontOfSize:12.f];
    viewController.tintColor = [UIColor systemBlueColor];
    viewController.textColor = [UIColor lightGrayColor];
    viewController.imagesPerRow = 3;
    viewController.delegate = delegate;
    
    return viewController;
}

- (void)dealloc {
    self.searchController.searchResultsUpdater = nil;
    self.searchController.searchBar.delegate = nil;
    self.searchController.delegate = nil;
    self.searchController = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Photos by Unsplash";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"Search or tap a word to find images...";
    self.searchController.searchBar.showsCancelButton = NO;
    [self.searchController.searchBar sizeToFit];
    
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    UIButton *searchCancelOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchCancelOverlayButton.translatesAutoresizingMaskIntoConstraints = NO;
    [searchCancelOverlayButton addTarget:self action:@selector(cancelSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.searchController.searchBar addSubview:searchCancelOverlayButton];
    [searchCancelOverlayButton.superview addConstraints:(@[[searchCancelOverlayButton.topAnchor constraintEqualToAnchor:searchCancelOverlayButton.superview.topAnchor],
                                                           [searchCancelOverlayButton.rightAnchor constraintEqualToAnchor:searchCancelOverlayButton.superview.rightAnchor],
                                                           [searchCancelOverlayButton.bottomAnchor constraintEqualToAnchor:searchCancelOverlayButton.superview.bottomAnchor],
                                                           [NSLayoutConstraint constraintWithItem:searchCancelOverlayButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:44.f]])];
    
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        // Set app-wide shared cache (first number is megabyte value)
//        NSUInteger cacheSize = 50*1024*1024; // 50 MB
//        NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSize diskCapacity:cacheSize diskPath:@"nsurlcache"];
//        [NSURLCache setSharedURLCache:sharedCache];
//    });
    
    self.spinner = @"Spinner";
    
    self.objects = [NSMutableArray new];
    self.searchResults = [NSMutableArray new];
    
    self.tagsView = [CPSTagsCollectionHeader newWithFont:self.font normalTintColor:self.textColor selectedTintColor:self.tintColor];
    self.tagsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tagsView.delegate = self;
    [self.view addSubview:self.tagsView];
    
    self.tagsHeightConstraint = [NSLayoutConstraint constraintWithItem:self.tagsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:0.f];
    [self.view addConstraints:@[[self.tagsView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
                                [self.tagsView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor],
                                [self.tagsView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor],
                                self.tagsHeightConstraint]];
    
    IGListCollectionViewLayout *flowLayout = [[IGListCollectionViewLayout alloc] initWithStickyHeaders:YES topContentInset:0 stretchToEdge:NO];
    self.collectionView = [[IGListCollectionView alloc] initWithFrame:CGRectZero listCollectionViewLayout:flowLayout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = self.backgroundColor;
    //    self.collectionView.panGestureRecognizer.cancelsTouchesInView = NO; // Was cause attribution button to be triggered on scroll
    [self.view addSubview:self.collectionView];
    [self.view addConstraints:(@[[self.collectionView.topAnchor constraintEqualToAnchor:self.tagsView.bottomAnchor],
                                 [self.collectionView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor],
                                 [self.collectionView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor],
                                 [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]])];
    
    self.updater = [IGListAdapterUpdater new];
    self.adapter = [[IGListAdapter alloc] initWithUpdater:self.updater viewController:self workingRangeSize:2];
    self.adapter.collectionView = self.collectionView;
    self.adapter.dataSource = self;
    self.adapter.scrollViewDelegate = self;
    
    NSArray *defaultFilterItems = [self.configuration filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isDefault == YES"]];
    self.filter = defaultFilterItems.firstObject;
    self.defaultTag = self.filter.title;
    
    /* Load with curated photos to start */
    self.page = 1;
    self.totalPages = NSUIntegerMax;
    [self fetchCurrentFilter];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dismiss {
    [(self.navigationController ?: self) dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    if ([self.delegate respondsToSelector:@selector(unsplashViewController:didSelectImage:)])
        [self.delegate unsplashViewController:self didSelectImage:self.selectedImage];
    
    [(self.navigationController ?: self) dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view];
        return (fabs(translation.x) < 5);
    }
    
    return YES;
}

- (void)setSelectedImageId:(NSString *)selectedImageId image:(UIImage *)selectedImage
{
    self.selectedImageId = selectedImageId;
    self.selectedImage = selectedImage;
    
    self.navigationItem.rightBarButtonItem.enabled = self.selectedImage;
}

#pragma mark - Private Methods -
- (void)fetchSearchTerm:(NSString *)search page:(NSUInteger)page {
    if (self.page > self.totalPages)
        return;
    
    self.loading = YES;
    [self.adapter performUpdatesAnimated:YES completion:nil];
    
    if (search)
        self.searchTerm = search;
    
    [self.searchTask cancel];
    
    void (^processResults)(NSArray *) = ^void(NSArray *results) {
        self.loading = NO;
        
        [self sectionSearchResults:results];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (page == 1)
                [self.collectionView setContentOffset:CGPointZero animated:YES];
            
            [self.adapter performUpdatesAnimated:YES completion:nil];
            
            if ([self.searchController.searchBar isFirstResponder])
                [self.searchController.searchBar resignFirstResponder];
        });
    };
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@-%zu", search, self.page];
    NSArray *results = [self.cachedResponses objectForKey:cacheKey];
    
    if (!results) {
        NSString *endpoint = [CPSConfigurationItem endpointForSearchTerm:self.searchTerm];
        
        NSURLComponents *components;
        if (endpoint) {
            components = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"https://api.unsplash.com/%@", endpoint]];
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:self.clientId],
                                      [NSURLQueryItem queryItemWithName:@"per_page" value:@"25"],
                                      [NSURLQueryItem queryItemWithName:@"page" value:[@(page) stringValue]]];
        }
        else {
            components = [NSURLComponents componentsWithString:@"https://api.unsplash.com/search/photos"];
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"query" value:self.searchTerm],
                                      [NSURLQueryItem queryItemWithName:@"client_id" value:self.clientId],
                                      [NSURLQueryItem queryItemWithName:@"per_page" value:@"25"],
                                      [NSURLQueryItem queryItemWithName:@"page" value:[@(page) stringValue]]];
        }
        
        self.searchTask = [[NSURLSession sharedSession] dataTaskWithURL:components.URL
                                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSArray *results;
            if (data && !error) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
                results = (endpoint ? dict : [dict objectForKey:@"results"]);
                
                if (results) {
                    self.page = page;
                    
                    if ([dict isKindOfClass:[NSDictionary class]])
                        self.totalPages = [(NSNumber *)[dict objectForKey:@"total_pages"] unsignedIntegerValue];
                    else
                        self.totalPages = ((!results || ([results isKindOfClass:[NSArray class]] && [(NSArray *)results count] == 0)) ?
                                           self.totalPages = page :
                                           NSUIntegerMax);
                        
                    [self.cachedResponses setObject:results forKey:cacheKey];
                }
            }
            
            processResults(results);
        }];
        [self.searchTask resume];
    }
    else {
        processResults(results);
    }
}

- (void)downloadPhotoForImageId:(NSString *)imageId {
    if (imageId) {
        NSArray *newTags = [self.cachedResponses objectForKey:imageId];
        
        if (!newTags) {
            NSURLComponents *components = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"https://api.unsplash.com/photos/%@", imageId]];
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:self.clientId]];
            NSURL *url = components.URL;
            
            [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data && !error) {
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
                    NSArray *newTags = ([dict valueForKeyPath:@"tags.title"] ?: @[]);
                    
                    [self.cachedResponses setObject:newTags forKey:imageId];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self processNewTags:newTags];
                    });
                }
            }] resume];
        }
        else {
            [self processNewTags:newTags];
        }
    }
}

- (void)processNewTags:(NSArray *)newTags
{
    NSMutableArray *tags = [NSMutableArray new];
    if (self.filter.selectedTag)
        [tags insertObject:self.filter.selectedTag atIndex:0];
    
    
    for (NSString *tag in newTags) {
        NSString *capitalizedTag = [tag capitalizedString];
        if (![tags containsObject:capitalizedTag] && ![self.searchController.searchBar.text isEqual:capitalizedTag])
            [tags addObject:capitalizedTag];
    }
    
    self.filter.relatedTags = tags;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.filter = self.filter;
        [self.tagsView scrollToTop];
    });
}

- (void)trackPhotoDownloadForImageId:(NSString *)imageId {
    if (imageId) {
        NSURLComponents *components = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"https://api.unsplash.com/photos/%@/download", imageId]];
        components.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:self.clientId]];
        NSURL *url = components.URL;
        
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
        }] resume];
    }
}

- (void)sectionSearchResults:(NSArray *)results {
    if (self.page == 1 && results != nil)
        [self.searchResults removeAllObjects];
    
    /* If we have a selected image, save it */
    __block NSDictionary *selectedImageDict;
    if (self.selectedImageId) {
        if (self.page == 1) {
            [self.objects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]] && [[(NSDictionary *)obj objectForKey:@"id"] isEqual:self.selectedImageId]) {
                    selectedImageDict = obj;
                    *stop = YES;
                }
            }];
            
            if (selectedImageDict)
                [self.searchResults addObject:selectedImageDict];
        }
        
        /* Remove it from the results if it is in them */
        NSUInteger index = [results indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [[obj objectForKey:@"id"] isEqual:self.selectedImageId];
        }];
        
        if (index != NSNotFound) {
            NSMutableArray *mutableResults = results.mutableCopy;
            [mutableResults removeObjectAtIndex:index];
            results = mutableResults;
        }
    }
    
    [self.objects removeAllObjects];
    
    if (results)
        [self.searchResults addObjectsFromArray:results];

    [self.objects addObjectsFromArray:self.searchResults];
}

#pragma mark - IGListAdapterDataSource -
- (NSArray<id <IGListDiffable>> *)objectsForListAdapter:(IGListAdapter *)listAdapter; {
    if (self.loading && [self.objects indexOfObject:self.spinner] == NSNotFound)
        [self.objects addObject:self.spinner];
    
    /* Deduplicate objects */
    self.objects = [[NSOrderedSet orderedSetWithArray:self.objects] array].mutableCopy;
    
    return self.objects;
}

- (IGListSectionController *)listAdapter:(IGListAdapter *)listAdapter sectionControllerForObject:(id)object; {
    if (object == self.spinner)
        return [CPSSpinnerCell spinnerSectionController];
    else {
        CPSImageSectionController *sectionController = [CPSImageSectionController new];
        sectionController.searchViewController = self;
        sectionController.imageItem = object;
        sectionController.numberOfImagesPerSection = self.imagesPerRow;
        sectionController.thumbnailKeyPath = (self.view.bounds.size.width > 400 ? @"urls.small" :@"urls.thumb");
        sectionController.imageKeyPath = @"urls.regular";
        sectionController.attributionKeyPath = @"user.username";
        sectionController.attributionTextKeyPath = @"user.name";
        
        return sectionController;
    }
    
    return nil;
}

- (nullable UIView *)emptyViewForListAdapter:(IGListAdapter *)listAdapter; {
    NSString *searchText = self.searchController.searchBar.text;
    
    if (!searchText || searchText.length == 0) {
        if (!self.emptyView) {
            self.emptyView = [UIView new];
            
            DBSphereView *sphereView = [DBSphereView new];
            sphereView.translatesAutoresizingMaskIntoConstraints = NO;
            
            NSMutableArray *tagCloudTitles = [NSMutableArray new];
            for (CPSConfigurationItem *item in self.configuration) {
                if (!item.hideFromTagCloud)
                    [tagCloudTitles addObject:item.title];
            }
            
            NSMutableArray *array = [NSMutableArray new];
            for (NSString *title in tagCloudTitles) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                [btn setTitle:title forState:UIControlStateNormal];
                [btn setTitleColor:self.tintColor forState:UIControlStateNormal];
                btn.titleLabel.font = [self.font fontWithSize:24.f];
                btn.frame = (CGRect){.size = [btn.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 14.f)]};
                [btn addTarget:self action:@selector(cloudSearchTermTapped:) forControlEvents:UIControlEventTouchUpInside];
                [array addObject:btn];
                [sphereView addSubview:btn];
            }
            [sphereView setCloudTags:array];
            sphereView.backgroundColor = self.backgroundColor;
            [self.emptyView addSubview:sphereView];
            
            [self.emptyView addConstraints:(@[[NSLayoutConstraint constraintWithItem:sphereView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.emptyView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f],
                                              [NSLayoutConstraint constraintWithItem:sphereView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.emptyView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:-150.f],
                                              [NSLayoutConstraint constraintWithItem:sphereView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.emptyView attribute:NSLayoutAttributeWidth multiplier:0.65f constant:0.f],
                                              [NSLayoutConstraint constraintWithItem:sphereView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.emptyView attribute:NSLayoutAttributeWidth multiplier:0.65f constant:0.f]])];
            
            self.sphereView = sphereView;
            
//            /* Instructive label under the tag cloud */
//            UILabel *tagCloudLabel = [UILabel new];
//            tagCloudLabel.translatesAutoresizingMaskIntoConstraints = NO;
//            tagCloudLabel.textAlignment = NSTextAlignmentCenter;
//            tagCloudLabel.font = [self.font fontWithSize:12.f];
//            tagCloudLabel.textColor = self.textColor;
//            tagCloudLabel.text = @"Search or tap on a word to find images";
//            [self.emptyView addSubview:tagCloudLabel];
//            [self.emptyView addConstraints:(@[[NSLayoutConstraint constraintWithItem:tagCloudLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.sphereView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f],
//                                              [NSLayoutConstraint constraintWithItem:tagCloudLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.sphereView attribute:NSLayoutAttributeBottom multiplier:1.f constant:70.f],
//                                              [NSLayoutConstraint constraintWithItem:tagCloudLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.emptyView attribute:NSLayoutAttributeWidth multiplier:0.8f constant:0.f],
//                                              [NSLayoutConstraint constraintWithItem:tagCloudLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:14.f]])];
        }
        
        return self.emptyView;
    }
    else {
        if (!self.emptySearchResultsView) {
            self.emptySearchResultsView = [UIView new];
            
            UILabel *noResultsLabel = [UILabel new];
            noResultsLabel.translatesAutoresizingMaskIntoConstraints = NO;
            noResultsLabel.textAlignment = NSTextAlignmentCenter;
            noResultsLabel.font = [self.font fontWithSize:12.f];
            noResultsLabel.textColor = self.textColor;
            noResultsLabel.text = @"No matching images found";
            [self.emptySearchResultsView addSubview:noResultsLabel];
            [self.emptySearchResultsView addConstraints:(@[[NSLayoutConstraint constraintWithItem:noResultsLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.emptySearchResultsView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f],
                                                           [NSLayoutConstraint constraintWithItem:noResultsLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.emptySearchResultsView attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f],
                                                           [NSLayoutConstraint constraintWithItem:noResultsLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.emptySearchResultsView attribute:NSLayoutAttributeWidth multiplier:0.8f constant:0.f],
                                                           [NSLayoutConstraint constraintWithItem:noResultsLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:14.f]])];
        }
        
        return self.emptySearchResultsView;
    }
}

#pragma mark - Filter
- (void)setFilter:(CPSConfigurationItem *)filter
{
    _filter = filter;
    
    self.tagsView.selectedTag = filter.selectedTag;
    self.tagsView.tags = ([CPSConfigurationItem endpointForSearchTerm:self.searchTerm] ? nil : filter.relatedTags);
    
    self.tagsHeightConstraint.constant = (self.tagsView.tags && self.tagsView.tags.count > 0 ? 44.f : 0.f);
    [self.view layoutIfNeeded];
}

- (CPSConfigurationItem *)filterForText:(NSString *)text {
    __block CPSConfigurationItem *filter = nil;
    
    [self.configuration enumerateObjectsUsingBlock:^(CPSConfigurationItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.title isEqual:text]) {
            filter = obj;
            *stop = YES;
        }
    }];
    
    return filter;
}

- (void)fetchCurrentFilter {
    if (!self.filter) {
        self.objects = @[].mutableCopy;
        
        NSString *text = self.searchController.searchBar.text;
        if (text && text.length > 0)
            [self fetchSearchTerm:text page:self.page];
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.adapter performUpdatesAnimated:YES completion:nil];
            });
    }
    else {
        self.searchController.searchBar.text = self.filter.title;
        [self fetchSearchTerm:self.filter.searchTerm page:self.page];
    }
}

#pragma mark - Search -
- (void)cloudSearchTermTapped:(UIButton *)button
{
    [self.sphereView timerStop];
    
    [UIView animateWithDuration:0.3 animations:^{
        button.transform = CGAffineTransformMakeScale(1.4f, 1.4f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            button.transform = CGAffineTransformMakeScale(1.f, 1.f);
        } completion:^(BOOL finished) {
            [self.sphereView timerStart];
            
            NSString *text = [button titleForState:UIControlStateNormal];
            self.searchController.searchBar.text = text;
            [self handleSearch];
        }];
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
{
    [self handleSearch];
}

- (void)handleSearch
{
    [self.searchTask cancel];
    
    self.page = 1;
    self.loading = NO;
    self.totalPages = NSUIntegerMax;
    
    NSString *text = self.searchController.searchBar.text;
    CPSConfigurationItem *filter = [self filterForText:text];
    
    if (filter)
        self.filter = filter;
    else
        self.filter = nil;
    
    [self fetchCurrentFilter];
}

- (void)cancelSearch
{
    self.filter = nil;
    self.searchController.searchBar.text = nil;
    [self handleSearch];
    
    [self.searchController.searchBar resignFirstResponder];
}

#pragma mark - CPSImageSectionControllerDelegate -
- (void)didSelectImage:(UIImage *)image imageId:(NSString *)imageId
{
    [self setSelectedImageId:imageId image:image];
    
    [self trackPhotoDownloadForImageId:imageId];
    [self downloadPhotoForImageId:imageId];
}

- (void)didSelectImageAtributionURL:(NSURL *)url;
{
    if ([self.delegate respondsToSelector:@selector(unsplashViewController:didSelectImageAttributionURL:)])
        [self.delegate unsplashViewController:self didSelectImageAttributionURL:url];
}

#pragma mark - UNTagsCollectionHeaderDelegate -
- (void)tagsChanged:(NSString *)tag;
{
    self.page = 1;
    self.totalPages = NSUIntegerMax;
    
    CPSConfigurationItem *filter = self.filter;
    filter.selectedTag = tag;
    self.filter = filter;
    
    NSString *searchTerms = [[NSString stringWithFormat:@"%@ %@", self.filter.searchTerm, self.filter.selectedTag] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [self fetchSearchTerm:searchTerms page:self.page];
}

#pragma mark - UIScrollViewDelegate -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.searchController.searchBar isFirstResponder])
        [self.searchController.searchBar resignFirstResponder];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat distance = scrollView.contentSize.height - ((*targetContentOffset).y + scrollView.bounds.size.height);
    if (!self.loading && distance < 200.f)
    {
        self.page++;
        
        if (self.searchTerm && [self.searchTerm length] > 0)
            [self fetchSearchTerm:self.searchTerm page:self.page];
    }
}

@end
