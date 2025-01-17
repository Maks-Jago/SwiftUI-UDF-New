//
//  PaginatorTests.swift
//
//
//  Created by Max Kuznetsov on 15.09.2021.
//

@testable import UDF
import XCTest

class PaginatorTests: XCTestCase {
    struct Item: Identifiable, Hashable, Codable {
        struct Id: Hashable, Codable {
            var value: Int
        }

        var id: Id
        var title: String
        var text: String

        init() {
            id = .init(value: .random(in: 0 ..< Int.max))
            title = "title \(id.value)"
            text = "text \(id.value)"
        }

        static func fakeItems(count: Int) -> [Item] {
            (0 ..< count).map { _ in Self() }
        }
    }

    enum ItemFlow: IdentifiableFlow {
        case none

        init() { self = .none }

        mutating func reduce(_ action: some Action) {}
    }

    struct AppState: AppReducer, Equatable {
        var itemsForm = ItemsForm()
    }

    struct ItemsForm: Form, Codable {
        var paginator: Paginator = .init(Item.self, flowId: ItemFlow.id, perPage: 10)
    }

    func testPaginatorPagesRemoving() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let firstPageItems = Item.fakeItems(count: 10)
        let secondPageItems = Item.fakeItems(count: 10)
        let thirdPageItems = Item.fakeItems(count: 4)

        paginator.reduce(Actions.LoadPage(id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: firstPageItems, id: ItemFlow.id))
        XCTAssertEqual(paginator.items.count, 10)
        XCTAssertEqual(paginator.page, .number(1))

        paginator.reduce(Actions.LoadPage(pageNumber: 2, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: secondPageItems, id: ItemFlow.id))
        XCTAssertEqual(paginator.items.count, 20)
        XCTAssertEqual(paginator.page, .number(2))

        paginator.reduce(Actions.LoadPage(pageNumber: 3, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: thirdPageItems, id: ItemFlow.id))
        XCTAssertEqual(paginator.items.count, 24)
        XCTAssertEqual(paginator.page, .lastPage(3))

        let firstPageItemPageNumber = try XCTUnwrap(paginator.pageNumber(for: firstPageItems.first!))
        XCTAssertEqual(firstPageItemPageNumber, 1)

        let secondPageItemPageNumber = try XCTUnwrap(paginator.pageNumber(for: secondPageItems.randomElement()!))
        XCTAssertEqual(secondPageItemPageNumber, 2)

        paginator.removeItems(after: 2)
        XCTAssertEqual(paginator.items.count, 20)

        paginator.removeItems(after: 1)
        XCTAssertEqual(paginator.items.count, 10)

        paginator.removeAllItems()
        XCTAssertTrue(paginator.items.isEmpty)
        XCTAssertEqual(paginator.page, .number(1))
    }

    func testPaginatorSetItems() {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 24)

        paginator.set(items: items)
        XCTAssertEqual(paginator.items.count, 24)
        XCTAssertEqual(paginator.page.pageNumber, 3)
    }

    func testPaginatorSetItemsAction() {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 24)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))
        XCTAssertEqual(paginator.items.count, 24)
        XCTAssertEqual(paginator.page.pageNumber, 3)

        paginator.removeAllItems()
        paginator.reduce(Actions.SetPaginationItems<Item.Id>(items: items.map(\.id), id: ItemFlow.id))
        XCTAssertEqual(paginator.items.count, 24)
        XCTAssertEqual(paginator.page.pageNumber, 3)
    }

    func testPaginatorLoadingMiddlePage() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 44)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))
        XCTAssertEqual(paginator.page.pageNumber, 5)

        paginator.reduce(Actions.LoadPage(pageNumber: 2, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: Item.fakeItems(count: 10), id: ItemFlow.id))

        XCTAssertEqual(paginator.page.pageNumber, 2)
        XCTAssertEqual(paginator.items.count, 30)
    }

    func testPaginatorLoadingFirstPage() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 44)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))
        XCTAssertEqual(paginator.page.pageNumber, 5)

        paginator.reduce(Actions.LoadPage(pageNumber: 1, id: ItemFlow.id))
        paginator.reduce(Actions.DidLoadItems(items: Item.fakeItems(count: 10), id: ItemFlow.id))

        XCTAssertEqual(paginator.page.pageNumber, 1)
        XCTAssertEqual(paginator.items.count, 10)
    }

    func testPaginatorLoading() async {
        let store = await XCTestStore(initial: AppState())
        await store.dispatch(Actions.LoadPage(id: ItemFlow.id))

        let isLoading = await store.state.itemsForm.paginator.isLoading
        XCTAssertEqual(isLoading, true)

        await store.dispatch(Actions.DidLoadItems(items: Item.fakeItems(count: 10), id: ItemFlow.id))

        let pageNumber = await store.state.itemsForm.paginator.page.pageNumber
        XCTAssertEqual(pageNumber, 1)

        let itemsCount = await store.state.itemsForm.paginator.items.count
        XCTAssertEqual(itemsCount, 10)
    }

    func testMoveItem() throws {
        var paginator = Paginator(Item.self, flowId: ItemFlow.id, perPage: 10)
        let items = Item.fakeItems(count: 14)
        let firstItem = try XCTUnwrap(items.first)

        paginator.reduce(Actions.SetPaginationItems<Item>(items: items, id: ItemFlow.id))

        let isSuccess = paginator.moveItem(fromIndex: 0, toIndex: 13)
        XCTAssertTrue(isSuccess)
        XCTAssertEqual(firstItem.id, try XCTUnwrap(paginator.items.last))

        let isFailure = paginator.moveItem(fromIndex: 0, toIndex: 14) // toIndex >= items.count
        XCTAssertFalse(isFailure)

        let itemAt10Index = try XCTUnwrap(paginator.elements[10])
        let isMovedIntoBeginning = paginator.moveItem(fromIndex: 10, toIndex: 0)
        XCTAssertTrue(isMovedIntoBeginning)
        XCTAssertEqual(itemAt10Index, try XCTUnwrap(paginator.items.first))
    }
}
