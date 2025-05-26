# Tokenized Supply Chain Sustainability Finance

A blockchain-based platform that incentivizes and tracks sustainability improvements across supply chains through tokenized financing mechanisms.

## Overview

This project implements a comprehensive sustainability finance system using smart contracts to verify participants, assess environmental performance, and distribute rewards based on sustainability achievements.

## Smart Contracts

### Core Contracts

- **Entity Verification Contract** (`entity-verification.clar`)
    - Validates and registers supply chain participants
    - Manages participant credentials and verification status

- **Sustainability Assessment Contract** (`sustainability-assessment.clar`)
    - Evaluates environmental performance metrics
    - Stores sustainability scores and historical data

- **Financing Arrangement Contract** (`financing-arrangement.clar`)
    - Links funding opportunities to sustainability goals
    - Manages loan terms and conditions

- **Performance Monitoring Contract** (`performance-monitoring.clar`)
    - Tracks real-time sustainability improvements
    - Records performance data and milestones

- **Incentive Distribution Contract** (`incentive-distribution.clar`)
    - Distributes rewards based on sustainability achievements
    - Manages token allocation and distribution logic

## Features

- ✅ Participant verification and onboarding
- ✅ Automated sustainability scoring
- ✅ Performance-based financing
- ✅ Real-time monitoring and tracking
- ✅ Transparent reward distribution
- ✅ Immutable audit trail

## Getting Started

### Prerequisites

- Clarity CLI
- Stacks blockchain development environment

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd tokenized-supply-chain-finance
```

2. Deploy contracts to local testnet
```bash
clarinet deploy --testnet
```

### Usage

1. **Register as a participant**
    - Call `register-entity` in the entity verification contract
    - Provide required documentation and credentials

2. **Submit sustainability data**
    - Use the sustainability assessment contract
    - Upload performance metrics and evidence

3. **Apply for financing**
    - Submit application through financing arrangement contract
    - Link funding to specific sustainability targets

4. **Monitor performance**
    - Track progress through performance monitoring contract
    - Receive automated updates on goal achievement

5. **Claim rewards**
    - Earn tokens through the incentive distribution contract
    - Rewards are automatically distributed based on performance

## Testing

Run the test suite using Vitest:

```bash
npm test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support, please open an issue in the GitHub repository.
```

