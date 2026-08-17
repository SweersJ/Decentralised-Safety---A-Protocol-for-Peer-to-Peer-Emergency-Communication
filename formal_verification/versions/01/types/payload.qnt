/// Define the payload record type used by the batch protocol.
///
/// - @returns payload the payload record type module
module payload {
    import message_id.* from "./message_id"
    import message.* from "./message"
    import payload_id.* from "./payload_id"
    import record_state.* from "./record_state"

    /// Represent the acknowledgements, records, and messages exchanged between peers.
    ///
    /// TODO add payload type to indicate if it is a batch or interactive payload or can it be determined already from the payload itself
    ///
    /// - @returns Payload the complete batch payload
    type Payload = {
        payloadId: PayloadId,
        
        // This field contains a list (can be empty) of message identifiers informing the receiver that sender holds a specific message.
        acks: Set[MessageId],
        
        // This field contains a list (can be empty) of message identifiers that the sender would like to give to the receiver.
        offers: Set[MessageId], //only for interactive  TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        
        // This field contains a list (can be empty) of message identifiers that the sender would like to receive from the recipient.
        requests: Set[MessageId], //only for interactive  TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.

        // This field contains a list of messages (can be empty).
        messages: Set[Message]
    }
}