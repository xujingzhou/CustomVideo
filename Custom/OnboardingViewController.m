//
//  OnboardingViewController.m
//  Onboard
//
//  Created by Mike on 8/17/14.
//  Copyright (c) 2014 Mike Amaral. All rights reserved.
//

#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"
@import Accelerate;

#import "UzysAssetsPickerController.h"
#import "CaptureViewController.h"
#import "PCStackMenu.h"
#import "STAlertView.h"
#import "ThemeScrollView.h"

static CGFloat const kPageControlHeight = 35;
static CGFloat const kSkipButtonWidth = 100;
static CGFloat const kSkipButtonHeight = 44;
static CGFloat const kBackgroundMaskAlpha = 0.6;
static CGFloat const kDefaultBlurRadius = 20;
static CGFloat const kDefaultSaturationDeltaFactor = 1.8;

static NSString * const kSkipButtonText = @"Skip";

@interface OnboardingViewController()<UzysAssetsPickerControllerDelegate, ThemeScrollViewDelegate>
{
     UzysAssetsPickerController *_imagePicker;
}

@property (nonatomic, strong) STAlertView *stAlertView;

@property (retain, nonatomic) ThemeScrollView *frameScrollView;

@end

@implementation OnboardingViewController
{
    UIImage *_backgroundImage;
    UIPageViewController *_pageVC;
    NSArray *_viewControllers;
    
    OnboardingContentViewController *_currentPage;
    OnboardingContentViewController *_upcomingPage;
}

#pragma mark - Video Border Picker
- (void) pickVideoBorder
{
    self.frameScrollView.hidden = !self.frameScrollView.hidden;
}

- (void) initThemeScrollView
{
    CGFloat height = 150;
    _frameScrollView = [[ThemeScrollView alloc] initWithFrame:CGRectMake(0, _currentPage.actionButton.frame.origin.y - height, self.view.frame.size.width, height)];
    _frameScrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_frameScrollView];
    
    [self.frameScrollView setDelegate:self];
//    [self.frameScrollView setCurrentSelectedItem:0];
//    [self.frameScrollView scrollToItemAtIndex:0];
    self.frameScrollView.hidden = YES;
}

- (UIImage *) scaleFromImage:(UIImage *)image toSize:(CGSize)size
{
    if (!image)
    {
        return nil;
    }
    
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) themeScrollView:(ThemeScrollView *)themeScrollView didSelectMaterial:(NSNumber*)material
{
    int index = [material intValue];
    if (index < -1)
    {
        NSLog(@"Currently choose is empty.");
        return;
    }
    
    if (index >= -1 && index < 12)
    {
        self.frameScrollView.hidden = YES;
        self.callbackPickVideoBorder(YES, material);
    }
    else
    {
        self.callbackPickVideoBorder(NO, @"Choose video border error.");
    }
}

// Hide video border by Johnny Xu, 2014/11/1
- (void) hideVideoBorderFrame
{
    self.frameScrollView.hidden = YES;
}

#pragma mark - Video Picker
- (void) pickVideo
{
    CaptureViewController *captureVC = [[CaptureViewController alloc] init];
    [captureVC setCallback:^(BOOL success, id result)
     {
         if (success)
         {
             self.callbackPickVideo(YES, result);
         }
         else
         {
             self.callbackPickVideo(NO, result);
         }
     }];
     
    [self presentViewController:captureVC animated:YES completion:^{
        NSLog(@"PickVideo present");
    }];
}

#pragma mark - Music Picker
- (void) pickMusic
{
    UIButton *button;
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        button = contentVC.actionButton;
        break;
    }
    
    NSArray *musics = [NSArray arrayWithObjects: @"Untitled", @"Pretty Boy", @"Big Big World", @"Rhythm Of Rain", @"The mood of love", @"Because I Love You", @"Yesterday Once More", @"The Day You Went Away",  @"I love you more than I can say", nil];
    PCStackMenu *stackMenu = [[PCStackMenu alloc] initWithTitles:musics
													  withImages:nil
													atStartPoint:CGPointMake(button.frame.origin.x + button.frame.size.width/2+50, button.frame.origin.y)
														  inView:self.view
													  itemHeight:35
												   menuDirection:PCStackMenuDirectionClockWiseUp];
     
    for(PCStackMenuItem *item in stackMenu.items)
    {
        item.stackTitleLabel.textColor = [UIColor yellowColor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [stackMenu show:^(NSInteger selectedMenuIndex)
         {
             NSLog(@"Menu index : %ld", (long)selectedMenuIndex);
             
             self.callbackPickMusic(YES, [NSNumber numberWithLong:selectedMenuIndex]);
         }];
    });
}

#pragma mark - Effect Picker
- (void) pickEffect
{
    UIButton *button;
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        button = contentVC.actionButton;
        break;
    }
    
    NSArray *effects = [NSArray arrayWithObjects: @"PhotoCloud", @"PhotoExplodeDrop", @"PhotoSpin360", @"PhotoEmitter", @"PhotoFlare", @"PhotoParabola", @"PhotoDrop",  @"PhotoCentringShow", nil];
    PCStackMenu *stackMenu = [[PCStackMenu alloc] initWithTitles:effects
													  withImages:nil
													atStartPoint:CGPointMake(button.frame.origin.x+50, button.frame.origin.y)
														  inView:self.view
													  itemHeight:35
												   menuDirection:PCStackMenuDirectionCounterClockWiseUp];
    
    for(PCStackMenuItem *item in stackMenu.items)
    {
        item.stackTitleLabel.textColor = [UIColor yellowColor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [stackMenu show:^(NSInteger selectedMenuIndex)
         {
             NSLog(@"Menu index : %ld", (long)selectedMenuIndex);
             
             self.callbackPickEffect(YES, [NSNumber numberWithLong:selectedMenuIndex]);
         }];
    });
}

#pragma mark - Effect Picker
- (void) pickTextEffectByDic:(NSMutableDictionary*)dic
{
    UIButton *button;
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        button = contentVC.actionButton;
        break;
    }
    
    NSArray *effects = [NSArray arrayWithObjects: @"Startup Text", @"Bottom Text", @"Top Text", @"Scroll Text", nil];
    PCStackMenu *stackMenu = [[PCStackMenu alloc] initWithTitles:effects
													  withImages:nil
													atStartPoint:CGPointMake(button.frame.origin.x+50, button.frame.origin.y)
														  inView:self.view
													  itemHeight:35
												   menuDirection:PCStackMenuDirectionCounterClockWiseUp];
    
    for(PCStackMenuItem *item in stackMenu.items)
    {
        item.stackTitleLabel.textColor = [UIColor yellowColor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [stackMenu show:^(NSInteger selectedMenuIndex)
         {
             NSLog(@"Menu index : %ld", (long)selectedMenuIndex);
             
             NSString *cancel = NSLocalizedString(@"Cancel", nil);
             NSString *confirm = NSLocalizedString(@"Confirm", nil);
             NSString *title = nil;
             NSString *textHint = nil;
             NSString *textValue = nil;
             
             if (selectedMenuIndex == 0)
             {
                 title = NSLocalizedString(@"StartupTextTitle", nil);
                 textHint = NSLocalizedString(@"StartupTextHint", nil);
                 textValue = [dic objectForKey:@"StartupText"];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.stAlertView = [[STAlertView alloc] initWithTitle:title
                                                message:nil
                                          textFieldHint:textHint
                                         textFieldValue:textValue
                                      cancelButtonTitle:cancel
                                      otherButtonTitles:confirm
                      
                                      cancelButtonBlock:^{
                                          
                                          NSLog(@"Cancel!");
                                          self.callbackPickTextEffect(NO, @"Cancel");
                                          
                                      } otherButtonBlock:^(NSString * result){
                                          
                                          NSLog(@"The result: %@", result);
                                          
                                          if (result && ![result isEqualToString:@""])
                                          {
                                              [dic setObject:result forKey:@"StartupText"];
                                              self.callbackPickTextEffect(YES, dic);
                                          }
                                         
                                      }];
                 });
            
             }
             else if (selectedMenuIndex == 1)
             {
                 title = NSLocalizedString(@"BottomTextTitle", nil);
                 textHint = NSLocalizedString(@"BottomTextHint", nil);
                 textValue = [dic objectForKey:@"BottomText"];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.stAlertView = [[STAlertView alloc] initWithTitle:title
                                                message:nil
                                          textFieldHint:textHint
                                         textFieldValue:textValue
                                      cancelButtonTitle:cancel
                                      otherButtonTitles:confirm
                      
                                      cancelButtonBlock:^{
                                          
                                          NSLog(@"Cancel!");
                                          self.callbackPickTextEffect(NO, @"Cancel");
                                          
                                      } otherButtonBlock:^(NSString * result){
                                          
                                          if (result && ![result isEqualToString:@""])
                                          {
                                              [dic setObject:result forKey:@"BottomText"];
                                              self.callbackPickTextEffect(YES, dic);
                                          }
                                          
                                          NSLog(@"The result: %@", result);
                                      }];
                 });
             }
             else if (selectedMenuIndex == 2)
             {
                 title = NSLocalizedString(@"TopTextTitle", nil);
                 textHint = NSLocalizedString(@"TopTextHint", nil);
                 textValue = [dic objectForKey:@"TopText"];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.stAlertView = [[STAlertView alloc] initWithTitle:title
                                                message:nil
                                          textFieldHint:textHint
                                         textFieldValue:textValue
                                      cancelButtonTitle:cancel
                                      otherButtonTitles:confirm
                      
                                      cancelButtonBlock:^{
                                          
                                          NSLog(@"Cancel!");
                                          self.callbackPickTextEffect(NO, @"Cancel");
                                          
                                      } otherButtonBlock:^(NSString * result){
                                          
                                          if (result && ![result isEqualToString:@""])
                                          {
                                              [dic setObject:result forKey:@"TopText"];
                                              self.callbackPickTextEffect(YES, dic);
                                          }
                                          
                                          NSLog(@"The result: %@", result);
                                      }];
                 });
             }
             else
             {
                 title = NSLocalizedString(@"ScrollTextTitle", nil);
                 textHint = NSLocalizedString(@"ScrollTextHint", nil);
                 textValue = [dic objectForKey:@"ScrollText"];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.stAlertView = [[STAlertView alloc] initWithTitle:title
                                                                   message:nil
                                                             textFieldHint:textHint
                                                            textFieldValue:textValue
                                                         cancelButtonTitle:cancel
                                                         otherButtonTitles:confirm
                                         
                                                         cancelButtonBlock:^{
                                                             
                                                             NSLog(@"Cancel!");
                                                             self.callbackPickTextEffect(NO, @"Cancel");
                                                             
                                                         } otherButtonBlock:^(NSString * result){
                                                             
                                                             if (result && ![result isEqualToString:@""])
                                                             {
                                                                 [dic setObject:result forKey:@"ScrollText"];
                                                                 self.callbackPickTextEffect(YES, dic);
                                                             }
                                                             
                                                             NSLog(@"The result: %@", result);
                                                         }];
                 });
             }
         }];
    });
}

#pragma mark - Image Picker
-(void) pickPhotos
{
	[self initImagePicker];
}

- (void) initImagePicker
{
    _imagePicker = [[UzysAssetsPickerController alloc] init];
    _imagePicker.delegate = self;
    _imagePicker.maximumNumberOfSelectionVideo = 0;
    _imagePicker.maximumNumberOfSelectionPhoto = 15;
    
    [self presentViewController:_imagePicker animated:YES completion:^{
        NSLog(@"ImagePicker present");
    }];
}

#pragma mark - UzysAssetsPickerControllerDelegate methods
- (void) UzysAssetsPickerController:(UzysAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    NSLog(@"%ld asset selected",(unsigned long)assets.count);
    NSLog(@"assets %@",assets);
    
    // Callback
    if (assets && [assets count]>0)
    {
        self.callbackPickPhotos(YES, assets);
    }
    else
    {
        self.callbackPickPhotos(NO, @"Pick image is empty.");
    }
}

- (void) UzysAssetsPickerControllerDidExceedMaximumNumberOfSelection:(UzysAssetsPickerController *)picker
{
    NSString *ok = NSLocalizedString(@"Ok", nil);
    NSString *title = NSLocalizedString(@"Reminder", nil);
    NSString *message = NSLocalizedString(@"ExceedHint", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:ok
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) UzysAssetsPickerControllerDidCancel:(UzysAssetsPickerController *)picker
{
    NSLog(@"AssetsPickerControllerDidCancel");
    
    // Callback
    self.callbackPickPhotos(NO, @"AssetsPickerController did cancel");
}

#pragma mark - View LifeCycle
- (id)initWithBackgroundImage:(UIImage *)backgroundImage contents:(NSArray *)contents
{
    self = [super init];

    // store the passed in background image and view controllers array
    _backgroundImage = backgroundImage;
    _viewControllers = contents;
    
    // set the default properties
    self.shouldMaskBackground = YES;
    self.shouldBlurBackground = NO;
    self.shouldFadeTransitions = NO;
    
    self.allowSkipping = NO;
    self.skipHandler = ^{};
    
    // create the initial exposed components so they can be customized
    self.pageControl = [UIPageControl new];
    self.skipButton = [UIButton new];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // now that the view has loaded, we can generate the content
    [self generateView];
    
    // Video border by Johnny Xu, 2014/11/1
    [self initThemeScrollView];
}

- (void)viewDidUnload
{
     _imagePicker = nil;
}

- (void)generateView
{
    // create our page view controller
    _pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageVC.view.frame = self.view.frame;
    _pageVC.view.backgroundColor = [UIColor whiteColor];
    _pageVC.delegate = self;
    _pageVC.dataSource = self;
    
    if (self.shouldBlurBackground)
    {
        [self blurBackground];
    }
    
    // create the background image view and set it to aspect fill so it isn't skewed
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [backgroundImageView setImage:_backgroundImage];
    [self.view addSubview:backgroundImageView];
    
    // as long as the shouldMaskBackground setting hasn't been set to NO, we want to
    // create a partially opaque view and add it on top of the image view, so that it
    // darkens it a bit for better contrast
    UIView *backgroundMaskView;
    if (self.shouldMaskBackground)
    {
        backgroundMaskView = [[UIView alloc] initWithFrame:_pageVC.view.frame];
        backgroundMaskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kBackgroundMaskAlpha];
        [_pageVC.view addSubview:backgroundMaskView];
    }
    
    // set the initial current page as the first page provided
    _currentPage = [_viewControllers firstObject];
    
    // more page controller setup
    [_pageVC setViewControllers:@[_currentPage] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    _pageVC.view.backgroundColor = [UIColor clearColor];
    [self addChildViewController:_pageVC];
    [self.view addSubview:_pageVC.view];
    [_pageVC didMoveToParentViewController:self];
    [_pageVC.view sendSubviewToBack:backgroundMaskView];
    [_pageVC.view sendSubviewToBack:backgroundImageView];
    
    // create and configure the the page control
    self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - kPageControlHeight, self.view.frame.size.width, kPageControlHeight);
    self.pageControl.numberOfPages = _viewControllers.count;
    [self.view addSubview:self.pageControl];
    
    if (self.allowSkipping)
    {
        NSString *skipText = NSLocalizedString(@"Finish", nil);
        self.skipButton.frame = CGRectMake(CGRectGetMaxX(self.view.frame) - kSkipButtonWidth, CGRectGetMaxY(self.view.frame) - kSkipButtonHeight, kSkipButtonWidth, kSkipButtonHeight);
        [self.skipButton setTitle:skipText forState:UIControlStateNormal];
        
        // Add background image by Johnny Xu
        [self.skipButton setTitleColor:BrightBlue forState:UIControlStateNormal];
        NSString *fontName = @"Noteworthy-Bold";
        self.skipButton.titleLabel.font = [UIFont fontWithName:fontName size:20];
        
        [self.skipButton addTarget:self action:@selector(handleSkipButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.skipButton];
        
        
        UIButton *exitButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 20, 45, 45)];
        [exitButton setImage:[UIImage imageNamed:@"sm_btn_msg_close"] forState:UIControlStateNormal];
        [exitButton addTarget:self action:@selector(exitView) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:exitButton];
    }
    

    if (self.shouldFadeTransitions)
    {
        for (UIView *view in _pageVC.view.subviews)
        {
            if ([view isKindOfClass:[UIScrollView class]])
            {
                [(UIScrollView *)view setDelegate:self];
            }
        }
        
        // set ourself as the delegate on all of the content views
        for (OnboardingContentViewController *contentVC in _viewControllers)
        {
            contentVC.delegate = self;
        }
    }
}


#pragma mark - Skipping

- (void)handleSkipButtonPressed
{
    self.skipHandler();
}

- (void)exitView
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Convenience setters for content pages

- (void)setIconSize:(CGFloat)iconSize
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.iconWidth = iconSize;
        contentVC.iconHeight = iconSize;
    }
}

- (void)setIconWidth:(CGFloat)iconWidth
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.iconWidth = iconWidth;
    }
}

- (void)setIconHeight:(CGFloat)iconHeight
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.iconHeight = iconHeight;
    }
}

- (void)setTitleTextColor:(UIColor *)titleTextColor
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.titleTextColor = titleTextColor;
    }
}

- (void)setBodyTextColor:(UIColor *)bodyTextColor
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.bodyTextColor = bodyTextColor;
    }
}

- (void)setButtonTextColor:(UIColor *)buttonTextColor
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.buttonTextColor = buttonTextColor;
    }
}

- (void)setFontName:(NSString *)fontName
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.titleFontName = fontName;
        contentVC.bodyFontName = fontName;
        contentVC.buttonFontName = fontName;
    }
}

- (void)setTitleFontName:(NSString *)fontName
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.titleFontName = fontName;
    }
}

- (void)setTitleFontSize:(CGFloat)titleFontSize
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.titleFontSize = titleFontSize;
    }
}

- (void)setBodyFontName:(NSString *)fontName
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.bodyFontName = fontName;
    }
}

- (void)setBodyFontSize:(CGFloat)bodyFontSize
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.bodyFontSize = bodyFontSize;
    }
}

- (void)setButtonFontName:(NSString *)fontName
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.buttonFontName = fontName;
    }
}

- (void)setButtonFontSize:(CGFloat)bodyFontSize
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.buttonFontSize = bodyFontSize;
    }
}

- (void)setTopPadding:(CGFloat)topPadding
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.topPadding = topPadding;
    }
}

- (void)setUnderIconPadding:(CGFloat)underIconPadding
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.underIconPadding = underIconPadding;
    }
}

- (void)setUnderTitlePadding:(CGFloat)underTitlePadding
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.underTitlePadding = underTitlePadding;
    }
}

- (void)setBottomPadding:(CGFloat)bottomPadding
{
    for (OnboardingContentViewController *contentVC in _viewControllers)
    {
        contentVC.bottomPadding = bottomPadding;
    }
}

#pragma mark - Page view controller data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    [self hideVideoBorderFrame];
    
    // return the previous view controller in the array unless we're at the beginning
    if (viewController == [_viewControllers firstObject])
    {
        return nil;
    }
    else
    {
        NSInteger priorPageIndex = [_viewControllers indexOfObject:viewController] - 1;
        return _viewControllers[priorPageIndex];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    [self hideVideoBorderFrame];
    
    // return the next view controller in the array unless we're at the end
    if (viewController == [_viewControllers lastObject])
    {
        return nil;
    }
    else
    {
        NSInteger nextPageIndex = [_viewControllers indexOfObject:viewController] + 1;
        return _viewControllers[nextPageIndex];
    }
}


#pragma mark - Page view controller delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    // if we haven't completed animating yet, we don't want to do anything because it could be cancelled
    if (!completed)
    {
        return;
    }
    
    // get the view controller we are moving towards, then get the index, then set it as the current page
    // for the page control dots
    UIViewController *viewController = [pageViewController.viewControllers lastObject];
    NSInteger newIndex = [_viewControllers indexOfObject:viewController];
    [self.pageControl setCurrentPage:newIndex];
}

- (void)moveToPageForViewController:(UIViewController *)viewController
{
    [_pageVC setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self.pageControl setCurrentPage:[_viewControllers indexOfObject:viewController]];
}


#pragma mark - Page scroll status

- (void)setCurrentPage:(OnboardingContentViewController *)currentPage
{
    _currentPage = currentPage;
}

- (void)setNextPage:(OnboardingContentViewController *)nextPage
{
    _upcomingPage = nextPage;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // calculate the percent complete of the transition of the current page given the
    // scrollview's offset and the width of the screen
    CGFloat percentComplete = fabs(scrollView.contentOffset.x - self.view.frame.size.width) / self.view.frame.size.width;
    
    // these cases have some funk results given the way this method is called, like stuff
    // just disappearing, so we want to do nothing in these cases
    if (_upcomingPage == _currentPage || percentComplete == 0)
    {
        return;
    }
    
    // set the next page's alpha to be the percent complete, so if we're 90% of the way
    // scrolling towards the next page, its content's alpha should be 90%
    [_upcomingPage updateAlphas:percentComplete];
    
    // set the current page's alpha to the difference between 100% and this percent value,
    // so we're 90% scrolling towards the next page, the current content's alpha sshould be 10%
    [_currentPage updateAlphas:1.0 - percentComplete];
}


#pragma mark - Image blurring

- (void)blurBackground
{
    // Check pre-conditions.
    if (_backgroundImage.size.width < 1 || _backgroundImage.size.height < 1)
    {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", _backgroundImage.size.width, _backgroundImage.size.height, _backgroundImage);
        return;
    }
    if (!_backgroundImage.CGImage)
    {
        NSLog (@"*** error: image must be backed by a CGImage: %@", _backgroundImage);
        return;
    }
    
    UIColor *tintColor = [UIColor colorWithWhite:0.7 alpha:0.3];
    CGFloat blurRadius = kDefaultBlurRadius;
    CGFloat saturationDeltaFactor = kDefaultSaturationDeltaFactor;
    CGRect imageRect = { CGPointZero, _backgroundImage.size };
    UIImage *effectImage = _backgroundImage;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange)
    {
        UIGraphicsBeginImageContextWithOptions(_backgroundImage.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -_backgroundImage.size.height);
        CGContextDrawImage(effectInContext, imageRect, _backgroundImage.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(_backgroundImage.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur)
        {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            unsigned int radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1)
            {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange)
        {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i)
            {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur)
            {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else
            {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(_backgroundImage.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -_backgroundImage.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, _backgroundImage.CGImage);
    
    // Draw effect image.
    if (hasBlur)
    {
        CGContextSaveGState(outputContext);
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor)
    {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    _backgroundImage = outputImage;
}


#pragma mark - Getters for unit tests

- (NSArray *)contentViewControllers
{
    return _viewControllers;
}

@end
