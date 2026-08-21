/// Define the message identifier type used by version 01.
///
/// - @returns message_id the message identifier type module
module message_id {
    /// Identify a message by its content-derived string identifier.
    ///
    /// - @returns MessageId the message identifier
    type MessageId = str
}