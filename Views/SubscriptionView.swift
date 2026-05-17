import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var showSuccess = false

    let bg   = Color(red: 0.02, green: 0.05, blue: 0.09)
    let card = Color(red: 0.06, green: 0.10, blue: 0.16)
    let accent = Color(hex: "#FF6B35")!

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                            .padding(.top, 12)
                        Text("Доступ к платформе")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("AR-просмотр АМО для выездных специалистов")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }

                    // Тарифы
                    VStack(spacing: 12) {
                        ForEach(subscriptionManager.plans) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: subscriptionManager.selectedPlan == plan,
                                accent: accent
                            ) {
                                subscriptionManager.selectedPlan = plan
                            }
                        }
                    }

                    // Что включено
                    FeaturesCard(accent: accent)

                    // Кнопка оплаты
                    Button {
                        subscriptionManager.purchase(plan: subscriptionManager.selectedPlan) { _ in
                            showSuccess = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if subscriptionManager.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "lock.open.fill")
                                Text("Оплатить \(subscriptionManager.selectedPlan.price)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [accent, Color(hex: "#FF9A5C")!],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: accent.opacity(0.4), radius: 14, y: 6)
                    }
                    .disabled(subscriptionManager.isPurchasing)

                    Text("Доступ активируется после подтверждения оплаты.\nСчёт выставляется менеджером.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)

                    // Индивидуальный заказ
                    CustomOrderCard()

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Подписка")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Заявка отправлена", isPresented: $showSuccess) {
            Button("Отлично!") { dismiss() }
        } message: {
            Text("Счёт на оплату отправлен на ваш email. Доступ будет активирован после подтверждения.")
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let accent: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? accent : .white.opacity(0.3))
                        Text(plan.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Полный доступ ко всем AR-объектам")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.leading, 28)

                    if let badge = plan.savingBadge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accent)
                            .cornerRadius(6)
                            .padding(.leading, 28)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? accent : .white)
                    Text(plan.period)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(18)
            .background(Color(red: 0.06, green: 0.10, blue: 0.16))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accent : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}

struct FeaturesCard: View {
    let accent: Color

    let features = [
        ("arkit", "AR-просмотр всех объектов АМО"),
        ("ruler", "Технические характеристики"),
        ("doc.richtext", "Чертежи и документация"),
        ("camera", "Фото и видеофиксация на месте"),
        ("arrow.clockwise", "Обновления базы объектов"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ЧТО ВХОДИТ")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))

            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(accent)
                        .frame(width: 22)
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.06, green: 0.10, blue: 0.16))
        .cornerRadius(16)
    }
}

struct CustomOrderCard: View {
    @State private var showOrderSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color(hex: "#00B4D8")!)
                Text("Индивидуальный объект")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Закажите отдельный AR-объект или чертёж под ваш проект. Стоимость — по запросу.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(3)

            Button("Оставить заявку") {
                showOrderSheet = true
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#00B4D8")!)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "#00B4D8")!.opacity(0.1))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#00B4D8")!, lineWidth: 1))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#00B4D8")!.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#00B4D8")!.opacity(0.2), lineWidth: 1))
        .sheet(isPresented: $showOrderSheet) {
            CustomOrderSheet()
        }
    }
}

struct CustomOrderSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.05, blue: 0.09).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Опишите нужный объект и мы свяжемся с вами для уточнения ТЗ и стоимости.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    ForEach([("Имя / Организация", $name), ("Телефон / WhatsApp", $phone)], id: \.0) { label, binding in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(label.uppercased())
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                            TextField(label, text: binding)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color(red: 0.06, green: 0.10, blue: 0.16))
                                .cornerRadius(12)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("ОПИСАНИЕ ОБЪЕКТА")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.35))
                        TextEditor(text: $comment)
                            .foregroundColor(.white)
                            .frame(height: 100)
                            .padding(14)
                            .background(Color(red: 0.06, green: 0.10, blue: 0.16))
                            .cornerRadius(12)
                    }

                    Button("Отправить заявку") { dismiss() }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#FF6B35")!)
                        .cornerRadius(14)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Заявка на объект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
