/// Define the shared per-peer payload-state variable.
///
/// - @returns payload_state the payload-state module
module payload_state {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import message_id.* from "./../types/message_id"
    import message.* from "./../types/message"
    import node.* from "./../types/node"
    import payload.* from "./../types/payload"

    /// Store the current payload for every sender-receiver pair.
    ///
    /// - @returns Node -> (Node -> Option[Payload]) the payloads indexed by sender and receiver
    var payloadState: Node -> (Node -> Option[Payload])

}
