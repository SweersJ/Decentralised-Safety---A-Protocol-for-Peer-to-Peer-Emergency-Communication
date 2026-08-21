/// Test shared message lookup and identifier getters.
///
/// - @returns tests_unit_getters the focused unit-test module
module tests_unit_getters {
    import tests_fixture.* from "fixture"

    // ------------------------------------------------------------------------------------
    // TESTS - GETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test retrieval of a predefined message by identifier.
    ///
    /// - @returns bool whether the test passes
    run getMessageTest = all {
        assert(getMessage(message1.messageId) == message1)
    }

    /// Test that an unknown identifier returns the empty fallback message.
    ///
    /// - @returns bool whether the test passes
    run getMessageUnknownTest = all {
        assert(getMessage("unknown") == EMPTY_MESSAGE)
    }

    /// Test retrieval of multiple predefined messages by identifier.
    ///
    /// - @returns bool whether the test passes
    run getMessagesTest = all {
        assert(getMessages(TEST_MESSAGE_IDS.get(ALICE)) == Set(message1, message2))
    }
    
    /// Test that an empty identifier set produces an empty message set.
    ///
    /// - @returns bool whether the test passes
    run getMessagesEmptyTest = all {
        assert(getMessages(Set()) == Set())
    }
    
    /// Test enumeration of every subset of predefined message identifiers.
    ///
    /// - @returns bool whether the test passes
    run getMessageIdsPowersetTest = all {
        assert(getMessageIdsPowerset == MESSAGE_IDS_POWERSET)
    }
    
    /// Test that a chosen identifier set belongs to the expected powerset.
    ///
    /// - @returns bool whether the test passes
    run getRandomMessageIdsTest = all {
        assert(getRandomMessageIds.in(MESSAGE_IDS_POWERSET))
    }
    
    /// Test extraction of identifiers from a set of messages.
    ///
    /// - @returns bool whether the test passes
    run getSetMessageIdsTest = all {
        assert(getSetMessageIds(getMessages(TEST_MESSAGE_IDS.get(ALICE))) == TEST_MESSAGE_IDS.get(ALICE))
    }
}
