
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

import Foundation
import DifferenceKit
import UIKit

private let CellReuseIdConnectionRequests = "CellIdConnectionRequests"
private let CellReuseIdConversation = "CellId"

final class ConversationListContentController: UICollectionViewController {
    weak var contentDelegate: ConversationListContentDelegate?
    let listViewModel: ConversationListViewModel = ConversationListViewModel()
    private weak var activeMediaPlayerObserver: NSObject?
    private weak var mediaPlaybackManager: MediaPlaybackManager?
    private var focusOnNextSelection = false
    private var animateNextSelection = false
    private weak var scrollToMessageOnNextSelection: ZMConversationMessage?
    private var selectConversationCompletion: Completion?
    private let layoutCell = ConversationListCell()
    var startCallController: ConversationCallController?
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    init() {
        let flowLayout = BoundsAwareFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero

        super.init(collectionViewLayout: flowLayout)

        registerSectionHeader()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        listViewModel.delegate = self

        setupViews()

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // viewWillAppear: can get called also when dismissing the controller above this one.
        // The user session might not be there anymore in some cases, e.g. when logging out
        guard let _ = ZMUserSession.shared() else {
            return
        }

        updateVisibleCells()

        scrollToCurrentSelection(animated: false)

        if let mediaPlaybackManager = AppDelegate.shared().mediaPlaybackManager {
            activeMediaPlayerObserver = KeyValueObserver.observe(mediaPlaybackManager, keyPath: "activeMediaPlayer", target: self, selector: #selector(activeMediaPlayerChanged(_:)))

            self.mediaPlaybackManager = mediaPlaybackManager
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activeMediaPlayerObserver = nil
    }

    func reload() {
        collectionView.reloadData()
        ensureCurrentSelection()

        // we MUST call layoutIfNeeded here because otherwise bad things happen when we close the archive, reload the conv
        // and then unarchive all at the same time
        view.layoutIfNeeded()
    }

    func updateVisibleCells() {
        for cell in collectionView.visibleCells {
            (cell as? ConversationListCell)?.updateAppearance()
        }
    }

    private func setupViews() {
        collectionView.register(ConnectRequestsCell.self, forCellWithReuseIdentifier: CellReuseIdConnectionRequests)
        collectionView.register(ConversationListCell.self, forCellWithReuseIdentifier: CellReuseIdConversation)

        collectionView.backgroundColor = UIColor.clear
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.contentInset = .zero
        collectionView.delaysContentTouches = false
        collectionView.accessibilityIdentifier = "conversation list"
        clearsSelectionOnViewWillAppear = false
    }



    // MARK: - section header

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let section = indexPath.section
            
            if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier, for: indexPath) as? ConversationListHeaderView {
                header.title = listViewModel.sectionHeaderTitle(sectionIndex: section)?.uppercased()
                
                header.folderBadge = listViewModel.folderBadge(at: section)

                header.collapsed = listViewModel.collapsed(at: section)

                header.tapHandler = {[weak self] collapsed in
                    self?.listViewModel.setCollapsed(sectionIndex: section, collapsed: collapsed)
                }
                
                return header
            } else {
                fatal("Unknown supplementary view for \(kind)")
            }
        default:
            fatal("No supplementary view for \(kind)")
        }
    }


    private func registerSectionHeader() {
        collectionView?.register(ConversationListHeaderView.self, forSupplementaryViewOfKind:
            UICollectionView.elementKindSectionHeader, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier)

    }

    /// ensures that the list selection state matches that of the model.
    func ensureCurrentSelection() {
        guard let selectedItem = listViewModel.selectedItem else { return }

        let selectedIndexPaths = collectionView.indexPathsForSelectedItems

        if let currentIndexPath = listViewModel.indexPath(for: selectedItem) {
            if selectedIndexPaths?.contains(currentIndexPath) == false {
                // This method doesn't trigger any delegate callbacks, so no worries about special handling
                collectionView.selectItem(at: currentIndexPath, animated: false, scrollPosition: [])
            }
        } else {
            // Current selection is no longer available so we should unload the conversation view
            listViewModel.select(itemToSelect: nil)
        }
    }

    func scrollToCurrentSelection(animated: Bool) {
        guard let selectedItem = listViewModel.selectedItem,
            let selectedIndexPath = listViewModel.indexPath(for: selectedItem),
            // Check if indexPath is valid for the collection view
            collectionView.numberOfSections > selectedIndexPath.section,
            collectionView.numberOfItems(inSection: selectedIndexPath.section) > selectedIndexPath.item else {
            return
        }

        if !collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
            collectionView.scrollToItem(at: selectedIndexPath, at: [], animated: animated)
        }
    }

    @discardableResult
    func selectInboxAndFocus(onView focus: Bool) -> Bool {
        // If there is anything in the inbox, select it
        if listViewModel.numberOfItems(inSection: 0) > 0 {

            focusOnNextSelection = focus
            selectModelItem(ConversationListViewModel.contactRequestsItem)
            return true
        }
        return false
    }

    func deselectAll() {
        selectModelItem(nil)
    }

    func select(_ conversation: ZMConversation?, scrollTo message: ZMConversationMessage?, focusOnView focus: Bool, animated: Bool, completion: Completion?) -> Bool {
        focusOnNextSelection = focus
        
        selectConversationCompletion = completion
        animateNextSelection = animated
        scrollToMessageOnNextSelection = message
        
        // Tell the model to select the item
        return selectModelItem(conversation)
    }
    
    @discardableResult
    func selectModelItem(_ itemToSelect: ConversationListItem?) -> Bool {
        return listViewModel.select(itemToSelect: itemToSelect)
    }
    
    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        selectionFeedbackGenerator.prepare()
        return true
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentDelegate?.conversationListDidScroll(self)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        selectionFeedbackGenerator.selectionChanged()
        
        let item = listViewModel.item(for: indexPath)
        
        focusOnNextSelection = true
        animateNextSelection = true
        selectModelItem(item)
    }
    
    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return listViewModel.sectionCount
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listViewModel.numberOfItems(inSection: section)
    }


    override func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = listViewModel.item(for: indexPath)
        let cell: UICollectionViewCell

        if item is ConversationListConnectRequestsItem,
            let labelCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdConnectionRequests, for: indexPath) as? ConnectRequestsCell {
            cell = labelCell
        } else if item is ZMConversation,
            let listCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdConversation, for: indexPath) as? ConversationListCell {

            listCell.delegate = self
            listCell.mutuallyExclusiveSwipeIdentifier = "ConversationList"
            listCell.conversation = item as? ZMConversation

            cell = listCell
        } else {
            fatal("Unknown cell type")
        }

        (cell as? SectionListCellType)?.sectionName = listViewModel.sectionCanonicalName(of: indexPath.section)

        cell.autoresizingMask = .flexibleWidth

        return cell
    }
}


extension ConversationListContentController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: listViewModel.sectionHeaderVisible(section: section) ? CGFloat.ConversationListSectionHeader.height: 0)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layoutCell.size(inCollectionViewSize: collectionView.bounds.size)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: section == 0 ? 12 : 0, left: 0, bottom: 0, right: 0)
    }
}

extension ConversationListContentController: ConversationListViewModelDelegate {

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: Int) {
        guard let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section)) as? ConversationListHeaderView else {
            return
        }

        header.folderBadge = listViewModel.folderBadge(at: section)
    }

    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: ConversationListItem?) {
        defer {
            scrollToMessageOnNextSelection = nil
            focusOnNextSelection = false
        }

        guard let item = item else {
            // Deselect all items in the collection view
            let indexPaths = collectionView.indexPathsForSelectedItems
            (indexPaths as NSArray?)?.enumerateObjects({ obj, idx, stop in
                if let obj = obj as? IndexPath {
                    self.collectionView.deselectItem(at: obj, animated: false)
                }
            })
            ZClientViewController.shared()?.loadPlaceholderConversationController(animated: true)
            ZClientViewController.shared()?.transitionToList(animated: true, completion: nil)

            return
        }

        if let conversation = item as? ZMConversation {

            // Actually load the new view controller and optionally focus on it
            ZClientViewController.shared()?.load(conversation, scrollTo: scrollToMessageOnNextSelection, focusOnView: focusOnNextSelection, animated: animateNextSelection, completion: selectConversationCompletion)
            selectConversationCompletion = nil

            contentDelegate?.conversationList(self, didSelect: conversation, focusOnView: !focusOnNextSelection)
        } else if (item is ConversationListConnectRequestsItem) {
            ZClientViewController.shared()?.loadIncomingContactRequestsAndFocus(onView: focusOnNextSelection, animated: true)
        } else {
            assert(false, "Invalid item in conversation list view model!!")
        }
        // Make sure the correct item is selected in the list, without triggering a collection view
        // callback
        ensureCurrentSelection()
    }


    func listViewModelShouldBeReloaded() {
        reload()
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: Int, animated: Bool) {
        let reloadClosure = {
            self.collectionView.reloadSections(IndexSet(integer: section))
            self.ensureCurrentSelection()
        }

        if animated {
            reloadClosure()
        } else {
            UIView.performWithoutAnimation {
                reloadClosure()
            }
        }
    }

    func listViewModel(_ model: ConversationListViewModel?, didChangeFolderEnabled folderEnabled: Bool) {
        collectionView.accessibilityValue = folderEnabled ? "folders" : "recent"
    }

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C?) -> Void
        ) {
        collectionView.reload(using: stagedChangeset, interrupt: interrupt, setData: setData)
    }
}

extension ConversationListContentController: UIViewControllerPreviewingDelegate {
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard let previewViewController = viewControllerToCommit as? ConversationPreviewViewController else { return }
        
        focusOnNextSelection = true
        animateNextSelection = true
        selectModelItem(previewViewController.conversation)
    }
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath),
              let conversation = listViewModel.item(for: indexPath) as? ZMConversation else {
            return nil
        }
        
        previewingContext.sourceRect = layoutAttributes.frame
        
        return ConversationPreviewViewController(conversation: conversation, presentingViewController: self)
    }

}

extension ConversationListContentController: ConversationListCellDelegate {
    func indexPath(for cell: ConversationListCell) -> IndexPath? {
        return collectionView.indexPath(for: cell)
    }

    func conversationListCellOverscrolled(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation else {
            return
        }

        contentDelegate?.conversationListContentController(self, wantsActionMenuFor: conversation, fromSourceView: cell)
    }

    func conversationListCellJoinCallButtonTapped(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation else { return }

        startCallController = ConversationCallController(conversation: conversation, target: self)
        startCallController?.joinCall()
    }
}
