import UIKit

var greeting = "Memory layout"

// 1 byte = 8 bit
// 1 word = 8 byte (or 64 bit)

// MARK: - MEMORY LAYOUT AND SIZE

struct FullResume {
    let id: String         // 16 byte (128 bit)
    let age: Int           // 8 byte (64 bit)
    let hashVehicle: Bool  // 1 byte (8 bit)
}

// Memory layout of FullResume

/// Размер вычисляется достаточно просто — это сумма всех его полей. Как мы можем увидеть, String занимает 16 байт, Int — 8 байт, а Bool — 1 байт.

MemoryLayout<FullResume>.size // 25 byte


// Memory layout of String

MemoryLayout<String>.size // 16 byte

// Memory layout of Int

MemoryLayout<Int>.size    // 8 byte
MemoryLayout<Int8>.size   // 1 byte
MemoryLayout<Int16>.size  // 2 byte
MemoryLayout<Int32>.size  // 4 byte
MemoryLayout<Int64>.size  // 8 byte (equal to Int)

// Memory layout of Bool

MemoryLayout<Bool>.size   // 1 byte

// Memory layout of Float, Double

MemoryLayout<Float>.size  // 4 bute
MemoryLayout<Double>.size // 8 byte

MemoryLayout<Array<Bool>>.size


// MARK: - SWAPING BOOL on first place IN OUR STRUCT


struct FullResumeWithSwapBool {
    let hashVehicle: Bool  // 1 byte (8 bit)
    let id: String         // 16 byte (128 bit)
    let age: Int           // 8 byte (64 bit)
}

/// Немного неожиданный результат: перестановкой мы заняли только больше памяти. Что ж, давайте разбираться дальше.

var bytes = MemoryLayout<FullResumeWithSwapBool>.size // 32 byte
withUnsafeBytes(of: &bytes) { pointer in
    print(pointer)
}


// MARK: - STRIDE

struct ShortResume {
    let age: Int32 // 4 byte
    let hashVehicle: Bool // 1 byte
}

MemoryLayout<ShortResume>.size // 5 byte
MemoryLayout<ShortResume>.stride // шаг - промежуток между элементами, всегда больше или равен size

let firstResume = ShortResume(age: 22, hashVehicle: true)
// | 22 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
let seconsResume = ShortResume(age: 18, hashVehicle: false)
// | 18 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

/// Благодаря шагу мы знаем, на сколько байтов нужно двигать указатель, чтобы добраться до следующего объекта. Можно заметить, что между первым и вторым резюме остается свободные 3 байта.

// MARK: - ALIGMENT

/// Суть выравнивания в том, чтобы сделать как можно меньше обращений к памяти для получения данных — это позволит работать программе максимально быстро.
/// У всех простых типов в Swift есть свое выравнивание. Простой Int или String должен выравниваться по 8 байт, Int32 и Int16 требуют меньше выравнивания — 4 и 2 байта соответственно, а для Bool достаточно одного. Как можно заметить, для простых типов выравнивание равно размеру:

MemoryLayout<String>.alignment // 8
MemoryLayout<Int>.alignment // 8
MemoryLayout<Int32>.alignment // 4
MemoryLayout<Int16>.alignment // 2
MemoryLayout<Bool>.alignment // 1

// Возвращаясь к нашему FullResume (из которого был убран только String), можно заметить следующее: размер  —  9, выравнивание  —  8, шаг  —  16. Каждое свойство выровнено, мы можем получить любое значение свойства из резюме за один цикл чтения памяти.

struct ShortResume2 {
    let age: Int // 8 byte - выравнивание
    let hashVehicle: Bool // 1 byte
}

MemoryLayout<ShortResume2>.size      // 9 byte
MemoryLayout<ShortResume2>.stride    // 16 byte
MemoryLayout<ShortResume2>.alignment // 8 byte

/// Выравнивание всей структуры рассчитывается достаточно просто  —  это наибольшее выравнивание из всех свойств. Если мы заменим Int на Int16, у которого выравнивание равно 2, то и вся структура будет иметь выравнивание 2.
/// Шаг считается также просто, но немного хитрее  —  это размер округленный в большую сторону, кратный выравниванию. Именно поэтому при размере структуры равному 9 байт следующим числом, кратным 8, будет 16.

// MARK: Check yourself

struct Test {
    let firstBool: Bool // 1 byte = 8 byte
    let array: [Bool] // 8 byte встает на след после 1 кратное 8, то есть на 8 ===> 8 + 8 = 16 byte
    let secondBool: Bool // 1 byte = 16 byte + 1 = 17 byte
    let smallInt: Int32 // 4 byte = встает на след после 17 кратное 4, значит 20 ===> 24
}

let test = Test(firstBool: true, array: [true, false], secondBool: true, smallInt: 22)

// | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |   | 192 | 88 | 222 | 1 | 0 | 96 | 0 | 0 |   | 1 | 0 | 0 | 0 | 22 | 0 | 0 | 0 |


MemoryLayout<Test>.size // 24 byte
MemoryLayout<Test>.alignment // 8 byte
MemoryLayout<Test>.stride // 24 byte

// MARK: Class

class PaidService {
    let id: String = ""     // 16
    let name: String = ""  // 32
    let isActive: Bool =  false  // 40 (8 Bool (1 + 7 alignment))
    let expiresAt: Date? = nil // 56 (8 Date + 8 Optional (1 + 7 alignment)) + 16 metadata (isa ptr + ref count)
}

MemoryLayout<PaidService>.size
MemoryLayout<PaidService>.alignment
MemoryLayout<PaidService>.stride

/// Что ж, везде будет 8, потому что классы — ссылочный тип, а все ссылки равны 8 байтам (на 64-битной машине).
/// Чтобы узнать реальный размер, занимаемый в куче, нужно воспользоваться Objective-C runtime функцией  —  class_getInstanceSize(_:). В этом случае получится:
/// 16 * 2 String + 8 Bool (1 + 7 alignment) + 8 Date + 8 Optional (1 + 7 alignment) + 16 metadata (isa ptr + ref count)

class_getInstanceSize(PaidService.self) // 72

