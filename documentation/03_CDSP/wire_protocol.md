# Wire Protocol

## Secure Transport

## Payloads

```
RecordType: Ack | Offer | Request

MessageId: str

Message {
  message_id: bytes
  group_id: bytes
  timestamp: int64
  body: bytes
}

Payload {
  acks: bytes[]
  offers: bytes[]
  requests: bytes[]
  messages: Message[]
}

MessageStore {
  messages: Message[]
}

NodeState {
  offers: bytes[]
  requests: bytes[]
  messages: Message[]
}
```