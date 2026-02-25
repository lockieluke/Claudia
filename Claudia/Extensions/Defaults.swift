//
//  Defaults.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import Defaults

extension Defaults.Keys {
    static let sidebarOpened = Key<Bool>("sidebarOpened", default: true)
    static let lastOrganisationId = Key<String?>("lastOrgId", default: nil)
}
