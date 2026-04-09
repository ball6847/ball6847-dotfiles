---
name: api-design-guide
description: |
  Create technology-neutral API design documents with consistent structure, 
  response formats, error handling, and ASCII diagram integration.

  Use this skill when:
  - User asks to "design an API" or "create API documentation"
  - User needs to document REST API endpoints
  - User wants "API design guidelines" or "API specification"
  - User is creating high-level API design docs (not implementation)
  - User needs consistent API response/error formats
  - User wants to visualize API flows with diagrams
---

# API Design Guide

Create professional, technology-neutral API design documents that follow industry standards and consistent patterns.

## Core Principles

1. **Technology Neutral**: Use HTTP/REST standards, not framework-specific code
2. **Consistent Format**: Standard response wrapper, error codes, data models
3. **Visual Documentation**: Include ASCII/Mermaid diagrams for flows
4. **Implementation Agnostic**: Focus on interface, not backend technology

## Document Structure

ALWAYS use this exact structure:

````markdown
# {API Name} Design

> **Approach**: {One-line summary of the design approach}
> **Date**: {YYYY-MM-DD}

---

## Overview

{High-level description of the API purpose and design philosophy}

{ASCII flowchart diagram showing main flows}

> **Diagram Reference**: `diagrams/01-overview.mmd`

---

## API Specifications

### Standard Response Format

All API responses follow the standard wrapper format:

```json
{
  "status": {
    "code": 0,
    "message": "success",
    "attrs": {}  // Optional, for error details
  },
  "data": { ... }  // Response payload (omitted on error)
}
```
````

**Success**: `code: 0`  
**Error**: Non-zero code with HTTP status matching error context

---

### 1. {Endpoint Name} ({Step/Context})

{Brief description of what this endpoint does}

**Endpoint**: `{METHOD} /api/v{N}/{path}`

**Authentication**: Required (Bearer token) / Optional / Not required

**Request**:

- Content-Type: `application/json` or `multipart/form-data`
- Body: {Describe request body structure}

**Request Example**:

```json
{
  "field": "value"
}
```

**Response ({HTTP Status})**:

```json
{
  "status": {
    "code": 0,
    "message": "success"
  },
  "data": {
    // Response fields
  }
}
```

**Error Responses**:

| HTTP Status | Error Code | Message            | Description           |
| ----------- | ---------- | ------------------ | --------------------- |
| `400`       | `9001`     | `validation error` | Invalid input         |
| `401`       | `9101`     | `unauthorized`     | Missing/invalid token |

**Error Response Format**:

```json
{
  "status": {
    "code": 9001,
    "message": "validation error",
    "attrs": {
      "field": "fieldName",
      "reason": "specific error"
    }
  }
}
```

---

## Entity Relationship Diagram

{ASCII ER diagram showing entities and relationships}

> **Diagram Reference**: `diagrams/02-entity-relationship.mmd`

**Relationships**:

- EntityA 1:N EntityB (relationship description)

---

## Sequence Diagrams

### {Flow Name}

{ASCII sequence diagram}

> **Diagram Reference**: `diagrams/03-sequence-{name}.mmd`

**Notes**:

- Key implementation notes

---

## Data Models

### {ModelName}

```typescript
interface {ModelName} {
  id: string;           // Example: "usr_abc123"
  fieldName: string;    // Description
  numericField: number; // Unit/description
  optionalField?: string;
  enumField: "value1" | "value2";
  arrayField: string[];
  createdAt: string;    // ISO 8601 format
}
```

---

## Error Code Registry

| Code Range    | Module     | Description              |
| ------------- | ---------- | ------------------------ |
| 0             | Success    | Operation successful     |
| 9000-9099     | Validation | Input validation errors  |
| 9100-9199     | Auth       | Authentication errors    |
| {N}000-{N}999 | {Module}   | {Module} specific errors |

### Specific Error Codes Used

| Code   | Error           | HTTP     | Scenario                 |
| ------ | --------------- | -------- | ------------------------ |
| 0      | Success         | 200/201  | Operation successful     |
| 9001   | `ErrValidation` | 400      | Generic validation error |
| {code} | `{ErrorName}`   | {status} | {scenario}               |

---

## Data Flow Summary

| Step       | Action   | Storage   | API Call                    |
| ---------- | -------- | --------- | --------------------------- |
| **Step 1** | {Action} | {Storage} | `{METHOD} /api/v{N}/{path}` |

---

## Benefits of This Design

| Benefit         | Explanation   |
| --------------- | ------------- |
| **{Benefit 1}** | {Explanation} |
| **{Benefit 2}** | {Explanation} |

````

## Technology-Neutral Guidelines

### ALLOWED (Industry Standards)
- HTTP methods: GET, POST, PUT, DELETE, PATCH
- HTTP status codes: 200, 201, 204, 400, 401, 403, 404, 500
- Content-Types: application/json, multipart/form-data
- Authentication: Bearer token, API key
- Data formats: JSON, ISO 8601 dates
- REST conventions: plural nouns, hierarchical paths

### AVOID (Technology-Specific)
- ❌ Framework-specific code (Go structs, Java annotations, Python decorators)
- ❌ Database-specific syntax (SQL operators, MongoDB operators)
- ❌ Cloud provider names (S3 → use "Cloud Storage" or "Storage")
- ❌ Language-specific types (int64 → number, string → string)
- ❌ Local storage mechanisms (localStorage → Client cache)
- ❌ Implementation details (garbage collection → cleanup job)

### Data Types
Use TypeScript-style interface definitions:

| TypeScript | Meaning |
|------------|---------|
| `string` | Text values |
| `number` | Numeric values (integers and floats) |
| `boolean` | true/false |
| `T[]` | Array of type T |
| `Type \| Type` | Union types (enums) |
| `field?: T` | Optional field |

## Response Format Rules

### Success Response (200/201)
```json
{
  "status": {
    "code": 0,
    "message": "success"
  },
  "data": { ... }
}
````

### Error Response

```json
{
  "status": {
    "code": {non-zero},
    "message": "human readable error",
    "attrs": {
      "field": "which field failed",
      "reason": "why it failed"
    }
  }
}
```

### Error Code Organization

| Range       | Module           |
| ----------- | ---------------- |
| 0           | Success          |
| 9000-9099   | Validation       |
| 9100-9199   | Authentication   |
| 9200-9299   | Authorization    |
| 9300-9399   | Not Found        |
| 9400-9499   | Rate Limiting    |
| 9900-9999   | Internal Error   |
| 10000-10999 | User/Identity    |
| 11000-11999 | Deal/Transaction |
| 12000-12999 | Media/Upload     |

## Diagram Integration

### Creating Diagrams

1. Write Mermaid diagrams in `diagrams/*.mmd` files
2. Render to ASCII using pretty-mermaid skill
3. Include ASCII in document
4. Add reference to source Mermaid file

### Diagram Types by Use Case

| Purpose            | Diagram Type  | Tool                    |
| ------------------ | ------------- | ----------------------- |
| Process flow       | Flowchart     | Mermaid flowchart       |
| API interactions   | Sequence      | Mermaid sequenceDiagram |
| Data relationships | ER Diagram    | Mermaid erDiagram       |
| State transitions  | State Diagram | Mermaid stateDiagram-v2 |
| Object hierarchy   | Class Diagram | Mermaid classDiagram    |

### Diagram Reference Format

Always include after ASCII diagram:

```markdown
> **Diagram Reference**: `diagrams/{NN}-{name}.mmd` (Source: {Diagram Type} - {Description})
```

## Working with User Requests

### Step 1: Understand Requirements

Ask the user:

1. What is the API for? (domain/purpose)
2. What are the main operations?
3. Who are the consumers? (mobile app, web, third-party)
4. Are there existing patterns to follow?
5. What storage/entities are involved?

### Step 2: Create Diagrams First

Before writing API specs:

1. Create overview flowchart
2. Design entity relationships
3. Map sequence flows
4. Render to ASCII

### Step 3: Design Endpoints

For each endpoint:

1. Define URL path (RESTful)
2. Specify method and auth
3. Design request/response schemas
4. Document error cases
5. Assign error codes

### Step 4: Compile Document

1. Follow the document structure
2. Ensure all sections are populated
3. Add diagram references
4. Create error code registry
5. Add data flow summary

## Example: Complete Endpoint Design

**User says**: "I need an endpoint to upload user profile photos"

**Design process**:

1. Identify: File upload endpoint
2. Path: `POST /api/v1/users/{id}/photos`
3. Auth: Required
4. Request: multipart/form-data
5. Response: 201 Created with media info
6. Errors: 400 (file too large, wrong type), 401, 404 (user not found)
7. Error codes: 16001 (file too large), 16002 (invalid type)

**Document**:

````markdown
### 3. Upload User Photo

Upload a profile photo for the specified user.

**Endpoint**: `POST /api/v1/users/{id}/photos`

**Authentication**: Required (Bearer token)

**Request**:

- Content-Type: `multipart/form-data`
- Max file size: 5MB
- Allowed types: JPEG, PNG

**Request Body**:

```http
Content-Disposition: form-data; name="photo"; filename="avatar.jpg"
Content-Type: image/jpeg

[binary data]
```
````

**Response (201 Created)**:

```json
{
  "status": {
    "code": 0,
    "message": "success"
  },
  "data": {
    "mediaId": "med_abc123",
    "url": "https://cdn.example.com/photos/med_abc123.jpg",
    "thumbnailUrl": "https://cdn.example.com/photos/med_abc123_thumb.jpg"
  }
}
```

**Error Responses**:

| HTTP Status | Error Code | Message             | Description           |
| ----------- | ---------- | ------------------- | --------------------- |
| `400`       | `16001`    | `file too large`    | Exceeds 5MB limit     |
| `400`       | `16002`    | `invalid file type` | Not JPEG/PNG          |
| `401`       | `9101`     | `unauthorized`      | Invalid token         |
| `404`       | `11001`    | `user not found`    | User ID doesn't exist |

````

## Quality Checklist

Before finalizing the document, verify:

- [ ] All endpoints use `/api/v{N}/` prefix
- [ ] All responses use standard wrapper format
- [ ] All error codes follow range conventions
- [ ] All data models use TypeScript interfaces
- [ ] No framework-specific code
- [ ] No cloud provider names (use generic terms)
- [ ] All diagrams have Mermaid source references
- [ ] ASCII diagrams are properly aligned
- [ ] Error code registry is complete
- [ ] Data flow summary table is populated
- [ ] Benefits section explains design decisions

## Common Patterns

### CRUD Operations

| Operation | Method | Path | Auth |
|-----------|--------|------|------|
| Create | POST | /api/v1/{resources} | Required |
| Read (list) | GET | /api/v1/{resources} | Required |
| Read (one) | GET | /api/v1/{resources}/{id} | Required |
| Update | PUT/PATCH | /api/v1/{resources}/{id} | Required |
| Delete | DELETE | /api/v1/{resources}/{id} | Required |

### Authentication Patterns

```markdown
**Authentication**: Required (Bearer token)

Header: `Authorization: Bearer {token}`
````

### Pagination Pattern

```json
{
  "status": { "code": 0, "message": "success" },
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

### File Upload Pattern

```markdown
**Request**:

- Content-Type: `multipart/form-data`
- Max files: {N}
- Max size per file: {N}MB
- Allowed types: {list}
```
