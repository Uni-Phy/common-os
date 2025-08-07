# Phase 1 Implementation Plan: Go-Substrate Bridge

## 🎯 Objective
Implement basic communication between the existing Go api-server and Substrate blockchain infrastructure to enable compute node registration and simple task submission.

## 📅 Timeline
**Duration**: 4-6 weeks  
**Priority**: P0 (Critical)  
**Team Size**: 2 developers  

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Phase 1 Architecture                        │
├─────────────────────────────────────────────────────────────────┤
│  Existing api-server (Enhanced)                                │
│  ├── internal/substrate/           # NEW: Bridge components    │
│  │   ├── client.go                 # Substrate connection     │
│  │   ├── types.go                  # Data structures          │
│  │   └── pallets/                  # Pallet interfaces       │
│  │       ├── compute_registry.go   # Node registration        │
│  │       └── inference_market.go   # Basic task handling      │
│  ├── internal/compute/ (NEW)       # Compute orchestration    │
│  │   ├── orchestrator.go           # Route to substrate       │
│  │   └── node_manager.go           # Manage compute nodes     │
│  └── internal/http/ (Enhanced)     # Add blockchain routes    │
│      └── blockchain_handlers.go    # New API endpoints        │
├─────────────────────────────────────────────────────────────────┤
│  Substrate Node (Basic Runtime)                                │
│  ├── pallet-compute-registry       # Node registration        │
│  ├── pallet-inference-market       # Basic task management    │
│  └── pallet-balances              # Token balances           │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Implementation Tasks

### Task 1: Go-Substrate Client Library (Week 1-2)

**Location**: `internal/substrate/`

**Dependencies**:
```bash
go get github.com/centrifuge/go-substrate-rpc-client/v4
go get github.com/ethereum/go-ethereum/crypto
```

**Files to Create**:
- `internal/substrate/client.go` - Main Substrate client
- `internal/substrate/types.go` - Common data structures
- `internal/substrate/config.go` - Configuration management

**Key Interfaces**:
```go
type SubstrateClient interface {
    Connect(wsURL string) error
    RegisterNode(ctx context.Context, node ComputeNodeInfo) error
    SubmitTask(ctx context.Context, task InferenceTask) (string, error)
    GetBalance(ctx context.Context, accountID string) (*big.Int, error)
    Close() error
}

type ComputeNodeInfo struct {
    NodeID       string            `json:"node_id"`
    Endpoint     string            `json:"endpoint"`
    Capabilities []ModelCapability `json:"capabilities"`
    StakeAmount  *big.Int          `json:"stake_amount"`
    Location     string            `json:"location"`
}
```

### Task 2: Substrate Pallet Interfaces (Week 1-2)

**Location**: `internal/substrate/pallets/`

**Files to Create**:
- `compute_registry.go` - Interface with pallet-compute-registry
- `inference_market.go` - Interface with pallet-inference-market
- `economics.go` - Interface with pallet-economics (basic)

**Example Implementation**:
```go
// compute_registry.go
type ComputeRegistryPallet struct {
    client *SubstrateClient
}

func (c *ComputeRegistryPallet) RegisterNode(ctx context.Context, node ComputeNodeInfo) error {
    call, err := types.NewCall(
        c.client.meta,
        "ComputeRegistry.register_node",
        types.NewAccountID([]byte(node.NodeID)),
        types.NewText(node.Endpoint),
        // ... encode capabilities
    )
    // Submit extrinsic
}
```

### Task 3: API Server Integration (Week 2-3)

**Location**: `internal/http/` and new `internal/compute/`

**New API Endpoints**:
```
POST /api/v1/blockchain/nodes/register
GET  /api/v1/blockchain/nodes
GET  /api/v1/blockchain/nodes/:id
POST /api/v1/blockchain/inference/submit
GET  /api/v1/blockchain/inference/:id/status
GET  /api/v1/blockchain/balance/:address
POST /api/v1/blockchain/stake
```

**Files to Modify/Create**:
- `internal/http/routes.go` - Add blockchain routes
- `internal/http/blockchain_handlers.go` - NEW: Blockchain endpoints
- `internal/compute/orchestrator.go` - NEW: Compute orchestration
- `internal/compute/node_manager.go` - NEW: Node management

### Task 4: Configuration and Environment Setup (Week 3)

**Environment Variables to Add**:
```bash
# .env additions
SUBSTRATE_WS_URL=ws://localhost:9944
SUBSTRATE_HTTP_URL=http://localhost:9933
BLOCKCHAIN_KEYRING_URI=//Alice
BLOCKCHAIN_ENABLED=true
```

**Configuration Updates**:
```go
// config/config.go additions
type Config struct {
    // ... existing fields
    Blockchain BlockchainConfig `json:"blockchain"`
}

type BlockchainConfig struct {
    Enabled    bool   `json:"enabled"`
    WSURL      string `json:"ws_url"`
    HTTPURL    string `json:"http_url"`
    KeyringURI string `json:"keyring_uri"`
}
```

### Task 5: Basic Compute Orchestration (Week 3-4)

**Purpose**: Route inference requests through blockchain when enabled

**Implementation**:
```go
// internal/compute/orchestrator.go
type ComputeOrchestrator struct {
    substrateClient substrate.SubstrateClient
    llmService      llms.Service
    blockchainEnabled bool
}

func (co *ComputeOrchestrator) HandleInferenceRequest(
    ctx context.Context, 
    req InferenceRequest,
) (*InferenceResponse, error) {
    if co.blockchainEnabled {
        // Route through blockchain
        return co.routeDecentralized(ctx, req)
    }
    // Fallback to existing centralized routing
    return co.llmService.Chat(ctx, req.ToChatRequest())
}
```

### Task 6: Testing and Integration (Week 4-5)

**Test Coverage**:
- Unit tests for Substrate client (>80% coverage)
- Integration tests with local Substrate node
- API endpoint testing
- End-to-end workflow tests

**Test Files to Create**:
- `internal/substrate/client_test.go`
- `internal/substrate/pallets/compute_registry_test.go`
- `internal/http/blockchain_handlers_test.go`
- `tests/integration/blockchain_integration_test.go`

### Task 7: Documentation and Examples (Week 5-6)

**Documentation to Create**:
- `docs/BLOCKCHAIN_API.md` - API documentation
- `docs/SUBSTRATE_SETUP.md` - Development setup guide
- `examples/blockchain_usage.go` - Code examples
- Updated `README.md` with blockchain features

## 🔗 Dependencies

### Go Dependencies
```go
// go.mod additions
require (
    github.com/centrifuge/go-substrate-rpc-client/v4 v4.0.12
    github.com/ethereum/go-ethereum v1.13.8
)
```

### Development Tools
```bash
# Substrate development
cargo install --git https://github.com/paritytech/substrate subkey
cargo install --git https://github.com/paritytech/polkadot-sdk substrate-node

# Testing tools
go install github.com/onsi/ginkgo/v2/ginkgo@latest
```

### Infrastructure
- Local Substrate node for testing
- Docker compose for development environment
- CI/CD pipeline updates for blockchain testing

## 🧪 Testing Strategy

### Unit Tests
- All Substrate client methods
- Pallet interface functions
- Error handling and edge cases
- Mock substrate responses

### Integration Tests
- Connect to local Substrate node
- Register test compute nodes
- Submit and track inference tasks
- Balance and staking operations

### End-to-End Tests
- Complete workflow: register node → submit task → get result
- Failover to centralized APIs when blockchain unavailable
- Performance benchmarking

## 🚀 Deployment Plan

### Development Environment
```bash
# 1. Start local Substrate node
cd substrate-node
cargo build --release
./target/release/substrate-node --dev

# 2. Run enhanced API server
cd api-server
export BLOCKCHAIN_ENABLED=true
export SUBSTRATE_WS_URL=ws://localhost:9944
go run main.go
```

### Testing Workflow
```bash
# Register a test node
curl -X POST http://localhost:3000/api/v1/blockchain/nodes/register \
  -H "Content-Type: application/json" \
  -d '{
    "node_id": "test-node-1",
    "endpoint": "http://localhost:11434",
    "capabilities": [...],
    "stake_amount": "10000",
    "location": "local"
  }'

# Submit inference task
curl -X POST http://localhost:3000/api/v1/blockchain/inference/submit \
  -H "Content-Type: application/json" \
  -d '{
    "model_id": "gemma3:1b",
    "prompt": "Hello world",
    "max_fee": "100"
  }'
```

## 📊 Success Metrics

### Technical Metrics
- [ ] Substrate client connects successfully to local node
- [ ] Node registration works end-to-end
- [ ] Task submission and retrieval functional
- [ ] All tests pass with >80% coverage
- [ ] API response times <500ms for blockchain operations

### Integration Metrics
- [ ] Existing API functionality unchanged
- [ ] Graceful fallback when blockchain unavailable
- [ ] Configuration-based feature toggling works
- [ ] No breaking changes to existing endpoints

### Documentation Metrics
- [ ] Complete API documentation
- [ ] Developer setup guide tested by team member
- [ ] Code examples working and tested
- [ ] Architecture decisions documented

## ⚠️ Risks and Mitigations

### Technical Risks
1. **Substrate Connection Issues**
   - **Risk**: Network connectivity or node issues
   - **Mitigation**: Robust error handling, automatic reconnection, fallback to centralized

2. **Performance Impact**
   - **Risk**: Blockchain calls slow down API responses
   - **Mitigation**: Async processing, caching, timeout handling

3. **Integration Complexity**
   - **Risk**: Breaking existing functionality
   - **Mitigation**: Comprehensive testing, feature flags, gradual rollout

### Development Risks
1. **Learning Curve**
   - **Risk**: Team unfamiliarity with Substrate
   - **Mitigation**: Documentation, examples, pair programming

2. **Scope Creep**
   - **Risk**: Adding unnecessary features
   - **Mitigation**: Clear requirements, regular reviews

## 🔄 Phase 1 Completion Criteria

### Functional Requirements
- [ ] Go application can connect to Substrate node
- [ ] Compute nodes can be registered via API
- [ ] Basic inference tasks can be submitted to blockchain
- [ ] Token balances can be queried
- [ ] Graceful fallback to existing centralized APIs

### Non-Functional Requirements
- [ ] >80% test coverage for new code
- [ ] API response times within acceptable limits
- [ ] Comprehensive error handling and logging
- [ ] Production-ready configuration management

### Documentation Requirements
- [ ] Complete API documentation
- [ ] Development setup guide
- [ ] Architecture documentation updated
- [ ] Code review completed and approved

---

**Phase 1 Success**: Basic blockchain integration working with existing api-server, ready for Phase 2 edge agent development.
