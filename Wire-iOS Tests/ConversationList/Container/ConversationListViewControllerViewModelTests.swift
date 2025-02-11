
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest
@testable import Wire

final class ConversationListViewControllerViewModelTests: XCTestCase {
    var sut: ConversationListViewController.ViewModel!
    fileprivate var mockViewController: MockConversationListContainer!

    var mockConversation: ZMConversation!

    override func setUp() {
        super.setUp()

        let account = Account.mockAccount(imageData: Data())
        sut = ConversationListViewController.ViewModel(account: account, selfUser: MockUser.mockSelf())
        mockViewController = MockConversationListContainer(viewModel: sut)
        sut.viewController = mockViewController
    }

    override func tearDown() {
        sut = nil
        mockViewController = nil

        super.tearDown()
    }

    func testThatSelectAConversationCallsSelectOnListContentController() {
        /// GIVEN
        XCTAssertFalse(mockViewController.isSelectedOnListContentController)

        /// WHEN
        mockConversation = ZMConversation()
        sut.select(mockConversation)

        /// THEN
        XCTAssertEqual(mockConversation, sut.selectedConversation)
        XCTAssert(mockViewController.isSelectedOnListContentController)
    }

    func testThatShowPushPermissionDeniedDialogIfNeededReturnTrueWhenHandleExists() {
        /// GIVEN
        var result = sut.showPushPermissionDeniedDialogIfNeeded()
        XCTAssertFalse(result)

        /// WHEN
        MockUser.mockSelf().handle = "blah"
        result = sut.showPushPermissionDeniedDialogIfNeeded()

        /// THEN
        XCTAssert(result)
    }
}
