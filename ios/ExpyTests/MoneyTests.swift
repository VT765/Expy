import Testing
@testable import Expy

struct MoneyTests {
    @Test(arguments: [(80.0, 8_000), (0.1, 10), (1003.555, 100_356), (8687.17, 868_717), (-703.0, -70_300)])
    func convertsRupeesToPaise(_ rupees: Double, _ paise: Int) {
        #expect(Money.paise(rupees) == paise)
    }

    @Test func roundTripsExactly() {
        #expect(Money.rupees(868_717) == 8687.17)
        #expect(Money.paise(Money.rupees(123_456_789)) == 123_456_789)
    }
}
