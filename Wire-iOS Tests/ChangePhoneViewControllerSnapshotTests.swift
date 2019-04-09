//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class ChangePhoneViewControllerSnapshotTests: CoreDataSnapshotTestCase {

    func testThatItShowsCurrentUserPhoneNumber() {
        let sut = ChangePhoneViewController()
        sut.view.backgroundColor = .black

        verify(view: sut.view)
    }

    func testThatItCanPastePhoneNumber() {
        // GIVEN
        let inputView = PhoneNumberInputView()

        // WHEN
        UIPasteboard.general.string = "+41 86 079 209 36 37"
        inputView.paste(self)

        // THEN
        XCTAssertEqual(inputView.country.e164PrefixString, "+41")
        XCTAssertEqual(inputView.input, "860792093637")
    }

}
