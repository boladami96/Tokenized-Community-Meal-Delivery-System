# Tokenized Community Meal Delivery System

A decentralized meal delivery platform built on the Stacks blockchain using Clarity smart contracts. This system enables community-driven meal delivery with tokenized incentives, dietary accommodations, local sourcing, and quality assurance.

## System Overview

The platform consists of five interconnected smart contracts that work together to provide a comprehensive meal delivery ecosystem:

### Core Contracts

1. **Dietary Accommodation Contract** (`dietary-accommodation.clar`)
    - Manages user food allergies and dietary restrictions
    - Stores nutritional requirements and preferences
    - Validates meal compatibility with user profiles

2. **Local Sourcing Contract** (`local-sourcing.clar`)
    - Registers neighborhood restaurants and meal providers
    - Manages provider ratings and verification status
    - Handles meal inventory and availability

3. **Delivery Coordination Contract** (`delivery-coordination.clar`)
    - Optimizes delivery routes and timing
    - Manages delivery personnel assignments
    - Tracks delivery status and completion

4. **Quality Assurance Contract** (`quality-assurance.clar`)
    - Ensures food safety standards compliance
    - Manages quality ratings and reviews
    - Handles dispute resolution

5. **Subscription Management Contract** (`subscription-management.clar`)
    - Manages recurring meal plan subscriptions
    - Handles billing and payment processing
    - Tracks user preferences and order history

## Features

- **Tokenized Rewards**: Users earn tokens for various platform activities
- **Dietary Safety**: Comprehensive allergy and dietary restriction management
- **Local Economy**: Support for neighborhood restaurants and providers
- **Quality Control**: Built-in quality assurance and rating system
- **Flexible Subscriptions**: Customizable meal plans and billing cycles
- **Efficient Delivery**: Optimized routing and timing coordination

## Token Economics

The platform uses a native token (MEAL) for:
- Rewarding quality providers
- Incentivizing timely deliveries
- Compensating quality reviewers
- Subscription payments and discounts

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet for testing
- Node.js for running tests

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage

1. **Register as Provider**: Use local-sourcing contract to register restaurant
2. **Set Dietary Profile**: Configure allergies and preferences in dietary-accommodation
3. **Subscribe to Plan**: Choose meal plan in subscription-management
4. **Quality Assurance**: Rate meals and providers for token rewards

## Contract Interactions

Each contract operates independently while maintaining data consistency:

- Users register dietary restrictions before subscribing
- Providers must be verified before offering meals
- Deliveries are coordinated based on subscription schedules
- Quality ratings affect provider standings and token rewards

## Testing

The project includes comprehensive test suites for each contract:

\`\`\`
npm test                    # Run all tests
npm test dietary           # Test dietary accommodation
npm test sourcing          # Test local sourcing
npm test delivery          # Test delivery coordination
npm test quality           # Test quality assurance
npm test subscription      # Test subscription management
\`\`\`

## Security Considerations

- All user data is encrypted and stored securely
- Provider verification prevents malicious actors
- Multi-signature requirements for high-value transactions
- Regular security audits and updates

## Contributing

1. Fork the repository
2. Create feature branch
3. Add comprehensive tests
4. Submit pull request with detailed description

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions:
- Create GitHub issue
- Join community Discord
- Email: support@tokenizedmeals.com
