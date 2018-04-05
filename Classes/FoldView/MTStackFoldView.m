//
//  MTStackFoldView.m
//  MTStackViewControllerExample
//
//  Created by Jeff Ward on 6/20/13.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//

#import "MTStackFoldView.h"

#import "UIView+Screenshot.h"

@interface MTStackFoldView()

@property (nonatomic, strong) UIView* contentView;

@end

@implementation MTStackFoldView

- (id)initWithFrame:(CGRect)frame foldDirection:(FoldDirection)foldDirection
{
    self = [super initWithFrame:frame];
    if (self) {
        _useOptimizedScreenshot = YES;
        _foldDirection = foldDirection;
        
        // foldview consists of leftView & rightView (or topView & bottomView), and a content view
        // set shadow direction of leftView and rightView such that the shadow falls on the fold in the middle
        
        // content view holds a subview which is the actual displayed content
        // contentView is required as a wrapper of the original content because it is better to take a screenshot of the wrapper view layer
        // taking a screenshot of a tableview layer directly for example, may end up with blank view because of recycled cells
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,frame.size.width,frame.size.height)];
        [_contentView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_contentView];
        
       // set anchor point of the leftView to the left edge
        _leftView = [[FacingView alloc] initWithFrame:CGRectMake(-1*frame.size.width/4,0,frame.size.width/2,frame.size.height)];
        [_leftView setBackgroundColor:[UIColor colorWithWhite:0.99 alpha:1]];
        [_leftView.layer setAnchorPoint:CGPointMake(0.0, 0.5)];
        [self addSubview:_leftView];
        [_leftView.shadowView setColorArrays:[NSArray arrayWithObjects:[UIColor colorWithWhite:0 alpha:0.05],[UIColor colorWithWhite:0 alpha:0.6], nil]];
        
        // set anchor point of the rightView to the right edge
        _rightView = [[FacingView alloc] initWithFrame:CGRectMake(-1*frame.size.width/4,0,frame.size.width/2,frame.size.height)];
        [_rightView setBackgroundColor:[UIColor colorWithWhite:0.99 alpha:1]];
        [_rightView.layer setAnchorPoint:CGPointMake(1.0, 0.5)];
        [self addSubview:_rightView];
        [_rightView.shadowView setColorArrays:[NSArray arrayWithObjects:[UIColor colorWithWhite:0 alpha:0.9],[UIColor colorWithWhite:0 alpha:0.55], nil]];
        
        // set perspective of the transformation
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1/500.0;
        [self.layer setSublayerTransform:transform];
        
        // make sure the views are closed properly when initialized
        [_leftView.layer setTransform:CATransform3DMakeRotation((M_PI / 2), 0, 1, 0)];
        [_rightView.layer setTransform:CATransform3DMakeRotation((M_PI / 2), 0, 1, 0)];

    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self sendSubviewToBack:self.contentView];
}

- (void)setContentView:(UIView *)contentView
{
    if(_contentView)
    {
        [_contentView removeFromSuperview];
    }
    _contentView = contentView;
    [self insertSubview:contentView atIndex:0];
    [self drawScreenshotOnFolds];
}


- (void)drawScreenshotOnFolds
{
    UIImage *image = [self.contentView screenshotWithOptimization:self.useOptimizedScreenshot];
    [self setImage:image];
}

- (void)setImage:(UIImage*)image
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width*image.scale/2, image.size.height*image.scale));
    [self.leftView.layer setContents:(__bridge id)imageRef];
    CFRelease(imageRef);
    
    CGImageRef imageRef2 = CGImageCreateWithImageInRect([image CGImage], CGRectMake(image.size.width*image.scale/2, 0, image.size.width*image.scale/2, image.size.height*image.scale));
    [self.rightView.layer setContents:(__bridge id)imageRef2];
    CFRelease(imageRef2);
}

#pragma mark - MTStackContainerView Overrides

- (void)stackViewController:(MTStackViewController*)stackViewController show:(BOOL)show side:(MTStackViewControllerPosition)side toFrame:(CGRect)rect withDuration:(CGFloat)duration
{
    // force fold into transition
    if(self.state != FoldStateTransition)
    {
        [self updateFoldStateWithOffset:0.5f];
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:(UIViewAnimationOptions)(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         [self animateToFraction: show ? 1.0 : 0.0f ];
                     }
                     completion:^(BOOL finished) {
                         if(finished)
                         {
                             if(show)
                             {
                                 [self updateFoldStateWithOffset:1.0f];
                             }
                             else
                             {
                                 [self updateFoldStateWithOffset:0.0f];
                             }
                         }
                     }];

}

-(void)animateToFraction:(CGFloat)fraction
{
    float delta = asinf(fraction);
    
    // rotate leftView on the left edge of the view
    [self.leftView.layer setTransform:CATransform3DMakeRotation((M_PI / 2) - delta, 0, 1, 0)];
    
    // rotate rightView on the right edge of the view
    // translate rotated view to the left to join to the edge of the leftView
    CATransform3D transform1 = CATransform3DMakeTranslation(2*self.leftView.frame.size.width, 0, 0);
    CATransform3D transform2 = CATransform3DMakeRotation((M_PI / 2) - delta, 0, -1, 0);
    CATransform3D transform = CATransform3DConcat(transform2, transform1);
    [self.rightView.layer setTransform:transform];
    
    // fade in shadow when folding
    // fade out shadow when unfolding
    [self.leftView.shadowView setAlpha:1-fraction];
    [self.rightView.shadowView setAlpha:1-fraction];
}

-(void)stackViewController:(MTStackViewController *)stackViewController anmimateToFame:(CGRect)rect side:(MTStackViewControllerPosition)side withOffset:(CGFloat)offset;
{
    [UIView animateWithDuration:stackViewController.trackingAnimationDuration
                          delay:0.0f
                        options:(UIViewAnimationOptions)(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         [self animateToFraction: offset ];
                     }
                     completion:^(BOOL finished) {
                         [self updateFoldStateWithOffset:offset];
                     }];
}

- (void)showFolds:(BOOL)show
{
    if (self.foldDirection==FoldDirectionHorizontalRightToLeft  || self.foldDirection==FoldDirectionHorizontalLeftToRight)
    {
        [self.leftView setHidden:!show];
        [self.rightView setHidden:!show];
    }
    else if (self.foldDirection==FoldDirectionVertical)
    {
        [self.topView setHidden:!show];
        [self.bottomView setHidden:!show];
    }
    
}

-(void)updateFoldStateWithOffset:(CGFloat)offset
{
    if (self.state==FoldStateClosed && offset>0)
    {
        self.state = FoldStateTransition;
        [self foldWillOpen];
    }
    else if (self.state==FoldStateOpened && offset<1)
    {
        self.state = FoldStateTransition;
        [self foldWillClose];
        
    }
    else if (self.state==FoldStateTransition)
    {
        if (offset<=0)
        {
            self.state = FoldStateClosed;
            [self foldDidClose];
        }
        else if (offset>=1)
        {
            self.state = FoldStateOpened;
            [self foldDidOpen];
        }
    }
}

- (void)foldDidOpen
{
    [self.contentView setHidden:NO];
    [self showFolds:NO];
}

- (void)foldDidClose
{
    [self.contentView setHidden:YES];
    [self showFolds:YES];
}

- (void)foldWillOpen
{
    [self.contentView setHidden:YES];
    [self showFolds:YES];
}

- (void)foldWillClose
{
    [self drawScreenshotOnFolds];
    [self.contentView setHidden:YES];
    [self showFolds:YES];
}


@end
