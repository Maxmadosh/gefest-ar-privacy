import SwiftUI

// MARK: - AMO Object Model

struct AMOObject: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let folder: String
    let type: String
    let usdzFileName: String   // имя файла без расширения, напр. "BA_24"

    // Технические характеристики
    let height: String
    let weight: String
    let base: String
    let windLoad: String
    let payload: String
    let material: String
    let standard: String
    let description: String

    // Цвет категории (hex)
    let colorHex: String

    // Доступные чертежи (имена PDF-файлов)
    let drawings: [Drawing]

    var color: Color {
        Color(hex: colorHex) ?? .orange
    }
}

struct Drawing: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let fileName: String   // PDF в bundle
}

// MARK: - Sample Data (замените на загрузку с сервера)

extension AMOObject {
    static let sampleData: [AMOObject] = [
        AMOObject(
            id: "ba24",
            name: "БА-24",
            folder: "Башни решётчатые",
            type: "Башня антенная",
            usdzFileName: "BA_24",
            height: "24 м",
            weight: "1 850 кг",
            base: "3.5 × 3.5 м",
            windLoad: "до 160 км/ч",
            payload: "до 1 200 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Решётчатая стальная башня для размещения антенн сотовой связи в зонах с умеренными ветровыми нагрузками. Применяется на базовых станциях 4G/5G. Монтаж по проекту, фундамент — монолитный ж/б.",
            colorHex: "#FF6B35",
            drawings: [
                Drawing(id: "ba24_front", title: "Вид спереди", fileName: "BA24_front"),
                Drawing(id: "ba24_side",  title: "Вид сбоку",   fileName: "BA24_side"),
                Drawing(id: "ba24_base",  title: "План фундамента", fileName: "BA24_base"),
                Drawing(id: "ba24_node",  title: "Узел крепления антенны", fileName: "BA24_node"),
            ]
        ),
        AMOObject(
            id: "ba30",
            name: "БА-30",
            folder: "Башни решётчатые",
            type: "Башня антенная",
            usdzFileName: "BA_30",
            height: "30 м",
            weight: "2 640 кг",
            base: "4.0 × 4.0 м",
            windLoad: "до 160 км/ч",
            payload: "до 1 500 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Усиленная решётчатая башня высотой 30 м для открытой местности. Увеличенная несущая способность позволяет размещение антенн нескольких операторов одновременно.",
            colorHex: "#FF6B35",
            drawings: [
                Drawing(id: "ba30_front", title: "Вид спереди", fileName: "BA30_front"),
                Drawing(id: "ba30_side",  title: "Вид сбоку",   fileName: "BA30_side"),
                Drawing(id: "ba30_base",  title: "План фундамента", fileName: "BA30_base"),
            ]
        ),
        AMOObject(
            id: "bdk14",
            name: "БДК-14",
            folder: "Мобильные мачты",
            type: "Мачта на прицепе",
            usdzFileName: "BDK_14",
            height: "14 м",
            weight: "3 200 кг",
            base: "Прицеп 6 × 2.4 м",
            windLoad: "до 140 км/ч",
            payload: "до 600 кг",
            material: "Ст3сп, эпоксидная окраска",
            standard: "ТУ 4854-001",
            description: "Мобильная базовая станция контейнерного типа на буксируемом прицепе. Предназначена для оперативного развёртывания в труднодоступных районах. Автономная работа до 72 часов.",
            colorHex: "#00B4D8",
            drawings: [
                Drawing(id: "bdk14_general", title: "Общий вид", fileName: "BDK14_general"),
                Drawing(id: "bdk14_mast",    title: "Мачтовый блок", fileName: "BDK14_mast"),
                Drawing(id: "bdk14_trailer", title: "Прицеп (план)", fileName: "BDK14_trailer"),
            ]
        ),
        AMOObject(
            id: "mbs12",
            name: "МБС-КНТ-12",
            folder: "Мобильные мачты",
            type: "Контейнерная мачта",
            usdzFileName: "MBS_KNT_12",
            height: "12 м",
            weight: "2 100 кг",
            base: "Контейнер 20 фут.",
            windLoad: "до 150 км/ч",
            payload: "до 800 кг",
            material: "Ст3сп, горячее цинкование",
            standard: "ГОСТ 23118-2012",
            description: "Мачтовая конструкция, интегрированная с 20-футовым транспортным контейнером. Полная автономность: дизель-генератор, система охлаждения, АКБ резервирования.",
            colorHex: "#00B4D8",
            drawings: [
                Drawing(id: "mbs12_front",     title: "Вид спереди", fileName: "MBS12_front"),
                Drawing(id: "mbs12_container", title: "Контейнер (план)", fileName: "MBS12_container"),
            ]
        ),
        AMOObject(
            id: "mp23",
            name: "МП-23",
            folder: "Мачты трубчатые",
            type: "Мачта призматическая",
            usdzFileName: "MP_23",
            height: "23 м",
            weight: "920 кг",
            base: "Ø 1.2 м (фундамент)",
            windLoad: "до 130 км/ч",
            payload: "до 400 кг",
            material: "Ст20, покраска",
            standard: "ТУ 4854-002",
            description: "Трубчатая призматическая мачта для городских застроек. Малый диаметр основания позволяет монтаж на ограниченных площадках и крышах зданий. Секционная конструкция.",
            colorHex: "#06D6A0",
            drawings: [
                Drawing(id: "mp23_front", title: "Вид спереди", fileName: "MP23_front"),
                Drawing(id: "mp23_sect",  title: "Сечения секций", fileName: "MP23_sections"),
            ]
        ),
        AMOObject(
            id: "orrk",
            name: "ОР-РК",
            folder: "Кровельные конструкции",
            type: "Опора кровельная",
            usdzFileName: "OR_RK",
            height: "до 6 м",
            weight: "180 кг",
            base: "1.5 × 1.5 м",
            windLoad: "до 120 км/ч",
            payload: "до 200 кг",
            material: "Ст3сп, оцинкование",
            standard: "ГОСТ 23118-2012",
            description: "Компактная кровельная опора для размещения антенн на плоских крышах. Не требует сверления несущих конструкций — балластное крепление. Быстрый монтаж (до 4 часов).",
            colorHex: "#06D6A0",
            drawings: [
                Drawing(id: "orrk_top",  title: "Вид сверху",  fileName: "ORRK_top"),
                Drawing(id: "orrk_side", title: "Вид сбоку",   fileName: "ORRK_side"),
            ]
        ),
    ]

    static var folders: [String] {
        Array(Set(sampleData.map(\.folder))).sorted()
    }

    static func objects(inFolder folder: String) -> [AMOObject] {
        sampleData.filter { $0.folder == folder }
    }
}

// MARK: - Color from Hex helper

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
