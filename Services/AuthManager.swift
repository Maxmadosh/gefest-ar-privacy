import SwiftUI
import Combine

// MARK: - Auth Manager

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: AppUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Замените на ваш API endpoint
    private let baseURL = "https://api.gefest-ar.com/v1"

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        // TODO: Замените на реальный API-запрос
        // Пример структуры запроса:
        // POST /auth/login
        // { "email": "...", "password": "..." }
        // Ответ: { "token": "...", "user": { ... }, "subscription": { ... } }

        // Временная заглушка для разработки:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.isLoading = false

            if email.contains("@") && password.count >= 6 {
                self.currentUser = AppUser(
                    id: UUID().uuidString,
                    email: email,
                    name: "Специалист НУР Телеком",
                    company: "ООО НУР Телеком",
                    subscriptionStatus: .active,
                    subscriptionExpiry: Calendar.current.date(byAdding: .month, value: 1, to: Date())
                )
                self.isLoggedIn = true
                self.saveToken("demo_token_\(email)")
            } else {
                self.errorMessage = "Неверный email или пароль"
            }
        }
    }

    func logout() {
        isLoggedIn = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }

    func checkSavedSession() {
        // Проверяем сохранённый токен при запуске
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            // TODO: Верифицировать токен на сервере
            // Временно — автовход если токен есть
            _ = token
            // self.verifyToken(token)
        }
    }

    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
}

// MARK: - App User Model

struct AppUser: Identifiable {
    let id: String
    let email: String
    let name: String
    let company: String
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiry: Date?

    var hasActiveSubscription: Bool {
        subscriptionStatus == .active
    }

    var expiryText: String {
        guard let expiry = subscriptionExpiry else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: expiry)
    }
}

enum SubscriptionStatus: String, Codable {
    case active   = "active"
    case expired  = "expired"
    case trial    = "trial"
    case none     = "none"
}

// MARK: - Subscription Manager

class SubscriptionManager: ObservableObject {
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var isPurchasing: Bool = false
    @Published var purchaseSuccess: Bool = false

    let plans: [SubscriptionPlan] = SubscriptionPlan.allCases

    func purchase(plan: SubscriptionPlan, completion: @escaping (Bool) -> Void) {
        isPurchasing = true
        // TODO: Интегрировать StoreKit 2 или выставление счёта через backend
        // После успешной оплаты — сервер активирует доступ
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isPurchasing = false
            self?.purchaseSuccess = true
            completion(true)
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "monthly"
    case yearly  = "yearly"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "Месячный"
        case .yearly:  return "Годовой"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "2 900 ₸"
        case .yearly:  return "24 900 ₸"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "/ месяц"
        case .yearly:  return "/ год"
        }
    }

    var savingBadge: String? {
        switch self {
        case .monthly: return nil
        case .yearly:  return "ВЫГОДА −28%"
        }
    }

    var features: [String] {
        [
            "AR-просмотр всех объектов АМО",
            "Технические характеристики",
            "Чертежи и документация",
            "Фото и видеофиксация на месте",
            "Обновления базы объектов",
        ]
    }
}
