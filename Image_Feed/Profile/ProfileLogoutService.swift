

import Foundation
import WebKit
import SwiftKeychainWrapper

final class ProfileLogoutService {
   static let shared = ProfileLogoutService()
  
   private init() { }

   func logout() {
       cleanCookies()
       KeychainWrapper.standard.removeObject(forKey: "AuthToken")
       ProfileService.shared.clearProfile()
       ProfileImageService.shared.clearAvatar()
       ImagesListService.shared.clearPhotos()
   }

   private func cleanCookies() {
      // Очищаем все куки из хранилища
      HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
      // Запрашиваем все данные из локального хранилища
      WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
         // Массив полученных записей удаляем из хранилища
         records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
         }
      }
   }
}
    
