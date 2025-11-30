# REST API Documentation

## GiftHealth Pharmacy Prescription Events API

Base URL: `http://localhost:3000/api/v1`

### Authentication

Currently no authentication is required. In production, you should implement API key authentication or OAuth2.

---

## Endpoints

### 1. Create Single Prescription Event

**Endpoint:** `POST /api/v1/prescription_events`

**Description:** Process a single prescription event.

**Request Body:**
```json
{
  "patient_name": "John",
  "drug_name": "A",
  "event_name": "created"
}
```

**Parameters:**
- `patient_name` (string, required): The name of the patient
- `drug_name` (string, required): The name/code of the drug
- `event_name` (string, required): Type of event: `created`, `filled`, or `returned`

**Success Response (201 Created):**
```json
{
  "message": "Event processed successfully",
  "patient_name": "John",
  "drug_name": "A",
  "event_name": "created"
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Missing required parameters: patient_name, drug_name, event_name"
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "error": "Failed to process event: <error message>"
}
```

**Example with curl:**
```bash
curl -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "John",
    "drug_name": "A",
    "event_name": "created"
  }'
```

---

### 2. Batch Create Prescription Events

**Endpoint:** `POST /api/v1/prescription_events/batch`

**Description:** Process multiple prescription events in a single request.

**Request Body:**
```json
{
  "events": [
    {
      "patient_name": "John",
      "drug_name": "A",
      "event_name": "created"
    },
    {
      "patient_name": "John",
      "drug_name": "A",
      "event_name": "filled"
    },
    {
      "patient_name": "Jane",
      "drug_name": "B",
      "event_name": "created"
    }
  ]
}
```

**Parameters:**
- `events` (array, required): Array of event objects
  - Each event must contain `patient_name`, `drug_name`, and `event_name`

**Success Response (200 OK):**
```json
{
  "processed": 3,
  "total": 3
}
```

**Partial Success Response (200 OK):**
```json
{
  "processed": 2,
  "total": 3,
  "errors": [
    {
      "index": 1,
      "error": "Missing required fields"
    }
  ]
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "events must be an array"
}
```

**Example with curl:**
```bash
curl -X POST http://localhost:3000/api/v1/prescription_events/batch \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      {"patient_name": "John", "drug_name": "A", "event_name": "created"},
      {"patient_name": "John", "drug_name": "A", "event_name": "filled"},
      {"patient_name": "John", "drug_name": "A", "event_name": "returned"}
    ]
  }'
```

---

## Business Rules

### Event Types

1. **created**: Initializes a prescription for a patient-drug combination
   - Must be the first event for any patient-drug combination
   - Multiple creates for the same combination are idempotent

2. **filled**: Records a prescription fill
   - Can only be processed after a prescription is created
   - Can be recorded multiple times
   - Generates $5 income per fill

3. **returned**: Records a prescription return
   - Can only be processed after a prescription is created
   - Can only return prescriptions that have been filled
   - Cannot return more than the number of fills
   - Cancels the income from one fill ($5) and incurs a $1 penalty
   - Net effect: reduces income by $6 per return

### Income Calculation

The income for a prescription is calculated as:
```
income = (net_fills × $5) - (return_count × $1)
```

Where:
- `net_fills = fill_count - return_count`
- Each fill generates $5
- Each return cancels a fill's income AND costs $1

**Example:**
- 3 fills, 1 return:
  - net_fills = 2
  - income = (2 × $5) - (1 × $1) = $10 - $1 = $9

---

## Response Codes

- `200 OK`: Request processed successfully (batch endpoint)
- `201 Created`: Event created successfully (single event endpoint)
- `400 Bad Request`: Invalid request format or missing required parameters
- `422 Unprocessable Entity`: Request format valid but processing failed

---

## Example Workflows

### Complete Prescription Lifecycle

```bash
# 1. Create prescription
curl -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Alice", "drug_name": "Aspirin", "event_name": "created"}'

# 2. Fill prescription (first time)
curl -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Alice", "drug_name": "Aspirin", "event_name": "filled"}'

# 3. Fill prescription (second time - refill)
curl -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Alice", "drug_name": "Aspirin", "event_name": "filled"}'

# 4. Return one prescription
curl -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Alice", "drug_name": "Aspirin", "event_name": "returned"}'
```

Result: Alice will have:
- 2 fills - 1 return = 1 net fill
- Income: (1 × $5) - (1 × $1) = $4

### Batch Processing Multiple Patients

```bash
curl -X POST http://localhost:3000/api/v1/prescription_events/batch \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      {"patient_name": "Bob", "drug_name": "Ibuprofen", "event_name": "created"},
      {"patient_name": "Bob", "drug_name": "Ibuprofen", "event_name": "filled"},
      {"patient_name": "Carol", "drug_name": "Antibiotics", "event_name": "created"},
      {"patient_name": "Carol", "drug_name": "Antibiotics", "event_name": "filled"},
      {"patient_name": "Carol", "drug_name": "Antibiotics", "event_name": "filled"}
    ]
  }'
```

Result:
- Bob: 1 fill, $5 income
- Carol: 2 fills, $10 income

---

## Testing the API

### Using curl

```bash
# Test single event
curl -i -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Test", "drug_name": "X", "event_name": "created"}'

# Test batch events
curl -i -X POST http://localhost:3000/api/v1/prescription_events/batch \
  -H "Content-Type: application/json" \
  -d '{"events": [{"patient_name": "Test", "drug_name": "X", "event_name": "filled"}]}'
```

### Using JavaScript/Fetch

```javascript
// Single event
fetch('http://localhost:3000/api/v1/prescription_events', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    patient_name: 'John',
    drug_name: 'A',
    event_name: 'created'
  })
})
.then(response => response.json())
.then(data => console.log(data));

// Batch events
fetch('http://localhost:3000/api/v1/prescription_events/batch', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    events: [
      { patient_name: 'John', drug_name: 'A', event_name: 'created' },
      { patient_name: 'John', drug_name: 'A', event_name: 'filled' }
    ]
  })
})
.then(response => response.json())
.then(data => console.log(data));
```

### Using Python/Requests

```python
import requests

# Single event
response = requests.post(
    'http://localhost:3000/api/v1/prescription_events',
    json={
        'patient_name': 'John',
        'drug_name': 'A',
        'event_name': 'created'
    }
)
print(response.json())

# Batch events
response = requests.post(
    'http://localhost:3000/api/v1/prescription_events/batch',
    json={
        'events': [
            {'patient_name': 'John', 'drug_name': 'A', 'event_name': 'created'},
            {'patient_name': 'John', 'drug_name': 'A', 'event_name': 'filled'}
        ]
    }
)
print(response.json())
```

---

## Rate Limiting

Currently no rate limiting is implemented. In production, consider implementing rate limiting to prevent abuse.

## Future Enhancements

- Authentication (API keys or OAuth2)
- Rate limiting
- Pagination for large datasets
- Filtering and querying capabilities
- Webhooks for event notifications
- Async processing for large batches
