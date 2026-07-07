--------------------------------- MODULE batch ---------------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => Set(Int));
*)
EMPTY_MSG_IDS == { id__13 \in {0}: FALSE }

(*
  @type: (() => Str);
*)
A == "A"

VARIABLE
  (*
    @type: (Str -> (Str -> Set(Int)));
  *)
  messageState

VARIABLE
  (*
    @type: (Str -> Set(Int));
  *)
  received

VARIABLE
  (*
    @type: (Str -> (Str -> Set(Int)));
  *)
  ackPayload

VARIABLE
  (*
    @type: Int;
  *)
  nextMsgId

(*
  @type: (() => Str);
*)
B == "B"

(*
  @type: ((Str, Str) => Bool);
*)
sendMessage(sender_104, receiver_104) ==
  sender_104 /= receiver_104
    /\ messageState'
      := (LET (*
        @type: (() => (Str -> (Str -> Set(Int))));
      *)
      __quint_var1 == messageState
      IN
      [
        (__quint_var1) EXCEPT
          ![sender_104] =
            LET (*
              @type: (((Str -> Set(Int))) => (Str -> Set(Int)));
            *)
            __QUINT_LAMBDA1(perReceiver_88) ==
              LET (*
                @type: (() => (Str -> Set(Int)));
              *)
              __quint_var0 == perReceiver_88
              IN
              [
                (__quint_var0) EXCEPT
                  ![receiver_104] =
                    LET (*
                      @type: ((Set(Int)) => Set(Int));
                    *)
                    __QUINT_LAMBDA0(ids_86) == ids_86 \union {nextMsgId}
                    IN
                    __QUINT_LAMBDA0((__quint_var0)[receiver_104])
              ]
            IN
            __QUINT_LAMBDA1((__quint_var1)[sender_104])
      ])
    /\ received' := received
    /\ ackPayload' := ackPayload
    /\ nextMsgId' := (nextMsgId + 1)

(*
  @type: ((Str, Str, Int) => Bool);
*)
receiveMessage(sender_153, receiver_153, msgId_153) ==
  sender_153 /= receiver_153
    /\ msgId_153 \in messageState[sender_153][receiver_153]
    /\ messageState' := messageState
    /\ received'
      := (LET (*@type: (() => (Str -> Set(Int))); *) __quint_var2 == received IN
      [
        (__quint_var2) EXCEPT
          ![receiver_153] =
            LET (*
              @type: ((Set(Int)) => Set(Int));
            *)
            __QUINT_LAMBDA2(ids_129) == ids_129 \union {msgId_153}
            IN
            __QUINT_LAMBDA2((__quint_var2)[receiver_153])
      ])
    /\ ackPayload'
      := (LET (*
        @type: (() => (Str -> (Str -> Set(Int))));
      *)
      __quint_var4 == ackPayload
      IN
      [
        (__quint_var4) EXCEPT
          ![receiver_153] =
            LET (*
              @type: (((Str -> Set(Int))) => (Str -> Set(Int)));
            *)
            __QUINT_LAMBDA4(perReceiver_145) ==
              LET (*
                @type: (() => (Str -> Set(Int)));
              *)
              __quint_var3 == perReceiver_145
              IN
              [
                (__quint_var3) EXCEPT
                  ![sender_153] =
                    LET (*
                      @type: ((Set(Int)) => Set(Int));
                    *)
                    __QUINT_LAMBDA3(ids_143) == ids_143 \union {msgId_153}
                    IN
                    __QUINT_LAMBDA3((__quint_var3)[sender_153])
              ]
            IN
            __QUINT_LAMBDA4((__quint_var4)[receiver_153])
      ])
    /\ nextMsgId' := nextMsgId

(*
  @type: ((Str, Str, Int) => Bool);
*)
receiveAck(receiver_213, sender_213, msgId_213) ==
  sender_213 /= receiver_213
    /\ msgId_213 \in ackPayload[receiver_213][sender_213]
    /\ messageState'
      := (LET (*
        @type: (() => (Str -> (Str -> Set(Int))));
      *)
      __quint_var6 == messageState
      IN
      [
        (__quint_var6) EXCEPT
          ![sender_213] =
            LET (*
              @type: (((Str -> Set(Int))) => (Str -> Set(Int)));
            *)
            __QUINT_LAMBDA6(perReceiver_183) ==
              LET (*
                @type: (() => (Str -> Set(Int)));
              *)
              __quint_var5 == perReceiver_183
              IN
              [
                (__quint_var5) EXCEPT
                  ![receiver_213] =
                    LET (*
                      @type: ((Set(Int)) => Set(Int));
                    *)
                    __QUINT_LAMBDA5(ids_181) ==
                      { id_179 \in ids_181: id_179 /= msgId_213 }
                    IN
                    __QUINT_LAMBDA5((__quint_var5)[receiver_213])
              ]
            IN
            __QUINT_LAMBDA6((__quint_var6)[sender_213])
      ])
    /\ received' := received
    /\ ackPayload'
      := (LET (*
        @type: (() => (Str -> (Str -> Set(Int))));
      *)
      __quint_var8 == ackPayload
      IN
      [
        (__quint_var8) EXCEPT
          ![receiver_213] =
            LET (*
              @type: (((Str -> Set(Int))) => (Str -> Set(Int)));
            *)
            __QUINT_LAMBDA8(perReceiver_205) ==
              LET (*
                @type: (() => (Str -> Set(Int)));
              *)
              __quint_var7 == perReceiver_205
              IN
              [
                (__quint_var7) EXCEPT
                  ![sender_213] =
                    LET (*
                      @type: ((Set(Int)) => Set(Int));
                    *)
                    __QUINT_LAMBDA7(ids_203) ==
                      { id_201 \in ids_203: id_201 /= msgId_213 }
                    IN
                    __QUINT_LAMBDA7((__quint_var7)[sender_213])
              ]
            IN
            __QUINT_LAMBDA8((__quint_var8)[receiver_213])
      ])
    /\ nextMsgId' := nextMsgId

(*
  @type: (() => Set(Str));
*)
NODES == { (A), (B) }

(*
  @type: (() => Bool);
*)
two_nodes_only == Cardinality((NODES)) = 2

(*
  @type: (() => Bool);
*)
no_self_receiver_state ==
  \A n_313 \in NODES: Cardinality(messageState[n_313][n_313]) = 0

(*
  @type: (() => Bool);
*)
no_self_ack_state ==
  \A n_326 \in NODES: Cardinality(ackPayload[n_326][n_326]) = 0

(*
  @type: (() => Bool);
*)
message_ids_bounded ==
  \A sender_350 \in NODES:
    \A receiver_348 \in NODES:
      \A id_346 \in messageState[sender_350][receiver_348]:
        id_346 >= 0 /\ id_346 < nextMsgId

(*
  @type: (() => Bool);
*)
ack_ids_bounded ==
  \A receiver_374 \in NODES:
    \A sender_372 \in NODES:
      \A id_370 \in ackPayload[receiver_374][sender_372]:
        id_370 >= 0 /\ id_370 < nextMsgId

(*
  @type: (() => Bool);
*)
received_ids_bounded ==
  \A receiver_392 \in NODES:
    \A id_390 \in received[receiver_392]: id_390 >= 0 /\ id_390 < nextMsgId

(*
  @type: (() => Bool);
*)
ack_implies_received ==
  \A receiver_414 \in NODES:
    \A sender_412 \in NODES:
      \A id_410 \in ackPayload[receiver_414][sender_412]:
        id_410 \in received[receiver_414]

(*
  @type: (() => Bool);
*)
in_flight_never_self ==
  \A sender_441 \in NODES:
    \A receiver_439 \in NODES:
      sender_441 /= receiver_439
        => Cardinality((messageState[sender_441][receiver_439]
          \intersect messageState[sender_441][sender_441]))
          = 0

(*
  @type: (() => Bool);
*)
received_is_monotonic ==
  [](\A n_454 \in NODES: received[n_454] \subseteq received[n_454]')

(*
  @type: (() => Bool);
*)
pending_ack_is_eventually_cleared ==
  \A receiver_485 \in NODES:
    \A sender_483 \in NODES:
      receiver_485 /= sender_483
        => Cardinality(ackPayload[receiver_485][sender_483]) > 0
          ~> Cardinality(ackPayload[receiver_485][sender_483]) = 0

(*
  @type: (() => Bool);
*)
pending_message_is_eventually_acked ==
  \A sender_515 \in NODES:
    \A receiver_513 \in NODES:
      sender_515 /= receiver_513
        => Cardinality(messageState[sender_515][receiver_513]) > 0
          ~> Cardinality(ackPayload[receiver_513][sender_515]) > 0

(*
  @type: (() => Bool);
*)
can_have_in_flight_messages ==
  \E sender_580 \in NODES:
    \E receiver_578 \in NODES:
      sender_580 /= receiver_578
        /\ Cardinality(messageState[sender_580][receiver_578]) > 0

(*
  @type: (() => Bool);
*)
can_have_pending_acks ==
  \E receiver_601 \in NODES:
    \E sender_599 \in NODES:
      receiver_601 /= sender_599
        /\ Cardinality(ackPayload[receiver_601][sender_599]) > 0

(*
  @type: (() => Bool);
*)
can_have_delivered_messages ==
  \E receiver_612 \in NODES: Cardinality(received[receiver_612]) > 0

(*
  @type: (() => Bool);
*)
init ==
  messageState = [ id__44 \in NODES |-> [ id__42 \in NODES |-> EMPTY_MSG_IDS ] ]
    /\ received = [ id__51 \in NODES |-> EMPTY_MSG_IDS ]
    /\ ackPayload
      = [ id__62 \in NODES |-> [ id__60 \in NODES |-> EMPTY_MSG_IDS ] ]
    /\ nextMsgId = 0

(*
  @type: (() => Bool);
*)
step ==
  \E sender \in NODES:
    \E receiver \in { n_223 \in NODES: n_223 /= sender }:
      \E msgId \in 0 .. nextMsgId:
        sendMessage(sender, receiver)
          \/ receiveMessage(sender, receiver, msgId)
          \/ receiveAck(receiver, sender, msgId)

(*
  @type: (() => Bool);
*)
someReceiveMessage ==
  \E sender \in NODES:
    \E receiver \in { n_256 \in NODES: n_256 /= sender }:
      \E msgId \in 0 .. nextMsgId: receiveMessage(sender, receiver, msgId)

(*
  @type: (() => Bool);
*)
someReceiveAck ==
  \E sender \in NODES:
    \E receiver \in { n_281 \in NODES: n_281 /= sender }:
      \E msgId \in 0 .. nextMsgId: receiveAck(receiver, sender, msgId)

(*
  @type: (() => Bool);
*)
fair_receive_message == WF_{received}(someReceiveMessage)

(*
  @type: (() => Bool);
*)
fair_receive_ack == WF_{messageState}(someReceiveAck)

(*
  @type: (() => Bool);
*)
q_init == init

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
eventual_cleanup_under_fairness ==
  fair_receive_message /\ fair_receive_ack
    => (\A sender_558 \in NODES:
      \A receiver_556 \in NODES:
        sender_558 /= receiver_556
          => Cardinality(messageState[sender_558][receiver_556]) > 0
            ~> Cardinality(messageState[sender_558][receiver_556]) = 0)

================================================================================