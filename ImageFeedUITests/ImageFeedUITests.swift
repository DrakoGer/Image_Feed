//
//  ImageFeedUITests.swift
//  ImageFeedUITests
//
//  Created by Yura on 22.03.25.
//

import XCTest

final class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("UITests")
        app.launch()
    }
    
    // Вспомогательная функция для ожидания элемента
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let existsPredicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    func testAuth() throws {
         //Если пользователь авторизован, выполняем выход
        if !app.buttons["Logout"].exists {
            app.tabBars.buttons.element(boundBy: 1).tap()
            let logoutButton = app.buttons["Logout"]
            XCTAssertTrue(waitForElement(logoutButton), "Кнопка выхода не найдена")
            logoutButton.tap()
            
            let alert = app.alerts["Пока, пока!"]
            XCTAssertTrue(waitForElement(alert), "Алерт выхода не отобразился")
            alert.buttons["Да"].tap()
        }

        let authButton = app.buttons["LoginButton"]
        XCTAssertTrue(waitForElement(authButton), "Кнопка 'Войти' не найдена")
        authButton.tap()
        
        // Ждём WebView
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(waitForElement(webView, timeout: 15), "WebView не отобразился")
        
        // Вводим логин
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(waitForElement(loginTextField), "Поле для ввода логина не найдено")
        loginTextField.tap()
        loginTextField.typeText("gije.ger@gmail.com")
        webView.tap() // Тапаем по webView, чтобы убрать клавиатуру
        sleep(1)
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10))
        passwordTextField.tap()
        if !passwordTextField.isHittable {
                webView.swipeUp() // Прокручиваем, если поле не в видимой области
                sleep(1)
                XCTAssertTrue(passwordTextField.isHittable, "Поле пароля не доступно для нажатия после прокрутки")
            }
        passwordTextField.tap()
        sleep(1)

        UIPasteboard.general.string = "PoNchik123"

        passwordTextField.press(forDuration: 1.5)
        XCTAssertTrue(app.menuItems["Paste"].waitForExistence(timeout: 5))
        app.menuItems["Paste"].tap()
        
        // Нажимаем кнопку логина
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(waitForElement(loginButton), "Кнопка логина на WebView не найдена")
        loginButton.tap()
        
        // Проверяем переход на экран ленты
        let table = app.tables.element
        XCTAssertTrue(
            table.waitForExistence(timeout: 30))
    
        let cell = table.cells.element(boundBy: 0)
        XCTAssertTrue(
            cell.waitForExistence(timeout: 15))
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables.firstMatch
        XCTAssertTrue(waitForElement(tablesQuery, timeout: 15), "Таблица не найдена")
        
        let firstCell = tablesQuery.cells.firstMatch
        XCTAssertTrue(waitForElement(firstCell, timeout: 10), "Первая ячейка не найдена")
        
        tablesQuery.swipeUp()
        
        let likeButton = firstCell.buttons["like_button_on"]
        XCTAssertTrue(waitForElement(likeButton, timeout: 5), "Кнопка лайка не найдена")
        
        likeButton.tap()
        
        XCTAssertTrue(waitForElement(likeButton, timeout: 5), "Кнопка лайка исчезла после первого нажатия")
        
        likeButton.tap()
        
        XCTAssertTrue(waitForElement(likeButton, timeout: 5), "Кнопка лайка исчезла после второго нажатия")
        
        
        // Нажимаем на первую ячейку
        firstCell.tap()
        
        // Ожидаем появления изображения
        let image = app.scrollViews.images.firstMatch
        XCTAssertTrue(waitForElement(image, timeout: 15), "Изображение не найдено")
        
        // Увеличиваем масштаб изображения
        image.pinch(withScale: 3, velocity: 1)
        
        // Уменьшаем масштаб изображения
        image.pinch(withScale: 0.5, velocity: -1)
        
        // Ожидаем появления кнопки "Назад"
        sleep(1)
        let backButton = app.buttons["BackButton"]
        XCTAssertTrue(waitForElement(backButton, timeout: 15), "Кнопка 'Назад' не найдена")
        
        // Нажимаем на кнопку "Назад"
        backButton.tap()
    }
    
    func testProfile() throws {
        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(waitForElement(profileTab, timeout: 15), "Вкладка профиля не найдена")
        profileTab.tap()
        
        // Проверяем метки профиля
        let nameLabel = app.staticTexts["nameLabel"]
        let emailLabel = app.staticTexts["emailLabel"]
        let descriptionLabel = app.staticTexts["descriptionLabel"]
        
        XCTAssertTrue(waitForElement(nameLabel, timeout: 10), "Метка имени не отобразилась")
        XCTAssertTrue(waitForElement(emailLabel, timeout: 10), "Метка email не отобразилась")
        XCTAssertTrue(waitForElement(descriptionLabel, timeout: 10), "Метка описания не отобразилась")
        
        // Нажимаем кнопку логаута
        let logoutButton = app.buttons["Logout"]
        XCTAssertTrue(waitForElement(logoutButton), "Кнопка выхода не найдена")
        logoutButton.tap()
        
        // Подтверждаем выход
        let alert = app.alerts["Пока, пока!"]
        XCTAssertTrue(waitForElement(alert), "Алерт выхода не отобразился")
        alert.buttons["Да"].tap()
        
        // Проверяем возврат на экран авторизации
        let authButton = app.buttons["LoginButton"]
        XCTAssertTrue(waitForElement(authButton, timeout: 15), "Экран авторизации не отобразился после выхода")
    }
}
