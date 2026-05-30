//
//  PublicAPITests.swift
//  ChessCoreTests
//
//  Copyright © 2026 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

import ChessCore

@Test func serializationTypesArePubliclyInitializable() {
    _ = FENSerializer()
    _ = SANSerializer()
}
