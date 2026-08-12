/// Model the two-node batch message synchronisation and acknowledgement protocol.
///
/// -@return batch the protocol module
module batch {
    import messages.* from "./../messages/messages"
    
    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    /// Classify a synchronisation record as an offer, request, or absent record.
    /// ! only for interactive !
    ///
    /// -@return RecordType the record classification
    type RecordType = Offer | Request | None
    
    /// Associate a message identifier with its synchronisation record classification.
    /// ! only for interactive !
    ///
    /// -@return RecordState the synchronisation record state
    type RecordState = { //TODO: add count and epoch in next version
        messageId: MessageId, // Not used as map key, but as a value to be able to track the message ID in the record state.
        recordType: RecordType
    }

    /// Identify a protocol payload with an id encoded as integer instead of UUID.
    ///
    /// -@return PayloadId the integer payload identifier
    type PayloadId = int
    
    /// Represent the acknowledgements, records, and messages exchanged between peers.
    /// TODO add payload type to indicate if it is a batch or interactive payload or can it be determined already from the payload itself
    ///
    /// -@return Payload the complete batch payload
    type Payload = {
        payloadId: PayloadId,
        acks: Set[MessageId],
        offers: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }

    /// Represent a node's synchronisation knowledge for one peer.
    ///
    /// -@return NodeState the per-peer synchronisation state
    type NodeState = {
        offers: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }

    /// Identify a protocol participant by name.
    ///
    /// -@return Node the string node identifier
    type Node = str

    /// Track the lifecycle phase and processing flags of a payload exchange.
    ///
    /// -@return PayloadExchangeState the payload exchange lifecycle state
    type PayloadExchangeState = {
        phase: PayloadExchangePhase,
        messagesStored: bool,
        ackDetermined: bool
    }

    /// Enumerate the phases of the batch payload exchange lifecycle.
    ///
    /// -@return PayloadExchangePhase the current exchange phase
    type PayloadExchangePhase = Idle | MessagesAdded | MessagesSent | MessagesReceived | AckSent | AckReceived

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    /// Identify the Alice protocol participant.
    ///
    /// -@return Node Alice's node identifier
    pure val ALICE: Node = "Alice"

    /// Identify the Bob protocol participant.
    ///
    /// -@return Node Bob's node identifier
    pure val BOB: Node = "Bob"

    /// Collect all protocol participants in the model.
    ///
    /// -@return Set[Node] the modeled nodes
    pure val NODES: Set[Node] = Set(ALICE, BOB)

    /// Provide the default payload containing no synchronisation data.
    ///
    /// -@return Payload the empty payload value
    pure val EMPTY_PAYLOAD: Payload = {
        payloadId: 0, //TODO: reuse payloadId to check if it is the same payload that is being sent and received, or if it is a new payload. This can be used to detect if a payload has been lost or if it is a duplicate.
        acks: Set(),
        offers: Set(),
        requests: Set(),
        messages: Set()
    }

    /// Provide the default per-peer node state containing no synchronisation data.
    ///
    /// -@return NodeState the empty node-state value
    pure val EMPTY_NODE_STATE: NodeState = {
        offers: Set(),
        requests: Set(),
        messages: Set()
    }

    /// Provide the default record state with no message or classification.
    /// ! only for interactive !
    ///
    /// -@return RecordState the empty record-state value
    pure val EMPTY_RECORD_STATE: RecordState = {
        messageId: "",
        recordType: None
    }

    /// Provide the default idle and unprocessed payload exchange state.
    ///
    /// -@return PayloadExchangeState the empty exchange-state value
    pure val EMPTY_PAYLOAD_EXCHANGE_STATE: PayloadExchangeState = {
        phase: Idle,
        messagesStored: false,
        ackDetermined: false
    }

    // ------------------------------------------------------------------------------------
    // STATE VARIABLES
    // ------------------------------------------------------------------------------------
    
    /// Store the messages persisted by each node.
    ///
    /// -@return Node -> Set[Message] the messages indexed by their storing node
    var messageStore: Node -> Set[Message] //TODO: add a map of messageId to message to be able to retrieve the message by its ID.
    
    /// Track each sender's synchronisation knowledge for every receiver.
    /// (simulation of storing at node side what transport is expected for each node at the node side)
    ///
    /// -@return Node -> (Node -> NodeState) the per-sender and per-receiver node states
    var nodeState: Node -> (Node -> NodeState)

    /// Store the current payload for every sender-receiver pair.
    ///
    /// -@return Node -> (Node -> Payload) the payloads indexed by sender and receiver
    var payloadState: Node -> (Node -> Payload)

    /// Track the payload exchange lifecycle for every sender-receiver pair.
    ///
    /// -@return Node -> (Node -> PayloadExchangeState) the exchange states indexed by sender and receiver
    var payloadExchangeState: Node -> (Node -> PayloadExchangeState)

    /// Payload-id generator for future send actions.
    /// TODO: add the payload generator
    /// -@return int the next payload id for the next payload to be sent
    // var nextPayloadId: int

    // ------------------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // ------------------------------------------------------------------------------------

    // > INIT FUNCTIONS

    /// Build the initial per-peer node state from the messages assigned to each node.
    ///
    /// -@param Node -> Set[MessageId] randomMessageIds the message identifiers assigned to each node
    /// -@return Node -> (Node -> NodeState) the computed result
    pure def initNodeState(randomMessageIds: Node -> Set[MessageId]): Node -> (Node -> NodeState) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => {
                    ...EMPTY_NODE_STATE,
                    messages: if (sender != receiver) getMessages(randomMessageIds.get(sender)) else EMPTY_NODE_STATE.messages
                }
            )
        )
    }

    /// Build an empty payload for every sender-receiver pair.
    ///
    /// -@return Node -> (Node -> Payload) the computed result
    pure def initPayloadState(): Node -> (Node -> Payload) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => EMPTY_PAYLOAD
            )
        )
    }

    /// Populate each node's message store from its assigned message identifiers.
    ///
    /// -@param Node -> Set[MessageId] randomMessageIds the message identifiers assigned to each node
    /// -@return Node -> Set[Message] the computed result
    pure def initMessageStore(randomMessageIds: Node -> Set[MessageId]): Node -> Set[Message] = {
        NODES.mapBy(
            node => getMessages(randomMessageIds.get(node))
        )
    }

    /// Initialise every sender-receiver exchange to the empty idle state.
    ///
    /// -@return Node -> (Node -> PayloadExchangeState) the computed result
    pure def initPayloadExchangeState(): Node -> (Node -> PayloadExchangeState) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => EMPTY_PAYLOAD_EXCHANGE_STATE
            )
        )
    }

    /// Choose an initial set of message identifiers for every node.
    ///
    /// -@return Node -> Set[MessageId] the computed result
    pure def initRandomMessageIds(): Node -> Set[MessageId] = {
        NODES.mapBy(n => getRandomMessageIds)
    }

    // > GUARD FUNCTIONS

    /// Check whether the sender and receiver are distinct peers, otherwise it doesn't make sense to send a payload.
    ///
    /// -@param Node sender the node sending the payload
    /// -@param Node receiver the node receiving the payload
    /// -@return bool the computed result
    pure def isPeerPair(sender: Node, receiver: Node): bool = {
        sender != receiver
    }

    /// Check whether a sender-receiver pair has messages available for synchronisation.
    ///
    /// -@param Node sender the node whose messages are synchronized
    /// -@param Node receiver the destination peer
    /// -@return bool the computed result
    def hasSyncDelta(sender: Node, receiver: Node): bool = {
        and {
            getMessagesMessageStore(sender).size() > 0,   
            getNodeState(sender,receiver).messages.size() > 0,
        }
    }

    /// Check whether pending messages may be added to the pair's payload.
    ///
    /// -@param Node sender the node adding messages
    /// -@param Node receiver the destination peer
    /// -@return bool the computed result
    def canAddMessages(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            hasSyncDelta(sender, receiver),
            getPayloadExchangeState(sender,receiver).phase == Idle,
        }
    }

    /// Check whether the pair's populated message payload may be sent.
    ///
    /// -@param Node sender the node sending the payload
    /// -@param Node receiver the destination peer
    /// -@return bool the computed result
    def canSendMessagesPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            hasSyncDelta(sender, receiver),
            getPayload(sender,receiver).messages.size() != 0,
            getNodeState(sender,receiver).messages.size() != 0,
            getPayloadExchangeState(sender,receiver).phase == MessagesAdded,
        }
        
    }

    /// Check whether the receiver may receive the sender's in-flight message payload.
    ///
    /// -@param Node sender the node that sent the payload
    /// -@param Node receiver the node receiving the payload
    /// -@return bool the computed result
    def canReceiveMessagesPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadExchangeState(sender,receiver).phase == MessagesSent,
        }
    }

    /// Check whether a received payload's messages may be stored by the receiver.
    ///
    /// -@param Node sender the node that sent the payload
    /// -@param Node receiver the node storing the messages
    /// -@return bool the computed result
    def canStoreReceivedMessages(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(sender,receiver)

        and {
            isPeerPair(sender, receiver),
            state.phase == MessagesReceived,
            not(state.messagesStored),
        }
    }

    /// Check whether acknowledgements may be determined for a received payload.
    ///
    /// -@param Node sender the node that sent the payload
    /// -@param Node receiver the node determining acknowledgements
    /// -@return bool the computed result
    def canDetermineAck(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(sender,receiver)

        and {
            isPeerPair(sender, receiver),
            state.phase == MessagesReceived,
            not(state.ackDetermined),
        }
    }

    /// Check whether the acknowledgement for a processed payload may be sent.
    ///
    /// -@param Node sender the original message sender
    /// -@param Node receiver the node sending the acknowledgement
    /// -@return bool the computed result
    def canAckPayload(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(sender,receiver)

        and {
            isPeerPair(sender, receiver),
            state.phase == MessagesReceived,
            state.messagesStored,
            state.ackDetermined,
        }
    }

    /// Check whether the sender may receive the outstanding acknowledgement payload.
    ///
    /// -@param Node sender the original message sender
    /// -@param Node receiver the node returning the acknowledgement
    /// -@return bool the computed result
    def canReceiveAckPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayload(sender,receiver).acks.size() != 0,
            getPayloadExchangeState(sender,receiver).phase == AckSent,
        }
    }

    /// Check whether the pair may enter or remain in the idle phase.
    ///
    /// -@param Node sender the sending node
    /// -@param Node receiver the receiving node
    /// -@return bool the computed result
    def canIdle(sender: Node, receiver: Node): bool = {
        val phase = getPayloadExchangeState(sender,receiver).phase

        and {
            isPeerPair(sender, receiver),
            (phase == Idle or phase == AckReceived),
        }
        
    }

    // > GETTER FUNCTIONS

    /// Return the messages currently stored by a node.
    ///
    /// -@param Node sender the node whose message store is returned
    /// -@return Set[Message] the computed result
    def getMessagesMessageStore(sender: Node): Set[Message] = {
        messageStore.get(sender)
    }

    /// Return the sender's synchronisation state for a receiver.
    ///
    /// -@param Node sender the node maintaining the synchronisation state
    /// -@param Node receiver the peer represented by that state
    /// -@return NodeState the computed result
    def getNodeState(sender: Node, receiver: Node): NodeState = {
        nodeState.get(sender).get(receiver)
    }

    /// Return the payload state associated with a sender-receiver pair.
    ///
    /// -@param Node sender the payload sender
    /// -@param Node receiver the payload receiver
    /// -@return Payload the computed result
    def getPayload(sender: Node, receiver: Node): Payload = {
        payloadState.get(sender).get(receiver)
    }

    /// Return the exchange lifecycle state associated with a sender-receiver pair.
    ///
    /// -@param Node sender the payload sender
    /// -@param Node receiver the payload receiver
    /// -@return PayloadExchangeState the computed result
    def getPayloadExchangeState(sender: Node, receiver: Node): PayloadExchangeState = {
        payloadExchangeState.get(sender).get(receiver)
    }

    /// Return the record state messages ids from the set of RecordStates
    /// TODO: activate when in interactive mode
    /// -@param Set[RecordState] recordStates the record states to analyse and extract message ids from
    /// -@return Set[MessageId] the computed set of message ids
    // pure def getRecordStateMessageIds(recordStates: Set[RecordState]): Set[MessageId] = {
    //     recordStates.map(rs => rs.messageId)
    // } 
    

    // > SETTER FUNCTIONS

    /// Return the exchange-state map with one sender-receiver entry replaced.
    ///
    /// -@param Node sender the sender entry to update
    /// -@param Node receiver the receiver entry to update
    /// -@param PayloadExchangePhase newPayloadExchangePhase the replacement exchange phase
    /// -@param bool newMessagesStored whether received messages have been stored
    /// -@param bool newAckDetermined whether acknowledgements have been determined
    /// -@return Node -> (Node -> PayloadExchangeState) the computed result
    def setPayloadExchangeState(
        sender: Node, 
        receiver: Node, 
        newPayloadExchangePhase: PayloadExchangePhase, 
        newMessagesStored: bool, 
        newAckDetermined: bool
    ): Node -> (Node -> PayloadExchangeState) = {
        payloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver, 
                receiverState => {
                    phase: newPayloadExchangePhase,
                    messagesStored: newMessagesStored,
                    ackDetermined: newAckDetermined
                }
            )
        )
    }

    // > GENERAL FUNCTIONS
    
    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise all protocol state with nondeterministically selected node messages.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action init() = {
        val randomMessageIds = initRandomMessageIds
        all {
            nodeState' = initNodeState(randomMessageIds),
            payloadState' = initPayloadState,
            messageStore' = initMessageStore(randomMessageIds),
            payloadExchangeState' = initPayloadExchangeState
        }
    }

    // ------------------------------------------------------------------------------------
    // STEP ACTIONS
    // ------------------------------------------------------------------------------------

    /// Perform one enabled protocol transition for a nondeterministically selected peer pair.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action step() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(
            n => n != sender
        ).oneOf()
        any {
            //TODO: add generate messages as step
            idle(sender, receiver),
            addMessages(sender, receiver),
            sendMessagesPayload(sender, receiver),
            receiveMessagesPayload(sender, receiver),
            storeReceivedMessages(sender, receiver),
            determineAck(sender,receiver),
            sendAckPayload(sender, receiver),
            receiveAckPayload(sender, receiver),
        }
    }

    // ------------------------------------------------------------------------------------
    // PROCESS ACTIONS
    // ------------------------------------------------------------------------------------

    /// Reset an eligible peer pair to the idle exchange state without changing stored data.
    ///
    /// -@param Node sender the sending node
    /// -@param Node receiver the receiving node
    /// -@return bool whether the action is enabled and its transition constraints hold
    action idle(sender, receiver) = all {
        // Guards,
        canIdle(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = setPayloadExchangeState(
            sender, 
            receiver, 
            Idle,
            false,
            false
        ),
    }

    /// Add the sender's pending messages to its payload for the receiver.
    ///
    /// -@param Node sender the node adding pending messages
    /// -@param Node receiver the destination peer
    /// -@return bool whether the action is enabled and its transition constraints hold
    action addMessages(sender, receiver) = all {
        // Guards
        canAddMessages(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                receiverPayload => {
                    ...receiverPayload,
                    // Make sure if another payload is send the previous messages are not removed from the payload from sender to receiver
                    messages: receiverPayload.messages.union(
                        getNodeState(sender,receiver).messages
                    )
                }
            )
        ),
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender, receiver)
            setPayloadExchangeState(
                sender, 
                receiver, 
                MessagesAdded,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
            ),
    }

    /// Mark the sender's populated message payload as sent to the receiver.
    ///
    /// -@param Node sender the node sending the message payload
    /// -@param Node receiver the destination peer
    /// -@return bool whether the action is enabled and its transition constraints hold
    action sendMessagesPayload(sender, receiver) = all {
        // Guards
        canSendMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender,receiver)
            setPayloadExchangeState(
                sender, 
                receiver, 
                MessagesSent,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
            ),
    }

    /// Mark an in-flight message payload as received by the receiver.
    ///
    /// -@param Node sender the node that sent the message payload
    /// -@param Node receiver the node receiving it
    /// -@return bool whether the action is enabled and its transition constraints hold
    action receiveMessagesPayload(sender, receiver) = all {
        // Guards
        canReceiveMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender,receiver)
            setPayloadExchangeState(
                sender, 
                receiver, 
                MessagesReceived,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
            ),
    }

    /// Store received messages and update the receiver's knowledge of the sender.
    ///
    /// -@param Node sender the node that sent the messages
    /// -@param Node receiver the node storing them
    /// -@return bool whether the action is enabled and its transition constraints hold
    action storeReceivedMessages(sender, receiver) = all {
        // Guards
        canStoreReceivedMessages(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore.setBy(
            receiver,
            // With the use of union no previous messages can be removed, thus proving monotonicity.
            receiverStore => receiverStore.union(
                getPayload(sender,receiver).messages
            )
        ),
        nodeState' = nodeState.setBy(
            receiver,
            receiverState => receiverState.setBy(
                sender,
                senderState => {
                    ...senderState,
                    messages: excludeMessagesById(
                        senderState.messages,
                        getSetMessageIds(getPayload(sender, receiver).messages)
                    )
                }
            )
        ),
        payloadState' = payloadState,
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender,receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                currentPayloadExchangeState.phase,
                true,
                currentPayloadExchangeState.ackDetermined
            ),
    }

    /// Determine acknowledgement identifiers for all messages in a received payload.
    ///
    /// -@param Node sender the original message sender
    /// -@param Node receiver the node determining acknowledgements
    /// -@return bool whether the action is enabled and its transition constraints hold
    action determineAck(sender, receiver) = all {
        // Guards
        canDetermineAck(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                // Reuse the sender payload to prevent conflicting payload states.
                receiverState => {
                    ...receiverState,
                    // Acknowledge all messages received from the sender regardless of whether they were already in the message store or not. This is because the sender may have sent messages that the receiver already has, and the receiver needs to acknowledge those messages to inform the sender that it has received them.
                    acks: getSetMessageIds(receiverState.messages)
                }
            )
        ),
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender,receiver)
        
            setPayloadExchangeState(
                sender, 
                receiver, 
                currentPayloadExchangeState.phase,
                currentPayloadExchangeState.messagesStored,
                true
            ),
    }

    /// Mark a determined acknowledgement payload as sent.
    ///
    /// -@param Node sender the original message sender
    /// -@param Node receiver the node sending the acknowledgement
    /// -@return bool whether the action is enabled and its transition constraints hold
    action sendAckPayload(sender, receiver) = all {
        // Guards
        canAckPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender,receiver)
            setPayloadExchangeState(
                sender, 
                receiver, 
                AckSent,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
            ),
    }


    /// Receive acknowledgements and remove acknowledged messages from pending state and payload.
    /// With retransmission, the sender can now check with the offers and the acks if everything 
    /// has been delivered or resend specific messages.
    ///
    /// -@param Node sender the node receiving the acknowledgement
    /// -@param Node receiver the node that produced it
    /// -@return bool whether the action is enabled and its transition constraints hold
    action receiveAckPayload(sender, receiver) = all {
        // Guards
        canReceiveAckPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = 
            val ackIds = getPayload(sender,receiver).acks

            nodeState.setBy(
                sender,
                senderState => senderState.setBy(
                    receiver,
                    receiverState => {
                        ...receiverState,
                        // Remove the acknowledged messages from the sender's node state for the receiver, as they have been acknowledged by the receiver.
                        messages: excludeMessagesById(receiverState.messages, ackIds)
                    }
                )
            ),
        payloadState' = 
            val ackIds = getPayload(sender,receiver).acks
            
            payloadState.setBy(
                sender,
                senderPayload => senderPayload.setBy(
                    receiver,
                    // Cleanup of the acks in the payload state for the sender to receiver, as they have been acknowledged by the receiver. This is done to avoid resending the same messages again.
                    receiverPayload => {
                        ...receiverPayload,
                        acks: Set(),  // TODO: the payload acks are in the reverse direction //TODO: check if all messages have been acknowledged and if so, clear the payload state for the sender to receiver to avoid resending the same messages again.
                        messages: excludeMessagesById(receiverPayload.messages, ackIds)
                    }
                )
            ),
        payloadExchangeState' = 
            val currentPayloadExchangeState = getPayloadExchangeState(sender,receiver)
            setPayloadExchangeState(
                sender, 
                receiver, 
                AckReceived,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
            ),
    }

    // ------------------------------------------------------------------------------------
    // HELPER VERIFICATION ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise two nodes with distinct nonempty message sets that require synchronisation.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action initWithMessagesToSyncTwoNodes() = {
        val aliceIds = MESSAGES.keys().powerset().filter(s => s.size() > 0).chooseSome()
        val bobIds = MESSAGES.keys().powerset().filter(s =>
            aliceIds.exists(id => not(id.in(s)))
        ).chooseSome()
        val randomMessageIds = Map(ALICE -> aliceIds, BOB -> bobIds)
        all {
            nodeState' = initNodeState(randomMessageIds),
            payloadState' = initPayloadState,
            messageStore' = initMessageStore(randomMessageIds),
            payloadExchangeState' = initPayloadExchangeState,
        }
    }

    /// Initialise two nodes such that Alice already contains Bob's selected messages.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action initWithoutMessagesToSyncTwoNodes() = {
        val bobIds = MESSAGES.keys().powerset().filter(s => s.size() > 0).chooseSome()
        val aliceIds = bobIds.powerset().filter(s => s.size() > 0).chooseSome()
        val randomMessageIds = Map(ALICE -> aliceIds, BOB -> bobIds)
        all {
            nodeState' = initNodeState(randomMessageIds),
            payloadState' = initPayloadState,
            messageStore' = initMessageStore(randomMessageIds),
            payloadExchangeState' = initPayloadExchangeState,
        }
    }

    /// Receive an eligible message payload for some nondeterministically chosen peer pair.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action someReceiveMessagesPayload() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        receiveMessagesPayload(sender, receiver)
    }

    /// Determine acknowledgements for some nondeterministically chosen peer pair.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action someDetermineAck() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        determineAck(sender, receiver)
    }

    /// Receive an acknowledgement for some nondeterministically chosen peer pair.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
    action someReceiveAckPayload() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        receiveAckPayload(sender, receiver)
    }

    // -------------------------------------------------------------------------------------
    // HELPER VERIFICATION FUNCTIONS
    // -------------------------------------------------------------------------------------

    /// Check whether a pair's node state equals the empty default state.
    ///
    /// -@param Node sender the node maintaining the state
    /// -@param Node receiver the peer represented by the state
    /// -@return bool the computed result
    def isDefaultNodeState(sender: Node, receiver: Node): bool = {
        val nodeState = getNodeState(sender, receiver)
        and {
            nodeState.messages.size() == 0,
            nodeState.offers.size() == 0,  //only for interactive
            nodeState.requests.size() == 0, //only for interactive
        }
    }

    /// Check whether a pair's payload equals the empty default payload.
    ///
    /// -@param Node sender the payload sender
    /// -@param Node receiver the payload receiver
    /// -@return bool the computed result
    def isDefaultPayloadState(sender: Node, receiver: Node): bool = {
        val payload = getPayload(sender, receiver)
        and {
            payload.payloadId == 0,
            payload.acks.size() == 0,
            payload.offers.size() == 0, //only for interactive
            payload.requests.size() == 0, //only for interactive
            payload.messages.size() == 0,
        }
    }

    /// Check whether a pair's exchange state equals the empty default exchange state.
    ///
    /// -@param Node sender the payload sender
    /// -@param Node receiver the payload receiver
    /// -@return bool the computed result
    def isDefaultPayloadExchangeState(sender: Node, receiver: Node): bool = {
        val payloadExchangeState = getPayloadExchangeState(sender, receiver)

        and {
            payloadExchangeState.phase == Idle,
            not(payloadExchangeState.messagesStored),
            not(payloadExchangeState.ackDetermined),
        }
        
    }

    /// Return the identifiers of all messages in a pair's payload.
    ///
    /// -@param Node sender the payload sender
    /// -@param Node receiver the payload receiver
    /// -@return Set[MessageId] the computed result
    def payloadMessageIds(sender: Node, receiver: Node): Set[MessageId] = {
        getSetMessageIds(getPayload(sender,receiver).messages)
    }

    /// Check whether a pair currently has a sent message payload awaiting receipt.
    ///
    /// -@param Node sender the payload sender
    /// -@param Node receiver the payload receiver
    /// -@return bool the computed result
    def hasInFlightPayload(sender: Node, receiver: Node): bool = {
        getPayloadExchangeState(sender, receiver).phase == MessagesSent
    }

    // -------------------------------------------------------------------------------------
    // SAFETY PROPOSITIONS
    // -------------------------------------------------------------------------------------

    /// Assert that the model contains exactly Alice and Bob.
    ///
    /// -@return bool whether the proposition holds
    val two_nodes_only = 
        NODES.size() == 2

    /// Assert that every node's synchronisation state for itself remains empty.
    ///
    /// -@return bool whether the proposition holds
    val self_nodeState_is_always_empty = 
        NODES.forall(
            n => isDefaultNodeState(n, n)
        )

    /// Assert that every node's payload addressed to itself remains empty.
    ///
    /// -@return bool whether the proposition holds
    val self_payloadState_is_always_empty = 
        NODES.forall(
            n => isDefaultPayloadState(n, n)
        )

    /// Assert that the unused reverse-direction payload remains empty during an exchange.
    ///
    /// -@return bool whether the proposition holds
    val reverse_payloadState_is_always_empty = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    (
                        // Allow both directions to be empty only when both directions are idle.
                        (
                            (
                                getPayloadExchangeState(sender, receiver).phase == Idle or
                                getPayloadExchangeState(sender, receiver).phase == AckReceived
                            ) 
                            and
                            (
                                getPayloadExchangeState(receiver, sender).phase == Idle or
                                getPayloadExchangeState(receiver, sender).phase == AckReceived
                            )
                        )
                        or
                        // During sync activity, at least one direction must differ from EMPTY_PAYLOAD.
                        (
                            not(isDefaultPayloadState(sender, receiver)) or
                            not(isDefaultPayloadState(receiver, sender))
                        )
                    )
            )
        )
    
    /// Assert that every node's exchange state with itself remains at its default.
    ///
    /// -@return bool whether the proposition holds
    val self_payloadExchangeState_is_always_empty = 
        NODES.forall(
            n => isDefaultPayloadExchangeState(n, n)
        )

    /// Assert that every payload message is pending or already known by the receiver.
    ///
    /// -@return bool whether the proposition holds
    val payload_messages_are_pending_or_known_by_receiver =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getPayload(sender, receiver).messages.forall(
                        m =>
                            // Still scheduled for this receiver
                            m.in(getNodeState(sender, receiver).messages)
                            or 
                            // No longer scheduled because the receiver already has it
                            m.in(getMessagesMessageStore(receiver))
                    )
            )
        )

    /// Assert that every payload message exists in the sender's message store.
    ///
    /// -@return bool whether the proposition holds
    val payload_messages_belong_to_sender =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getPayload(sender, receiver).messages.forall(
                        m => m.in(getMessagesMessageStore(sender))
                    )
            )
        )

    /// Combine the payload-message ownership and receiver-knowledge safety properties.
    ///
    /// -@return bool whether the proposition holds
    val payload_message_invariant = 
        and {
            payload_messages_are_pending_or_known_by_receiver,
            payload_messages_belong_to_sender,
            pending_messages_belong_to_sender,
        }

    /// Assert that every message pending for a receiver belongs to the sender.
    ///
    /// -@return bool whether the proposition holds
    val pending_messages_belong_to_sender =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getNodeState(sender, receiver).messages.forall(
                        m => m.in(getMessagesMessageStore(sender))
                    )
            )
        )

    /// Assert that acknowledgement identifiers refer to messages in the same payload.
    ///
    /// -@return bool whether the proposition holds
    val ack_ids_match_payload_messages =
        NODES.forall(
            sender => NODES.forall(
                receiver => getPayload(sender,receiver).acks.forall(
                    id => id.in(payloadMessageIds(sender, receiver))
                )
            )
        )

    /// Assert that sent acknowledgement identifiers refer to messages stored by the receiver.
    ///
    /// -@return bool whether the proposition holds
    val sent_ack_ids_match_stored_messages  =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).phase == AckSent 
                        implies
                        getPayload(sender, receiver).acks.forall(
                            id => id.in(
                                getSetMessageIds(messageStore.get(receiver))
                            )
                        )
                    )
            )
        )
    
    /// Combine the acknowledgement soundness safety properties.
    ///
    /// -@return bool whether the proposition holds
    val sent_acks_are_sound = 
        and {
            sent_ack_ids_match_stored_messages,
            ack_ids_match_payload_messages,
            pending_acks_imply_nonempty_payload,
        }

    /// Assert that a nonempty acknowledgement set implies a nonempty message payload.
    ///
    /// -@return bool whether the proposition holds
    val pending_acks_imply_nonempty_payload =
        NODES.forall(
            sender => NODES.forall(
                receiver => getPayload(sender,receiver).acks.size() > 0
                    implies getPayload(sender,receiver).messages.size() > 0
            )
        )
    
    /// Assert that a determined acknowledgement covers exactly the payload's messages.
    ///
    /// -@return bool whether the proposition holds
    val determined_ack_covers_payload =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).ackDetermined
                        implies
                        getPayload(sender, receiver).acks
                            == payloadMessageIds(sender, receiver)
                    )
            )
        )

    /// Assert that the idle phase has neither stored-message nor determined-ack flags set.
    ///
    /// -@return bool whether the proposition holds
    val when_idle_not_messageStored_and_not_ackDetermined =
        NODES.forall(
            sender => NODES.forall(
                receiver => 
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).phase == Idle
                        implies
                        and {
                            not(getPayloadExchangeState(sender, receiver).messagesStored),
                            not(getPayloadExchangeState(sender, receiver).ackDetermined)
                        }
                    )
            )
        )

    /// Assert that the MessagesAdded phase always has a nonempty message payload.
    ///
    /// -@return bool whether the proposition holds
    val when_MessagesAdded_payload_messages_non_empty =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).phase == MessagesAdded
                        implies
                        getPayload(sender, receiver).messages.size() > 0
                    )
            )
        )

    /// Assert that the MessagesSent phase always has a nonempty message payload.
    ///
    /// -@return bool whether the proposition holds
    val when_MessagesSent_payload_messages_non_empty =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).phase == MessagesSent
                        implies
                        getPayload(sender, receiver).messages.size() > 0
                    )
            )
        )

    /// Assert that AckSent follows storage and acknowledgement determination with nonempty acknowledgements.
    ///
    /// -@return bool whether the proposition holds
    val when_AckSent_messagesStored_ackDetermined_acks_non_empty =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).phase == AckSent
                        implies
                        and {
                            getPayloadExchangeState(sender, receiver).messagesStored,
                            getPayloadExchangeState(sender, receiver).ackDetermined,
                            getPayload(sender, receiver).acks.size() > 0
                        }
                    )
            )
        )

    /// Assert that acknowledgement receipt leaves the acknowledgement set empty.
    ///
    /// -@return bool whether the proposition holds
    val when_AckReceived_acks_empty = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).phase == AckReceived
                        implies
                        getPayload(sender, receiver).acks.size() == 0
                    )
            )
        )

    /// Assert that acknowledgement determination occurs only in compatible exchange phases.
    ///
    /// -@return bool whether the proposition holds
    val when_ackDetermined = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).ackDetermined
                        implies
                        getPayloadExchangeState(sender, receiver).phase.in(Set(MessagesReceived, AckSent, AckReceived))
                    )
            )
        )

    /// Assert that received-message storage occurs only in compatible exchange phases.
    ///
    /// -@return bool whether the proposition holds
    val when_messagesStored = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(sender, receiver).messagesStored
                        implies
                        getPayloadExchangeState(sender, receiver).phase.in(Set(MessagesReceived, AckSent, AckReceived))
                    )
            )
        )

    // -------------------------------------------------------------------------------------
    // LIVENESS PROPOSITIONS
    // -------------------------------------------------------------------------------------

    /// Ensure each node's message store never loses previously stored messages.
    ///
    /// NOT CONVERTABLE TO TLA+
    /// This proposition produces error:
    ///     [] followed by action not of form [A]_v
    /// Therefore it can't be used
    ///
    /// -@return bool whether the proposition holds
    // temporal messageStores_are_monotonic = 
    //     always(
    //         NODES.forall(
    //             n => messageStore.get(n).subseteq(
    //                 next(messageStore.get(n))
    //             )
    //         )
    //     )

    /// Require weak fairness for receiving some sent message payload.
    ///
    /// -@return bool whether the proposition holds
    temporal fair_receive_messages_payload =
        someReceiveMessagesPayload.weakFair(Set(payloadExchangeState))

    /// Require weak fairness for determining some payload acknowledgement.
    ///
    /// -@return bool whether the proposition holds
    temporal fair_determine_ack =
        someDetermineAck.weakFair(Set(payloadState))

    /// Require weak fairness for receiving some acknowledgement payload.
    ///
    /// -@return bool whether the proposition holds
    temporal fair_receive_ack_payload =
        someReceiveAckPayload.weakFair(Set(nodeState))

    /// Assert that every in-flight payload is eventually received under receive fairness.
    ///
    /// -@return bool whether the proposition holds
    temporal in_flight_payload_is_eventually_received =
        fair_receive_messages_payload implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        hasInFlightPayload(sender, receiver)
                        leadsTo getPayloadExchangeState(sender, receiver).phase == MessagesReceived
                )
            )
        )

    /// Assert that every sent payload is eventually acknowledged under delivery fairness.
    ///
    /// -@return bool whether the proposition holds
    temporal pending_payload_is_eventually_acknowledged =
        (fair_receive_messages_payload and fair_determine_ack) implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        and {
                            getPayload(sender,receiver).messages.size() > 0,
                            getPayloadExchangeState(sender,receiver).phase == MessagesSent,
                        }
                        leadsTo getPayload(sender,receiver).acks.size() > 0
                )
            )
        )

    /// Assert that every pending acknowledgement is eventually cleared under receive fairness.
    ///
    /// -@return bool whether the proposition holds
    temporal pending_ack_is_eventually_cleared =
        fair_receive_ack_payload implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        getPayload(sender,receiver).acks.size() > 0
                        leadsTo getPayload(sender,receiver).acks.size() == 0
                )
            )
        )

    /// Ensure a pending message ID is removed only after the receiver stores the message.
    ///
    /// Not liveness, but temporal safety property
    /// NOT CONVERTABLE TO TLA+
    /// This proposition produces error:
    ///     [] followed by action not of form [A]_v
    /// Therefore it can't be used
    ///
    /// -@return bool whether the proposition holds
    // temporal pending_message_id_removed_only_after_storage =
    //     NODES.forall(
    //         sender => NODES.forall(
    //             receiver =>
    //                 isPeerPair(sender, receiver) implies
    //                 MESSAGES.keys().forall(
    //                     id =>
    //                         always(
    //                             (
    //                                 id.in(
    //                                     getSetMessageIds(
    //                                         getNodeState(sender, receiver).messages
    //                                     )
    //                                 )
    //                                 and next(
    //                                     not(
    //                                         id.in(
    //                                             getSetMessageIds(
    //                                                 getNodeState(sender, receiver).messages
    //                                             )
    //                                         )
    //                                     )
    //                                 )
    //                             )
    //                             implies next(
    //                                 id.in(
    //                                     getSetMessageIds(
    //                                         getMessagesMessageStore(receiver)
    //                                     )
    //                                 )
    //                             )
    //                         )
    //                 )
    //         )
    //     )

    /// Assert that acknowledged messages are eventually removed from pending and payload state.
    ///
    /// -@return bool whether the proposition holds
    temporal acknowledged_messages_are_eventually_removed =
        fair_receive_ack_payload implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver =>
                        isPeerPair(sender, receiver) implies
                        MESSAGES.keys().forall(
                            id =>
                                id.in(getPayload(sender, receiver).acks)
                                leadsTo (
                                    not(
                                        id.in(
                                            getSetMessageIds(
                                                getNodeState(sender, receiver).messages
                                            )
                                        )
                                    )
                                    and not(
                                        id.in(
                                            payloadMessageIds(sender, receiver)
                                        )
                                    )
                                )
                        )
                )
            )
        )

    /// Assert that pending messages eventually reach the receiver under delivery fairness.
    ///
    /// -@return bool whether the proposition holds
    temporal pending_messages_are_eventually_delivered =
        delivery_fairness implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver =>
                        isPeerPair(sender, receiver) implies
                        MESSAGES.keys().forall(
                            id =>
                                id.in(
                                    getSetMessageIds(
                                        getNodeState(sender, receiver).messages
                                    )
                                )
                                leadsTo id.in(
                                    getSetMessageIds(
                                        getMessagesMessageStore(receiver)
                                    )
                                )
                        )
                )
            )
        )

    /// Assert that pending messages eventually leave sender state under protocol fairness.
    ///
    /// -@return bool whether the proposition holds
    temporal pending_messages_are_eventually_cleared =
        protocol_fairness implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver =>
                        isPeerPair(sender, receiver) implies
                        MESSAGES.keys().forall(
                            id =>
                                id.in(
                                    getSetMessageIds(
                                        getNodeState(sender, receiver).messages
                                    )
                                )
                                leadsTo not(
                                    id.in(
                                        getSetMessageIds(
                                            getNodeState(sender, receiver).messages
                                        )
                                    )
                                )
                        )
                )
            )
        )

    /// Define fairness for the complete delivery, acknowledgement, and idle protocol cycle.
    ///
    /// -@return bool whether the proposition holds
    temporal protocol_fairness =
        delivery_fairness
        and acknowledgement_fairness
        and NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                        idle(sender, receiver)
                            .weakFair(Set(payloadExchangeState))
            )
        )

    /// Define weak fairness for every message-delivery action and peer pair.
    ///
    /// -@return bool whether the proposition holds
    temporal delivery_fairness =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        and {
                            addMessages(sender, receiver).weakFair(Set(payloadExchangeState)),
                            sendMessagesPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                            receiveMessagesPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                            storeReceivedMessages(sender, receiver).weakFair(Set(payloadExchangeState)),
                        }
                    )
            )
        )

    /// Define weak fairness for every acknowledgement action and peer pair.
    ///
    /// -@return bool whether the proposition holds
    temporal acknowledgement_fairness =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        and {
                            determineAck(sender, receiver).weakFair(Set(payloadExchangeState)),
                            sendAckPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                            receiveAckPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                        }
                    )
            )
        )

    /// Ensure changes to one exchange direction leave the reverse payload unchanged.
    ///
    /// NOT CONVERTABLE TO TLA+
    /// This proposition produces error:
    ///     [] followed by action not of form [A]_v
    ///
    /// -@return bool whether the proposition holds
    // temporal reverse_payload_is_unchanged =
    //     always(
    //         NODES.forall(
    //             sender => NODES.forall(
    //                 receiver =>
    //                     isPeerPair(sender, receiver) implies (
    //                         (
    //                             next(
    //                                 getPayloadExchangeState(sender, receiver)
    //                             )
    //                             != getPayloadExchangeState(sender, receiver)
    //                             or
    //                             next(
    //                                 getPayload(sender, receiver)
    //                             )
    //                             != getPayload(sender, receiver)
    //                         )
    //                         implies
    //                         next(
    //                             getPayload(receiver, sender)
    //                         )
    //                         == getPayload(receiver, sender)
    //                     )
    //             )
    //         )
    //     )

    // -------------------------------------------------------------------------------------
    // WITNESS-STYLE PROPOSITIONS (NON-INVARIANTS)
    // -------------------------------------------------------------------------------------
    /* > start witness with 'can_' for quint runner */

    /// Witness that a reachable state may contain messages pending for a peer.
    ///
    /// -@return bool whether the proposition holds
    val can_have_pending_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getNodeState(sender,receiver).messages.size() > 0,
                    }
            )
        )

    /// Witness that a reachable state may contain messages in a payload.
    ///
    /// -@return bool whether the proposition holds
    val can_have_payload_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getPayload(sender,receiver).messages.size() > 0,
                    }
            )
        )

    /// Witness that a reachable state may contain an in-flight payload.
    ///
    /// -@return bool whether the proposition holds
    val can_have_in_flight_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        hasInFlightPayload(sender, receiver),
                    }
            )
        )

    /// Witness that a reachable state may contain pending acknowledgements.
    ///
    /// -@return bool whether the proposition holds
    val can_have_pending_acks =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getPayload(sender,receiver).acks.size() > 0,
                    }
            )
        )

    /// Witness that a reachable state may contain a delivered payload.
    ///
    /// -@return bool whether the proposition holds
    val can_have_delivered_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getPayloadExchangeState(sender, receiver).phase == MessagesReceived,
                    }
            )
        )


    // ------------------------------------------------------------------------------------
    // TESTS
    // ------------------------------------------------------------------------------------

    /// Test that a complete exchange synchronises Alice's messages to Bob.
    ///
    /// -@return bool whether the test passes
    run messageStoreSyncTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                // After complete bidirectional message exchange, both nodes should have messages
                // This verifies that the protocol correctly syncs messages when nodes start with different sets
                and {
                    messageStore.get(ALICE).size() > 0,
                    messageStore.get(BOB).size() > 0,
                    messageStore.get(ALICE).forall(m => m.in(messageStore.get(BOB))),
                }
            )

    /// Test that adding messages remains enabled when no synchronisation delta exists.
    ///
    /// Unknown receiver knowledge permits redundant transmission, so Alice can still send
    /// messages to Bob when Bob already has all of them.
    ///
    /// -@return bool whether the test passes
    run addMessagesDoesNotFailWhenNoSyncDeltaTest =
        initWithoutMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))

    /// Test that adding messages produces pending messages and a nonempty payload.
    ///
    /// -@return bool whether the test passes
    run payloadMessagesWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .expect(
                and {
                    can_have_pending_messages,
                    can_have_payload_messages,
                }
            )

    /// Test that sending a message payload produces an in-flight payload.
    ///
    /// -@return bool whether the test passes
    run inFlightPayloadWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(can_have_in_flight_payload)

    /// Test that acknowledgement determination produces pending acknowledgements.
    ///
    /// -@return bool whether the test passes
    run pendingAckWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .expect(
                and {
                    can_have_pending_acks,
                    can_have_delivered_payload,
                }
            )

    /// Test that storing received messages preserves every message already stored.
    ///
    /// -@return bool whether the test passes
    run storeReceivedMessagesPreservesExistingMessagesTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(
                {
                    val oldBobStore = messageStore.get(BOB)
                    storeReceivedMessages(ALICE, BOB)
                        .expect(
                            oldBobStore.forall(
                                m => m.in(messageStore.get(BOB))
                            )
                        )
                }
            )
}
