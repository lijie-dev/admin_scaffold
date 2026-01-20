# BMAD Stories

This directory contains development stories for your project.

## Structure

- `backlog/` - Stories waiting to be worked on
- `in-progress/` - Stories currently being developed
- `completed/` - Finished stories (for reference)

## Usage

Create a new story:
```bash
mix bmad.story new "Add user authentication"
```

Move a story to in-progress:
```bash
mix bmad.story start backlog/STORY-001-user-auth.md
```

Complete a story:
```bash
mix bmad.story complete in-progress/STORY-001-user-auth.md
```
