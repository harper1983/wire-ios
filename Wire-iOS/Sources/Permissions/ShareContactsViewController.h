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


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ShareContactsViewControllerDelegate <NSObject>

- (void)shareContactsViewControllerDidSkip:(UIViewController *)viewController;
- (void)shareContactsViewControllerDidFinish:(UIViewController *)viewController;

@end

@interface ShareContactsViewController : UIViewController

@property (nonatomic, weak, nullable) id<ShareContactsViewControllerDelegate> delegate;

@property (nonatomic) BOOL uploadAddressBookImmediately;
@property (nonatomic) BOOL backgroundBlurDisabled;
@property (nonatomic) BOOL notNowButtonHidden;
@property (nonatomic) BOOL monochromeStyle;
@property (nonatomic, readonly) BOOL showingAddressBookAccessDeniedViewController;

@end

NS_ASSUME_NONNULL_END
