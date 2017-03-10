
public extension String {
    
    public var pluralized: String {
        return pluralize()
    }
    
    private var length: Int {
        return  characters.count
    }
    
    private func substring(from index: Int, length: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: index)
        let end = self.index(self.startIndex, offsetBy: index + length)
        return self[start ..< end]
    }
    
    private var vowels: [String] {
        return ["a", "e", "i", "o", "u"]
    }
    
    private var consonants: [String] {
        return ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"]
    }
    
    public func pluralize(count: Int = 2) -> String {
        if count == 1 {
            return self
        }
        else {
            let lastChar = self.substring(from: self.length - 1, length: 1)
            let secondToLastChar = self.substring(from: self.length - 2, length: 1)
            var prefix = "", suffix = ""
            
            if lastChar.lowercased() == "y" && vowels.filter({x in x == secondToLastChar}).count == 0 {
                prefix = self.substring(to: index(self.endIndex, offsetBy: -1))
                suffix = "ies"
            }
            else if lastChar.lowercased() == "s" || (lastChar.lowercased() == "o" && consonants.filter({x in x == secondToLastChar}).count > 0) {
                prefix = self
                suffix = "es"
            }
            else {
                prefix = self
                suffix = "s"
            }
            
            return prefix + (lastChar != lastChar.uppercased() ? suffix : suffix.uppercased())
        }
    }
    
}
