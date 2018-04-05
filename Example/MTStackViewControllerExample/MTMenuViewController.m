//
//  MTMenuViewController.m
//  MTStackViewControllerExample
//
//  Created by Andrew Carter on 1/31/13.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//

#import "MTMenuViewController.h"

#import "MTStackViewController.h"

static NSString *const MTTableViewCellIdentifier = @"MTTableViewCell";

@interface MTMenuViewController ()
{
    NSMutableArray *_datasource;
    BOOL _didSetInitialViewController;
}
@end

@implementation MTMenuViewController

#pragma mark - UIViewController Overrides

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _datasource = [NSMutableArray new];
        [self populateDatasource];
        
        [[self navigationItem] setTitle:@"Menu"];
    }
    return self;
}

- (void)viewDidLoad
{
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:MTTableViewCellIdentifier];
    
    // For some reason, when the view is added for the fold view, the nav bar gets pushed down for the status bar
    CGRect frame = self.navigationController.navigationBar.frame;
    self.navigationController.navigationBar.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Frame = %@", self.navigationController.navigationBar);
    if (!_didSetInitialViewController)
    {
        [self setInitialViewController];
        _didSetInitialViewController = YES;
    }
}

#pragma mark - Instance Methods

- (void)setInitialViewController
{
    [self tableView:[self tableView] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)populateDatasource
{
    [_datasource setArray:@[
        [UIColor redColor],
        [UIColor blueColor],
        [UIColor greenColor],
        [UIColor yellowColor],
        [UIColor purpleColor]
     ]];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [[cell textLabel] setText:[NSString stringWithFormat:@"View Controller %ld", (long)[indexPath row]]];
}

- (UIViewController *)contentViewcontrollerForIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewController = [UIViewController new];
    [[viewController view] setBackgroundColor:_datasource[[indexPath row]]];
    [[viewController navigationItem] setTitle:[NSString stringWithFormat:@"View Controller %d", (long)[indexPath row]]];
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStyleBordered target:[self stackViewController] action:@selector(toggleLeftViewController)];
    [[viewController navigationItem] setLeftBarButtonItem:menuBarButtonItem];
    
    return viewController;
}

#pragma mark - UITableViewDatasource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MTTableViewCellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_datasource count];
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UINavigationController *navigationController = (UINavigationController *)[[self stackViewController] contentViewController];
    [navigationController setViewControllers:@[[self contentViewcontrollerForIndexPath:indexPath]]];
    
    [[self stackViewController] hideRightViewController];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
