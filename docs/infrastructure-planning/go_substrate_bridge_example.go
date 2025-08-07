// Example Go-Substrate Bridge Implementation for Common Compute Network
// This demonstrates the integration pattern between the existing Go API server 
// and Substrate blockchain infrastructure

package main

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"time"

	gsrpc "github.com/centrifuge/go-substrate-rpc-client/v4"
	"github.com/centrifuge/go-substrate-rpc-client/v4/signature"
	"github.com/centrifuge/go-substrate-rpc-client/v4/types"
)

// SubstrateClient provides blockchain integration for Common Compute Network
type SubstrateClient struct {
	api     *gsrpc.SubstrateAPI
	keyring *signature.KeyringPair
	meta    *types.Metadata
}

// ComputeNodeInfo represents a compute node in the network
type ComputeNodeInfo struct {
	NodeID       string            `json:"node_id"`
	Endpoint     string            `json:"endpoint"`
	Capabilities []ModelCapability `json:"capabilities"`
	StakeAmount  *big.Int          `json:"stake_amount"`
	Location     string            `json:"location"`
}

// ModelCapability represents AI model capabilities of a compute node
type ModelCapability struct {
	ModelID      string  `json:"model_id"`
	ModelName    string  `json:"model_name"`
	Parameters   uint64  `json:"parameters"`
	AvgLatency   uint32  `json:"avg_latency"`
	SuccessRate  uint8   `json:"success_rate"`
	MaxTokens    uint32  `json:"max_tokens"`
	CostPerToken float64 `json:"cost_per_token"`
}

// InferenceTask represents an AI inference request on the blockchain
type InferenceTask struct {
	ID          string    `json:"id"`
	RequesterID string    `json:"requester_id"`
	ModelID     string    `json:"model_id"`
	InputHash   string    `json:"input_hash"`
	MaxFee      *big.Int  `json:"max_fee"`
	Deadline    time.Time `json:"deadline"`
	Strategy    string    `json:"strategy"` // DECENTRALIZED_FIRST, COST_OPTIMIZED, etc.
}

// InferenceResult represents the result of an AI inference task
type InferenceResult struct {
	TaskID      string        `json:"task_id"`
	Response    string        `json:"response"`
	TokensUsed  uint32        `json:"tokens_used"`
	Latency     time.Duration `json:"latency"`
	NodeID      string        `json:"node_id"`
	Quality     uint8         `json:"quality"`
	Timestamp   time.Time     `json:"timestamp"`
}

// NewSubstrateClient creates a new Substrate blockchain client
func NewSubstrateClient(wsURL string, keyringURI string) (*SubstrateClient, error) {
	// Connect to Substrate node
	api, err := gsrpc.NewSubstrateAPI(wsURL)
	if err != nil {
		return nil, fmt.Errorf("failed to create Substrate API: %w", err)
	}

	// Get metadata
	meta, err := api.RPC.State.GetMetadataLatest()
	if err != nil {
		return nil, fmt.Errorf("failed to get metadata: %w", err)
	}

	// Create keyring from URI (or load from secure storage)
	keyring, err := signature.KeyringPairFromSecret(keyringURI, 42)
	if err != nil {
		return nil, fmt.Errorf("failed to create keyring: %w", err)
	}

	return &SubstrateClient{
		api:     api,
		keyring: &keyring,
		meta:    meta,
	}, nil
}

// RegisterComputeNode registers a new compute node with the blockchain
func (sc *SubstrateClient) RegisterComputeNode(ctx context.Context, node ComputeNodeInfo) error {
	fmt.Printf("Registering compute node: %s\n", node.NodeID)

	// Create the extrinsic call
	call, err := types.NewCall(
		sc.meta,
		"ComputeRegistry.register_node", // Substrate pallet call
		types.NewAccountID([]byte(node.NodeID)),
		types.NewText(node.Endpoint),
		sc.encodeCapabilities(node.Capabilities),
		types.NewU128(*node.StakeAmount),
		types.NewText(node.Location),
	)
	if err != nil {
		return fmt.Errorf("failed to create call: %w", err)
	}

	// Create and submit extrinsic
	ext := types.NewExtrinsic(call)
	return sc.submitExtrinsic(ctx, ext)
}

// SubmitInferenceTask submits a new inference task to the blockchain market
func (sc *SubstrateClient) SubmitInferenceTask(ctx context.Context, task InferenceTask) error {
	fmt.Printf("Submitting inference task: %s\n", task.ID)

	call, err := types.NewCall(
		sc.meta,
		"InferenceMarket.submit_task",
		types.NewText(task.ID),
		types.NewAccountID([]byte(task.RequesterID)),
		types.NewText(task.ModelID),
		types.NewText(task.InputHash),
		types.NewU128(*task.MaxFee),
		types.NewU64(uint64(task.Deadline.Unix())),
	)
	if err != nil {
		return fmt.Errorf("failed to create task submission call: %w", err)
	}

	ext := types.NewExtrinsic(call)
	return sc.submitExtrinsic(ctx, ext)
}

// SubmitInferenceResult submits the result of an inference task
func (sc *SubstrateClient) SubmitInferenceResult(ctx context.Context, result InferenceResult) error {
	fmt.Printf("Submitting inference result for task: %s\n", result.TaskID)

	call, err := types.NewCall(
		sc.meta,
		"InferenceMarket.submit_result",
		types.NewText(result.TaskID),
		types.NewText(result.Response),
		types.NewU32(result.TokensUsed),
		types.NewU32(uint32(result.Latency.Milliseconds())),
		types.NewAccountID([]byte(result.NodeID)),
		types.NewU8(result.Quality),
	)
	if err != nil {
		return fmt.Errorf("failed to create result submission call: %w", err)
	}

	ext := types.NewExtrinsic(call)
	return sc.submitExtrinsic(ctx, ext)
}

// GetBalance retrieves the token balance for an account
func (sc *SubstrateClient) GetBalance(ctx context.Context, accountID string) (*big.Int, error) {
	account, err := types.NewAccountID([]byte(accountID))
	if err != nil {
		return nil, fmt.Errorf("invalid account ID: %w", err)
	}

	// Get account info from Substrate
	key, err := types.CreateStorageKey(sc.meta, "System", "Account", account)
	if err != nil {
		return nil, fmt.Errorf("failed to create storage key: %w", err)
	}

	var accountInfo types.AccountInfo
	ok, err := sc.api.RPC.State.GetStorageLatest(key, &accountInfo)
	if err != nil {
		return nil, fmt.Errorf("failed to get account info: %w", err)
	}

	if !ok {
		return big.NewInt(0), nil // Account doesn't exist
	}

	return accountInfo.Data.Free.Int, nil
}

// StakeTokens stakes tokens for a compute node
func (sc *SubstrateClient) StakeTokens(ctx context.Context, amount *big.Int) error {
	fmt.Printf("Staking tokens: %s\n", amount.String())

	call, err := types.NewCall(
		sc.meta,
		"Economics.stake",
		types.NewU128(*amount),
	)
	if err != nil {
		return fmt.Errorf("failed to create stake call: %w", err)
	}

	ext := types.NewExtrinsic(call)
	return sc.submitExtrinsic(ctx, ext)
}

// ClaimRewards claims accumulated rewards for a compute provider
func (sc *SubstrateClient) ClaimRewards(ctx context.Context) (*big.Int, error) {
	fmt.Println("Claiming rewards...")

	call, err := types.NewCall(sc.meta, "Economics.claim_rewards")
	if err != nil {
		return nil, fmt.Errorf("failed to create claim call: %w", err)
	}

	ext := types.NewExtrinsic(call)
	if err := sc.submitExtrinsic(ctx, ext); err != nil {
		return nil, err
	}

	// Return the claimed amount (in practice, this would come from event parsing)
	return big.NewInt(0), nil // Placeholder
}

// GetAvailableNodes retrieves available compute nodes for a specific model
func (sc *SubstrateClient) GetAvailableNodes(ctx context.Context, modelID string, requirements ComputeRequirements) ([]ComputeNodeInfo, error) {
	fmt.Printf("Getting available nodes for model: %s\n", modelID)

	// Query the compute registry pallet storage
	key, err := types.CreateStorageKey(sc.meta, "ComputeRegistry", "NodesByModel", types.NewText(modelID))
	if err != nil {
		return nil, fmt.Errorf("failed to create storage key: %w", err)
	}

	var nodeIDs []types.AccountID
	ok, err := sc.api.RPC.State.GetStorageLatest(key, &nodeIDs)
	if err != nil {
		return nil, fmt.Errorf("failed to get node IDs: %w", err)
	}

	if !ok {
		return []ComputeNodeInfo{}, nil // No nodes available
	}

	// Fetch detailed information for each node
	var nodes []ComputeNodeInfo
	for _, nodeID := range nodeIDs {
		node, err := sc.getNodeInfo(ctx, nodeID)
		if err != nil {
			continue // Skip failed nodes
		}
		
		// Filter by requirements
		if sc.meetsRequirements(node, requirements) {
			nodes = append(nodes, node)
		}
	}

	return nodes, nil
}

// ComputeRequirements specifies requirements for node selection
type ComputeRequirements struct {
	MinSuccessRate  uint8   `json:"min_success_rate"`
	MaxLatency      uint32  `json:"max_latency"`
	MaxCostPerToken float64 `json:"max_cost_per_token"`
	PreferredRegion string  `json:"preferred_region"`
}

// Helper methods

func (sc *SubstrateClient) submitExtrinsic(ctx context.Context, ext types.Extrinsic) error {
	// Get the latest nonce
	key, err := types.CreateStorageKey(sc.meta, "System", "Account", sc.keyring.PublicKey)
	if err != nil {
		return fmt.Errorf("failed to create storage key: %w", err)
	}

	var accountInfo types.AccountInfo
	_, err = sc.api.RPC.State.GetStorageLatest(key, &accountInfo)
	if err != nil {
		return fmt.Errorf("failed to get account info: %w", err)
	}

	// Create signature options
	o := types.SignatureOptions{
		BlockHash:          sc.api.GenesisHash,
		Era:                types.ExtrinsicEra{IsMortalEra: false},
		GenesisHash:        sc.api.GenesisHash,
		Nonce:              types.NewUCompactFromUInt(uint64(accountInfo.Nonce)),
		SpecVersion:        sc.api.RuntimeVersion.SpecVersion,
		Tip:                types.NewUCompactFromUInt(0),
		TransactionVersion: sc.api.RuntimeVersion.TransactionVersion,
	}

	// Sign the extrinsic
	err = ext.Sign(*sc.keyring, o)
	if err != nil {
		return fmt.Errorf("failed to sign extrinsic: %w", err)
	}

	// Submit to blockchain
	hash, err := sc.api.RPC.Author.SubmitExtrinsic(ext)
	if err != nil {
		return fmt.Errorf("failed to submit extrinsic: %w", err)
	}

	fmt.Printf("Extrinsic submitted with hash: %#x\n", hash)
	return nil
}

func (sc *SubstrateClient) encodeCapabilities(capabilities []ModelCapability) types.Text {
	// In practice, this would use proper SCALE encoding
	// For demo purposes, using JSON encoding
	encoded := "[]" // Placeholder
	return types.NewText(encoded)
}

func (sc *SubstrateClient) getNodeInfo(ctx context.Context, nodeID types.AccountID) (ComputeNodeInfo, error) {
	// Query node information from blockchain storage
	// This is a simplified implementation
	return ComputeNodeInfo{
		NodeID:       string(nodeID[:]),
		Endpoint:     "http://example.com:11434",
		Capabilities: []ModelCapability{},
		StakeAmount:  big.NewInt(1000),
		Location:     "US-West",
	}, nil
}

func (sc *SubstrateClient) meetsRequirements(node ComputeNodeInfo, req ComputeRequirements) bool {
	// Implement requirement checking logic
	for _, cap := range node.Capabilities {
		if cap.SuccessRate >= req.MinSuccessRate &&
			cap.AvgLatency <= req.MaxLatency &&
			cap.CostPerToken <= req.MaxCostPerToken {
			return true
		}
	}
	return false
}

// Example integration with existing Go API server
func IntegrateWithAPIServer() {
	// This shows how the Substrate client would integrate with the existing api-server

	// Initialize Substrate client
	client, err := NewSubstrateClient("ws://localhost:9944", "//Alice")
	if err != nil {
		log.Fatal("Failed to create Substrate client:", err)
	}

	ctx := context.Background()

	// Example: Register a compute node
	node := ComputeNodeInfo{
		NodeID:   "node-001",
		Endpoint: "http://192.168.1.100:11434",
		Capabilities: []ModelCapability{
			{
				ModelID:      "gemma3:1b",
				ModelName:    "Gemma 3 1B",
				Parameters:   1_000_000_000,
				AvgLatency:   2000, // 2 seconds
				SuccessRate:  95,
				MaxTokens:    2048,
				CostPerToken: 0.0001,
			},
		},
		StakeAmount: big.NewInt(10000),
		Location:    "US-West-1",
	}

	err = client.RegisterComputeNode(ctx, node)
	if err != nil {
		log.Printf("Failed to register node: %v", err)
	}

	// Example: Submit an inference task
	task := InferenceTask{
		ID:          "task-001",
		RequesterID: "user-001",
		ModelID:     "gemma3:1b",
		InputHash:   "hash-of-input-data",
		MaxFee:      big.NewInt(100),
		Deadline:    time.Now().Add(5 * time.Minute),
		Strategy:    "COST_OPTIMIZED",
	}

	err = client.SubmitInferenceTask(ctx, task)
	if err != nil {
		log.Printf("Failed to submit task: %v", err)
	}

	// Example: Get available nodes
	requirements := ComputeRequirements{
		MinSuccessRate:  90,
		MaxLatency:      5000, // 5 seconds
		MaxCostPerToken: 0.001,
		PreferredRegion: "US-West",
	}

	nodes, err := client.GetAvailableNodes(ctx, "gemma3:1b", requirements)
	if err != nil {
		log.Printf("Failed to get available nodes: %v", err)
	} else {
		fmt.Printf("Found %d available nodes\n", len(nodes))
	}

	// Example: Check balance
	balance, err := client.GetBalance(ctx, "user-001")
	if err != nil {
		log.Printf("Failed to get balance: %v", err)
	} else {
		fmt.Printf("User balance: %s tokens\n", balance.String())
	}
}

func main() {
	fmt.Println("Common Compute Network - Go-Substrate Bridge Example")
	fmt.Println("=====================================================")
	
	// This would be integrated into the existing api-server
	IntegrateWithAPIServer()
	
	fmt.Println("\nExample integration complete!")
	fmt.Println("In production, this would be integrated into:")
	fmt.Println("- internal/substrate/client.go")
	fmt.Println("- internal/compute/orchestrator.go") 
	fmt.Println("- cmd/edge-agent/main.go")
}
