# Modes of Dataflow Examples

Concrete examples of REST, RPC, durable workflows, message brokers, and actor frameworks.

## REST URL Examples

```
GET    /v1/users/123                # Fetch user resource
POST   /v1/users                    # Create user
PUT    /v1/users/123                # Replace user
DELETE /v1/users/123                # Remove user
GET    /v1/users/123/orders         # Nested resource
```

**Why it works**: URLs identify resources; HTTP verbs express intent; HTTP features (caching, auth, content negotiation) are reused rather than reinvented.

## OpenAPI Definition (YAML)

```yaml
openapi: 3.0.3
info:
  title: Users API
  version: 1.0.0
paths:
  /users/{id}:
    get:
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: integer }
      responses:
        '200':
          description: A user
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      properties:
        id:   { type: integer }
        name: { type: string }
```

**Why it works**: Single document defines endpoints, schemas, versions; tooling generates docs, clients, GUIs, compatibility checks.

## gRPC Service Definition (.proto)

```protobuf
syntax = "proto3";
package payments;

service PaymentService {
  rpc ChargeCard(ChargeRequest) returns (ChargeResponse);
  rpc RefundCard(RefundRequest) returns (RefundResponse);
}

message ChargeRequest {
  string card_token  = 1;
  int64  amount_cents = 2;
  string currency    = 3;
  string idempotency_key = 4;  // dedupe retries
}

message ChargeResponse {
  string charge_id = 1;
  bool   succeeded = 2;
  string error    = 3;
}
```

**Why it works**: Schema-driven, compact binary on the wire, generates client/server stubs in many languages; field numbers preserve forward/backward compat as fields are added.

## Temporal Workflow (Durable Execution)

```python
from temporalio import workflow, activity
from datetime import timedelta

@activity.defn
async def check_fraud(payment): ...

@activity.defn
async def charge_card(payment): ...

@activity.defn
async def deposit_to_bank(payment): ...

@workflow.defn
class PaymentWorkflow:
    @workflow.run
    async def run(self, payment):
        risk = await workflow.execute_activity(
            check_fraud, payment,
            start_to_close_timeout=timedelta(seconds=30),
        )
        if risk.is_fraudulent:
            return "blocked"

        charge = await workflow.execute_activity(
            charge_card, payment,
            start_to_close_timeout=timedelta(seconds=60),
            retry_policy=workflow.RetryPolicy(maximum_attempts=5),
        )

        await workflow.execute_activity(
            deposit_to_bank, payment,
            start_to_close_timeout=timedelta(seconds=60),
        )
        return charge.id
```

**Why it works**: Workflow code expresses business logic linearly. Temporal's WAL records each completed activity; on crash + replay it skips successes and resumes from the failure. Retries and timeouts are declarative.

**Caveats**: `charge_card` must accept an idempotency key (Temporal can't make a third-party API exactly-once). Workflow body must be deterministic (no `random()`, `time.now()` — use `workflow.now()`). Reordering activities in a deployed workflow breaks in-flight runs; ship as a new version.

## Kafka Topic / Pub-Sub Pattern

**Producer (Python)**:
```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['kafka:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
)
producer.send('payments.charged', {
    'charge_id': 'ch_abc123',
    'amount_cents': 4999,
    'card_last4': '4242',
})
```

**Consumer (Python)**:
```python
from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'payments.charged',
    group_id='fraud-analytics',  # consumer group = queue semantics
    bootstrap_servers=['kafka:9092'],
)
for msg in consumer:
    process(msg.value)
```

**Patterns illustrated**:
- One topic, many consumer groups → fan-out (each group sees every message)
- Within a group, partitions split work → queue semantics
- Brokers retain messages on disk; consumer crash doesn't lose data

## Akka Actor Example (Scala)

```scala
import akka.actor.typed._
import akka.actor.typed.scaladsl._

object Counter {
  sealed trait Command
  case object Increment extends Command
  case class GetValue(replyTo: ActorRef[Int]) extends Command

  def apply(count: Int = 0): Behavior[Command] = Behaviors.receive { (ctx, msg) =>
    msg match {
      case Increment       => Counter(count + 1)
      case GetValue(reply) => reply ! count; Behaviors.same
    }
  }
}

val system = ActorSystem(Counter(), "counter")
system ! Counter.Increment
```

**Why it works**: Actor owns state, processes one message at a time (no locks). Message send is async; works the same whether actor is local or on another node — Akka encodes the message and ships it across the cluster transparently.

## Real Systems Mentioned

| Category | Systems |
|----------|---------|
| RPC frameworks | gRPC (Protobuf), Avro RPC, Apache Thrift |
| Service IDLs | OpenAPI / Swagger, Protocol Buffers, AsyncAPI |
| Service frameworks | Spring Boot, FastAPI, gRPC |
| Load balancers | NGINX, HAProxy, hardware LBs |
| Service discovery | etcd, Apache ZooKeeper, DNS |
| Service mesh | Istio, Linkerd |
| Workflow engines (data) | Apache Airflow, Dagster, Prefect |
| Workflow engines (BPMN) | Camunda, Orkes |
| Durable execution | Temporal, Restate, Cadence |
| Message brokers (OSS) | Apache Kafka, RabbitMQ, ActiveMQ, HornetQ, NATS, Redpanda |
| Message brokers (cloud) | Amazon Kinesis, Amazon SQS, Azure Service Bus, Google Cloud Pub/Sub |
| Schema registries | Confluent Schema Registry, AsyncAPI |
| Distributed actors | Akka, Microsoft Orleans, Erlang/OTP |
| Legacy RPC (avoid) | EJB, Java RMI, DCOM, CORBA, SOAP/WS-* |
