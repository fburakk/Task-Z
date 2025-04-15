import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1.0
        
        switch hexSanitized.count {
        case 6: // RGB
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
        case 8: // RGBA
            red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func toHex() -> String? {
        guard let components = self.cgColor.components else {
            return nil
        }
        
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(red * 255),
                     lroundf(green * 255),
                     lroundf(blue * 255))
    }
    
    // MARK: - App Colors
    static let appBackground = UIColor(hex: "#1C1C1E")!
    static let appPrimary = UIColor(hex: "#7A92BF")!    // Button background color from the design
    static let appAccent = UIColor(hex: "#35C2C1")!     // Accent color (Register/Login Now text)
    static let appTextFieldBg = UIColor(hex: "#2E2E2E")! // TextField background
    static let appTextFieldAccent = UIColor(hex: "#8391A1")! // TextField border - placeholder
}
