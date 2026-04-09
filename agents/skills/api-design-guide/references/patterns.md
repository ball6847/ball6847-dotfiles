# API Design Patterns Reference

Common patterns and decisions for API design documents.

## Response Wrapper Pattern

Always use a standard response wrapper for consistency:

```json
{
  "status": {
    "code": 0,
    "message": "success",
    "attrs": {}
  },
  "data": {}
}
```

**Why**:

- Client can always check `status.code === 0` for success
- Error details in `attrs` allow programmatic handling
- Consistent structure regardless of endpoint

## Error Code Ranges

Standard error code allocation:

| Range     | Purpose                                        |
| --------- | ---------------------------------------------- |
| 0         | Success                                        |
| 9000-9099 | Validation/Input errors                        |
| 9100-9199 | Authentication errors                          |
| 9200-9299 | Authorization errors                           |
| 9300-9399 | Not found errors                               |
| 9400-9499 | Rate limiting                                  |
| 9900-9999 | Internal errors                                |
| 10000+    | Domain-specific (10000=User, 11000=Deal, etc.) |

## Technology-Neutral Replacements

| Instead of             | Use                     |
| ---------------------- | ----------------------- |
| S3                     | Cloud Storage / Storage |
| localStorage           | Client cache            |
| NULL / IS NULL         | empty / is empty        |
| Garbage collection     | Cleanup job             |
| int64                  | number                  |
| struct                 | interface               |
| Go/TypeScript specific | Generic HTTP/JSON terms |

## Authentication Patterns

### Bearer Token

```markdown
**Authentication**: Required (Bearer token)

Header: `Authorization: Bearer {token}`
```

### Optional Auth

```markdown
**Authentication**: Optional (Bearer token)

If provided, user-specific data is returned.
If omitted, public data only.
```

## Pagination Patterns

### Offset-Based

```typescript
interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}
```

### Cursor-Based

```typescript
interface CursorResponse<T> {
  items: T[];
  nextCursor: string | null;
  hasMore: boolean;
}
```

## File Upload Patterns

### Single File

```markdown
**Request**:

- Content-Type: `multipart/form-data`
- Max size: 5MB
- Allowed: JPEG, PNG

**Response**: Media object with id, url
```

### Multiple Files

```markdown
**Request**:

- Content-Type: `multipart/form-data`
- Min: 1 file
- Max: 3 files
- Max each: 5MB

**Response**: Array of Media objects
```

## Common Endpoint Patterns

### Create Resource

```
POST /api/v1/{resources}
Body: { resource data }
Response: 201 Created + created resource
```

### List Resources

```
GET /api/v1/{resources}?page=1&limit=20
Response: 200 OK + paginated list
```

### Get Resource

```
GET /api/v1/{resources}/{id}
Response: 200 OK + resource / 404 Not Found
```

### Update Resource

```
PUT /api/v1/{resources}/{id}
Body: { full resource }
Response: 200 OK + updated resource

PATCH /api/v1/{resources}/{id}
Body: { partial updates }
Response: 200 OK + updated resource
```

### Delete Resource

```
DELETE /api/v1/{resources}/{id}
Response: 204 No Content
```

## Sequence Diagram Conventions

1. Number steps sequentially
2. Include HTTP method/path in request arrows
3. Show validation as self-call
4. Use dashed lines for returns
5. Include error flows separately

## Error Response Format

```json
{
  "status": {
    "code": 9001,
    "message": "validation error",
    "attrs": {
      "field": "email",
      "reason": "invalid format"
    }
  }
}
```

**Field attributes** (safe for user handlers):

- `field` - Which field failed
- `reason` - Human-readable explanation
- `constraint` - What constraint was violated
- `value` - The invalid value (be careful with PII)

## Date/Time Formats

Always use ISO 8601 format in responses:

```typescript
createdAt: string; // "2026-01-15T10:30:00Z"
```

## Enum Patterns

Use string literals in TypeScript:

```typescript
type Status = "pending" | "active" | "completed";
type Condition = "new" | "good" | "fair";
```

Document allowed values in field tables:
| Field | Type | Allowed Values |
|-------|------|----------------|
| status | string | `pending`, `active`, `completed` |
