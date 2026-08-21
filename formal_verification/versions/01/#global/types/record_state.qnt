module record_state {
    import message_id.* from "./message_id"
    import record_type.* from "./record_type"
    
    /// Associate a message identifier with its synchronisation record classification.
    /// ! only for interactive !
    ///
    /// - @returns RecordState the synchronisation record state
    type RecordState = { //TODO: add count and epoch in next version
        messageId: MessageId, // Not used as map key, but as a value to be able to track the message ID in the record state.
        recordType: RecordType // Redundant information as the record state is already stored in a specific field for only that type
    }    
}