/// Test the shared message fixtures and helper functions.
///
/// -@return tests_unit the message unit-test module
module tests_unit {
    import messages.* from "./messages"

    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    /// Identify a test participant by name.
    ///
    /// -@return Node the test participant identifier
    type Node = str

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------
    
    /// Identify the Alice test participant.
    ///
    /// -@return Node Alice's node identifier
    pure val ALICE: Node = "Alice"

    /// Identify the Bob test participant.
    ///
    /// -@return Node Bob's node identifier
    pure val BOB: Node = "Bob"

    /// Associate each test participant with a deterministic set of message identifiers.
    ///
    /// -@return Node -> Set[MessageId] the test message identifiers by participant
    pure val TEST_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId, message2.messageId),
        BOB -> Set(message2.messageId)
    )

    /// Enumerate the expected powerset of the predefined message identifiers.
    ///
    /// -@return Set[Set[MessageId]] the expected message-identifier powerset
    pure val MESSAGE_IDS_POWERSET: Set[Set[MessageId]] = Set(
        Set(), // {}
        Set(message1.messageId), // {1}
        Set(message2.messageId), // {2}
        Set(message3.messageId), // {3}
        Set(message4.messageId), // {4}
        Set(message5.messageId), // {5}
        Set(message1.messageId, message2.messageId), // {1, 2}
        Set(message1.messageId, message3.messageId), // {1, 3}
        Set(message1.messageId, message4.messageId), // {1, 4}
        Set(message1.messageId, message5.messageId), // {1, 5}
        Set(message2.messageId, message3.messageId), // {2, 3}
        Set(message2.messageId, message4.messageId), // {2, 4}
        Set(message2.messageId, message5.messageId), // {2, 5}
        Set(message3.messageId, message4.messageId), // {3, 4}
        Set(message3.messageId, message5.messageId), // {3, 5}
        Set(message4.messageId, message5.messageId), // {4, 5}
        Set(message1.messageId, message2.messageId, message3.messageId), // {1, 2, 3}
        Set(message1.messageId, message2.messageId, message4.messageId), // {1, 2, 4}
        Set(message1.messageId, message2.messageId, message5.messageId), // {1, 2, 5}
        Set(message1.messageId, message3.messageId, message4.messageId), // {1, 3, 4}
        Set(message1.messageId, message3.messageId, message5.messageId), // {1, 3, 5}
        Set(message1.messageId, message4.messageId, message5.messageId), // {1, 4, 5}
        Set(message2.messageId, message3.messageId, message4.messageId), // {2, 3, 4}
        Set(message2.messageId, message3.messageId, message5.messageId), // {2, 3, 5}
        Set(message2.messageId, message4.messageId, message5.messageId), // {2, 4, 5}
        Set(message3.messageId, message4.messageId, message5.messageId), // {3, 4, 5}
        Set(message1.messageId, message2.messageId, message3.messageId, message4.messageId), // {1, 2, 3, 4}
        Set(message1.messageId, message2.messageId, message3.messageId, message5.messageId), // {1, 2, 3, 5}
        Set(message1.messageId, message2.messageId, message4.messageId, message5.messageId), // {1, 2, 4, 5}
        Set(message1.messageId, message3.messageId, message4.messageId, message5.messageId), // {1, 3, 4, 5}
        Set(message2.messageId, message3.messageId, message4.messageId, message5.messageId), // {2, 3, 4, 5}
        Set(message1.messageId, message2.messageId, message3.messageId, message4.messageId, message5.messageId) // {1, 2, 3, 4, 5}
    )

    // ------------------------------------------------------------------------------------
    // TESTS - GETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test retrieval of a predefined message by identifier.
    ///
    /// -@return bool whether the test passes
    run getMessageTest = all {
        assert(getMessage(message1.messageId) == message1)
    }

    /// Test that an unknown identifier returns the empty fallback message.
    ///
    /// -@return bool whether the test passes
    run getMessageUnknownTest = all {
        assert(getMessage("unknown") == EMPTY_MESSAGE)
    }

    /// Test retrieval of multiple predefined messages by identifier.
    ///
    /// -@return bool whether the test passes
    run getMessagesTest = all {
        assert(getMessages(TEST_MESSAGE_IDS.get(ALICE)) == Set(message1, message2))
    }
    
    /// Test that an empty identifier set produces an empty message set.
    ///
    /// -@return bool whether the test passes
    run getMessagesEmptyTest = all {
        assert(getMessages(Set()) == Set())
    }
    
    /// Test enumeration of every subset of predefined message identifiers.
    ///
    /// -@return bool whether the test passes
    run getMessageIdsPowersetTest = all {
        assert(getMessageIdsPowerset == MESSAGE_IDS_POWERSET)
    }
    
    /// Test that a chosen identifier set belongs to the expected powerset.
    ///
    /// -@return bool whether the test passes
    run getRandomMessageIdsTest = all {
        assert(getRandomMessageIds.in(MESSAGE_IDS_POWERSET))
    }
    
    /// Test extraction of identifiers from a set of messages.
    ///
    /// -@return bool whether the test passes
    run getSetMessageIdsTest = all {
        assert(getSetMessageIds(getMessages(TEST_MESSAGE_IDS.get(ALICE))) == TEST_MESSAGE_IDS.get(ALICE))
    }

    // ------------------------------------------------------------------------------------
    // TESTS - GENERAL FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test exclusion of messages whose identifiers occur in a supplied set.
    ///
    /// -@return bool whether the test passes
    run excludeMessagesByIdTest = all {
        assert(
            excludeMessagesById(
                getMessages(TEST_MESSAGE_IDS.get(ALICE)),
                TEST_MESSAGE_IDS.get(BOB)
            ) == Set(message1)
        )
    }
         
}
