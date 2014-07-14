//
//  MTStackViewController.m
//  Maple
//
//  Created by Andrew Carter on 10/19/12.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MTStackViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "MTStackDefaultContainerView.h"

const char *MTStackViewControllerKey = "MTStackViewControllerKey";

#pragma mark - UIViewController VPStackNavigationController Additions

@implementation UIViewController (MTStackViewController)

#pragma mark - Accessors

- (MTStackViewController *)stackViewController
{
    MTStackViewController *stackViewController = objc_getAssociatedObject(self, &MTStackViewControllerKey);
    
    if (!stackViewController && [self parentViewController] != nil)
    {
        stackViewController = [[self parentViewController] stackViewController];
    }
    
    return stackViewController;
}

- (void)setStackViewController:(MTStackViewController *)stackViewController
{
    objc_setAssociatedObject(self, &MTStackViewControllerKey, stackViewController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation MTStackContainerView

- (void)setContentView:(UIView *)contentView
{
    [self addSubview:contentView];
}

- (void)stackViewController:(MTStackViewController*)stackViewController
                       show:(BOOL)show side:(MTStackViewControllerPosition)side
                    toFrame:(CGRect)rect withDuration:(CGFloat)duration
{
    
}

- (void)stackViewController:(MTStackViewController *)stackViewController animateToFrame:(CGRect)rect side:(MTStackViewControllerPosition)side withOffset:(CGFloat)offset
{
    
}

@end

@implementation MTStackContentContainerView

#pragma mark - UIView Overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizingMask:(UIViewAutoresizing)(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
        [self setAutoresizesSubviews:YES];

        [self.layer setRasterizationScale:[UIScreen mainScreen].scale];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:[self bounds]];
    [[self layer] setShadowPath:[shadowPath CGPath]];
}

@end

#pragma mark - VPStackNavigationController

@interface MTStackViewController ()
{
    CGPoint _initialPanGestureLocation;
    CGRect _initialContentControllerFrame;
    UITapGestureRecognizer *_tapGestureRecognizer;
}

// Added property to enable private variable exposed.
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@interface MTStackViewController () <UIGestureRecognizerDelegate>

@end

@implementation MTStackViewController
@synthesize panGestureRecognizer = _panGestureRecognizer;

#pragma mark - UIViewController Overrides

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		[self setup];
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
		[self setup];
    }
    return self;
}

- (void)setup
{
    CGRect screenBounds = [self screenBounds];
    
    _swipeVelocity = 500.0f;
    
    _leftViewControllerEnabled = YES;
    _rightViewControllerEnabled = NO;
    _leftSnapThreshold = screenBounds.size.width / 2.0f;
    _rasterizesViewsDuringAnimation = NO;
    
    [self setSlideOffset:roundf(screenBounds.size.width * 0.8f)];
    
    _leftContainerView = [[MTStackDefaultContainerView alloc] initWithFrame:screenBounds];
    _rightContainerView = [[MTStackDefaultContainerView alloc] initWithFrame:screenBounds];
    _contentContainerView = [[MTStackContentContainerView alloc] initWithFrame:screenBounds];
    
    UIView *transitionView = [[UIView alloc] initWithFrame:screenBounds];
    [_contentContainerView addSubview:transitionView];
  
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerDidTap:)];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidPan:)];
    [_panGestureRecognizer setCancelsTouchesInView:YES];
    [_panGestureRecognizer setDelegate:self];
    [self.contentContainerView addGestureRecognizer:_panGestureRecognizer];
    
    _screenEdgeGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidPan:)];
    [_screenEdgeGestureRecognizer setEdges:UIRectEdgeLeft];
    [_screenEdgeGestureRecognizer setCancelsTouchesInView:YES];
    [_screenEdgeGestureRecognizer setDelegate:self];
    [self.contentContainerView addGestureRecognizer:_screenEdgeGestureRecognizer];

    [self setSlideAnimationDuration:0.3f];
    [self setTrackingAnimationDuration:0.05f];
    [self setMinShadowRadius:3.0f];
    [self setMaxShadowRadius:10.0f];
    [self setMinShadowOpacity:0.5f];
    [self setMaxShadowOpacity:1.0f];
    [self setShadowOffset:CGSizeZero];
    [self setShadowColor:[UIColor blackColor]];
    [self setShouldCloseRevealedViewControllerOnTap:YES];
    [self setShouldDisableTouchesOnContentViewOnReveal:YES];
    [self setShouldResizeContentViewOnReveal:NO];
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    frame.size.height -= MIN(statusBarFrame.size.width, statusBarFrame.size.height);
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view setAutoresizesSubviews:YES];
    [view setAutoresizingMask:(UIViewAutoresizing)(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];

    self.leftContainerView.frame = view.bounds;
    [view addSubview:self.leftContainerView];
    
    float frameWidth = CGRectGetWidth(view.frame);
    self.rightContainerView.frame = CGRectMake(frameWidth - self.slideOffset,
                                               0.0f, frameWidth,
                                               CGRectGetHeight(view.frame));
    [view addSubview:self.rightContainerView];

    [_contentContainerView setFrame:[view bounds]];
    [view addSubview:_contentContainerView];
    
    [self setView:view];
}

#pragma mark - Accessors

- (UITapGestureRecognizer *)tapGestureRecognizer
{
    return _tapGestureRecognizer;
}

- (void)setNoSimultaneousPanningViewClasses:(NSArray *)noSimultaneousPanningViewClasses
{
    _noSimultaneousPanningViewClasses = [noSimultaneousPanningViewClasses copy];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    for (id object in [self noSimultaneousPanningViewClasses])
    {
        NSAssert(class_isMetaClass(object_getClass(object)), @"Objects in this array must be of type 'Class'");
        NSAssert([(Class)object isSubclassOfClass:[UIView class]], @"Class objects in this array must be UIView subclasses");
    }
#pragma clang diagnostic pop
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    _shadowColor = [shadowColor copy];
    [[_contentContainerView layer] setShadowColor:[[self shadowColor] CGColor]];
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    _shadowOffset = shadowOffset;
    [[_contentContainerView layer] setShadowOffset:[self shadowOffset]];
}

- (void)setMinShadowRadius:(CGFloat)minShadowRadius
{
    _minShadowRadius = minShadowRadius;
    if ([self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
    }
}

- (void)setMaxShadowRadius:(CGFloat)maxShadowRadius
{
    _maxShadowRadius = maxShadowRadius;
    if (![self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius]];
    }
}

- (void)setMinShadowOpacity:(CGFloat)minShadowOpacity
{
    _minShadowOpacity = minShadowOpacity;
    if ([self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
    }
}

- (void)setMaxShadowOpacity:(CGFloat)maxShadowOpacity
{
    _maxShadowOpacity = maxShadowOpacity;
    if (![self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowOpacity:[self maxShadowOpacity]];
    }
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    
    if (!_contentContainerView.separatorView)
    {
        CGRect frame = CGRectMake(-1,
                                  0,
                                  1,
                                  CGRectGetHeight(self.view.frame));

        UIView *separatorView = [[UIView alloc] initWithFrame:frame];
        [separatorView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [_contentContainerView addSubview:separatorView];
        _contentContainerView.separatorView = separatorView;
    }
    
    _contentContainerView.separatorView.backgroundColor = separatorColor;

}

- (void)setLeftViewController:(UIViewController *)leftViewController
{
    [self setViewController:leftViewController position:MTStackViewControllerPositionLeft];
}

- (void)setRightViewController:(UIViewController *)rightViewController
{
    [self setViewController:rightViewController position:MTStackViewControllerPositionRight];
}

- (void)setViewController:(UIViewController *)newViewController position:(MTStackViewControllerPosition)position
{
    UIViewController* currentViewController;
    MTStackContainerView* containerView;
    
    switch (position) {
        case MTStackViewControllerPositionLeft:
            currentViewController = [self leftViewController];
            containerView = self.leftContainerView;
            _leftViewController = newViewController;
            break;
        case MTStackViewControllerPositionRight:
            currentViewController = [self rightViewController];
            containerView = self.rightContainerView;
            _rightViewController = newViewController;
            break;
    }
    
    if (newViewController)
    {
        [newViewController setStackViewController:self];
        [newViewController.view setFrame:[containerView bounds]];
        [self addChildViewController:newViewController];

        if (currentViewController)
        {
            [self transitionFromViewController:currentViewController toViewController:newViewController duration:0.0f options:0 animations:nil completion:^(BOOL finished) {
                [newViewController didMoveToParentViewController:self];
                [currentViewController removeFromParentViewController];
                [currentViewController setStackViewController:nil];
            }];
        }
        else
        {
            [containerView setContentView:[newViewController view]];
            [newViewController didMoveToParentViewController:self];
        }
    }
    else if (currentViewController)
    {
        [[currentViewController view] removeFromSuperview];
        [currentViewController removeFromParentViewController];
        [currentViewController setStackViewController:nil];
    }
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    [self setContentViewController:contentViewController snapToContentViewController:YES animated:YES];
}

- (BOOL)isLeftViewControllerVisible
{
    return CGRectGetMinX([_contentContainerView frame]) == [self slideOffset];
}

- (BOOL)isRightViewControllerVisible
{
    BOOL isVisible = CGRectGetMinX([_contentContainerView frame]) == -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]);
    if (self.shouldResizeContentViewOnReveal)
    {
      isVisible = CGRectGetWidth([_contentContainerView frame]) < CGRectGetWidth(self.view.bounds);
    }
    return isVisible;
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (void)panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldPan = [self contentContainerView:_contentContainerView panGestureRecognizerShouldPan:panGestureRecognizer];
    
    if (shouldPan)
    {
        [self contentContainerView:_contentContainerView panGestureRecognizerDidPan:panGestureRecognizer];
    }
    
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view.superview isKindOfClass:[UITableViewCell class]])  {
        return (self.percentRevealed == 0);
    }
    
    BOOL shouldRecognize = YES;
 
    if ([[[otherGestureRecognizer view] superview] isKindOfClass:[UISwitch class]])
    {
        shouldRecognize = NO;
    }
    
    if (self.percentRevealed == 0 && [otherGestureRecognizer.view.superview isKindOfClass:[UITableViewCell class]])  {
        return YES;
    }
    for (Class class in [self noSimultaneousPanningViewClasses])
    {
        if ([[otherGestureRecognizer view] isKindOfClass:class] || [[[otherGestureRecognizer view] superview] isKindOfClass:class])
        {
            shouldRecognize = NO;
        }
    }
    
    return shouldRecognize;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _panGestureRecognizer && ![self isLeftViewControllerVisible])
    {
        return NO;
    }
    BOOL shouldBegin = [self contentContainerView:_contentContainerView panGestureRecognizerShouldPan:(UIPanGestureRecognizer *)gestureRecognizer];
  
    id <MTStackChildViewController> navigationChild = [self stackChildViewControllerForViewController:[self contentViewController]];
    if ([navigationChild respondsToSelector:@selector(shouldBeginPanningWithPanGestureRecognizer:)])
    {
      NSAssert([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]], @"This is only for panGestureRecognizer delegate. I am: %@", gestureRecognizer);
      shouldBegin = [navigationChild shouldBeginPanningWithPanGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer];
    }
  
    return shouldBegin;
}

#pragma mark - Instance Methods

- (void)tapGestureRecognizerDidTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if ([self isLeftViewControllerVisible])
    {
        [self hideLeftViewController];
    }
    else if ([self isRightViewControllerVisible])
    {
        [self hideRightViewController];
    }
}

- (void)setContentViewController:(UIViewController *)contentViewController hideLeftViewController:(BOOL)hideLeftViewController animated:(BOOL)animated
{
    [self setContentViewController:contentViewController snapToContentViewController:hideLeftViewController animated:animated];
}

- (void)setContentViewController:(UIViewController *)contentViewController snapToContentViewController:(BOOL)snapToContentViewController animated:(BOOL)animated
{
    UIViewController *currentContentViewController = [self contentViewController];
    
    _contentViewController = contentViewController;
    
    if ([self contentViewController])
    {
        [[self contentViewController] setStackViewController:self];
        [self addChildViewController:[self contentViewController]];
        self.contentViewController.view.frame = _contentContainerView.bounds;
        
        if (currentContentViewController)
        {
            [self transitionFromViewController:currentContentViewController toViewController:[self contentViewController] duration:[self contentViewControllerAnimationDuration] options:[self contentViewControllerAnimationOption] animations:nil completion:^(BOOL finished) {

                [self.contentViewController didMoveToParentViewController:self];

                [currentContentViewController removeFromParentViewController];
                [currentContentViewController setStackViewController:nil];
                if (snapToContentViewController)
                {
                    if ([self isLeftViewControllerVisible])
                    {
                        [self hideLeftViewControllerAnimated:animated];
                    }
                    else if ([self isRightViewControllerVisible])
                    {
                        [self hideRightViewControllerAnimated:animated];
                    }
                    else
                    {
                        [self setContentViewUserInteractionEnabled:YES];
                    }
                }
            }];
        }
        else
        {
            [_contentContainerView addSubview:[[self contentViewController] view]];
            [self.contentViewController didMoveToParentViewController:self];

            if (snapToContentViewController)
            {
                if ([self isLeftViewControllerVisible])
                {
                    [self hideLeftViewControllerAnimated:animated];
                }
                else if ([self isRightViewControllerVisible])
                {
                    [self hideRightViewControllerAnimated:animated];
                }
                else
                {
                    [self setContentViewUserInteractionEnabled:YES];
                }
            }
        }
    }
    else if (currentContentViewController)
    {
        [[currentContentViewController view] removeFromSuperview];
        [currentContentViewController removeFromParentViewController];
        [currentContentViewController setStackViewController:nil];
        if (snapToContentViewController)
        {
            if ([self isLeftViewControllerVisible])
            {
                [self hideLeftViewControllerAnimated:animated];
            }
            else if ([self isRightViewControllerVisible])
            {
                [self hideRightViewControllerAnimated:animated];
            }
            else
            {
                [self setContentViewUserInteractionEnabled:YES];
            }
        }
    }
}

- (void)panWithPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint location = [panGestureRecognizer locationInView:[self view]];
    
    if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:NO];
    }
    else if (CGRectGetMinX([_contentContainerView frame]) < 0.0f ||
             (CGRectGetWidth([_contentContainerView frame]) < CGRectGetWidth(self.view.bounds) && self.shouldResizeContentViewOnReveal))
      
    {
        [_rightContainerView setHidden:NO];
        [_leftContainerView setHidden:YES];
    }
    else
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:YES];
    }
    
    MTStackViewControllerPosition side = CGRectGetMinX([_contentContainerView frame]) >= 0.0f ? MTStackViewControllerPositionLeft : MTStackViewControllerPositionRight;
    if (self.shouldResizeContentViewOnReveal && CGRectGetMinX([_contentContainerView frame]) <= 0.0f && CGRectGetWidth([_contentContainerView frame]) < CGRectGetWidth(self.view.bounds))
    {
        side = MTStackViewControllerPositionRight;
    }
  
    MTStackContainerView *containerView;
    CGRect containerFrame;
    switch(side)
    {
        case MTStackViewControllerPositionLeft:
            containerView = _leftContainerView;
            containerFrame = [_leftContainerView frame];
            containerFrame.origin.x = 0.0f;
            break;
        case MTStackViewControllerPositionRight:
            containerView = _rightContainerView;
            containerFrame = [_rightContainerView frame];
            containerFrame.origin.x = CGRectGetWidth(self.view.bounds) - [self slideOffset];
            break;
    }
  
    CGRect contentViewRect = [_contentContainerView frame];
    CGFloat xDifference = _initialPanGestureLocation.x - location.x;
    CGFloat contentViewFrameX = CGRectGetMinX(_initialContentControllerFrame) - xDifference;
    if (contentViewFrameX < -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]))
    {
      contentViewFrameX = -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]);
    }
    if (contentViewFrameX > [self slideOffset])
    {
      contentViewFrameX = [self slideOffset];
    }
  
    // Depending whether we are resizing of sliding, set the appropriate rect's component
    if (self.shouldResizeContentViewOnReveal)
    {
        contentViewRect.size.width = CGRectGetWidth(_initialContentControllerFrame) + contentViewFrameX;
      
        // OK, this is for the rolling up (pan to the right) -- patch
        // to not be able to roll out below the slideOffset
        if (contentViewRect.size.width <= [self slideOffset] && contentViewFrameX <= 0)
        {
          contentViewRect.size.width = [self slideOffset];
          contentViewFrameX = 0.0f;
        }
    }
    else
    {
        contentViewRect.origin.x = contentViewFrameX;
    }
    
    if (([self isLeftViewControllerEnabled] && contentViewFrameX > 0.0f) ||
        ([self isRightViewControllerEnabled] && contentViewFrameX < 0.0f) ||
        ([self isRightViewControllerEnabled] && self.shouldResizeContentViewOnReveal && contentViewFrameX > 0.0f))
    {
        _percentRevealed = (fabs(contentViewFrameX) / [self slideOffset]);
      
        // Since we are rolling out to the right (revealing the content view controller)
        // swap the percent revealed
        if ([self isRightViewControllerEnabled] && self.shouldResizeContentViewOnReveal && contentViewFrameX > 0.0f)
        {
          _percentRevealed = 1 - _percentRevealed;
        }
        
        [containerView stackViewController:self animateToFrame:containerFrame side:side withOffset:_percentRevealed];

        [UIView animateWithDuration:[self trackingAnimationDuration]
                              delay:0.0f
                            options:(UIViewAnimationOptions)(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             
                             [[self contentContainerView] setFrame:contentViewRect];
                             

                             [[[self contentContainerView] layer] setShadowRadius:[self maxShadowRadius] - (([self maxShadowRadius] - [self minShadowRadius]) * [self percentRevealed])];
                             [[[self contentContainerView] layer] setShadowOpacity:1.0f - (0.5 * [self percentRevealed])];
                             
                         } completion:^(BOOL finished) {
                             
                             id <MTStackChildViewController> childViewController = [self stackChildViewControllerForViewController:[self contentViewController]];
                             if ([childViewController respondsToSelector:@selector(stackViewController:didPanToOffset:)])
                             {
                                  // Depending on whether it should resize slide,
                                  // pass in the right offset
                                  CGFloat offset = CGRectGetMinX([[self contentContainerView] frame]);
                                  if (self.shouldResizeContentViewOnReveal)
                                  {
                                      offset = CGRectGetWidth([[self contentContainerView] frame]);
                                  }
                                  [childViewController stackViewController:self didPanToOffset:offset];
                             }
                             
                         }];
    } else {
        _percentRevealed = 0;
    }
}

- (void)endPanning
{
    [self snapContentViewController];
}

- (void)snapContentViewController
{
    CGFloat contentWidth = CGRectGetWidth([_contentContainerView frame]);
    CGFloat thresholdWidth = CGRectGetWidth(self.view.bounds) - self.slideOffset/2.0f;
    if (CGRectGetMinX([_contentContainerView frame]) <= _leftSnapThreshold && CGRectGetMinX([_contentContainerView frame]) >= 0.0f
        && contentWidth > thresholdWidth )
    {
        [self hideLeftViewControllerAnimated:YES];
    }
    else if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
    {
        [self revealLeftViewControllerAnimated:YES];
    }
    else if (CGRectGetMaxX([_contentContainerView frame]) <= CGRectGetWidth([_contentContainerView frame]) / 2.0f ||
             (self.shouldResizeContentViewOnReveal && CGRectGetWidth([_contentContainerView frame]) <= CGRectGetWidth(self.view.bounds)))
    {
        [self revealRightViewControllerAnimated:YES];
    }
    else
    {
        [self hideRightViewController];
    }
}

- (void)revealLeftViewController
{
    [self revealLeftViewControllerAnimated:YES];
}

- (void)revealLeftViewControllerAnimated:(BOOL)animated
{
    if ([self isLeftViewControllerEnabled])
    {
        //TODO: Resize is not yet supported on the left VC.
        NSAssert((self.shouldResizeContentViewOnReveal == NO), @"Resize content view when reveal with the left view controller is not yet supported.");
      
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:NO];
        
        [self setShadowOffset:CGSizeMake(-1.0f, 0.0f)];
        
        if ([self rasterizesViewsDuringAnimation])
        {
            [[_contentContainerView layer] setShouldRasterize:YES];
            [[_leftContainerView layer] setShouldRasterize:YES];
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        NSTimeInterval animationDuration = 0.0f;
        
        if (animated)
        {
            if ([self animationDurationProportionalToPosition])
            {
                animationDuration = [self slideAnimationDuration] * ([self slideOffset] - [_contentContainerView frame].origin.x) / [self slideOffset];
                animationDuration = fmax(animationDuration, 0.15f);
            }
            else
                animationDuration = [self slideAnimationDuration];
        }
        
        
        CGRect containerFrame = CGRectMake(0.0f,
                                           CGRectGetMinY([_leftContainerView frame]),
                                           CGRectGetWidth([_leftContainerView frame]),
                                           CGRectGetHeight([_leftContainerView frame]));
        [self.leftContainerView stackViewController:self show:YES
                                               side:MTStackViewControllerPositionRight
                                            toFrame:containerFrame
                                       withDuration:animationDuration];
        
        [UIView animateWithDuration:animationDuration
                              delay:0.0f
                            options:(UIViewAnimationOptions)(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             
                             [[self contentContainerView] setFrame:CGRectMake([self slideOffset],
                                                                        CGRectGetMinY([[self contentContainerView] frame]),
                                                                        CGRectGetWidth([[self contentContainerView] frame]),
                                                                        CGRectGetHeight([[self contentContainerView] frame]))];
                             
                             
                             [[[self contentContainerView] layer] setShadowRadius:[self minShadowRadius]];
                             [[[self contentContainerView] layer] setShadowOpacity:[self minShadowOpacity]];
                             
                         } completion:^(BOOL finished) {
                             
                             if ([self rasterizesViewsDuringAnimation])
                             {
                                 [[[self contentContainerView] layer] setShouldRasterize:NO];
                                 [[[self leftContainerView] layer] setShouldRasterize:NO];
                                 [[[self rightContainerView] layer] setShouldRasterize:NO];
                             }
                             
                             [self setContentViewUserInteractionEnabled:NO];
                           
                              // Only add the tapGestureRecognizer when the `shouldCloseRevealedViewControllerOnTap` is YES.
                              if (self.shouldCloseRevealedViewControllerOnTap)
                              {
                                  [_contentContainerView addGestureRecognizer:_tapGestureRecognizer];
                              }
                           
                              if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealLeftViewController:)])
                              {
                                 [[self delegate] stackViewController:self didRevealLeftViewController:[self leftViewController]];
                              }
                             
                         }];
    }
}

- (void)revealRightViewController
{
    [self revealRightViewControllerAnimated:YES];
}

- (void)revealRightViewControllerAnimated:(BOOL)animated
{
    if ([self isRightViewControllerEnabled])
    {
        [_rightContainerView setHidden:NO];
        [_leftContainerView setHidden:YES];
        
        [self setShadowOffset:CGSizeMake(1.0f, 0.0f)];
        
        if ([self rasterizesViewsDuringAnimation])
        {
            [[_contentContainerView layer] setShouldRasterize:YES];
            [[_leftContainerView layer] setShouldRasterize:YES];
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        CGRect containerFrame = [_rightContainerView frame];
        containerFrame.origin.x = CGRectGetWidth(self.view.bounds) - [self slideOffset];
      
        [self.rightContainerView stackViewController:self show:YES
                                                side:MTStackViewControllerPositionRight
                                             toFrame:containerFrame
                                        withDuration:self.slideAnimationDuration];
      
        // Calculate the frame.
        CGFloat finalX = -CGRectGetWidth([_contentContainerView bounds]) + CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset];
        CGFloat finalWidth = CGRectGetWidth([_contentContainerView frame]);
        if (self.shouldResizeContentViewOnReveal)
        {
            // if we are resizing, the origin X stays and the width has to be substracted with the
            // slideCutOff
            finalX = CGRectGetMinX(self.view.bounds);
            finalWidth = CGRectGetWidth(self.view.bounds) - [self slideOffset];
        }
        CGRect finalFrame = CGRectMake(finalX, CGRectGetMinY([_contentContainerView frame]), finalWidth, CGRectGetHeight([_contentContainerView frame]));
      
        [UIView animateWithDuration:animated ? [self slideAnimationDuration] : 0.0f
                              delay:0.0f
                            options:(UIViewAnimationOptions)(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             
                             [[self contentContainerView] setFrame:finalFrame];
                             [[[self contentContainerView] layer] setShadowRadius:[self minShadowRadius]];
                             [[[self contentContainerView] layer] setShadowOpacity:[self minShadowOpacity]];
                             
                         } completion:^(BOOL finished) {
                             
                             if ([self rasterizesViewsDuringAnimation])
                             {
                                 [[[self contentContainerView] layer] setShouldRasterize:NO];
                                 [[[self leftContainerView] layer] setShouldRasterize:NO];
                                 [[[self rightContainerView] layer] setShouldRasterize:NO];
                             }
                             [self setContentViewUserInteractionEnabled:NO];

                              // Only add the tapGestureRecognizer when the `shouldCloseRevealedViewControllerOnTap` is YES.
                              if (self.shouldCloseRevealedViewControllerOnTap)
                              {
                                  [_contentContainerView addGestureRecognizer:_tapGestureRecognizer];
                              }
                             
                              if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealRightViewController:)])
                              {
                                  [[self delegate] stackViewController:self didRevealRightViewController:[self rightViewController]];
                              }
                             
                         }];
    }
}

- (void)hideLeftViewController
{
    [self hideLeftViewControllerAnimated:YES];
}

- (void)hideLeftViewControllerAnimated:(BOOL)animated
{
    [self hideLeftOrRightViewControllerAnimated:animated];
}

- (void)hideRightViewController
{
    [self hideRightViewControllerAnimated:YES];
}

- (void)hideRightViewControllerAnimated:(BOOL)animated
{
    [self hideLeftOrRightViewControllerAnimated:animated];
}

- (void)hideLeftOrRightViewControllerAnimated:(BOOL)animated
{
    if ([self rasterizesViewsDuringAnimation])
    {
        [[_contentContainerView layer] setShouldRasterize:YES];
        [[_leftContainerView layer] setShouldRasterize:YES];
        [[_rightContainerView layer] setShouldRasterize:YES];
    }
    
    NSTimeInterval animationDuration = 0.0f;
    
    if (animated)
    {
        if ([self animationDurationProportionalToPosition])
        {
            if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
            {
                animationDuration = [self slideAnimationDuration] * (CGRectGetMinX([_contentContainerView frame]) / [self slideOffset]);
            } 
            else
            {
                animationDuration = [self slideAnimationDuration] * ((CGRectGetWidth([_contentContainerView bounds]) - CGRectGetMaxX([_contentContainerView frame])) / [self slideOffset]);
            }
            animationDuration = fmax(0.15f, animationDuration);
        }
        else
        {
            animationDuration = [self slideAnimationDuration];
        }
    }

    //TODO: Do the same with the left (if resizeContentViewWhenReveal is `NO`)
    CGRect leftFrame = CGRectMake(0.0f, CGRectGetMinY([_leftContainerView frame]),
        CGRectGetWidth([_leftContainerView frame]), CGRectGetHeight([_leftContainerView frame]));
    
    CGRect rightFrame = [_rightContainerView frame];
    if (self.shouldResizeContentViewOnReveal == NO)
    {
        rightFrame.origin.x = CGRectGetWidth(_contentContainerView.frame) - self.slideOffset;
    }
  
    CGRect contentFrame = [_contentContainerView frame];
    contentFrame.origin.x = 0.0f;
    if (self.shouldResizeContentViewOnReveal)
    {
        contentFrame.size.width = CGRectGetWidth(self.view.bounds);
    }
    
    [self.leftContainerView stackViewController:self show:NO
                                           side:MTStackViewControllerPositionLeft
                                        toFrame:leftFrame
                                   withDuration:animationDuration];
    
    [self.rightContainerView stackViewController:self show:NO
                                            side:MTStackViewControllerPositionRight
                                         toFrame:rightFrame
                                    withDuration:animationDuration];
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0f
                        options:(UIViewAnimationOptions)(UIViewAnimationOptionCurveEaseOut |UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         [[self contentContainerView] setFrame:contentFrame];
                       
                          // Only does this animation when we are sliding, otherwise its
                          // going to negate the "paralax" effect on the container view.
                          if (self.shouldResizeContentViewOnReveal == NO)
                          {
                              [[[self contentContainerView] layer] setShadowRadius:[self maxShadowRadius]];
                              [[[self contentContainerView] layer] setShadowOpacity:[self maxShadowOpacity]];
                          }
                     } completion:^(BOOL finished) {
                         if ([self rasterizesViewsDuringAnimation])
                         {
                             [[[self contentContainerView] layer] setShouldRasterize:NO];
                             [[[self leftContainerView] layer] setShouldRasterize:NO];
                             [[[self rightContainerView] layer] setShouldRasterize:NO];
                         }
                         
                         [self setContentViewUserInteractionEnabled:YES];
                         [[self contentContainerView] removeGestureRecognizer:[self tapGestureRecognizer]];
                         
                         if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealContentViewController:)])
                         {
                             [[self delegate] stackViewController:self didRevealContentViewController:[self contentViewController]];
                         }
                     }];
}

- (void)toggleLeftViewController
{
    [self toggleLeftViewControllerAnimated:YES];
}

- (void)toggleLeftViewControllerAnimated:(BOOL)animated
{
    if ([self isLeftViewControllerVisible])
    {
        [self hideLeftViewControllerAnimated:animated];
    }
    else
    {
        [self revealLeftViewControllerAnimated:animated];
    }
}

- (void)toggleLeftViewController:(id)sender event:(UIEvent *)event
{
    [self toggleLeftViewController];
}

- (void)toggleRightViewController
{
    [self toggleRightViewControllerAnimated:YES];
}

- (void)toggleRightViewControllerAnimated:(BOOL)animated
{
    if ([self isRightViewControllerVisible])
    {
        [self hideRightViewControllerAnimated:animated];
    }
    else
    {
        [self revealRightViewControllerAnimated:animated];
    }
}

- (void)toggleRightViewController:(id)sender event:(UIEvent *)event
{
    [self toggleRightViewController];
}

- (void)setContentViewUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    if (self.shouldDisableTouchesOnContentViewOnReveal == NO && userInteractionEnabled == NO)
    {
        // Dont disable any user interaction on contentView if the value of `shouldDisableTouchesOnContentViewOnReveal`
        // is `NO`
        return;
    }
  
    UIViewController *contentViewController = [self contentViewController];
    if ([contentViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)contentViewController;
        
        if ([[navigationController viewControllers] count] > 1 && [self disableNavigationBarUserInterationWhenDrilledDown])
        {
            [[navigationController view] setUserInteractionEnabled:userInteractionEnabled];
        }
        else if ([[navigationController viewControllers] count])
        {
            UIViewController *currentViewController = [[navigationController viewControllers] lastObject];
            [[currentViewController view] setUserInteractionEnabled:userInteractionEnabled];
        }
    }
    else
    {
        [[[self contentViewController] view] setUserInteractionEnabled:userInteractionEnabled];
    }
}

#pragma mark - VPStackContentContainerView Methods

- (id <MTStackChildViewController>)stackChildViewControllerForViewController:(UIViewController *)childViewController
{
    id <MTStackChildViewController> navigationChild = nil;
    
    if ([childViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)childViewController;
        if ([navigationController conformsToProtocol:@protocol(MTStackChildViewController)])
        {
            navigationChild = (id <MTStackChildViewController>)navigationController;
        }
        else if ([[navigationController viewControllers] count])
        {
            UIViewController *viewController = [[navigationController viewControllers] lastObject];
            if ([viewController conformsToProtocol:@protocol(MTStackChildViewController)])
            {
                navigationChild = (id <MTStackChildViewController>)viewController;
            }
        }
    }
    else if ([childViewController isKindOfClass:[UIViewController class]])
    {
        if ([childViewController conformsToProtocol:@protocol(MTStackChildViewController)])
        {
            navigationChild = (id <MTStackChildViewController>)childViewController;
        }
    }
    
    return navigationChild;
}

- (BOOL)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerShouldPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldPan = YES;
    
    if ([self disableSwipeWhenContentNavigationControllerDrilledDown] &&
        [_contentViewController isKindOfClass:[UINavigationController class]] &&
        [[(UINavigationController *)_contentViewController viewControllers] count] > 1)
    {
        shouldPan = NO;
    }
    else
    {
        id <MTStackChildViewController> navigationChild = [self stackChildViewControllerForViewController:[self contentViewController]];
        
        if (navigationChild)
        {
            shouldPan = [navigationChild shouldAllowPanning];
        }
        
        if (shouldPan)
        {
            CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
            if (!_rightViewControllerEnabled &&
                (velocity.x < 0.0) &&
                (_contentContainerView.frame.origin.x == 0))
            {
                shouldPan = NO;
            }
            else if (!_leftViewControllerEnabled &&
                     (velocity.x > 0.0) &&
                     (_contentContainerView.frame.origin.x == 0))
            {
                shouldPan = NO;
            }
        }
        
    }
    
    return shouldPan;
}

- (CGRect)screenBounds
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (UIInterfaceOrientationIsLandscape([self interfaceOrientation]))
        screenBounds.size = CGSizeMake(screenBounds.size.height, screenBounds.size.width);
    
    return screenBounds;
}

- (void)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch ([panGestureRecognizer state])
    {
        case UIGestureRecognizerStateEnded:
        {
            if (![self handleSwipe:panGestureRecognizer])
            {
                [self endPanning];
            }
            id <MTStackChildViewController> controller = [self stackChildViewControllerForViewController:[self contentViewController]];
            if ([controller respondsToSelector:@selector(stackViewControllerDidEndPanning:)])
            {
                [controller stackViewControllerDidEndPanning:self];
            }
        }
            break;
        case UIGestureRecognizerStateBegan:
        {
            if ([self rasterizesViewsDuringAnimation])
            {
                [[_contentContainerView layer] setShouldRasterize:YES];
                [[_leftContainerView layer] setShouldRasterize:YES];
                [[_rightContainerView layer] setShouldRasterize:YES];
            }
            _initialPanGestureLocation = [panGestureRecognizer locationInView:[self view]];
            _initialContentControllerFrame = [_contentContainerView frame];
            id <MTStackChildViewController> controller = [self stackChildViewControllerForViewController:[self contentViewController]];
            if ([controller respondsToSelector:@selector(stackViewControllerWillBeginPanning:)])
            {
                [controller stackViewControllerWillBeginPanning:self];
            }
        }
        case UIGestureRecognizerStateChanged:
            [self panWithPanGestureRecognizer:panGestureRecognizer];
            break;
        default:
            break;
    }
}

-(void)setLeftContainerView:(MTStackContainerView *)leftContainerView
{
    NSAssert(leftContainerView, @"New view can not be nil");
    // Force the view to load if it hasn't
    CGRect frame = self.view.frame;
    _leftContainerView.frame = frame;
    [self.leftContainerView removeFromSuperview];

    
    _leftContainerView = leftContainerView;
    if(self.leftViewController)
    {
        [self.leftViewController.view removeFromSuperview];
        [self.leftContainerView setContentView:self.leftViewController.view];
    }
    [self.view addSubview:_leftContainerView];
    [self.view bringSubviewToFront:self.contentContainerView];
}

-(void)setRightContainerView:(MTStackContainerView *)rightContainerView
{
    NSAssert(rightContainerView, @"New view can not be nil");
    // Force the view to load if it hasn't
    CGRect frame = self.view.frame;
    _rightContainerView.frame = frame;

    [self.rightContainerView removeFromSuperview];
    
    _rightContainerView = rightContainerView;
    if(self.rightViewController)
    {
        [self.rightViewController.view removeFromSuperview];
        [self.rightContainerView setContentView:self.rightViewController.view];
    }
    [self.view addSubview:_rightContainerView];
    [self.view bringSubviewToFront:self.contentContainerView];
}

- (BOOL)handleSwipe:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL didSwipe = NO;
    CGFloat velocity = [panGestureRecognizer velocityInView:[self view]].x;
    if (velocity >= [self swipeVelocity])
    {
        if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
        {
            [self revealLeftViewController];
        }
        else
        {
            [self hideRightViewController];
        }
        didSwipe = YES;
    }
    else if (velocity <= [self swipeVelocity] * -1.0f)
    {
        if (CGRectGetMinX([_contentContainerView frame]) < 0.0f ||
            (CGRectGetWidth([_contentContainerView frame]) < CGRectGetWidth(self.view.bounds) && self.shouldResizeContentViewOnReveal))
        {
            [self revealRightViewController];
        }
        else
        {
            [self hideLeftViewController];
        }
        didSwipe = YES;
    }
    
    return didSwipe;
}

// Defaults to portrait only, subclass and override these methods, if you want to support landscape
// Also make sure your content view controller overrides these methods to support registration, so it resizes correctly
// for UINavigationController, the autoresizing mask needs to be flexible width and height (may need to be set in viewWillAppear:)

#pragma mark - Support Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
