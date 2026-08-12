/// Define the message types, fixtures, and helper functions used by protocol models.
///
/// - @returns messages the shared message module
module messages {
    import basicSpells.* from "./../../../spells/basicSpells"
    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    /// Identify a message by its content-derived string identifier.
    ///
    /// - @returns MessageId the message identifier
    type MessageId = str

    /// Represent a message and its group, timestamp, and body content.
    ///
    /// - @returns Message the complete message record
    type Message = {
        messageId: MessageId, // SHA256 hash of the message content => HASH("MESSAGE_ID", group_id, timestamp, body);
        groupId: str,
        timestamp: int,
        body: str
    }


    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    /// Map every predefined message identifier to its message fixture.
    ///
    /// - @returns MessageId -> Message the predefined messages by identifier
    pure val MESSAGES: MessageId -> Message = Map(
        message1.messageId -> message1,
        message2.messageId -> message2,
        message3.messageId -> message3,
        message4.messageId -> message4,
        message5.messageId -> message5
    )

    /// Provide a fallback message when an identifier is unknown.
    ///
    /// - @returns Message the empty fallback message
    pure val EMPTY_MESSAGE: Message = {
        messageId: "",
        groupId: "",
        timestamp: 0,
        body: ""
    }

    /// Provide the insulin-request message fixture for group alpha.
    ///
    /// - @returns Message the first predefined message
    pure val message1: Message = {
        messageId: "741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75",
        groupId: "group-alpha", 
        timestamp: 1751966400, 
        body: "Need insulin at shelter A"
    }

    /// Provide the water-offer message fixture for group alpha.
    ///
    /// - @returns Message the second predefined message
    pure val message2: Message = {
        messageId: "12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c",
        groupId: "group-alpha", 
        timestamp: 1751966400, 
        body: "Offer: 2L water near station"
    }

    /// Provide the battery-request message fixture for group bravo.
    ///
    /// - @returns Message the third predefined message
    pure val message3: Message = {
        messageId: "4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1",
        groupId: "group-bravo", 
        timestamp: 1751966400, 
        body: "Request: flashlight batteries"
    }

    /// Provide the blocked-road message fixture for group charlie.
    ///
    /// - @returns Message the fourth predefined message
    pure val message4: Message = {
        messageId: "f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e",
        groupId: "group-charlie", 
        timestamp: 1751966400, 
        body: "Road blocked at bridge"
    }

    /// Provide the medic-availability message fixture for group charlie.
    ///
    /// - @returns Message the fifth predefined message
    pure val message5: Message = {
        messageId: "2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541",
        groupId: "group-charlie", 
        timestamp: 1751966400, 
        body: "Medic available at checkpoint"
    }

    // ------------------------------------------------------------------------------------
    // GETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Retrieve a predefined message, or the empty message when its identifier is unknown.
    ///
    /// - @param messageId the identifier of the message to retrieve
    /// - @returns Message the matching message or the empty fallback message
    pure def getMessage(messageId: MessageId): Message = {
        getOrElse(MESSAGES, messageId, EMPTY_MESSAGE)
    }

    /// Retrieve the messages associated with a set of identifiers.
    ///
    /// - @param messageIds the identifiers of the messages to retrieve
    /// - @returns Set[Message] the corresponding messages
    pure def getMessages(messageIds: Set[MessageId]): Set[Message] = {
        messageIds.map(id => getMessage(id))
    }

    /// Enumerate every subset of predefined message identifiers.
    ///
    /// - @returns Set[Set[MessageId]] the powerset of predefined message identifiers
    pure def getMessageIdsPowerset(): Set[Set[MessageId]] = {
        MESSAGES.keys().powerset()
    }

    /// Nondeterministically choose a subset of predefined message identifiers.
    ///
    /// - @returns Set[MessageId] a chosen subset of predefined message identifiers
    pure def getRandomMessageIds(): Set[MessageId] = {
        getMessageIdsPowerset.chooseSome()
    }

    /// Extract the identifiers from a set of messages.
    ///
    /// - @param messages the messages whose identifiers to extract
    /// - @returns Set[MessageId] the identifiers contained in the messages
    pure def getSetMessageIds(messages: Set[Message]): Set[MessageId] = {
        messages.map(message => message.messageId)
    }

    // ------------------------------------------------------------------------------------
    // GENERAL FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Exclude every message whose identifier occurs in the supplied identifier set.
    ///
    /// - @param messages the messages to filter
    /// - @param ids the message identifiers to exclude
    /// - @returns Set[Message] the messages whose identifiers are not excluded
    pure def excludeMessagesById(
        messages: Set[Message],
        ids: Set[MessageId]
    ): Set[Message] = {
        messages.filter(message => not(message.messageId.in(ids)))
    }
}
