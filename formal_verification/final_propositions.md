# Examples for final version:
- all chunks are delivered at receiver
- same chunk is not repeatedly requested after received
- transfer only depends on neighbour state, not server state

# Version 1-2 (batch) formal propositions now encoded in the model:

## Safety invariants
- two_nodes_only
- no_self_peer_state
- no_self_ack_state
- message_ids_bounded
- ack_ids_bounded
- received_ids_bounded
- ack_implies_received
- in_flight_never_self

## Temporal/liveness properties
- received_is_monotonic
- pending_ack_is_eventually_cleared
- pending_message_is_eventually_acked
- fair_receive_message
- fair_receive_ack
- eventual_cleanup_under_fairness

## Witness/feasibility propositions
- can_have_in_flight_messages
- can_have_pending_acks
- can_have_delivered_messages