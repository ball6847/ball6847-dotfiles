# Mermaid Syntax Reference

Quick reference for common Mermaid diagram types. For full documentation, see
https://mermaid.js.org/.

---

## Flowchart

Best for: Processes, workflows, decision trees, system architecture.

### Basic Syntax

```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action]
    B -->|No| D[End]
    C --> D
```

### Direction

- `TD` / `TB` — Top to Down / Top to Bottom
- `BT` — Bottom to Top
- `LR` — Left to Right
- `RL` — Right to Left

### Node Shapes

| Syntax      | Shape      | Example        |
| ----------- | ---------- | -------------- |
| `A[text]`   | Rectangle  | `[Process]`    |
| `A(text)`   | Rounded    | `(Start)`      |
| `A((text))` | Circle     | `((State))`    |
| `A{text}`   | Rhombus    | `{Decision}`   |
| `A[[text]]` | Subroutine | `[[Function]]` |
| `A[(text)]` | Cylinder   | `[(Database)]` |

### Connections

```mermaid
flowchart LR
    A --> B      %% Arrow
    A --- B      %% Line
    A -->|Label| B  %% Labeled
    A -.-> B     %% Dotted
    A ==> B      %% Thick
```

### Example: API Request Flow

```mermaid
flowchart TD
    A[Client] --> B[Load Balancer]
    B --> C[API Server]
    C --> D[(Database)]
    C --> E[(Cache)]
    D --> C
    E --> C
```

---

## Sequence Diagram

Best for: API calls, interactions, message flows, protocols.

### Basic Syntax

```mermaid
sequenceDiagram
    participant User
    participant Server
    participant DB
    
    User->>Server: Request
    Server->>DB: Query
    DB-->>Server: Result
    Server-->>User: Response
```

### Arrows

| Syntax | Meaning      |
| ------ | ------------ |
| `->>`  | Solid arrow  |
| `-->>` | Dotted arrow |
| `--)`  | Async        |
| `->>+` | Activate     |
| `->>-` | Deactivate   |

### Example: Authentication Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant A as Auth Server
    participant D as Database
    
    C->>+A: Login request
    A->>D: Check credentials
    D-->>A: User found
    A->>A: Generate JWT
    A-->>-C: Token + User info
```

---

## State Diagram

Best for: Application states, lifecycle, finite state machines.

### Basic Syntax

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading: Start
    Loading --> Success: Complete
    Loading --> Error: Fail
    Success --> Idle: Reset
    Error --> Idle: Retry
```

### Composite States

```mermaid
stateDiagram-v2
    [*] --> Unpaid
    
    state Unpaid {
        [*] --> Pending
        Pending --> Failed: Card rejected
        Failed --> Pending: Retry
    }
    
    Unpaid --> Paid: Payment received
    Paid --> [*]
```

### Example: Order States

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> Pending: Submit
    Pending --> Processing: Payment OK
    Pending --> Cancelled: Payment Fail
    Processing --> Shipped
    Shipped --> Delivered
    Delivered --> [*]
    Cancelled --> [*]
```

---

## Class Diagram

Best for: Object models, architecture, relationships, domain modeling.

### Basic Syntax

```mermaid
classDiagram
    class User {
        +String name
        +String email
        +login()
        +logout()
    }
    
    class Post {
        +String title
        +String content
        +publish()
    }
    
    User "1" --> "*" Post: creates
```

### Relationships

| Syntax | Relationship |
| ------ | ------------ |
| `-->`  | Association  |
| `--*`  | Composition  |
| `--o`  | Aggregation  |
| `--    | >`           |
| `--`   | Link (solid) |
| `..>`  | Dependency   |
| `..    | >`           |

### Multiplicity

- `"1"` — One
- `"*"` — Many
- `"0..1"` — Zero or one
- `"1..*"` — One or more

### Example: Domain Model

```mermaid
classDiagram
    class Order {
        +String id
        +Date createdAt
        +total()
    }
    
    class OrderItem {
        +Int quantity
        +Decimal price
    }
    
    class Product {
        +String name
        +Decimal price
    }
    
    Order "1" *-- "*" OrderItem: contains
    OrderItem "*" --> "1" Product: references
```

---

## Entity Relationship Diagram

Best for: Database schema, data models, system design.

### Basic Syntax

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
    PRODUCT ||--o{ ORDER_ITEM : "included in"
```

### Relationship Syntax

| Symbol | Meaning      |
| ------ | ------------ |
| `\|\|` | Exactly one  |
| `o{`   | Zero or more |
| `\|{`  | One or more  |
| `}o`   | Zero or more |
| `}\|`  | One or more  |

### Entity Attributes

```mermaid
erDiagram
    USER {
        string id PK
        string email UK
        string name
        timestamp created_at
    }
    
    ORDER {
        string id PK
        string user_id FK
        string status
        decimal total
    }
    
    USER ||--o{ ORDER : places
```

### Example: E-commerce Schema

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
    PRODUCT ||--o{ ORDER_ITEM : "included in"
    PRODUCT ||--o{ REVIEW : has
    
    CUSTOMER {
        string id PK
        string email UK
        string name
    }
    
    ORDER {
        string id PK
        string customer_id FK
        string status
        timestamp created_at
    }
    
    PRODUCT {
        string id PK
        string name
        decimal price
    }
```

---

## Tips

1. **Test at mermaid.live** — Validate syntax before running MAAR
2. **Keep it simple** — Complex diagrams render poorly as ASCII
3. **Use meaningful labels** — Short text works best in ASCII
4. **Limit node count** — Under 20 nodes for readable ASCII output
5. **Avoid deep nesting** — 3-4 levels max for flowcharts
