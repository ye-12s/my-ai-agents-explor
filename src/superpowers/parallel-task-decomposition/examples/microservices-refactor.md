# Example: Refactoring a Monolithic API into Microservices

This example demonstrates parallel task decomposition for a complex refactoring project.

## Scenario

Refactor a monolithic e-commerce API into separate services:
- User Service (auth, profiles)
- Product Service (catalog, inventory)
- Order Service (cart, checkout, history)
- Payment Service (processing, refunds)

## Decomposition Analysis

### Initial Assessment

```
Monolith Structure:
├── src/
│   ├── routes/
│   │   ├── users.ts       (800 lines)
│   │   ├── products.ts    (1200 lines)
│   │   ├── orders.ts      (1500 lines)
│   │   └── payments.ts    (900 lines)
│   ├── models/
│   │   ├── user.ts
│   │   ├── product.ts
│   │   ├── order.ts
│   │   └── payment.ts
│   └── shared/
│       ├── database.ts
│       ├── middleware.ts
│       └── utils.ts
```

### Dependency Analysis

| Component | Internal Dependencies | External Dependencies |
|-----------|----------------------|----------------------|
| User Service | User model | None (foundation) |
| Product Service | Product model | None (foundation) |
| Order Service | Order model | User Service, Product Service |
| Payment Service | Payment model | Order Service, User Service |
| Shared Utils | None | Used by all |

### Decomposition Plan

```typescript
const decompositionPlan = {
  tasks: [
    // Phase 1: Foundation Services (parallel)
    {
      id: 'shared-utils',
      scope: 'packages/shared/',
      description: 'Extract shared utilities into reusable package',
      dependencies: [],
      outputs: [
        'packages/shared/package.json',
        'packages/shared/src/database.ts',
        'packages/shared/src/middleware.ts',
        'packages/shared/src/utils.ts'
      ]
    },
    {
      id: 'user-service',
      scope: 'services/user/',
      description: 'Extract user management into standalone service',
      dependencies: ['shared-utils'],
      outputs: [
        'services/user/package.json',
        'services/user/src/routes.ts',
        'services/user/src/models.ts',
        'services/user/tests/'
      ]
    },
    {
      id: 'product-service',
      scope: 'services/product/',
      description: 'Extract product catalog into standalone service',
      dependencies: ['shared-utils'],
      outputs: [
        'services/product/package.json',
        'services/product/src/routes.ts',
        'services/product/src/models.ts',
        'services/product/tests/'
      ]
    },
    
    // Phase 2: Dependent Services (wait for Phase 1)
    {
      id: 'order-service',
      scope: 'services/order/',
      description: 'Extract order management with API client for user/product',
      dependencies: ['user-service', 'product-service', 'shared-utils'],
      outputs: [
        'services/order/package.json',
        'services/order/src/routes.ts',
        'services/order/src/models.ts',
        'services/order/src/clients/userClient.ts',
        'services/order/src/clients/productClient.ts',
        'services/order/tests/'
      ]
    },
    
    // Phase 3: Final Service
    {
      id: 'payment-service',
      scope: 'services/payment/',
      description: 'Extract payment processing with order integration',
      dependencies: ['order-service', 'user-service', 'shared-utils'],
      outputs: [
        'services/payment/package.json',
        'services/payment/src/routes.ts',
        'services/payment/src/models.ts',
        'services/payment/src/clients/orderClient.ts',
        'services/payment/tests/'
      ]
    },
    
    // Phase 4: Integration
    {
      id: 'api-gateway',
      scope: 'services/gateway/',
      description: 'Create API gateway to route requests to services',
      dependencies: ['user-service', 'product-service', 'order-service', 'payment-service'],
      outputs: [
        'services/gateway/package.json',
        'services/gateway/src/router.ts',
        'services/gateway/src/config.ts'
      ]
    },
    {
      id: 'docker-compose',
      scope: 'docker-compose.yml',
      description: 'Create orchestration configuration',
      dependencies: ['user-service', 'product-service', 'order-service', 'payment-service', 'api-gateway'],
      outputs: [
        'docker-compose.yml',
        '.env.example',
        'scripts/setup.sh'
      ]
    }
  ],
  
  phases: [
    ['shared-utils', 'user-service', 'product-service'],  // Phase 1
    ['order-service'],                                     // Phase 2
    ['payment-service'],                                   // Phase 3
    ['api-gateway', 'docker-compose']                      // Phase 4
  ]
};
```

## Execution Strategy

### Phase 1: Foundation (3 parallel tasks)

```typescript
// All three can run simultaneously - no dependencies
const phase1 = [
  {
    id: 'shared-utils',
    prompt: `
      Extract shared code from src/shared/ into packages/shared/
      
      CONTEXT (read-only):
      - src/shared/database.ts - database connection
      - src/shared/middleware.ts - auth middleware
      - src/shared/utils.ts - helper functions
      
      TASK:
      1. Create packages/shared/ structure
      2. Move shared code with proper exports
      3. Update imports to use package
      4. Create package.json with proper exports
      
      CONSTRAINTS:
      - Do not modify any service code yet
      - Ensure all exports are backward compatible
    `
  },
  {
    id: 'user-service',
    prompt: `
      Extract user service from src/routes/users.ts
      
      CONTEXT (read-only):
      - Assume packages/shared is available
      - Use shared/database for DB connection
      
      TASK:
      1. Create services/user/ structure
      2. Extract user routes and models
      3. Set up as standalone service
      4. Write tests for extracted service
      
      CONSTRAINTS:
      - Only extract user-related code
      - Keep original file intact (will delete later)
    `
  },
  {
    id: 'product-service',
    prompt: `
      Extract product service from src/routes/products.ts
      
      CONTEXT (read-only):
      - Assume packages/shared is available
      
      TASK:
      1. Create services/product/ structure
      2. Extract product routes and models
      3. Set up as standalone service
      4. Write tests for extracted service
      
      CONSTRAINTS:
      - Only extract product-related code
    `
  }
];
```

### Phase 2: Order Service (depends on Phase 1)

```typescript
const phase2 = [{
  id: 'order-service',
  prompt: `
    Extract order service with HTTP client dependencies
    
    CONTEXT (read-only):
    - packages/shared/ - available
    - services/user/ - user service API available
    - services/product/ - product service API available
    
    TASK:
    1. Create services/order/ structure
    2. Extract order routes and models
    3. Create HTTP clients for user/product services
    4. Update order logic to use clients instead of direct DB calls
    5. Write tests with mocked clients
    
    CLIENT IMPLEMENTATION:
    ```typescript
    class UserClient {
      async getUser(id: string): Promise<User> {
        return fetch(`http://user-service:3001/users/${id}`);
      }
    }
    ```
  `
}];
```

### Phase 3 & 4: Continue pattern...

## Handling Shared State

### Database Migration Strategy

```typescript
// Migration task (must run before service extraction)
const migrationTask = {
  id: 'database-migration',
  prompt: `
    Split monolithic database into service-specific databases
    
    BEFORE (monolith):
    - Single database with all tables
    
    AFTER (per-service):
    - users_db: users, user_profiles, sessions
    - products_db: products, categories, inventory
    - orders_db: orders, order_items, cart
    - payments_db: payments, refunds, transactions
    
    TASK:
    1. Create migration scripts for each service
    2. Handle foreign key relationships
    3. Ensure data consistency
    4. Create rollback scripts
    
    NOTE: This is a Phase 0 task - must complete before any service extraction
  `
};
```

## Result Integration

### File Structure After Refactoring

```
project/
├── packages/
│   └── shared/          # Shared utilities (from Phase 1)
├── services/
│   ├── user/            # User service (from Phase 1)
│   ├── product/         # Product service (from Phase 1)
│   ├── order/           # Order service (from Phase 2)
│   ├── payment/         # Payment service (from Phase 3)
│   └── gateway/         # API gateway (from Phase 4)
├── docker-compose.yml   # Orchestration (from Phase 4)
└── src/                 # Original monolith (to be deprecated)
```

### Verification Strategy

```typescript
const verificationTasks = [
  {
    id: 'integration-tests',
    dependencies: ['docker-compose'],
    prompt: `
      Run end-to-end tests on the complete microservices setup
      
      TEST SCENARIOS:
      1. User registration → login → profile update
      2. Browse products → add to cart → place order
      3. Order → payment → confirmation
      4. Order history retrieval
      
      Must all pass before considering refactor complete.
    `
  },
  {
    id: 'load-tests',
    dependencies: ['integration-tests'],
    prompt: `
      Compare performance: monolith vs microservices
      
      BENCHMARKS:
      - Response time p50, p95, p99
      - Throughput (requests/sec)
      - Memory usage per service
      
      Ensure microservices meet or exceed monolith performance.
    `
  }
];
```

## Lessons Learned

### What Worked
1. **Shared utils first** - Extracting common code first prevented duplication
2. **Interface contracts** - HTTP clients with clear interfaces decoupled services
3. **Phase-based execution** - Dependencies were clear, no circular waits
4. **Database migration separately** - Handling data first simplified service extraction

### What Didn't Work
1. **Initially tried to do database + service together** - Too complex, caused conflicts
2. **First attempt skipped shared utils** - Ended up with code duplication
3. **Integration tests too late** - Caught issues that could have been found earlier

### Surprises
1. **Order service was larger than expected** - Required the most refactoring
2. **Payment service was simpler** - Most logic was already isolated
3. **API Gateway took longer** - Routing logic was complex

## Applicability

### Use This Pattern When
- ✅ Refactoring large codebases into services
- ✅ Multiple modules have clear boundaries
- ✅ Database can be split or services can share read-only access
- ✅ Team has experience with distributed systems

### Don't Use When
- ❌ Modules are tightly coupled with shared mutable state
- ❌ Database cannot be partitioned
- ❌ Team is new to microservices (start with monolith modules)
- ❌ Performance requirements need local function calls
