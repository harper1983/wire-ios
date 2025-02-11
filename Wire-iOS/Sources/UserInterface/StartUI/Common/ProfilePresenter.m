// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "ProfilePresenter.h"
#import "ProfilePresenter+Internal.h"

// ui
#import "ZClientViewController.h"

#import "ZoomTransition.h"
#import "Wire-Swift.h"

// model


@implementation TransitionDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[ZoomTransition alloc] initWithInteractionPoint:CGPointMake(0.5, 0.5) reversed:NO];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[ZoomTransition alloc] initWithInteractionPoint:CGPointMake(0.5, 0.5) reversed:YES];
}

@end


@implementation ProfilePresenter

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(deviceOrientationChanged:) 
                                                     name:UIDeviceOrientationDidChangeNotification 
                                                   object:nil];
        
        _transitionDelegate = [[TransitionDelegate alloc] init];
    }
    return self;
}

#pragma mark - ViewControllerDismisser

- (void)dismissViewController:(UIViewController *)profileViewController completion:(dispatch_block_t)completion
{
    [profileViewController dismissViewControllerAnimated:YES completion:^{
        if (completion != nil) {
            completion();
        }
        if (self.onDismiss != nil) {
            self.onDismiss();
        }
        self.controllerToPresentOn = nil;
        self.viewToPresentOn = nil;
        self.presentedFrame = CGRectZero;
        self.onDismiss = nil;
    }];
}


@end
