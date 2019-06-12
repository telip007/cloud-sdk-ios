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
    var paymentTokensMethodMapping: [String: ApiRequest.PaymentTokenAttributes] {
        return included?.reduce(into: [String: ApiRequest.PaymentTokenAttributes]()) { (dict, i) in
                if let key = data.first(where: { d in
                    d.relationships?.paymentTokens?.data.contains(where: { r in r.id == i.id }) ?? false
                })?.id {
                    dict[key] = i.attributes
                }
            } ?? [:]
    }
}
