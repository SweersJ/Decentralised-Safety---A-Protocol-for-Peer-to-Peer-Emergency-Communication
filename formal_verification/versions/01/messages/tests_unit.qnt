module tests_unit {
    import messages.* from "./messages"

    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    type Node = str

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------
    
    pure val ALICE: Node = "Alice"
    pure val BOB: Node = "Bob"

    pure val TEST_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId, message2.messageId),
        BOB -> Set(message2.messageId)
    )

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

    run getMessageTest = all {
        assert(getMessage(message1.messageId) == message1)
    }

    run getMessageUnknownTest = all {
        assert(getMessage("unknown") == EMPTY_MESSAGE)
    }

    run getMessagesTest = all {
        assert(getMessages(TEST_MESSAGE_IDS.get(ALICE)) == Set(message1, message2))
    }
    
    run getMessagesEmptyTest = all {
        assert(getMessages(Set()) == Set())
    }
    
    run getMessageIdsPowersetTest = all {
        assert(getMessageIdsPowerset == MESSAGE_IDS_POWERSET)
    }
    
    run getRandomMessageIdsTest = all {
        assert(getRandomMessageIds.in(MESSAGE_IDS_POWERSET))
    }
    
    run getSetMessageIdsTest = all {
        assert(getSetMessageIds(getMessages(TEST_MESSAGE_IDS.get(ALICE))) == TEST_MESSAGE_IDS.get(ALICE))
    }

    // ------------------------------------------------------------------------------------
    // TESTS - GENERAL FUNCTIONS
    // ------------------------------------------------------------------------------------

    run excludeMessagesByIdTest = all {
        assert(
            excludeMessagesById(
                getMessages(TEST_MESSAGE_IDS.get(ALICE)),
                TEST_MESSAGE_IDS.get(BOB)
            ) == Set(message1)
        )
    }
         
}
