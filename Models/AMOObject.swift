import SwiftUI

// MARK: - AMO Object Model

struct AMOObject: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let folder: String
    let type: String
    let usdzFileName: String

    let height: String
    let weight: String
    let base: String
    let windLoad: String
    let payload: String
    let material: String
    let standard: String
    let description: String
    let colorHex: String
    let drawings: [Drawing]

    var color: Color { Color(hex: colorHex) ?? .orange }
}

struct Drawing: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let fileName: String
}

// MARK: - Sample Data

extension AMOObject {
    static let sampleData: [AMOObject] = [

        // ─── ТРЁХГРАННЫЕ МАЧТЫ ────────────────────────────────────────
        AMOObject(
            id: "tg24",
            name: "Трёхгранная мачта 24м",
            folder: "Трёхгранные мачты",
            type: "Мачта решётчатая трёхгранная",
            usdzFileName: "Трехгранная мачта",
            height: "24 м",
            weight: "1 850 кг",
            base: "4.2 × 4.2 м",
            windLoad: "до 160 км/ч",
            payload: "до 1 200 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Основная конструкция НУР Телеком. Секции С-1 (Ø159×5мм) и С-2 (Ø133×4мм). Фундамент Фм-1 4200×4200мм. Заземление ≤4.0 Ом.",
            colorHex: "#FF6B35",
            drawings: [
                Drawing(id: "tg24_front", title: "Вид спереди", fileName: "TG24_front"),
                Drawing(id: "tg24_base",  title: "Фундамент",   fileName: "TG24_base"),
                Drawing(id: "tg24_node",  title: "Узел Ножка А/Б/В", fileName: "TG24_node"),
            ]
        ),
        AMOObject(
            id: "tg30",
            name: "Трёхгранная мачта 30м",
            folder: "Трёхгранные мачты",
            type: "Мачта решётчатая трёхгранная",
            usdzFileName: "TG_30",
            height: "30 м",
            weight: "2 640 кг",
            base: "4.5 × 4.5 м",
            windLoad: "до 160 км/ч",
            payload: "до 1 500 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Усиленная трёхгранная мачта для открытой местности. Три секции. Несущая способность позволяет размещение антенн нескольких операторов.",
            colorHex: "#FF6B35",
            drawings: [
                Drawing(id: "tg30_front", title: "Вид спереди", fileName: "TG30_front"),
                Drawing(id: "tg30_base",  title: "Фундамент",   fileName: "TG30_base"),
            ]
        ),
        AMOObject(
            id: "tg18",
            name: "Трёхгранная мачта 18м",
            folder: "Трёхгранные мачты",
            type: "Мачта решётчатая трёхгранная",
            usdzFileName: "TG_18",
            height: "18 м",
            weight: "1 200 кг",
            base: "3.5 × 3.5 м",
            windLoad: "до 150 км/ч",
            payload: "до 900 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Компактная трёхгранная мачта для стеснённых условий. Две секции. Применяется в населённых пунктах с ограниченной площадью под фундамент.",
            colorHex: "#FF6B35",
            drawings: [
                Drawing(id: "tg18_front", title: "Вид спереди", fileName: "TG18_front"),
                Drawing(id: "tg18_base",  title: "Фундамент",   fileName: "TG18_base"),
            ]
        ),

        // ─── БАШНИ РЕШЁТЧАТЫЕ ────────────────────────────────────────
        AMOObject(
            id: "ba24",
            name: "БА-24",
            folder: "Башни решётчатые",
            type: "Башня антенная четырёхгранная",
            usdzFileName: "BA_24",
            height: "24 м",
            weight: "2 100 кг",
            base: "3.5 × 3.5 м",
            windLoad: "до 160 км/ч",
            payload: "до 1 200 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Четырёхгранная решётчатая башня для базовых станций 4G/5G. Монтаж по проекту, фундамент — монолитный ж/б.",
            colorHex: "#E76F51",
            drawings: [
                Drawing(id: "ba24_front", title: "Вид спереди",  fileName: "BA24_front"),
                Drawing(id: "ba24_side",  title: "Вид сбоку",    fileName: "BA24_side"),
                Drawing(id: "ba24_base",  title: "Фундамент",    fileName: "BA24_base"),
            ]
        ),
        AMOObject(
            id: "ba30",
            name: "БА-30",
            folder: "Башни решётчатые",
            type: "Башня антенная четырёхгранная",
            usdzFileName: "BA_30",
            height: "30 м",
            weight: "2 640 кг",
            base: "4.0 × 4.0 м",
            windLoad: "до 160 км/ч",
            payload: "до 1 500 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Усиленная башня высотой 30 м для открытой местности. Размещение антенн нескольких операторов одновременно.",
            colorHex: "#E76F51",
            drawings: [
                Drawing(id: "ba30_front", title: "Вид спереди", fileName: "BA30_front"),
                Drawing(id: "ba30_base",  title: "Фундамент",   fileName: "BA30_base"),
            ]
        ),

        // ─── МОБИЛЬНЫЕ МАЧТЫ ─────────────────────────────────────────
        AMOObject(
            id: "bdk14",
            name: "БДК-14",
            folder: "Мобильные мачты",
            type: "Мачта мобильная на прицепе",
            usdzFileName: "BDK_14",
            height: "14 м",
            weight: "3 200 кг",
            base: "Прицеп 6 × 2.4 м",
            windLoad: "до 140 км/ч",
            payload: "до 600 кг",
            material: "Ст3сп, эпоксидная окраска",
            standard: "ТУ 4854-001",
            description: "Мобильная БС контейнерного типа на буксируемом прицепе. Оперативное развёртывание в труднодоступных районах. Автономная работа до 72 часов.",
            colorHex: "#00B4D8",
            drawings: [
                Drawing(id: "bdk14_general", title: "Общий вид",   fileName: "BDK14_general"),
                Drawing(id: "bdk14_mast",    title: "Мачтовый блок", fileName: "BDK14_mast"),
            ]
        ),
        AMOObject(
            id: "mbs12",
            name: "МБС-КНТ-12",
            folder: "Мобильные мачты",
            type: "Мачта контейнерная 20 фут.",
            usdzFileName: "MBS_KNT_12",
            height: "12 м",
            weight: "2 100 кг",
            base: "Контейнер 20 фут.",
            windLoad: "до 150 км/ч",
            payload: "до 800 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Мачта интегрированная с 20-футовым контейнером. Дизель-генератор, охлаждение, АКБ резервирования.",
            colorHex: "#00B4D8",
            drawings: [
                Drawing(id: "mbs12_front",     title: "Вид спереди",    fileName: "MBS12_front"),
                Drawing(id: "mbs12_container", title: "Контейнер план", fileName: "MBS12_container"),
            ]
        ),

        // ─── МАЧТЫ ТРУБЧАТЫЕ ─────────────────────────────────────────
        AMOObject(
            id: "mp23",
            name: "МП-23",
            folder: "Мачты трубчатые",
            type: "Мачта призматическая трубчатая",
            usdzFileName: "MP_23",
            height: "23 м",
            weight: "920 кг",
            base: "Ø 1.2 м (фундамент)",
            windLoad: "до 130 км/ч",
            payload: "до 400 кг",
            material: "Ст20, покраска",
            standard: "ТУ 4854-002",
            description: "Трубчатая мачта для городских застроек. Малый диаметр — монтаж на крышах зданий. Секционная конструкция.",
            colorHex: "#06D6A0",
            drawings: [
                Drawing(id: "mp23_front", title: "Вид спереди",    fileName: "MP23_front"),
                Drawing(id: "mp23_sect",  title: "Сечения секций", fileName: "MP23_sections"),
            ]
        ),

        // ─── КРОВЕЛЬНЫЕ ──────────────────────────────────────────────
        AMOObject(
            id: "orrk",
            name: "ОР-РК",
            folder: "Кровельные конструкции",
            type: "Опора кровельная балластная",
            usdzFileName: "OR_RK",
            height: "до 6 м",
            weight: "180 кг",
            base: "1.5 × 1.5 м",
            windLoad: "до 120 км/ч",
            payload: "до 200 кг",
            material: "Ст3сп, оцинкование",
            standard: "ГОСТ 23118-2012",
            description: "Кровельная опора для плоских крыш. Балластное крепление — без сверления несущих конструкций. Монтаж до 4 часов.",
            colorHex: "#06D6A0",
            drawings: [
                Drawing(id: "orrk_top",  title: "Вид сверху", fileName: "ORRK_top"),
                Drawing(id: "orrk_side", title: "Вид сбоку",  fileName: "ORRK_side"),
            ]
        ),
    ]

    static var folders: [String] {
        // Сортировка: Трёхгранные первыми
        let priority = ["Трёхгранные мачты", "Башни решётчатые", "Мобильные мачты", "Мачты трубчатые", "Кровельные конструкции"]
        let all = Array(Set(sampleData.map(\.folder)))
        return all.sorted {
            let i1 = priority.firstIndex(of: $0) ?? 99
            let i2 = priority.firstIndex(of: $1) ?? 99
            return i1 < i2
        }
    }

    static func objects(inFolder folder: String) -> [AMOObject] {
        sampleData.filter { $0.folder == folder }
    }
}

// MARK: - Color from Hex

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    }
}
