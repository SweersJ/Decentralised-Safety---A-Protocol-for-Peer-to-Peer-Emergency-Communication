/// Define the shared message-store state variable.
///
/// - @returns message_store the message-store state module
module message_store {
    import message.* from "./../types/message"
    import node.* from "./../types/node"

    /// Store the messages persisted by each node.
    ///
    /// TODO: add a map of message identifiers to messages to support retrieval by identifier.
    ///
    /// - @returns Node -> Set[Message] the messages indexed by their storing node
    var messageStore: Node -> Set[Message]

}
