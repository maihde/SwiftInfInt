/*
* SwiftInfInt - Arbitrary-Precision Integer Arithmetic Library for Apple Swift
*
* Based off InfInt.h Copyright (C) 2013 Sercan Tutar
* Copyright (C) 2015 Michael Ihde
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with this library; if not, write to the Free Software Foundation, Inc.,
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/
import Foundation

#if INFINT_USE_SHORT_BASE
typealias ELEM_TYPE = Int16
typealias PRODUCT_TYPE = Int32
let BASE : ELEM_TYPE = 10000
let BASE_ = PRODUCT_TYPE(BASE)
let UPPER_BOUND : ELEM_TYPE = 9999
let DIGIT_COUNT : Int = 4
let DIGIT_FORMAT = "%04d"
let powersOfTen : [ELEM_TYPE] = [1, 10, 100, 1000]
#else
typealias ELEM_TYPE = Int32
typealias PRODUCT_TYPE = Int64
let BASE : ELEM_TYPE = 1000000000
let BASE_ = PRODUCT_TYPE(BASE)
let UPPER_BOUND : ELEM_TYPE = 999999999
let DIGIT_COUNT : Int = 9
let DIGIT_FORMAT = "%09d"
let powersOfTen : [ELEM_TYPE] = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000]
#endif

/// Arbitrary-Precision Integer Arithmetic Type
public struct InfInt : Streamable {
    
    private var val : [ELEM_TYPE]
    private var pos : Bool
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK Constructors
    ////////////////////////////////////////////////////////////////////////////////
    
    /// Instantiate an InfInt with a value equal to the provided string
    ///     :param: fromSTring the value to initialize the InfInt with
    public init(_ fromString: String) {
        let slen = Swift.count(fromString)
        let vlen = (slen / DIGIT_COUNT) + 1
        val = [ELEM_TYPE]()
        val.reserveCapacity(vlen)
        
        var i = fromString.endIndex
        while distance(fromString.startIndex, i) >= DIGIT_COUNT {
            i = advance(i, -DIGIT_COUNT)
            let r = Range<String.Index>(start: i, end: advance(i, DIGIT_COUNT))
            let ss = fromString.substringWithRange(r)
            if let x = ss.toInt() {
                val.append(ELEM_TYPE(x))
            }
        }
        
        let rem = distance(fromString.startIndex, i)
        if rem > 0 {
            let e = advance(fromString.startIndex, rem)
            let r = Range<String.Index>(start: fromString.startIndex, end: e)
            let ss = fromString.substringWithRange(r)
            if Swift.count(ss) == 1 && fromString[fromString.startIndex] == "=" {
                pos = false
            } else if let x = ss.toInt() {
                val.append(ELEM_TYPE(x))
            }
        }
        
        if val.last < 0 {
            val[val.count-1] = -1 * val[val.count-1]
            pos = false
        } else {
            pos = true
        }
        
        correct(justCheckLeadingZeros: true)
    }
    
    /// Instantiate an InfInt with a value equal to the provided number
    ///     :param: fromInt the value to initialize the InfInt with
    public init(_ fromInt: Int) {
        var l = fromInt;
        self.pos = (fromInt >= 0)
        if (!self.pos) {
            // Handle the corner case where the value
            // happens to be INT_MIN by adding one now
            // and then subtracting it back out later
            l = -1*(l+1)
        }
        self.val = [ELEM_TYPE]()
        do {
            let quot = l /  Int(BASE)
            let rem = l % Int(BASE)
            val.append(ELEM_TYPE(rem))
            l = quot
        } while (l > 0)
        
        if (!self.pos) {
            val[0] += 1
        }
    }
    
    /// Instantiate an InfInt with a value holder of the requested size
    ///    :param: valSize the size of val array to be initialized
    private init(valSize: Int) {
        val = [ELEM_TYPE](count: valSize, repeatedValue: 0)
        pos = true
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK Helper Functions
    ////////////////////////////////////////////////////////////////////////////////
    
    private mutating func correct(justCheckLeadingZeros : Bool = false, hasValidSign : Bool = false) {
        if (!justCheckLeadingZeros) {
            self.truncateToBase()
            
            if (equalizeSigns()) {
                if (self.val.count == 1 && self.val[0] == 0) || (!hasValidSign) {
                    self.pos = true
                }
            } else {
                self.pos = hasValidSign ? !self.pos : false
                for var i=0; i < val.count; ++i {
                    val[i] = abs(val[i])
                }
            }
        }
        self.removeLeadingZeros()
    }
    
    /// Ensures all of the numbers in the val array have positive signs
    private mutating func equalizeSigns() -> Bool {
        var isPositive = true
        var i = val.count - 1
        // Find the first non-zero element in the array
        for ; i >= 0 ; --i {
            if val[i] != 0 {
                isPositive = val[i--] > 0
                break
            }
        }
        
        if (isPositive) {
            for ; i >= 0 ; --i {
                if val[i] < 0 {
                    var k = 0
                    var index = i + 1
                    // count adjacent zeros on right
                    for ; index < val.count && val[index] == 0; ++k, ++index {}
                    val[index] -= 1
                    val[i] += BASE
                    for ; k > 0; --k {
                        val[i+k] = UPPER_BOUND
                    }
                }
            }
        } else {
            for ; i >= 0 ; --i {
                if val[i] > 0 {
                    var k = 0
                    var index = i + 1
                    // count adjacent zeros on right
                    for ; index < val.count && val[index] == 0; ++k, ++index {}
                    val[index] += 1
                    val[i] -= BASE
                    for ; k > 0; --k {
                        val[i+k] = -UPPER_BOUND
                    }
                }
            }
        }
        
        return isPositive
    }
    
    /// Normalize the numbers in the val array
    private mutating func truncateToBase() {
        for i in 0..<self.val.count {
            let l = self.val[i]
            if l >= BASE || l <= -BASE {
                let quot = l /  BASE
                let rem : ELEM_TYPE = l % BASE
                self.val[i] = rem
                if (i + 1 >= self.val.count) {
                    self.val.append(quot)
                } else {
                    self.val[i+1] += quot
                }
            }
        }
    }
    
    /// Removes leading zeros from the number
    private mutating func removeLeadingZeros() {
        for var i = self.val.count - 1; i > 0; --i {
            if self.val[i] != 0 {
                return
            } else {
                self.val.removeAtIndex(i)
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK Public Functions
    ////////////////////////////////////////////////////////////////////////////////
    
    public func toInt() -> Int? {
        let isIntMax = self.compare(INT_MAX)
        let isIntMin = self.compare(INT_MIN)
        
        if isIntMax > 0 || isIntMin < 0 {
            // TODO throw out of rangeexception
            return nil
        }
        
        // It appears that the original InfIng doesn't handle
        // the situation where INT_MIN is encoded correct, but
        // we do it here
        if isIntMax == 0 {
            return Int.max
        }
        if isIntMin == 0 {
            return Int.min
        }
        
        var result : Int = 0
        for var i = self.val.count - 1; i >= 0; --i {
            result = (result * Int(BASE)) + Int(val[i])
        }
        return pos ? result : -result
    }
    
    public func toString() -> String {
        var target = ""
        self.writeTo(&target)
        return target
    }
    
    /// Implement the Streamable interface so that InfInt can be used with print
    public func writeTo<Target : OutputStreamType>(inout target: Target) {
        if (!self.pos) {
            target.write("-")
        }
        var first = true
        for var i = self.val.count - 1; i >= 0; --i {
            if first {
                target.write(String(self.val[i]))
                first = false
            } else {
                target.write(String(format: DIGIT_FORMAT, self.val[i]))
            }
        }
    }
    
    /// Access the digit at the provided position
    public subscript(pos: Int) -> Int? {
        get {
            // Handle edge cases
            if self.count == 0 && pos == 0 {
                // if we happen to be empty, allow digits to return 0
                return 0
            } else if pos >= self.count {
                // otherwise return nil
                return nil
            }
            let pow = powersOfTen[pos % DIGIT_COUNT]
            let i = pos / DIGIT_COUNT
            return Int((self.val[i] / pow) % 10)
        }
        set {
            // Handle edge cases
            if self.count == 0 && pos == 0 {
                self.val.append(ELEM_TYPE(newValue!))
            } else if pos >= self.count {
                return
            }
            if newValue == nil {
                return
            }
            if newValue < 0 || newValue > 9 {
                return
            }
            
            let pow = powersOfTen[pos % DIGIT_COUNT]
            let i = pos / DIGIT_COUNT
            let oldDigit = Int((self.val[i] / pow) % 10)
            let digitDiff = ELEM_TYPE(newValue! - oldDigit)
            let diff = digitDiff * pow
            self.val[i] += diff
            
            self.correct()
        }
    }
    
    /// Returns the digits of the number from right to left
    public var digits : GeneratorOf<Int> {
        if self.val.count == 0 {
            var done = false
            return GeneratorOf<Int> {
                if done {
                    return nil
                } else {
                    done = true
                    return 0
                }
            }
        }
        
        let c = self.count
        var i = 0
        return GeneratorOf<Int> {
            if (i >= c) {
                return nil
            }
            return self[i++]
        }
    }
    
    /// Returns how many digits are in the number
    public var count : Int {
        if self.val.count == 0 {
            return 0
        }
        
        let v = self.val.last
        var d = (self.val.count - 1) * DIGIT_COUNT
        for pt in powersOfTen {
            if v >= pt {
                d++
            }
        }
        
        return d
    }
    
    public func compare(rhs: InfInt) -> Int {
        // if the left-hand is positive and the right is negative
        if (self.pos && !rhs.pos) {
            return 1
        }
        // if the left-hand is negative and the right is positive
        if (!self.pos && rhs.pos) {
            return -1
        }
        // if the left hand uses more 'digits'
        if (self.val.count > rhs.val.count) {
            return self.pos ? 1 : -1
        }
        // if the left hand uses fewer 'digits'
        if (self.val.count < rhs.val.count) {
            return self.pos ? -1 : 1
        }
        // they are equal length so we compare each
        for var i=self.val.count-1; i >= 0; --i {
            if self.val[i] < rhs.val[i] {
                return self.pos ? -1 : 1
            }
            if self.val[i] > rhs.val[i] {
                return self.pos ? 1 : -1
            }
        }
        // the values are equal
        return 0
    }
    
    public func compare(rhs: Int) -> Int {
        return self.compare(InfInt(rhs))
    }
    
}

////////////////////////////////////////////////////////////////////////////////
// MARK Constants
////////////////////////////////////////////////////////////////////////////////
public let ZERO = InfInt(0)
public let ONE  = InfInt(1)
public let TWO  = InfInt(2)
public let INT_MIN = InfInt(Int.min)
public let INT_MAX = InfInt(Int.max)

////////////////////////////////////////////////////////////////////////////////
// MARK Operations

/// Negation operator
public prefix func -(lhs: InfInt) -> InfInt {
    var result = lhs // this works because InfInt is a struct with by-value semantics
    result.pos = !result.pos
    return result
}

/// Addition operator
public func +(lhs: InfInt, rhs: Int) -> InfInt {
    return lhs + InfInt(rhs)
}

public func +(lhs: Int, rhs: InfInt) -> InfInt {
    return InfInt(lhs) + rhs
}

public func +(lhs: InfInt, rhs: InfInt) -> InfInt {
    let resultSize = (lhs.val.count > rhs.val.count) ? lhs.val.count : rhs.val.count
    var result = InfInt(valSize: resultSize)
    for i in 0..<resultSize {
        let lval = (i < lhs.val.count) ? lhs.val[i] : 0
        let rval = (i < rhs.val.count) ? rhs.val[i] : 0
        result.val[i] = (lhs.pos ? lval : -lval) + (rhs.pos ? rval : -rval)
    }
    result.correct()
    return result
}

/// Subtraction operator
public func -(lhs: InfInt, rhs: Int) -> InfInt {
    return lhs - InfInt(rhs)
}

public func -(lhs: Int, rhs: InfInt) -> InfInt {
    return InfInt(lhs) - rhs
}

public func -(lhs: InfInt, rhs: InfInt) -> InfInt {
    let resultSize = (lhs.val.count > rhs.val.count) ? lhs.val.count : rhs.val.count
    var result = InfInt(valSize: resultSize)
    for i in 0..<resultSize {
        let lval = (i < lhs.val.count) ? lhs.val[i] : 0
        let rval = (i < rhs.val.count) ? rhs.val[i] : 0
        result.val[i] = (lhs.pos ? lval : -lval) - (rhs.pos ? rval : -rval)
    }
    result.correct()
    return result
}

/// Multiplication operator
public func *(lhs: InfInt, rhs: Int) -> InfInt {
    var result = lhs
    var carry : PRODUCT_TYPE = 0
    for var i=0; i < result.val.count; i++ {
        var pval : PRODUCT_TYPE = PRODUCT_TYPE(result.val[i]) * PRODUCT_TYPE(rhs) + carry
        if (pval >= BASE_) || (pval <= -BASE_) {
            carry = pval / BASE_
            pval -= carry * BASE_
        } else {
            carry = 0
        }
        result.val[i] = ELEM_TYPE(pval)
    }
    if (carry > 0) {
        result.val.append(ELEM_TYPE(carry))
    }
    return result
}

public func *(lhs: Int, rhs: InfInt) -> InfInt {
    return rhs * lhs // Multiple is communative so call the above operator
}

public func *(lhs: InfInt, rhs: InfInt) -> InfInt {
    let resultSize = lhs.val.count + rhs.val.count
    var result = InfInt(valSize: resultSize)
    var carry : PRODUCT_TYPE = 0
    var digit = 0
    for ;; ++digit {
        let oldcarry = carry
        carry /= BASE_
        let val = oldcarry - carry * BASE_
        result.val[digit] = ELEM_TYPE(val)
        
        var found = false
        let startAt = (digit < rhs.val.count) ? 0 : digit - rhs.val.count + 1
        for var i=startAt; i < lhs.val.count && i <= digit; ++i {
            var pval : PRODUCT_TYPE =
            PRODUCT_TYPE(result.val[digit]) +
                PRODUCT_TYPE(lhs.val[i]) * PRODUCT_TYPE(rhs.val[digit - i])
            if pval >= BASE_ || pval <= -BASE_ {
                let quot = pval / BASE_
                carry += quot
                pval -= quot * BASE_
            }
            result.val[digit] = ELEM_TYPE(pval)
            found = true
        }
        if (!found) {
            break
        }
    }
    for ; carry > 0; ++digit {
        result.val[digit] = ELEM_TYPE(carry % BASE_)
        carry /= BASE_
    }
    
    result.correct()
    result.pos = (result.val.count == 1 && result.val[0] == 0) ? true : (lhs.pos == rhs.pos);
    return result
}

/// Implements Exponentiation by Squaring algorithm
infix operator ^^ { associativity left precedence 160 }
public func ^^(lhs: InfInt, pow: Int) -> InfInt {
    var x = lhs
    var y = InfInt(1)
    var n = pow
    
    while n > 1 {
        if n % 2 == 0 {
            x = x * x
            n = n / 2
        } else {
            y = x * y
            x = x * x
            n = (n - 1) / 2
        }
    }
    return x * y
}

////////////////////////////////////////////////////////////////////////////////
// MARK Relational operators
////////////////////////////////////////////////////////////////////////////////

public func ==(lhs: InfInt, rhs: InfInt) -> Bool {
    // Implement == directly instead of using .compare so that it can
    // be slightly faster
    if (lhs.pos != rhs.pos) || (lhs.val.count != rhs.val.count) {
        return false
    }
    for var i=lhs.val.count-1; i >= 0; --i {
        if lhs.val[i] != rhs.val[i] {
            return false
        }
    }
    return true
}

public func !=(lhs: InfInt, rhs: InfInt) -> Bool {
    return !(lhs == rhs)
}

public func <(lhs: InfInt, rhs: InfInt) -> Bool {
    return lhs.compare(rhs) < 0
}

public func <=(lhs: InfInt, rhs: InfInt) -> Bool {
    return lhs.compare(rhs) <= 0
}

public func >(lhs: InfInt, rhs: InfInt) -> Bool {
    return lhs.compare(rhs) > 0
}

public func >=(lhs: InfInt, rhs: InfInt) -> Bool {
    return lhs.compare(rhs) >= 0
}