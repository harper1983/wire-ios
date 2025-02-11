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


@import UIKit;



@class Token;
@class TokenField;


NS_ASSUME_NONNULL_BEGIN

@interface TokenSeparatorAttachment : NSTextAttachment

@property (nonatomic) Token *token;
@property (weak, nonatomic) TokenField *tokenField;

- (instancetype)initWithToken:(Token *)token tokenField:(TokenField *)tokenField;

@end


@interface TokenTextAttachment : NSTextAttachment

@property (strong, nonatomic) Token *token;
@property (weak, nonatomic, nullable) TokenField *tokenField;
@property (assign, nonatomic, getter=isSelected) BOOL selected;

- (instancetype)initWithToken:(Token *)token tokenField:(TokenField *)tokenField;
- (void)refreshImage;

@end

NS_ASSUME_NONNULL_END
