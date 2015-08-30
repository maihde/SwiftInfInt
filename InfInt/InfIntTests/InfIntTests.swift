//
//  InfIntTests.swift
//  InfIntTests
//
//  Created by Ihde on 7/5/15.
//  Copyright (c) 2015 randomwalking.org. All rights reserved.
//

import InfInt
import XCTest

class InfIntTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConstructors() {
        let zero   = InfInt(0)
        XCTAssertEqual(zero.toInt()!, 0)
        
        let one    = InfInt(1)
        XCTAssertEqual(one.toInt()!, 1)
        
        let negone = InfInt(-1)
        XCTAssertEqual(negone.toInt()!, -1)
        
        let imin = InfInt(Int.min)
        XCTAssertEqual(imin.toInt()!, Int.min)
        
        let imax = InfInt(Int.max)
        XCTAssertEqual(imax.toInt()!, Int.max)
        
        let zeroS   = InfInt("0")
        XCTAssertEqual(zeroS.toInt()!, 0)
        
        let oneS    = InfInt("1")
        XCTAssertEqual(oneS.toInt()!, 1)
        
        let negoneS = InfInt("-1")
        XCTAssertEqual(negoneS.toInt()!, -1)
        
        let iminS = InfInt(String(Int.min))
        XCTAssertEqual(iminS.toInt()!, Int.min)
        XCTAssertEqual(iminS.toString(), String(Int.min))
        
        let imaxS = InfInt(String(Int.max))
        XCTAssertEqual(imaxS.toInt()!, Int.max)
        XCTAssertEqual(imaxS.toString(), String(Int.max))
    }
    
    func testDigits() {
        var oneDigit = InfInt(0)
        XCTAssertEqual(oneDigit[0]!, 0)
        XCTAssert(oneDigit[1] == nil)
        oneDigit[0] = 1
        XCTAssertEqual(oneDigit[0]!, 1)
        oneDigit[0] = 8
        XCTAssertEqual(oneDigit[0]!, 8)
        
        var twoDigit = InfInt(11)
        XCTAssertEqual(twoDigit[0]!, 1)
        XCTAssertEqual(twoDigit[1]!, 1)
        XCTAssert(twoDigit[2] == nil)
        twoDigit[0] = 5
        XCTAssertEqual(twoDigit.toInt()!, 15)
        twoDigit[1] = 8
        XCTAssertEqual(twoDigit.toInt()!, 85)
        twoDigit[1] = 3
        XCTAssertEqual(twoDigit.toInt()!, 35)
        twoDigit[0] = 2
        XCTAssertEqual(twoDigit.toInt()!, 32)
        
        var twentyDigits = InfInt("12345678901234567890")
        XCTAssertEqual(twentyDigits.count, 20)
        XCTAssertEqual(twentyDigits[0]!, 0)
        XCTAssertEqual(twentyDigits[1]!, 9)
        XCTAssertEqual(twentyDigits[18]!, 2)
        XCTAssertEqual(twentyDigits[19]!, 1)
        XCTAssert(twentyDigits[20] == nil)
        var cnt = 0
        var expected = 0
        for d in twentyDigits.digits {
            XCTAssertEqual(d, expected)
            ++cnt
            if (expected == 0) {
                expected = 9
            } else {
                --expected
            }
        }
        XCTAssertEqual(cnt, 20)
        twentyDigits[11] = 2
        XCTAssertEqual(twentyDigits[11]!, 2)
        XCTAssertEqual(twentyDigits.toString(), "12345678201234567890")
    }
    
    func testCompare() {
        let zero   = InfInt(0)
        let one    = InfInt(1)
        let negone = InfInt(-1)
        let imin = InfInt(Int.min)
        let imax = InfInt(Int.max)
        
        XCTAssertEqual(zero.compare(0), 0)
        XCTAssertEqual(zero.compare(zero), 0)
        XCTAssertEqual(one.compare(1), 0)
        XCTAssertEqual(one.compare(one), 0)
        XCTAssertEqual(negone.compare(-1), 0)
        XCTAssertEqual(negone.compare(negone), 0)
        XCTAssertEqual(imin.compare(Int.min), 0)
        XCTAssertEqual(imin.compare(imin), 0)
        XCTAssertEqual(imax.compare(Int.max), 0)
        XCTAssertEqual(imax.compare(imax), 0)
        
        XCTAssertEqual(zero.compare(1), -1)
        XCTAssertEqual(zero.compare(one), -1)
        XCTAssertEqual(zero.compare(Int.max), -1)
        XCTAssertEqual(zero.compare(imax), -1)
        XCTAssertEqual(zero.compare(-1), 1)
        XCTAssertEqual(zero.compare(negone), 1)
        XCTAssertEqual(zero.compare(Int.min), 1)
        XCTAssertEqual(zero.compare(imin), 1)
        
        XCTAssertEqual(imax.compare(imin), 1)
        XCTAssertEqual(imax.compare(one), 1)
        XCTAssertEqual(imax.compare(zero), 1)
        XCTAssertEqual(imax.compare(negone), 1)
        
        XCTAssertEqual(imin.compare(imax), -1)
        XCTAssertEqual(imin.compare(one), -1)
        XCTAssertEqual(imin.compare(zero), -1)
        XCTAssertEqual(imin.compare(negone), -1)
    }
    
    func testAddition() {
        let zero   = InfInt(0)
        let one    = InfInt(1)
        let negone = InfInt(-1)
        let imin = InfInt(Int.min)
        let imax = InfInt(Int.max)
        
        XCTAssert((zero + one) == one)
        XCTAssert((zero + negone) == negone)
        
        XCTAssertEqual((imax + one).toString(), "9223372036854775808")
        XCTAssertEqual((imax + negone).toString(), "9223372036854775806")
        XCTAssertEqual((imax + imin).toString(), "-1")
        XCTAssertEqual((imin + imax).toString(), "-1")
        XCTAssertEqual((imin + one).toString(), "-9223372036854775807")
        XCTAssertEqual((imin + negone).toString(), "-9223372036854775809")
        
        let a = InfInt("123456789123456789")
        let b = InfInt("987654321987654321")
        let s = a + b
        XCTAssertEqual((a + b).toString(), "1111111111111111110")
    }
    
    func testNegation() {
        let one    = InfInt(1)
        let negone = InfInt(-1)
        let imin = InfInt(Int.min)
        let imax = InfInt(Int.max)
        
        XCTAssert(-one == negone)
        XCTAssert(-negone == one)
        XCTAssertEqual((-imin).toString(), "9223372036854775808")
        XCTAssertEqual((-imax).toString(), "-9223372036854775807")
    }
    
    func testSubtraction() {
        let zero   = InfInt(0)
        let one    = InfInt(1)
        let negone = InfInt(-1)
        let imin = InfInt(Int.min)
        let imax = InfInt(Int.max)
        
        XCTAssert((zero - one) == negone)
        XCTAssert((zero - negone) == one)
        
        XCTAssertEqual((imax - one).toString(), "9223372036854775806")
        XCTAssertEqual((imax - negone).toString(), "9223372036854775808")
        XCTAssertEqual((imax - imin).toString(), "18446744073709551615")
        XCTAssertEqual((imin - imax).toString(), "-18446744073709551615")
        XCTAssertEqual((imin - one).toString(), "-9223372036854775809")
        XCTAssertEqual((imin - negone).toString(), "-9223372036854775807")
    }
    
    func testMultiplication() {
        let zero   = InfInt(0)
        let one    = InfInt(1)
        let two    = InfInt(2)
        let negone = InfInt(-1)
        let negtwo = InfInt(-2)
        let imin   = InfInt(Int.min)
        let imax   = InfInt(Int.max)
        
        XCTAssert((zero * zero) == zero)
        
        XCTAssert((zero * one) == zero)
        XCTAssert((one * zero) == zero)
        
        XCTAssert((zero * imax) == zero)
        XCTAssert((imax * zero) == zero)
        XCTAssert((zero * imax) == zero)
        
        XCTAssert((zero * imin) == zero)
        XCTAssert((imin * zero) == zero)
        
        XCTAssert((two * two) == InfInt(4))
        XCTAssert((two * imax) == InfInt("18446744073709551614"))
        XCTAssert((imax * two) == InfInt("18446744073709551614"))
        
        XCTAssert((negtwo * two) == InfInt(-4))
        XCTAssert((two * negtwo) == InfInt(-4))
        
        XCTAssert((negtwo * negtwo) == InfInt(4))
        XCTAssert((two * imin) == InfInt("-18446744073709551616"))
        XCTAssert((imin * two) == InfInt("-18446744073709551616"))
        
        let x = InfInt("100000000000000000000") * InfInt("200000000000000000000")
        XCTAssert(x == InfInt("20000000000000000000000000000000000000000"))
    }
    
    func testExponentiation() {
        let x = InfInt(2) ^^ 2
        XCTAssertEqual(x.toInt()!, 4)
        
        let y = InfInt(2) ^^ 1000
        var z = InfInt(2)
        for i in 1..<1000 {
            z = z * 2
        }
        XCTAssert(z == y)
        
        let a = InfInt(10) ^^ 2
        XCTAssertEqual(a.toInt()!, 100)
        
        let b = InfInt(10) ^^ 1000
        var c = InfInt(10)
        for i in 1..<1000 {
            c = c * 10
        }
        XCTAssert(b == c)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
