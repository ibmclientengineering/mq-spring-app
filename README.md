# mq-spring-app

A Spring Boot JMS client that puts and gets messages on an IBM MQ queue manager, exposing simple REST endpoints for sending and receiving.

> Part of the **IBM Client Engineering** Cloud Pak for Integration production-deployment demo — this is the **application** half of the MQ story: the workload that rides the `mq-spring-app-dev` GitOps pipeline and sits behind the governed API in the "Expose MQ app APIs" use case.

## What this is

This repo is the sample **MQ workload** an application team owns and ships. It is a Java 11 Spring Boot service built on the IBM `mq-jms-spring-boot-starter`, which uses a Spring `JmsTemplate` to `convertAndSend` and `receiveAndConvert` against a queue. It surfaces three REST endpoints:

- `GET /api/send-hello-world` — put a `Hello World!` text message on the queue
- `GET /api/recv` — get the message at the head of the queue
- `POST /api/send-json` — put an arbitrary JSON body on the queue

In the flagship "Expose MQ app APIs" flow, a client calls an **IBM API Connect** gateway, which routes to these endpoints, which land messages on MQ — so consumers never touch the queue manager directly.

## What's inside

- **`src/main/java/com/ibm/mqclient/`** — the app: `controller/` (REST + Swagger annotations), `service/MQService.java` (the JMS put/get logic), plus `config/`, `exceptions/`, and `model/` response objects. `com/ibm/health` adds an Actuator health endpoint with `liveness`/`readiness` probes (the readiness group includes a live `jms` check).
- **`src/main/resources/application*.yml`** — environment-driven config (`QM`, `CHANNEL`, `CONNECTION_NAME`, `QUEUE_NAME`, `USER`, `PASSWORD`) with profiles for local dev, `securemq` (mutual TLS via JKS keystore/truststore), and `ccdt` (Client Channel Definition Table).
- **`chart/base/`** — a Helm chart (Deployment, Service, OpenShift `Route`, ConfigMaps, ServiceAccount, Sealed Secret, optional Ingress and post-sync job).
- **`kustomize/base/`** — a Kustomize overlay base delivering the same resources for GitOps promotion.
- **`Dockerfile`** — a multistage build (Maven + Eclipse Temurin 11) producing a minimal **Red Hat UBI 9** runtime image, running as a non-root user.
- **`local/`** — Docker Compose for a local MQ queue manager, LDAP, and Jaeger, plus sample certs, for running the client end-to-end on a laptop.
- **`postman/`, `jmeter/`, `architecture/`** — a Postman collection with local/ROSA/GitOps environments, a JMeter load-test plan, and a draw.io security-architecture diagram.

## Why it's built this way

- **Separation of duties.** This repo carries only what an app team owns — code, container, and deploy manifests. The queue manager it talks to is provisioned separately by the MQ **infrastructure** factory, so platform and application concerns evolve independently and neither team blocks the other.
- **Config, not code.** Queue manager, channel, connection, and queue name are all injected as environment variables from a ConfigMap, and credentials come from a **Sealed Secret** (encrypted in git, decrypted only in-cluster). The same image promotes from dev to prod unchanged — you change values, never rebuild.
- **CCDT for connection portability.** The `ccdt` profile lets the client resolve its connection from a Client Channel Definition Table (HTTP URL or a file mounted from a ConfigMap) instead of hard-coded coordinates — the standard IBM MQ pattern for steering clients across environments.
- **Production-shaped from day one.** Mutual-TLS support, Actuator liveness/readiness (with a real JMS health probe), Jaeger distributed tracing, Swagger API docs, and a rootless UBI 9 image mean the demo mirrors how a governed MQ workload actually runs on OpenShift.
- **GitOps auditability.** Both Helm and Kustomize bases live in the repo, so promotion is a reviewable pull request and every deployed change has a git history.

## How it fits the bigger picture

This is the **`-app`** half of the MQ pair. Its companion, **`mq-infra`**, is the factory that stands up the queue manager this client connects to — the same infra-vs-app split used for the ACE pair (`ace-infra` and its app overlays). The `mq-spring-app-dev` pipeline builds this image and hands the manifests to the shared **`multi-tenancy-gitops`** repos (the GitOps control plane: the bootstrap, infra, services, and apps layers that Argo CD reconciles onto the cluster). Downstream, an **IBM API Connect** product publishes these endpoints as a governed, secured API — the "Expose MQ app APIs" story end to end: client → API Connect gateway → this app → IBM MQ.

Maintained by IBM Client Engineering.
