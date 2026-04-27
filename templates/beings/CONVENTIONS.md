# CONVENTIONS.md — Project Conventions

<!-- I'll document the project's code style and patterns
     as I discover them. -->

## Personas

Reusable expert personas live in `.beings/personas/`. Each is a markdown file defining:
- Name, role, and domain
- 5–10 review or decision lenses
- When to invoke

Example: `.beings/personas/cbo-varuna.md` — Chief Business Officer persona for
proposal review. Invoke by saying: "Wear your Varuna hat and review this proposal."

The Being loads the persona file on demand — not every session.
