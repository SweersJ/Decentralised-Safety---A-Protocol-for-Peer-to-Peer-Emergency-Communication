/// Test the pure peer-pair guard without a protocol instance.
///
/// - @returns peer_pair_tests the instance-independent peer-pair unit-test module
module peer_pair_tests {
    import unit_fixture.* from "fixture"

    /// Test that only distinct nodes form peer pairs.
    ///
    /// - @returns bool whether the test passes
    run isPeerPairTest =
        and {
            isPeerPair(ALICE, BOB),
            isPeerPair(BOB, ALICE),
            not(isPeerPair(ALICE, ALICE)),
            not(isPeerPair(BOB, BOB)),
        }
}
