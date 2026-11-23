import Foundation
import Testing
@testable import Expy

struct BankMessageParserTests {
    private let now = TestData.date(2026, 11, 23, 18, 30)

    @Test func hdfcUpiSent() throws {
        let sms = """
        Sent Rs.1950.00
        From HDFC Bank A/C *6821
        To MANISH JADEJA
        On 23/11/26
        Ref 007303004202
        Not You?
        Call 18002586161/SMS BLOCK UPI to 7308080808
        """
        let p = try #require(BankMessageParser.parse(sms, now: now))
        #expect(p.kind == .expense)
        #expect(p.amount == 1950)
        #expect(p.last4 == "6821")
        #expect(p.bank == "HDFC")
        #expect(p.counterparty == "Manish Jadeja")
        #expect(p.reference == "007303004202")
        #expect(p.date == now) // today: keeps the time it arrived
    }

    @Test func hdfcUpiCredit() throws {
        let sms = "Credit Alert!\nRs.500.00 credited to HDFC Bank A/c XX6821 on 21-11-26 from VPA rahul.shah@okicici (UPI 433012345678)"
        let p = try #require(BankMessageParser.parse(sms, now: now))
        #expect(p.kind == .credit)
        #expect(p.amount == 500)
        #expect(p.last4 == "6821")
        #expect(p.counterparty == "Rahul Shah")
        #expect(p.reference == "433012345678")
        #expect(TestData.calendar.component(.day, from: p.date) == 21)
    }

    @Test func bobUpiDebitWithBalance() throws {
        let sms = "Rs.320.00 Dr. from A/C XXXXXX4417 and Cr. to swiggy@axisbank. Ref:432198765432. AvlBal:Rs12,450.75(2026:11:23 13:05:11). Not you? Call 18005700-BOB"
        let p = try #require(BankMessageParser.parse(sms, now: now))
        #expect(p.kind == .expense)
        #expect(p.amount == 320) // not the balance
        #expect(p.last4 == "4417")
        #expect(p.bank == "BoB")
        #expect(p.counterparty == "Swiggy")
    }

    @Test func cardSpend() throws {
        let sms = "Spent Rs.2,499 On HDFC Bank Card 9912 At AMAZON PAY On 2026-11-22:19:44:10.Not You? To Block+Reissue Call 18002586161"
        let p = try #require(BankMessageParser.parse(sms, now: now))
        #expect(p.kind == .expense)
        #expect(p.amount == 2499)
        #expect(p.last4 == "9912")
        #expect(p.counterparty == "Amazon Pay")
    }

    @Test func salaryNeftCredit() throws {
        let sms = "Dear Customer, INR 85,000.00 credited to your A/c No XX1234 on 01-11-2026 by NEFT from ACME TECHNOLOGIES PVT LTD. Avl Bal INR 1,02,345.00 -SBI"
        let p = try #require(BankMessageParser.parse(sms, now: now))
        #expect(p.kind == .credit)
        #expect(p.amount == 85000)
        #expect(p.last4 == "1234")
        #expect(p.bank == "SBI")
        #expect(p.counterparty == "Acme Technologies PVT LTD")
    }

    @Test(arguments: [
        "123456 is your OTP for txn of Rs.1950 at AMAZON. Do not share.",
        "Rahul has requested money Rs.300 from you on Google Pay",
        "Rs.649 will be debited from your A/c XX6821 on 15-12-26 for Netflix mandate",
        "Your HDFC Bank credit card bill of Rs.12,000 is due on 05-12-26",
        // Balance-only alert
        "Avl bal in HDFC Bank A/c XX6821 is Rs.12,450.75 as on 23-11-26",
        // Failed / declined attempts
        "Txn of Rs.1,950.00 from HDFC Bank A/c XX6821 to MANISH JADEJA failed. Ref 007303004299",
        "Your HDFC Bank Card 9912 transaction of Rs.2,499 at AMAZON was declined due to insufficient balance",
        "UPI payment of Rs.320 from A/C XXXXXX4417 was unsuccessful. Ref:432198765499 -BOB",
        // Promotions
        "Get Rs.500 cashback credited on your next spend with BOB Card! T&C apply",
        "Pre-approved personal loan of Rs.5,00,000 credited instantly. Apply now - HDFC Bank",
        "Congratulations! You are eligible for an offer: Rs.200 off on recharge paid via HDFC Bank UPI",
        // Statement summary
        "HDFC Bank Card XX9912 statement: total due Rs.8,200, min due Rs.400",
    ])
    func ignoresNonTransactions(_ text: String) {
        #expect(BankMessageParser.parse(text, now: now) == nil)
    }

    @Test func reversalIsACredit() throws {
        let p = try #require(BankMessageParser.parse("Rs.1950.00 reversed to your HDFC Bank A/c XX6821 on 23-11-26. Ref 007303004202", now: now))
        #expect(p.kind == .credit)
        #expect(p.amount == 1950)
    }

    @Test func transactionWithoutAccountOrReferenceIsIgnored() {
        // An amount and a money word, but nothing tying it to your account: treated as marketing.
        #expect(BankMessageParser.parse("Rs.100 credited as welcome bonus! Shop now at example.com", now: now) == nil)
    }
}
