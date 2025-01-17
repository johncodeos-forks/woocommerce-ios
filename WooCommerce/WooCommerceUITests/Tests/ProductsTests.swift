import UITestsFoundation
import XCTest

final class ProductsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()
    }

    func testProductsScreenLoad() throws {
        let products = try GetMocks.readProductsData()

        _ = try TabNavComponent()
            .gotoProductsScreen()
            .verifyProductsScreenLoaded()
            .verifyProductListOnProductsScreen(products: products)
            .selectProduct(byName: products[0].name)
            .verifyProductOnSingleProductScreen(product: products[0])
            .goBackToProductList()
            .verifyProductsScreenLoaded()
    }
}
