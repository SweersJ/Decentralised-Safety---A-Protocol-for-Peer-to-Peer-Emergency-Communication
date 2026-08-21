/// Test shared message transformation helpers.
///
/// - @returns tests_unit_helpers the focused unit-test module
module tests_unit_helpers {
    import tests_fixture.* from "tests_fixture"

    // ------------------------------------------------------------------------------------
    // TESTS - GENERAL FUNCTIONS
    // ------------------------------------------------------------------------------------
    
    /// Test exclusion of messages whose identifiers occur in a supplied set.
    ///
    /// - @returns bool whether the test passes
    run excludeMessagesByIdTest = all {
        assert(
            excludeMessagesById(
                getMessages(TEST_MESSAGE_IDS.get(ALICE)),
                TEST_MESSAGE_IDS.get(BOB)
            ) == Set(message1)
        )
    }
}
