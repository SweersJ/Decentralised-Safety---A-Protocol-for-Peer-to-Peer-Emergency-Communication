module batch {
    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    pure val A = "A"
    pure val B = "B"
    pure val NODES = Set(A, B)

    // Empty int set used to initialize per-receiver MESSAGE/ACK collections.
    pure val EMPTY_MSG_IDS = Set(0).filter(_ => false)

    // ------------------------------------------------------------------------------------
    // STATE VARIABLES
    // ------------------------------------------------------------------------------------

    // MESSAGE state kept per sender -> receiver.
    var messageState: str -> (str -> Set[int])
    // Delivered message IDs per receiver.
    var received: str -> Set[int]
    // ACK payload prepared for the next epoch.
    var ackPayload: str -> (str -> Set[int])
    // Message-id generator for future send actions.
    var nextMsgId: int

    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    action init() = all {
        messageState' = NODES.mapBy(
            _ => NODES.mapBy(
                _ => EMPTY_MSG_IDS
            )
        ),
        received' = NODES.mapBy(
            _ => EMPTY_MSG_IDS
        ),
        ackPayload' = NODES.mapBy(
            _ => NODES.mapBy(
                _ => EMPTY_MSG_IDS
            )
        ),
        nextMsgId' = 0
    }

    // ------------------------------------------------------------------------------------
    // STEP ACTIONS
    // ------------------------------------------------------------------------------------

    action step() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(
            n => n != sender
        ).oneOf()
        nondet msgId = 0.to(nextMsgId).oneOf()
        any {
            sendMessage(sender, receiver),
            receiveMessage(sender, receiver, msgId),
            receiveAck(receiver, sender, msgId),
        }
    }

    // ------------------------------------------------------------------------------------
    // PROCESS ACTIONS
    // ------------------------------------------------------------------------------------

    // Batch flow 1: sender adds MESSAGE directly to payload/state for a receiver.
    action sendMessage(sender, receiver) = all {
        sender != receiver,
        messageState' = messageState.setBy(
            sender,
            perReceiver => perReceiver.setBy(
                receiver, 
                ids => ids.union(Set(nextMsgId))
            )
        ),
        received' = received,
        ackPayload' = ackPayload,
        nextMsgId' = nextMsgId + 1,
    }

    // Batch flow 2: receiver gets MESSAGE and prepares ACK for next payload.
    action receiveMessage(sender, receiver, msgId) = all {
        sender != receiver,
        messageState.get(sender).get(receiver).contains(msgId),
        messageState' = messageState,
        received' = received.setBy(
            receiver, 
            ids => ids.union(Set(msgId))
        ),
        ackPayload' = ackPayload.setBy(
            receiver,
            perReceiver => perReceiver.setBy(
                sender, 
                ids => ids.union(Set(msgId))
            )
        ),
        nextMsgId' = nextMsgId,
    }

    // Batch flow 3: sender receives ACK and removes MESSAGE from per-receiver state.
    action receiveAck(receiver, sender, msgId) = all {
        sender != receiver,
        ackPayload.get(receiver).get(sender).contains(msgId),
        messageState' = messageState.setBy(
            sender,
            perReceiver => perReceiver.setBy(
                receiver, 
                ids => ids.filter(id => id != msgId)
            )
        ),
        received' = received,
        ackPayload' = ackPayload.setBy(
            receiver,
            perReceiver => perReceiver.setBy(
                sender, 
                ids => ids.filter(id => id != msgId)
            )
        ),
        nextMsgId' = nextMsgId,
    }

    // ------------------------------------------------------------------------------------
    // HELPER ACTIONS
    // ------------------------------------------------------------------------------------
    // > Witness-style actions for exploration of the state space.

    action someReceiveMessage = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        nondet msgId = 0.to(nextMsgId).oneOf()
        receiveMessage(sender, receiver, msgId)
    }

    action someReceiveAck = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        nondet msgId = 0.to(nextMsgId).oneOf()
        receiveAck(receiver, sender, msgId)
    }

    // -------------------------------------------------------------------------------------
    // SAFETY PROPOSITIONS
    // -------------------------------------------------------------------------------------

    // Basic safety properties (invariants)
    val two_nodes_only = 
        NODES.size() == 2
    val no_self_receiver_state = 
        NODES.forall(
            n => messageState.get(n).get(n).size() == 0
        )
    val no_self_ack_state = 
        NODES.forall(
            n => ackPayload.get(n).get(n).size() == 0
        )

    // Every stored id should come from a previously created message id.
    val message_ids_bounded = 
        NODES.forall(
            sender => NODES.forall(
                receiver => messageState.get(sender).get(receiver).forall(
                    id => id >= 0 and id < nextMsgId
                )
            )
        )

    val ack_ids_bounded = 
        NODES.forall(
            receiver => NODES.forall(
                sender => ackPayload.get(receiver).get(sender).forall(
                    id => id >= 0 and id < nextMsgId
                )
            )
        )

    val received_ids_bounded = 
        NODES.forall(
            receiver => received.get(receiver).forall(
                id => id >= 0 and id < nextMsgId
            )
        )

    // ACKs should only exist for messages already marked as received by that receiver.
    val ack_implies_received = 
        NODES.forall(
            receiver => NODES.forall(
                sender => ackPayload.get(receiver).get(sender).forall(
                    id => received.get(receiver).contains(id)
                )
            )
        )

    // If a message is in-flight to a receiver, it should not also be in sender self-state.
    val in_flight_never_self = 
        NODES.forall(
            sender => NODES.forall(
                receiver => sender != receiver 
                implies messageState.get(sender).get(receiver).intersect(
                    messageState.get(sender).get(sender)
                ).size() == 0
            )
        )

    // -------------------------------------------------------------------------------------
    // LIVENESS PROPOSITIONS
    // -------------------------------------------------------------------------------------

    // Temporal/liveness properties
    // temporal received_is_monotonic = always(
    //     NODES.forall(n => received.get(n).subseteq(next(received.get(n)))))

    temporal pending_ack_is_eventually_cleared =
        NODES.forall(
            receiver => NODES.forall(
                sender => receiver != sender 
                implies ackPayload.get(receiver).get(sender).size() > 0
                leadsTo ackPayload.get(receiver).get(sender).size() == 0
            )
        )

    temporal pending_message_is_eventually_acked =
        NODES.forall(
            sender => NODES.forall(
                receiver => sender != receiver 
                implies messageState.get(sender).get(receiver).size() > 0
                leadsTo ackPayload.get(receiver).get(sender).size() > 0
            )
        )

    // Fairness assumptions for progress-oriented propositions.
    temporal fair_receive_message = 
        someReceiveMessage.weakFair(Set(received))
    temporal fair_receive_ack = 
        someReceiveAck.weakFair(Set(messageState))

    // Under fairness, messages are eventually removed from sender per-receiver state.
    temporal eventual_cleanup_under_fairness =
        (fair_receive_message and fair_receive_ack).implies(
            NODES.forall(
                sender => NODES.forall(
                    receiver => sender != receiver
                    implies messageState.get(sender).get(receiver).size() > 0
                    leadsTo messageState.get(sender).get(receiver).size() == 0
                )
            )
        )

    // -------------------------------------------------------------------------------------
    // WITNESS-STYLE PROPOSITIONS (NON-INVARIANTS)
    // -------------------------------------------------------------------------------------

    // Witness-style propositions (non-invariants) for exploration.
    val can_have_in_flight_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => sender != receiver and messageState.get(sender).get(receiver).size() > 0
            )
        )

    val can_have_pending_acks =
        NODES.exists(
            receiver => NODES.exists(
                sender => receiver != sender and ackPayload.get(receiver).get(sender).size() > 0
            )
        )

    val can_have_delivered_messages = 
        NODES.exists(
            receiver => received.get(receiver).size() > 0
        )

    // ------------------------------------------------------------------------------------
    // TESTS
    // ------------------------------------------------------------------------------------

    // Insert test cases here for exploration of the state space, if needed.
}