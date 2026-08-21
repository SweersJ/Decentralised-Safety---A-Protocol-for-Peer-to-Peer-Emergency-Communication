/// Provide the shared deterministic message unit-test fixture.
///
/// - @returns tests_fixture the shared message unit-test fixture module
module tests_fixture {
    import message_id.* from "./../../../types/message_id"
    import message.* from "./../../../types/message"
    import node.* from "./../../../types/node"
    import messages.* from "./../../messages"
    export message_id.*
    export message.*
    export node.*
    export messages.*

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------
    
    /// Identify the Alice test participant.
    ///
    /// - @returns Node Alice's node identifier
    pure val ALICE: Node = "Alice"

    /// Identify the Bob test participant.
    ///
    /// - @returns Node Bob's node identifier
    pure val BOB: Node = "Bob"

    /// Associate each test participant with a deterministic set of message identifiers.
    ///
    /// - @returns Node -> Set[MessageId] the test message identifiers by participant
    pure val TEST_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId, message2.messageId),
        BOB -> Set(message2.messageId)
    )

    /// Enumerate the expected powerset of the predefined message identifiers.
    ///
    /// - @returns Set[Set[MessageId]] the expected message-identifier powerset
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
}
