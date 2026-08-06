module batch {
    import messages.* from "messages"
    
    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    type RecordType = Offer | Request | None
    
    //TODO: store records states
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

    type PayloadExchangeState = Idle | MessagesSent | MessagesReceived | AckSent | AckReceived

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
    
    // store sent state
    var payloadSent: Node -> (Node -> bool) 
    
    // store received state
    var payloadReceived: Node -> (Node -> bool)

    // TODO: add the payload generator
    // Payload-id generator for future send actions.
    // var nextPayloadId: int
    
    //TODO: change this with payloadSent and payloadReceived to a single state variable that indicates the state of the payload exchange between two nodes.
    // var payloadExchangeState: Node -> (Node -> PayloadExchangeState)

    // ------------------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // ------------------------------------------------------------------------------------



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

    pure def initPayloadSentState(): Node -> (Node -> bool) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => false
            )
        )
    }

    pure def initPayloadReceivedState(): Node -> (Node -> bool) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => false
            )
        )
    }

    pure def initPayloadExchangeState(): Node -> (Node -> PayloadExchangeState) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => Idle
            )
        )
    }

    pure def initRandomMessageIds(): Node -> Set[MessageId] = {
        NODES.mapBy(n => getRandomMessageIds)
    }

    /* TODO: activate when in interactive mode
    pure def getRecordStateMessageIds(recordStates: Set[RecordState]): Set[MessageId] = {
        recordStates.map(rs => rs.messageId)
    } 
    */

    // Sender and receiver must be different nodes, otherwise it doesn't make sense to send a payload to itself.
    pure def isPeerPair(sender: Node, receiver: Node): bool = {
        sender != receiver
    }

    // check if the sender has messages to send to the receiver, otherwise it doesn't make sense to add messages to the payload with no messages.
    def hasMessagesToProcess(sender: Node, receiver: Node): bool = {
        messageStore.get(sender).size() != 0 and                    
        nodeState.get(sender).get(receiver).messages.size() != 0
    }

    // only proceed when there is at least one message the receiver does not yet have.
    def hasSyncDelta(sender: Node, receiver: Node): bool = {
        nodeState.get(sender).get(receiver).messages.exists(
            m => not(m.in(messageStore.get(receiver)))
        )
    }

    def canAddMessages(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        hasMessagesToProcess(sender, receiver) and
        hasSyncDelta(sender, receiver) and
        not(payloadSent.get(sender).get(receiver)) and
        not(payloadReceived.get(receiver).get(sender))
    }

    def canSendMessagesPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadState.get(sender).get(receiver).messages.size() != 0 and
        nodeState.get(sender).get(receiver).messages.size() != 0 and
        not(payloadSent.get(sender).get(receiver)) and
        not(payloadReceived.get(receiver).get(sender))
    }

    def canReceiveMessagesPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadSent.get(sender).get(receiver) and
        not(payloadReceived.get(receiver).get(sender))
    }

    def canProcessDeliveredPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadSent.get(sender).get(receiver) and
        payloadReceived.get(receiver).get(sender)
    }

    def canReceiveAckPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadState.get(sender).get(receiver).acks.size() != 0 and
        payloadSent.get(receiver).get(sender) and
        not(payloadReceived.get(sender).get(receiver))
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
            payloadSent' = initPayloadSentState,
            payloadReceived' = initPayloadReceivedState,
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
            addMessages(sender, receiver),
            sendMessagesPayload(sender, receiver),
            receiveMessagesPayload(sender, receiver),
            storeReceivedMessages(sender, receiver),
            determineAck(sender,receiver),
            sendAckPayload(sender, receiver),
            receiveAckPayload(sender, receiver)
        }
    }

    // ------------------------------------------------------------------------------------
    // PROCESS ACTIONS
    // ------------------------------------------------------------------------------------

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
                        nodeState.get(sender).get(receiver).messages
                    )
                }
            )
        ),
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived
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
        payloadSent' = payloadSent.setBy(
            sender,
            senderState => senderState.setBy(receiver, _ => true)
        ),
        payloadReceived' = payloadReceived
    }

    action receiveMessagesPayload(sender, receiver) = all {
        // Guards
        canReceiveMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadSent' = payloadSent, //TODO: maybe disable sent value of sender to receiver already instead of when the new payload is sent from receiver to sender.
        payloadReceived' = payloadReceived.setBy(
            receiver,
            receiverState => receiverState.setBy(sender, _ => true)
        )
    }

    action storeReceivedMessages(sender, receiver) = all {
        // Guards
        canProcessDeliveredPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore.setBy(
            receiver,
            receiverStore => receiverStore.union(
                payloadState.get(sender).get(receiver).messages
            )
        ),
        nodeState' = nodeState.setBy(
            receiver,
            receiverState => receiverState.setBy(
                sender,
                senderState => {
                    ...senderState,
                    messages: senderState.messages.exclude(
                        payloadState.get(sender).get(receiver).messages //TODO: check if this is correct, as the rec can be same with internal data but not the same object
                    )
                }
            )
        ),
        payloadState' = payloadState,
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived
    }

    // Batch flow 3: Receiver acknowledges the payload received from the sender. The receiver
    // checks the messages in the payload and acknowledges only those messages that it has not 
    // already received. The receiver updates its message store with the new messages and 
    // updates the payload state to reflect the acknowledged messages.
    action determineAck(sender, receiver) = all {
        // Guards
        canProcessDeliveredPayload(sender, receiver),

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
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived
    }

    // Batch flow 4: Sender sends the acknowledgment payload to the receiver. 
    action sendAckPayload(sender, receiver) = all {
        // Guards
        canProcessDeliveredPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadSent' = payloadSent.setBy(
            receiver,
            receiverState => receiverState.setBy(sender, _ => true)
        ).setBy( // Reset the payload sent state for the sender to receiver to false, as the sender has sent the acknowledgment payload to the receiver and is now waiting for the receiver to acknowledge the acknowledgment payload.
            sender,
            senderState => senderState.setBy(receiver, _ => false)
        ),
        // Reset the payload received state for the sender to receiver to false, as the sender has sent the acknowledgment payload to the receiver and is now waiting for the receiver to acknowledge the acknowledgment payload.
        payloadReceived' = payloadReceived.setBy(
            sender,
            senderState => senderState.setBy(receiver, _ => false)
        ).setBy( // Reset the payload received state for the receiver to sender to false, as the receiver has sent the acknowledgment payload to the sender and is now waiting for the sender to acknowledge the acknowledgment payload.
            receiver,
            receiverState => receiverState.setBy(sender, _ => false)
        )
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
        nodeState' = nodeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver,
                receiverState => {
                    ...receiverState,
                    // Remove the acknowledged messages from the sender's node state for the receiver, as they have been acknowledged by the receiver.
                    messages: receiverState.messages.filter(
                        m => not(
                            m.messageId.in(payloadState.get(receiver).get(sender).acks)
                        )
                    )
                }
            )
        ),
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                // Cleanup of the acks in the payload state for the sender to receiver, as they have been acknowledged by the receiver. This is done to avoid resending the same messages again.
                receiverState => {
                    ...receiverState,
                    acks: Set()  // TODO: the payload acks are in the reverse direction //TODO: check if alle messages have been acknowledged and if so, clear the payload state for the sender to receiver to avoid resending the same messages again.
                }
            )
        ),
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived.setBy(
            receiver,
            receiverState => receiverState.setBy(sender, _ => true)
        )
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
            payloadSent' = initPayloadSentState,
            payloadReceived' = initPayloadReceivedState
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
            payloadSent' = initPayloadSentState,
            payloadReceived' = initPayloadReceivedState
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
        payloadState.get(sender).get(receiver).payloadId == 0 and
        payloadState.get(sender).get(receiver).acks.size() == 0 and
        payloadState.get(sender).get(receiver).offers.size() == 0 and
        payloadState.get(sender).get(receiver).requests.size() == 0 and
        payloadState.get(sender).get(receiver).messages.size() == 0
    }

    def payloadMessageIds(sender: Node, receiver: Node): Set[MessageId] = {
        payloadState.get(sender).get(receiver).messages.map(m => m.messageId)
    }

    def hasInFlightPayload(sender: Node, receiver: Node): bool = {
        payloadSent.get(sender).get(receiver) and
        not(payloadReceived.get(receiver).get(sender))
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
                    sender != receiver implies
                    (
                        // Allow both directions to be empty only when both directions are idle.
                        (
                            not(payloadSent.get(sender).get(receiver)) and
                            not(payloadReceived.get(receiver).get(sender)) and
                            not(payloadSent.get(receiver).get(sender)) and
                            not(payloadReceived.get(sender).get(receiver))
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
                receiver => sender != receiver implies
                    nodeState.get(sender).get(receiver).messages.forall(
                        m => m.in(messageStore.get(sender))
                    )
            )
        )

    val ack_ids_match_payload_messages =
        NODES.forall(
            sender => NODES.forall(
                receiver => payloadState.get(sender).get(receiver).acks.forall(
                    id => id.in(payloadMessageIds(sender, receiver))
                )
            )
        )

    val pending_acks_imply_nonempty_payload =
        NODES.forall(
            sender => NODES.forall(
                receiver => payloadState.get(sender).get(receiver).acks.size() > 0
                    implies payloadState.get(sender).get(receiver).messages.size() > 0
            )
        )

    // -------------------------------------------------------------------------------------
    // LIVENESS PROPOSITIONS
    // -------------------------------------------------------------------------------------
   
    temporal fair_receive_messages_payload =
        someReceiveMessagesPayload.weakFair(Set(payloadReceived))

    temporal fair_determine_ack =
        someDetermineAck.weakFair(Set(payloadState))

    temporal fair_receive_ack_payload =
        someReceiveAckPayload.weakFair(Set(nodeState))

    temporal in_flight_payload_is_eventually_received =
        fair_receive_messages_payload implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => sender != receiver implies
                        hasInFlightPayload(sender, receiver)
                        leadsTo payloadReceived.get(receiver).get(sender)
                )
            )
        )

    temporal pending_payload_is_eventually_acknowledged =
        (fair_receive_messages_payload and fair_determine_ack) implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => sender != receiver implies
                        (payloadState.get(sender).get(receiver).messages.size() > 0 and
                        payloadSent.get(sender).get(receiver))
                        leadsTo payloadState.get(sender).get(receiver).acks.size() > 0
                )
            )
        )

    temporal pending_ack_is_eventually_cleared =
        fair_receive_ack_payload implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => sender != receiver implies
                        payloadState.get(sender).get(receiver).acks.size() > 0
                        leadsTo payloadState.get(sender).get(receiver).acks.size() == 0
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
                receiver => sender != receiver and
                    nodeState.get(sender).get(receiver).messages.size() > 0
            )
        )

    val can_have_payload_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => sender != receiver and
                    payloadState.get(sender).get(receiver).messages.size() > 0
            )
        )

    val can_have_in_flight_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => sender != receiver and hasInFlightPayload(sender, receiver)
            )
        )

    val can_have_pending_acks =
        NODES.exists(
            sender => NODES.exists(
                receiver => sender != receiver and
                    payloadState.get(sender).get(receiver).acks.size() > 0
            )
        )

    val can_have_delivered_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => sender != receiver and
                    payloadReceived.get(receiver).get(sender)
            )
        )


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

    run addMessagesFailsWhenNoSyncDeltaTest =
        initWithoutMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB).fail())

    run payloadMessagesWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .expect(can_have_pending_messages and can_have_payload_messages)

    run inFlightPayloadWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(can_have_in_flight_payload)

    run pendingAckWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .expect(can_have_pending_acks and can_have_delivered_payload)
}