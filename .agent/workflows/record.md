---
description: record prompt and answer
---

# Agent iOS Memory Recording Workflow

This workflow explains how to record prompts and responses to the persistent agent memory file.

## Memory File Location
`/agent_ios_memory.json` (project root)

## When to Use
The user will ask you to "register this prompt and your response" or similar phrases like:
- "registra este prompt"
- "record this"
- "add this to the memory file"

## Steps

1. **Read the memory file first**
   - Open `agent_ios_memory.json` at the project root
   - Read the `AGENT_INSTRUCTIONS` section for context
   - Check the `prompt_log` array to see the last entry's `id`

2. **Create a new entry**
   - Add a new object at the END of the `prompt_log` array
   - Use the next sequential `id` number

3. **Fill in these required fields:**

| Field | Description |
|-------|-------------|
| `id` | Next number in sequence |
| `timestamp` | Current date/time in ISO format (e.g., `2025-12-09T20:24:40-05:00`) |
| `user_prompt` | The EXACT text the user wrote (can be summarized if very long) |
| `agent_interpretation` | Your understanding of what the user wants |
| `actions_taken` | Array of what you did to fulfill the request |
| `key_learnings` | Important discoveries or configurations to remember |
| `outcome` | Brief result summary |

4. **Update metadata**
   - Update `metadata.last_updated` with current timestamp
   - Increment `metadata.total_prompts_logged`

## Important Rules

- **Language**: Write ALL entries in **ENGLISH** for agent consumption, even if user writes in Spanish
- **Purpose**: This creates institutional memory so future agents have full context of what has been done
- **Technical reference**: If you discover important technical info, also add it to the `technical_reference` section

## Example Entry

```json
{
    "id": 13,
    "timestamp": "2025-12-10T04:30:00-05:00",
    "user_prompt": "Add a new feature to the map",
    "agent_interpretation": "User wants to enhance the map functionality with...",
    "actions_taken": [
        "Modified MapView.swift to add...",
        "Added new state property for..."
    ],
    "key_learnings": [
        "MapKit feature X works best when...",
        "Use Y pattern for performance"
    ],
    "outcome": "Successfully added feature with full functionality"
}
```
