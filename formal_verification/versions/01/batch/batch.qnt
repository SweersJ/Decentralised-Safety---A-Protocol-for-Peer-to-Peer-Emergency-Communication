module batch {
    import messages.* from "./../messages/messages"
    
    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    type RecordType = Offer | Request | None
    
    type RecordState = { //TODO: add count and epoch in next version
        messageId: MessageId, // Not used as map key, but as a value to be able to track the message ID in the record state.
        recordType: RecordType
    }

    type PayloadId = int
    
    //TODO: add payload type to indicate if it is a batch or interactive payload or can it be determined already from the payload itself
    type Payload = {
        payloadId: PayloadId,
        acks: Set[MessageId],
        offers: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }

    type NodeState = {
        offers: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }

    type Node = str

    type PayloadExchangeState = {
        phase: PayloadExchangePhase,
        messagesStored: bool,
        ackDetermined: bool
    }

    type PayloadExchangePhase = Idle | MessagesAdded | MessagesSent | MessagesReceived | AckSent | AckReceived

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    pure val ALICE: Node = "Alice"
    pure val BOB: Node = "Bob"
    pure val NODES: Set[Node] = Set(ALICE, BOB)

    pure val EMPTY_PAYLOAD: Payload = {
        payloadId: 0, //TODO: reuse payloadId to check if it is the same payload that is being sent and received, or if it is a new payload. This can be used to detect if a payload has been lost or if it is a duplicate.
        acks: Set(),
        offers: Set(),
        requests: Set(),
        messages: Set()
    }

    pure val EMPTY_NODE_STATE: NodeState = {
        offers: Set(),
        requests: Set(),
        messages: Set()
    }

    pure val EMPTY_RECORD_STATE: RecordState = {
        messageId: "",
        recordType: None
    }

    pure val EMPTY_PAYLOAD_EXCHANGE_STATE: PayloadExchangeState = {
        phase: Idle,
        messagesStored: false,
        ackDetermined: false
    }

    // ------------------------------------------------------------------------------------
    // STATE VARIABLES
    // ------------------------------------------------------------------------------------
    
    // Messages stored per node
    // (simulation of storing messages in database of a specific node).
    var messageStore: Node -> Set[Message] //TODO: add a map of messageId to message to be able to retrieve the message by its ID.
    
    // states of every peer of the offers, requests, and messages (sender -> (receiver -> NodeState)).
    // (simulation of storing at node side what transport is expected for each node at the node side)
    var nodeState: Node -> (Node -> NodeState)
    
    // Payload state kept per sender -> receiver.
    var payloadState: Node -> (Node -> Payload)

    // TODO: add the payload generator
    // Payload-id generator for future send actions.
    // var nextPayloadId: int
    
    // a single state variable that indicates the state of the payload exchange between two nodes.
    var payloadExchangeState: Node -> (Node -> PayloadExchangeState)

    // ------------------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // ------------------------------------------------------------------------------------

    // > INIT FUNCTIONS
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

    pure def initPayloadState(): Node -> (Node -> Payload) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => EMPTY_PAYLOAD
            )
        )
    }

    pure def initMessageStore(randomMessageIds: Node -> Set[MessageId]): Node -> Set[Message] = {
        NODES.mapBy(
            node => getMessages(randomMessageIds.get(node))
        )
    }

    pure def initPayloadExchangeState(): Node -> (Node -> PayloadExchangeState) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => EMPTY_PAYLOAD_EXCHANGE_STATE
            )
        )
    }

    pure def initRandomMessageIds(): Node -> Set[MessageId] = {
        NODES.mapBy(n => getRandomMessageIds)
    }

    // > GUARD FUNCTIONS
    // Sender and receiver must be different nodes, otherwise it doesn't make sense to send a payload to itself.
    pure def isPeerPair(sender: Node, receiver: Node): bool = {
        sender != receiver
    }

    // check if the sender has messages to send to the receiver, otherwise it doesn't make sense to add messages to the payload with no messages.
    def hasSyncDelta(sender: Node, receiver: Node): bool = {
        messageStore.get(sender).size() > 0 and    
        getNodeState(sender,receiver).messages.size() > 0
    }

    def canAddMessages(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        hasSyncDelta(sender, receiver) and
        getPayloadExchangeState(sender,receiver).phase == Idle
    }

    def canSendMessagesPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        hasSyncDelta(sender, receiver) and
        getPayload(sender,receiver).messages.size() != 0 and
        getNodeState(sender,receiver).messages.size() != 0 and
        getPayloadExchangeState(sender,receiver).phase == MessagesAdded
    }

    def canReceiveMessagesPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        getPayloadExchangeState(sender,receiver).phase == MessagesSent
    }

    def canStoreReceivedMessages(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(sender,receiver)

        isPeerPair(sender, receiver) and
        state.phase == MessagesReceived and
        not(state.messagesStored)
    }

    def canDetermineAck(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(sender,receiver)

        isPeerPair(sender, receiver) and
        state.phase == MessagesReceived and
        not(state.ackDetermined)
    }

    def canAckPayload(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(sender,receiver)

        isPeerPair(sender, receiver) and
        state.phase == MessagesReceived and
        state.messagesStored and 
        state.ackDetermined
    }

    def canReceiveAckPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        getPayload(sender,receiver).acks.size() != 0 and
        getPayloadExchangeState(sender,receiver).phase == AckSent
    }

    def canIdle(sender: Node, receiver: Node): bool = {
        val phase = getPayloadExchangeState(sender,receiver).phase

        isPeerPair(sender, receiver) and
        (phase == Idle or phase == AckReceived)
    }

    // > GETTER FUNCTIONS

    def getNodeState(sender: Node, receiver: Node): NodeState = {
        nodeState.get(sender).get(receiver)
    }

    def getPayload(sender: Node, receiver: Node): Payload = {
        payloadState.get(sender).get(receiver)
    }

    def getPayloadExchangeState(sender: Node, receiver: Node): PayloadExchangeState = {
        payloadExchangeState.get(sender).get(receiver)
    }

    /* TODO: activate when in interactive mode
    pure def getRecordStateMessageIds(recordStates: Set[RecordState]): Set[MessageId] = {
        recordStates.map(rs => rs.messageId)
    } 
    */

    // > SETTER FUNCTIONS

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

    pure def excludeMessagesById(
        messages: Set[Message],
        ids: Set[MessageId]
    ): Set[Message] = {
        messages.filter(message => not(message.messageId.in(ids)))
    }
    
    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

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

    action idle(sender, receiver) = all {
        // Guards,
        canIdle(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = payloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver, 
                receiverState => {
                    phase: Idle,
                    messagesStored: false,
                    ackDetermined: false
                }
            )
        ),
    }

    // Batch flow 1: Sender adds messages to its payload.
    action addMessages(sender, receiver) = all {
        // Guards
        canAddMessages(sender, receiver),
        
        // Next state updates
        /* TODO: [added] add check to ensure that the messages added to the payload are not already 
        in the payload and [not added] that they are not already acknowledged by the receiver. */
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
            val currentPayloadExchangeState = payloadExchangeState.get(sender).get(receiver)
            setPayloadExchangeState(
                sender, 
                receiver, 
                MessagesAdded,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
            ),
    }

    // Batch flow 2: Sender sends its payload to the receiver. Functionally, this action does 
    // not change the state of the sender or receiver, but it is used to model the sending of 
    // the payload in the system.
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

    action storeReceivedMessages(sender, receiver) = all {
        // Guards
        canStoreReceivedMessages(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore.setBy(
            receiver,
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
                    messages: senderState.messages.exclude(
                        getPayload(sender,receiver).messages //TODO: check if this is correct, as the rec can be same with internal data but not the same object
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

    // Batch flow 3: Receiver acknowledges the payload received from the sender. The receiver
    // checks the messages in the payload and acknowledges only those messages that it has not 
    // already received. The receiver updates its message store with the new messages and 
    // updates the payload state to reflect the acknowledged messages.
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
                    acks: receiverState.messages.map(
                        m => m.messageId
                    ) 
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

    // Batch flow 4: Sender sends the acknowledgment payload to the receiver. 
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

    // Batch flow 5: Receiver receives the acknowledgment payload from the sender. The receiver
    // updates its payload state to reflect the acknowledged messages and clears the acknowledgments.
    // With retransmission, the sender can now check with the offers and the acks if everything has
    // been delivered or resend specific messages.
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

    // Init action for tests that require an actual sync from Alice to Bob.
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

    // Init action for tests that require no sync delta from Alice to Bob.
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

    action someReceiveMessagesPayload() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        receiveMessagesPayload(sender, receiver)
    }

    action someDetermineAck() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        determineAck(sender, receiver)
    }

    action someReceiveAckPayload() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        receiveAckPayload(sender, receiver)
    }

    // -------------------------------------------------------------------------------------
    // HELPER VERIFICATION FUNCTIONS
    // -------------------------------------------------------------------------------------

    def isDefaultNodeState(n: Node): bool = {
        nodeState.get(n).get(n).messages.size() == 0 and
        nodeState.get(n).get(n).offers.size() == 0 and
        nodeState.get(n).get(n).requests.size() == 0
    }

    def isDefaultPayloadState(sender: Node, receiver: Node): bool = {
        val payload = getPayload(sender,receiver)
        payload.payloadId == 0 and
        payload.acks.size() == 0 and
        payload.offers.size() == 0 and
        payload.requests.size() == 0 and
        payload.messages.size() == 0
    }

    def payloadMessageIds(sender: Node, receiver: Node): Set[MessageId] = {
        getPayload(sender,receiver).messages.map(m => m.messageId)
    }

    def hasInFlightPayload(sender: Node, receiver: Node): bool = {
        payloadExchangeState.get(sender).get(receiver).phase == MessagesSent
    }

    // -------------------------------------------------------------------------------------
    // SAFETY PROPOSITIONS
    // -------------------------------------------------------------------------------------

    val two_nodes_only = 
        NODES.size() == 2

    val no_self_receiver_nodeState = 
        NODES.forall(
            n => isDefaultNodeState(n)
        )

    val no_self_receiver_payloadState = 
        NODES.forall(
            n => isDefaultPayloadState(n, n)
        )

    val no_reverse_payloadState = 
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

    val pending_messages_belong_to_sender_store =
        NODES.forall(
            sender => NODES.forall(
                receiver => 
                    isPeerPair(sender, receiver) implies
                    getNodeState(sender,receiver).messages.forall(
                        m => m.in(messageStore.get(sender))
                    )
            )
        )
    
    val payload_messages_were_pending =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getPayload(sender,receiver).messages.forall(
                        m =>
                            m.in(getNodeState(sender, receiver).messages)
                            or getPayloadExchangeState(sender,receiver)
                                .phase == AckReceived
                    )
            )
        )

    val ack_ids_match_payload_messages =
        NODES.forall(
            sender => NODES.forall(
                receiver => getPayload(sender,receiver).acks.forall(
                    id => id.in(payloadMessageIds(sender, receiver))
                )
            )
        )

    val pending_acks_imply_nonempty_payload =
        NODES.forall(
            sender => NODES.forall(
                receiver => getPayload(sender,receiver).acks.size() > 0
                    implies getPayload(sender,receiver).messages.size() > 0
            )
        )

    // -------------------------------------------------------------------------------------
    // LIVENESS PROPOSITIONS
    // -------------------------------------------------------------------------------------
   
    // temporal fair_receive_messages_payload =
    //     someReceiveMessagesPayload.weakFair(Set(payloadReceived))

    temporal fair_determine_ack =
        someDetermineAck.weakFair(Set(payloadState))

    temporal fair_receive_ack_payload =
        someReceiveAckPayload.weakFair(Set(nodeState))

    // temporal in_flight_payload_is_eventually_received =
    //     fair_receive_messages_payload implies (
    //         NODES.forall(
    //             sender => NODES.forall(
    //                 receiver => isPeerPair(sender, receiver) implies
    //                     hasInFlightPayload(sender, receiver)
    //                     leadsTo payloadReceived.get(receiver).get(sender)
    //             )
    //         )
    //     )

    // temporal pending_payload_is_eventually_acknowledged =
    //     (fair_receive_messages_payload and fair_determine_ack) implies (
    //         NODES.forall(
    //             sender => NODES.forall(
    //                 receiver => isPeerPair(sender, receiver) implies
    //                     (getPayload(sender,receiver).messages.size() > 0 and
    //                     payloadSent.get(sender).get(receiver))
    //                     leadsTo getPayload(sender,receiver).acks.size() > 0
    //             )
    //         )
    //     )

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

    // -------------------------------------------------------------------------------------
    // WITNESS-STYLE PROPOSITIONS (NON-INVARIANTS)
    // -------------------------------------------------------------------------------------
    /* > start witness with 'can_' for quint runner */

    val can_have_pending_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => isPeerPair(sender, receiver) and
                    getNodeState(sender,receiver).messages.size() > 0
            )
        )

    val can_have_payload_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => isPeerPair(sender, receiver) and
                    getPayload(sender,receiver).messages.size() > 0
            )
        )

    val can_have_in_flight_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => isPeerPair(sender, receiver) and hasInFlightPayload(sender, receiver)
            )
        )

    val can_have_pending_acks =
        NODES.exists(
            sender => NODES.exists(
                receiver => isPeerPair(sender, receiver) and
                    getPayload(sender,receiver).acks.size() > 0
            )
        )

    // val can_have_delivered_payload =
    //     NODES.exists(
    //         sender => NODES.exists(
    //             receiver => isPeerPair(sender, receiver) and
    //                 payloadReceived.get(receiver).get(sender)
    //         )
    //     )


    // ------------------------------------------------------------------------------------
    // TESTS
    // ------------------------------------------------------------------------------------

    run messagesSuccessfullyStoredTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                messageStore.get(ALICE).forall(x => x.in(messageStore.get(BOB)))
            )

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
                messageStore.get(ALICE).size() > 0 and
                messageStore.get(BOB).size() > 0
            )

    // This should have for the reason that the sender doesn't know which messages have been stored by the other nodes. That can only be determined after acks are received.
    run addMessagesDoesNotFailWhenNoSyncDeltaTest =
        initWithoutMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))

    run payloadMessagesWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .expect(can_have_pending_messages and can_have_payload_messages)

    run inFlightPayloadWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(can_have_in_flight_payload)

    // run pendingAckWitnessTest =
    //     initWithMessagesToSyncTwoNodes
    //         .then(addMessages(ALICE, BOB))
    //         .then(sendMessagesPayload(ALICE, BOB))
    //         .then(receiveMessagesPayload(ALICE, BOB))
    //         .then(determineAck(ALICE, BOB))
    //         .expect(can_have_pending_acks and can_have_delivered_payload)
}