# Stacks-Art-Vault - Digital Art NFT Marketplace

A decentralized platform built on the Stacks blockchain that enables artists to mint, showcase, and sell their digital artwork as NFTs while providing collectors with a secure marketplace for discovering and trading unique digital art pieces.

## 🎨 Features

- **Artist Onboarding**: Artists can mint original digital artwork with custom metadata
- **Marketplace Trading**: Secure buying and selling of digital art pieces
- **Edition Management**: Support for limited edition artwork releases
- **Collector Registry**: Track ownership and provenance of art pieces
- **Refund System**: Protection for collectors in case of delisted artwork
- **Transfer Capability**: Peer-to-peer artwork transfers between collectors

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd artvault
```

2. Check contract validity
```bash
clarinet check
```

3. Run contract tests
```bash
clarinet test
```

## 📖 Contract Functions

### Core Functions

- `mint-artwork()` - Create new digital artwork NFT
- `purchase-artwork()` - Buy artwork from the marketplace
- `transfer-artwork()` - Transfer artwork between collectors
- `update-artwork-listing()` - Modify artwork details (before sales)
- `delist-artwork()` - Remove artwork from marketplace
- `claim-refund()` - Request refund for delisted artwork

### Query Functions

- `get-artwork-owner()` - Get current owner of an artwork
- `get-artwork-details()` - Retrieve artwork metadata and status

## 🏗️ Architecture

The contract uses Stacks NFTs to represent unique digital artwork pieces. Each artwork has associated metadata including title, description, pricing, and edition information stored in Clarity maps.

## 💰 Economics

Artists set their own pricing for artwork pieces. The platform facilitates secure STX transactions between buyers and sellers, with built-in refund mechanisms for edge cases.

## 🔒 Security

- Admin-only functions for platform management
- Ownership verification for all transfers
- Input validation for all user-provided data
- Protection against duplicate minting

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.