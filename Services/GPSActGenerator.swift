import UIKit
import CoreLocation

// MARK: - GPS Act Generator

struct GPSActGenerator {

    static func generate(
        object: AMOObject,
        screenshot: UIImage,
        location: CLLocation?,
        address: String,
        specialistName: String
    ) -> Data? {

        let pageWidth: CGFloat = 595   // A4
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { ctx in
            ctx.beginPage()

            var y: CGFloat = margin

            // ── Шапка ──────────────────────────────────────────────
            let headerBg = UIColor(red: 0.04, green: 0.08, blue: 0.15, alpha: 1)
            headerBg.setFill()
            UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 70), cornerRadius: 8).fill()

            // Логотип текст
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.white
            ]
            "ГЕФЕСТ АМО".draw(at: CGPoint(x: margin + 16, y: y + 12), withAttributes: titleAttrs)

            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(white: 0.7, alpha: 1)
            ]
            "ОсОО «Гефест Строй-Монтаж»".draw(at: CGPoint(x: margin + 16, y: y + 36), withAttributes: subtitleAttrs)
            "Субподрядчик ООО «НУР Телеком»".draw(at: CGPoint(x: margin + 16, y: y + 50), withAttributes: subtitleAttrs)

            // Дата справа
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
            let dateStr = dateFormatter.string(from: Date())
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(white: 0.8, alpha: 1)
            ]
            let dateSize = (dateStr as NSString).size(withAttributes: dateAttrs)
            (dateStr as NSString).draw(
                at: CGPoint(x: pageWidth - margin - dateSize.width - 16, y: y + 30),
                withAttributes: dateAttrs
            )

            y += 86

            // ── Заголовок акта ──────────────────────────────────────
            let actTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            let actTitle = "АКТ ВЫЕЗДНОЙ ИНСПЕКЦИИ"
            let actTitleSize = (actTitle as NSString).size(withAttributes: actTitleAttrs)
            (actTitle as NSString).draw(
                at: CGPoint(x: (pageWidth - actTitleSize.width) / 2, y: y),
                withAttributes: actTitleAttrs
            )
            y += 28

            let objNameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor(red: 1, green: 0.42, blue: 0.21, alpha: 1)
            ]
            let objNameStr = "Объект: \(object.name) — \(object.type)"
            let objSize = (objNameStr as NSString).size(withAttributes: objNameAttrs)
            (objNameStr as NSString).draw(
                at: CGPoint(x: (pageWidth - objSize.width) / 2, y: y),
                withAttributes: objNameAttrs
            )
            y += 24

            // Разделитель
            UIColor(red: 1, green: 0.42, blue: 0.21, alpha: 0.5).setStroke()
            let line = UIBezierPath()
            line.move(to: CGPoint(x: margin, y: y))
            line.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            line.lineWidth = 1
            line.stroke()
            y += 16

            // ── AR Скриншот ─────────────────────────────────────────
            let imgWidth: CGFloat = pageWidth - margin * 2
            let imgHeight: CGFloat = imgWidth * 0.55
            let imgRect = CGRect(x: margin, y: y, width: imgWidth, height: imgHeight)

            // Рамка
            UIColor(white: 0.85, alpha: 1).setStroke()
            UIBezierPath(roundedRect: imgRect, cornerRadius: 8).stroke()

            // Изображение
            screenshot.draw(in: imgRect.insetBy(dx: 1, dy: 1))

            // Водяной знак AR
            let watermarkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .backgroundColor: UIColor.black.withAlphaComponent(0.5)
            ]
            " AR ПРОСМОТР • GefestAR ".draw(at: CGPoint(x: margin + 8, y: y + 8), withAttributes: watermarkAttrs)

            y += imgHeight + 16

            // ── GPS Данные ──────────────────────────────────────────
            drawSection(title: "GPS ДАННЫЕ", x: margin, y: y, width: pageWidth - margin * 2)
            y += 28

            let rows: [(String, String)] = [
                ("Координаты", location != nil ?
                    String(format: "%.6f, %.6f", location!.coordinate.latitude, location!.coordinate.longitude)
                    : "Недоступно"),
                ("Точность", location != nil ? String(format: "±%.0f м", location!.horizontalAccuracy) : "—"),
                ("Адрес", address),
                ("Высота", location != nil ? String(format: "%.0f м н.у.м.", location!.altitude) : "—"),
            ]

            for (label, value) in rows {
                drawRow(label: label, value: value, x: margin, y: y, width: pageWidth - margin * 2)
                y += 22
            }

            y += 8

            // ── ТТХ Объекта ─────────────────────────────────────────
            drawSection(title: "ТЕХНИЧЕСКИЕ ХАРАКТЕРИСТИКИ", x: margin, y: y, width: pageWidth - margin * 2)
            y += 28

            let specs: [(String, String)] = [
                ("Высота", object.height),
                ("Масса", object.weight),
                ("База", object.base),
                ("Нагрузка", object.payload),
                ("Ветровая нагрузка", object.windLoad),
                ("Материал", object.material),
                ("Стандарт", object.standard),
            ]

            // Два столбца
            let colWidth = (pageWidth - margin * 2 - 10) / 2
            for (i, (label, value)) in specs.enumerated() {
                let col = i % 2
                let row = i / 2
                let xPos = margin + CGFloat(col) * (colWidth + 10)
                let yPos = y + CGFloat(row) * 22
                drawRow(label: label, value: value, x: xPos, y: yPos, width: colWidth)
            }

            y += CGFloat((specs.count + 1) / 2) * 22 + 8

            // ── Специалист ──────────────────────────────────────────
            drawSection(title: "СПЕЦИАЛИСТ", x: margin, y: y, width: pageWidth - margin * 2)
            y += 28

            let specialist: [(String, String)] = [
                ("ФИО", specialistName),
                ("Организация", "ОсОО «Гефест Строй-Монтаж»"),
                ("Дата и время", dateStr),
            ]

            for (label, value) in specialist {
                drawRow(label: label, value: value, x: margin, y: y, width: pageWidth - margin * 2)
                y += 22
            }

            y += 20

            // ── Подпись ─────────────────────────────────────────────
            let signAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(white: 0.5, alpha: 1)
            ]

            // Линия подписи
            UIColor(white: 0.3, alpha: 1).setStroke()
            let signLine = UIBezierPath()
            signLine.move(to: CGPoint(x: margin, y: y))
            signLine.addLine(to: CGPoint(x: margin + 200, y: y))
            signLine.lineWidth = 0.5
            signLine.stroke()
            y += 4
            "Подпись специалиста".draw(at: CGPoint(x: margin, y: y), withAttributes: signAttrs)

            // Подвал
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor(white: 0.6, alpha: 1)
            ]
            let footer = "Документ сформирован автоматически в GefestAR • ОсОО «Гефест Строй-Монтаж» • НУР Телеком"
            let footerSize = (footer as NSString).size(withAttributes: footerAttrs)
            (footer as NSString).draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - 30),
                withAttributes: footerAttrs
            )
        }
    }

    // MARK: - Helpers

    private static func drawSection(title: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        let bg = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        bg.setFill()
        UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: 22), cornerRadius: 4).fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 9),
            .foregroundColor: UIColor(white: 0.4, alpha: 1)
        ]
        title.draw(at: CGPoint(x: x + 8, y: y + 6), withAttributes: attrs)
    }

    private static func drawRow(label: String, value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor(white: 0.5, alpha: 1)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.black
        ]

        label.draw(at: CGPoint(x: x + 4, y: y + 3), withAttributes: labelAttrs)

        let labelWidth = width * 0.38
        let valueRect = CGRect(x: x + labelWidth, y: y + 3, width: width - labelWidth - 4, height: 18)
        (value as NSString).draw(in: valueRect, withAttributes: valueAttrs)

        // Разделитель
        UIColor(white: 0.9, alpha: 1).setStroke()
        let sep = UIBezierPath()
        sep.move(to: CGPoint(x: x, y: y + 20))
        sep.addLine(to: CGPoint(x: x + width, y: y + 20))
        sep.lineWidth = 0.5
        sep.stroke()
    }
}
