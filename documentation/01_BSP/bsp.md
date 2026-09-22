# Bramble Synchronisation Protocol (BSP)

> **Origin note:** This document was generated with AI from the BSP explanation in the author's master thesis, specifically `2_srq2.tex`. It is a derived documentation version and should be checked against the thesis and the referenced Briar source code before being treated as a normative protocol specification.

## Overview

The Bramble Synchronisation Protocol (BSP) is the data synchronisation protocol used by the Briar application. The protocol is based on the synchronisation protocol of Bramble, the underlying library used by Briar. The protocol supports two synchronization modes:

- **Simplex:** a one-directional, batch-oriented exchange.
- **Duplex:** a two-directional, interactive exchange.

BSP uses compact records with a fixed four-byte header and a variable payload. The header identifies the protocol version, record type, and payload length.

## Record Format

A BSP record has the following structure:

| Field | Size | Description |
| --- | ---: | --- |
| Protocol version | 1 byte | Currently version `0` in the described implementation. |
| Record type | 1 byte | Identifies the payload structure. |
| Payload length | 2 bytes | Unsigned 16-bit big-endian length. |
| Payload | Variable | Record-specific data, up to 49,152 bytes (48 KiB). |

The payload length field can represent values up to 65,535 bytes, although the protocol description limits the payload to 49,152 bytes. The version field is retained for extensibility and backward compatibility, even though the existing record structure has not required a version change.

### Record Types

BSP defines six record types:

| Code | Record | Purpose |
| ---: | --- | --- |
| `0x00` | `ACK` | Acknowledges messages received by the peer. |
| `0x01` | `MESSAGE` | Carries a synchronisation message. |
| `0x02` | `OFFER` | Advertises messages available from the sender. |
| `0x03` | `REQUEST` | Requests offered messages from the peer. |
| `0x04` | `VERSIONS` | Lists protocol versions supported by the sender. |
| `0x05` | `PRIORITY` | Carries a random value used to select between concurrent connections. |

## `MESSAGE` Record

The `MESSAGE` payload contains a group identifier, a timestamp, and the message body:

| Field | Size | Encoding |
| --- | ---: | --- |
| Group ID | 32 bytes | Binary identifier. |
| Timestamp | 8 bytes | Unsigned 64-bit big-endian value. |
| Message body | 1-32,768 bytes | Message-specific byte array. |

The BSP payload can hold up to 49,152 bytes. After reserving 32 bytes for the group ID and 8 bytes for the timestamp, the theoretical remaining space is 49,112 bytes. However, Briar limits a message body to 32,768 bytes (32 KiB). This limit constrains memory consumption and the application-layer transmission unit, while allowing a complete message to fit within one record together with metadata and serialization overhead. It also reduces the amount of data that must be retransmitted when an interruption occurs.

The message body varies by application feature. Examples include private messages, forum posts, blog posts, private-group messages, sharing invitations, contact introductions, and private-group invitations. The body is serialized from a Bramble Data Format (BDF) list into a byte array, so its serialized representation also consumes space.

### Message Identity

The `MESSAGE` payload does not contain an explicit message identifier. Instead, the identifier is derived from the group ID, timestamp, and message body. The message body is first hashed into a root hash, which is then included in the message ID calculation:

```text
BLOCK_LABEL = "org.briarproject.bramble/MESSAGE_BLOCK"
ID_LABEL    = "org.briarproject.bramble/MESSAGE_ID"
FORMAT_VERSION = 1

rootHash = Hash(
    utf8(BLOCK_LABEL),
    uint8(FORMAT_VERSION),
    body
)

messageId = Hash(
    utf8(ID_LABEL),
    uint8(FORMAT_VERSION),
    groupId,
    encodeUint64BE(timestamp),
    rootHash
)
```

This construction is expected to produce a distinct identifier for each distinct message instance under the assumption that the hash function is collision resistant. Editing a message changes the hashed input and therefore creates a different message ID. The edited message is consequently distributed and stored as a separate entry rather than as a revision of the original message.

## Identifier Records: `ACK`, `OFFER`, and `REQUEST`

The `ACK`, `OFFER`, and `REQUEST` payloads consist of a concatenation of 32-byte message identifiers:

```text
[message ID 1][message ID 2]...[message ID n]
```

With a maximum payload of 49,152 bytes and identifiers of 32 bytes, one record can contain up to 1,536 message identifiers.

- **`ACK`:** confirms that referenced messages have been received.
- **`OFFER`:** advertises messages available from the sender.
- **`REQUEST`:** identifies offered messages that the receiver wants to obtain.

## `VERSIONS` Record

A `VERSIONS` record lists the protocol versions supported by the sender. This allows both peers to select a mutually compatible version. The payload contains between one and ten one-byte version identifiers. The current specification supports version `0`, so the described byte stream is:

```text
00 04 00 01 00
```

This consists of a version byte of `00`, record type `04`, a payload length of `0001`, and a payload containing version `00`.

## `PRIORITY` Record

A `PRIORITY` record carries a cryptographically generated random value with an exact length of 16 bytes. During a duplex session, this value allows both peers to deterministically decide which of several concurrent connections to prefer.

The record is optional for duplex connections because it provides no additional information when only one connection to the peer exists. It is not used for simplex connections, which do not require a connection registry for concurrent duplex links.

## Synchronization Modes

### Simplex Synchronization

Simplex synchronization is a one-directional, batch-oriented exchange. The sender transmits queued messages without first learning which messages are missing at the receiver. Acknowledgements are returned later through a separate reverse-direction stream.

A typical simplex exchange is:

```text
VERSIONS -> ACK* -> MESSAGE* -> EOS
```

Here, `*` means zero or more records and `EOS` represents the end of the stream.

The sender-side flow is as follows:

1. A message is stored locally and becomes eligible for sharing.
2. The message may be deleted, become invisible, or otherwise cease to be eligible.
3. An eligible message is queued for a contact.
4. An expiration time is assigned, based on the transport and its expected latency.
5. The sender transmits queued messages and waits for acknowledgements.
6. If a message expires before acknowledgement, it may be retransmitted.
7. The retransmission receives a later expiration time, creating a progressive back-off interval.
8. A newer, lower-latency exchange may restart the sending process.
9. When the acknowledgement is received, the message is considered successfully exchanged.

The receiver validates each incoming message. It first checks the record format. Invalid messages are discarded without acknowledgement. It then checks whether the group ID belongs to an active and visible group. Messages for groups that are not visible are ignored; otherwise, the message is stored if it is not already present. In both the new-message and already-present cases, the receiver acknowledges the message.

Because simplex synchronization does not include a reverse direction in the same connection, acknowledgements require a subsequent connection.

### Duplex Synchronization

Duplex synchronization is a two-directional, interactive exchange. The peers determine missing messages by exchanging offers and requests over the same active connection.

A typical duplex exchange is:

```text
VERSIONS -> PRIORITY? -> (OFFER -> REQUEST -> MESSAGE -> ACK)*
```

Here, `?` means that the record is optional and `*` means zero or more repetitions.

The duplex flow is as follows:

1. A sender identifies messages eligible for sharing with a peer.
2. The sender places their message IDs in an `OFFER` record.
3. The receiver processes the offer and identifies unknown messages.
4. The receiver places the requested message IDs in a `REQUEST` record.
5. The sender receives the request and sends the corresponding `MESSAGE` records.
6. The receiver validates and stores each message using the same checks as in simplex synchronization.
7. The receiver acknowledges the messages with an `ACK` record.

At each waiting state, a message can become unshared, deleted, or invisible. If this happens, it is no longer eligible for transmission and the session stops sending that message.

## Simplex and Duplex Comparison

| Property | Simplex | Duplex |
| --- | --- | --- |
| Stream direction | One direction | Both directions |
| Offers sent first | No | Yes |
| Requests sent first | No | Yes |
| Message transfer | Sent proactively | Sent after a request |
| Delivery acknowledgement | Later, during a reverse-direction stream | During the same active connection |
| Connection lifetime | Closes when queues are empty | Remains open while active |
| Main records | `VERSIONS`, `ACK`, `MESSAGE` | `VERSIONS`, optional `PRIORITY`, `OFFER`, `REQUEST`, `MESSAGE`, `ACK` |

## Diagrams

The following diagrams are exported from the master thesis source and copied into this documentation repository.

### Record Model

- [Compact synchronisation record model](diagrams/class/exports/classDiagram-syncRecordModel_compact_20260915-155747.png)
- [Detailed synchronisation record model](diagrams/class/exports/classDiagram-syncRecordModel_detailed_20260915-155747.png)

### Synchronisation Sequences

- [Simplex synchronisation, compact](diagrams/sequence/exports/sequenceDiagram-simplexSync_compact_20260916-193255.png)
- [Simplex synchronisation, detailed](diagrams/sequence/exports/sequenceDiagram-simplexSync_detailed_20260916-193255.png)
- [Duplex synchronisation, compact](diagrams/sequence/exports/sequenceDiagram-duplexSync_compact_20260922-133109.png)
- [Duplex synchronisation, detailed](diagrams/sequence/exports/sequenceDiagram-duplexSync_detailed_20260922-133109.png)
- [Duplex priority handling](diagrams/sequence/exports/sequenceDiagram-duplexSync_priority_20260901-102020.png)

### Synchronisation States

- [Simplex sender state](diagrams/state/exports/stateDiagram-simplexSync_detailed-sender-side_20260916-193255.png)
- [Simplex receiver state](diagrams/state/exports/stateDiagram-simplexSync_detailed-receiver-side_20260916-193255.png)
- [Duplex sender state](diagrams/state/exports/stateDiagram-duplexSync_detailed-sender-side_20260916-193255.png)
- [Duplex receiver state](diagrams/state/exports/stateDiagram-duplexSync_detailed-receiver-side_20260916-193255.png)

## Implementation Context

The protocol records are represented in Java within the Briar and Bramble codebases. The BSP-related API is located under:

```text
bramble-api/src/main/java/org/briarproject/bramble/api/sync
```

The message and session behavior is implemented across Briar and Bramble components, including message factories, synchronization sessions, the connection registry, and database handling.

## Source and Scope

This documentation is extracted from the BSP subsection of the master thesis chapter `2_srq2.tex`. It summarizes the protocol explanation. The thesis, referenced literature, diagrams, and implementation source code remain the authoritative sources for details not reproduced here.
