/// Define the message record type used by version 01.
///
/// - @returns message the message record type module
module message {
    import message_id.* from "./message_id"

    /// Represent a message and its group, timestamp, and body content.
    ///
    /// - @returns Message the complete message record
    type Message = {
        messageId: MessageId, // SHA256 hash of the message content => HASH("MESSAGE_ID", group_id, timestamp, body);
        groupId: str,
        timestamp: int,
        body: str
    }
}