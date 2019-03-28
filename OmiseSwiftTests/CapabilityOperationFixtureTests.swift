import XCTest
@testable import Omise


class CapabilityOperationFixtureTests: FixtureTestCase {
    func testCapabilityRetrieve() {
        let expectation = self.expectation(description: "Capability result")

        let request = Capability.retrieve(using: testClient) { (result) in
            defer { expectation.fulfill() }
            
            switch result {
            case let .success(capability):
                XCTAssertEqual(capability.chargeLimit, Capability.Limit(min: 2000, max: 100000000))
                XCTAssertEqual(capability.transferLimit, Capability.Limit(min: 3000, max: 10_000_000_00))
                XCTAssertEqual(capability.supportedBackends.count, 8)
                XCTAssertNil(capability[.virtualAccount(.sinarmas)])
                
                if let creditCardBackend = capability.creditCardBackend {
                    XCTAssertEqual(creditCardBackend.payment, .card([]))
                    XCTAssertEqual(creditCardBackend.supportedCurrencies, [.thb, .jpy, .usd, .eur, .gbp, .sgd])
                    XCTAssertNil(creditCardBackend.limit)
                } else {
                    XCTFail("Capability doesn't have the Credit Card backend")
                }
                
                if let bayInstallmentBackend = capability[SourceType.installment(.bay)] {
                    XCTAssertEqual(
                        bayInstallmentBackend.payment,
                        .installment(.bay, availableNumberOfTerms: IndexSet(arrayLiteral: 3, 4, 6, 9, 10))
                    )
                    XCTAssertEqual(bayInstallmentBackend.supportedCurrencies, [.thb])
                    XCTAssertEqual(bayInstallmentBackend.limit, Capability.Limit(min: 20_00, max: 1_000_000_00))
                } else {
                    XCTFail("Capability doesn't have the BAY Installment backend")
                }
                
                if let ktbInternetBankingBackend = capability[SourceType.internetBanking(.ktb)] {
                    XCTAssertEqual(
                        ktbInternetBankingBackend.payment,
                        .internetBanking(.ktb)
                    )
                    XCTAssertEqual(ktbInternetBankingBackend.supportedCurrencies, [.thb])
                    XCTAssertEqual(ktbInternetBankingBackend.limit, Capability.Limit(min: 5_000_00, max: 100_000_00))
                } else {
                    XCTFail("Capability doesn't have the BAY Installment backend")
                }
                XCTAssertNil(capability[SourceType.internetBanking(.bbl)])
                
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 100_00, currency: .thb),
                        sourceType: .installment(Installment.CreateParameter(brand: .bay, numberOfTerms: 6))
                    )
                    XCTAssertTrue(capability ~= chargeParams)
                }
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 10_00, currency: .thb),
                        sourceType: .installment(Installment.CreateParameter(brand: .bay, numberOfTerms: 6))
                    )
                    XCTAssertFalse(capability ~= chargeParams)
                }
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 100_000_000_00, currency: .thb),
                        sourceType: .installment(Installment.CreateParameter(brand: .bay, numberOfTerms: 6))
                    )
                    XCTAssertFalse(capability ~= chargeParams)
                }
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 100_00, currency: .thb),
                        sourceType: .installment(Installment.CreateParameter(brand: .bay, numberOfTerms: 5))
                    )
                    XCTAssertFalse(capability ~= chargeParams)
                }
                
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 100_00, currency: .thb),
                        cardID: "card_test_123456789abcd"
                    )
                    XCTAssertTrue(capability ~= chargeParams)
                }
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 10_00, currency: .thb),
                        cardID: "card_test_123456789abcd"
                    )
                    XCTAssertFalse(capability ~= chargeParams)
                }
                do {
                    let chargeParams = ChargeParams(
                        value: Value(amount: 100_000_000_00, currency: .thb),
                        cardID: "card_test_123456789abcd"
                    )
                    XCTAssertFalse(capability ~= chargeParams)
                }

            case let .failure(error):
                XCTFail("\(error)")
            }
        }
        
        XCTAssertNotNil(request)
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testEncodeCapabilityRetrieve() throws {
        let capability = try fixturesObjectFor(type: Capability.self)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(capability)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedCapability = try decoder.decode(Capability.self, from: encodedData)
        XCTAssertEqual(capability.chargeLimit, decodedCapability.chargeLimit)
        
        XCTAssertEqual(capability.transferLimit, decodedCapability.transferLimit)
        XCTAssertEqual(capability.supportedBackends.count, decodedCapability.supportedBackends.count)
        XCTAssertNil(decodedCapability[SourceType.virtualAccount(.sinarmas)])
        
        XCTAssertEqual(capability.creditCardBackend?.payment, decodedCapability.creditCardBackend?.payment)
        XCTAssertEqual(capability.creditCardBackend?.supportedCurrencies,
                       decodedCapability.creditCardBackend?.supportedCurrencies)
        XCTAssertNil(decodedCapability.creditCardBackend?.limit)
        XCTAssertEqual(
            capability[SourceType.installment(.bay)]?.payment,
            decodedCapability[SourceType.installment(.bay)]?.payment
        )
        XCTAssertEqual(capability[SourceType.installment(.bay)]?.supportedCurrencies,
                       decodedCapability[SourceType.installment(.bay)]?.supportedCurrencies)
        XCTAssertEqual(capability[SourceType.installment(.bay)]?.limit,
                       decodedCapability[SourceType.installment(.bay)]?.limit)
    }
}
