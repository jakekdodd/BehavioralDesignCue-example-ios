//
//  BoundlessUser.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/4/18.
//

import Foundation

class BoundlessUser: NSObject {
    internal enum IdSource: String {
        case idfa, idfv, custom, `default`
    }

    internal var idSource: IdSource {
        didSet {
            _id = nil
            _ = self.id
        }
    }

    init(idSource: IdSource = .idfv) {
        self.idSource = idSource
        super.init()
    }

    fileprivate var _customId: String?
    public func set(customId: String?) -> String? {
        let oldId = _customId
        _customId = customId?.asValidId
        BoundlessKeychain.userIdCustom = _customId

        idSource = .custom
        return oldId
    }

    public var validId: Bool {
        if idSource == .custom {
            return _customId != nil
        }
        return true
    }

    fileprivate var _id: String?
    var id: String? {
        if _id == nil {
            switch idSource {
            case .idfa:
                _id = ASIdHelper.adId()?.uuidString.asValidId
                fallthrough

            case .idfv:
                _id = UIDevice.current.identifierForVendor?.uuidString
                fallthrough

            case .default:
                _id = BoundlessKeychain.userIdDefault ?? {
                    let uuid = UUID().uuidString
                    BoundlessKeychain.userIdDefault = uuid
                    return uuid
                }()
                break

            case .custom:
                if _customId == nil {
                    _customId = BoundlessKeychain.userIdCustom
                }
                _id = _customId
            }
        }

        return _id
    }

    internal(set) var experimentGroup: String? {
        get {
            return BoundlessKeychain.userExperiementGroup
        }
        set {
            BoundlessKeychain.userExperiementGroup = newValue
        }
    }
}

fileprivate extension String {
    var asValidId: String? {
        if !self.isEmpty,
            self.count <= 36,
            self != "00000000-0000-0000-0000-000000000000",
            self.range(of: "[^a-zA-Z0-9\\-]", options: .regularExpression) == nil {
            return self
        }
        return nil
    }
}
