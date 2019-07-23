//
//  JSONAPIExtensions.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 07.06.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

extension ApiRequest.GetAllPaymentMethodsWithPreAuthorizedResponse {
    // TODO: This is only a workaround until a proper jsonapi decoding is done
    public var paymentTokensMethodMapping: [String: [ApiRequest.PaymentTokenAttributes]] {
        var result: [String: [ApiRequest.PaymentTokenAttributes]] = [:]

        for entry in data {
            var paymentTokens: [ApiRequest.PaymentTokenAttributes] = []

            guard let tokens = entry.relationships?.paymentTokens?.data else { continue }

            for token in tokens {
                guard let paymentToken = included?.first(where: { $0.id == token.id })?.attributes else { continue }

                paymentTokens.append(paymentToken)
            }

            result[entry.id] = paymentTokens
        }

        return result
    }
}
