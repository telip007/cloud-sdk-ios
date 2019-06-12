//
//  PaymentEndpoints.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 10.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public extension ApiRequest {
    fileprivate static let paymentServiceVersion = "beta"

    static let paymentMethodType: String = "paymentMethod"

    /* Objects */

    class RegisterSepaDirectMethodRequest: DataContainer<SepaAttributes, Void, Void, Void> {
        public init(id: String, attributes: SepaAttributes) {
            super.init(id: id, type: paymentMethodType, attributes: attributes, relationships: nil, included: nil, meta: nil)
        }

        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    class RegisterSepaDirectMethodResponse: DataContainer<SepaAttributes, Void, Void, Void> {}
    class GetAllPaymentMethodsResponse: DataArrayContainer<SepaAttributes, PaymentTokensRelationship, DataObject<PaymentTokenAttributes, Void, Void>, Void> {}
    class GetAllPaymentMethodsWithPreAuthorizedResponse: DataArrayContainer<SepaAttributes, PaymentTokensRelationship, DataObject<PaymentTokenAttributes, Void, Void>, Void> {}

    typealias PaymentMethodData = DataObject<SepaAttributes, PaymentTokensRelationship, Void>

    struct SepaAttributes: Codable {
        public let kind: String?
        public let identificationString: String?

        let iban: String?
        let title: String?
        let firstName: String?
        let lastName: String?
        let company: String?
        let address: AddressAttributes?

        public init(iban: String?, title: String?, firstName: String?, lastName: String?, company: String?, address: AddressAttributes?, identificationString: String? = nil) {
            self.kind = "sepa"
            self.iban = iban
            self.title = title
            self.firstName = firstName
            self.lastName = lastName
            self.company = company
            self.address = address
            self.identificationString = identificationString
        }
    }

    struct AddressAttributes: Codable {
        let street: String
        let houseNo: String
        let postalCode: String
        let city: String
        let countryCode: String

        public init(street: String, houseNo: String, postalCode: String, city: String, countryCode: String) {
            self.street = street
            self.houseNo = houseNo
            self.postalCode = postalCode
            self.city = city
            self.countryCode = countryCode
        }
    }

    struct PaymentTokensRelationship: Codable {
        let paymentTokens: DataArrayContainer<Void, Void, Void, Void>?
    }

    struct PaymentTokenAttributes: Codable {
        let amount: Float
        let currency: String
        let value: String
        let validUntil: String
        let purposePRNs: [String]
    }

    /* Endpoints */

    static func registerSepaDirectMethod(host: String = Host.api.hostName, body: RegisterSepaDirectMethodRequest) -> ApiRequest {
        return JsonApiRequest(
            method: .post,
            host: host,
            path: "/pay/\(paymentServiceVersion)/payment-methods/sepa-direct-debit",
            queryItems: nil,
            body: body,
            headers: nil,
            meta: nil
        )
    }

    static func deletePaymentMethod(host: String = Host.api.hostName, paymentMethodId: String) -> ApiRequest {
        return JsonApiRequest(
            method: .delete, host: host, path: "/pay/\(paymentServiceVersion)/payment-methods/\(paymentMethodId)",
            queryItems: nil, body: nil, headers: nil, meta: nil
        )
    }

    static func getAllPaymentMethods(host: String = Host.api.hostName) -> ApiRequest {
        return JsonApiRequest(
            method: .get, host: host,
            path: "/pay/\(paymentServiceVersion)/payment-methods",
            queryItems: [], body: nil, headers: nil, meta: nil
        )
    }

    static func getReadyPaymentMethods(host: String = Host.api.hostName) -> ApiRequest {
        return JsonApiRequest(
            method: .get, host: host,
            path: "/pay/\(paymentServiceVersion)/payment-methods",
            queryItems: [URLQueryItem(name: "filter[status]", value: "valid")], body: nil, headers: nil, meta: nil
        )
    }

    static func getPreAuthorizedPaymentMethods(host: String = Host.api.hostName) -> ApiRequest {
        return JsonApiRequest(
            method: .get, host: host,
            path: "/pay/\(paymentServiceVersion)/payment-methods",
            queryItems: [URLQueryItem(name: "include", value: "paymentTokens")], body: nil, headers: nil, meta: nil
        )
    }
}
