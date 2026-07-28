module messages {
    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    type MessageId = str

    type Message = {
        messageId: MessageId, // SHA256 hash of the message content => HASH("MESSAGE_ID", group_id, timestamp, body);
        groupId: str,
        timestamp: int,
        body: str
    }

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    pure val MESSAGES: MessageId -> Message = Map(
        message1.messageId -> message1,
        message2.messageId -> message2,
        message3.messageId -> message3,
        message4.messageId -> message4,
        message5.messageId -> message5
    ) //TODO: maybe add a map of messageId to message to be able to retrieve the message by its ID.

    pure val EMPTY_MESSAGE: Message = {
        messageId: "",
        groupId: "",
        timestamp: 0,
        body: ""
    }

    pure val message1: Message = {
        messageId: "741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75",
        groupId: "group-alpha", 
        timestamp: 1751966400, 
        body: "Need insulin at shelter A"
    }

    pure val message2: Message = {
        messageId: "12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c",
        groupId: "group-alpha", 
        timestamp: 1751966400, 
        body: "Offer: 2L water near station"
    }

    pure val message3: Message = {
        messageId: "4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1",
        groupId: "group-bravo", 
        timestamp: 1751966400, 
        body: "Request: flashlight batteries"
    }

    pure val message4: Message = {
        messageId: "f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e",
        groupId: "group-charlie", 
        timestamp: 1751966400, 
        body: "Road blocked at bridge"
    }

    pure val message5: Message = {
        messageId: "2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541",
        groupId: "group-charlie", 
        timestamp: 1751966400, 
        body: "Medic available at checkpoint"
    }

    // ------------------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // ------------------------------------------------------------------------------------

    pure def getMessage(messageId: MessageId): Message = {
        MESSAGES.get(messageId)
    }

    pure def getMessages(messageIds: Set[MessageId]): Set[Message] = {
        messageIds.map(id => getMessage(id))
    }
}