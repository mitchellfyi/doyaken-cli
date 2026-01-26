---
name: prompt-testing
description: Apply testing best practices
args:
  - name: target
    description: File, directory, or code to analyze
    default: "."
  - name: output
    description: Output format (summary, detailed, checklist)
    default: "detailed"
---

# Testing

Apply the testing methodology to the specified target.

## Context

Target: {{ARGS.target}}
Output format: {{ARGS.output}}
Project: {{DOYAKEN_PROJECT}}

## Methodology

{{include:library/testing.md}}

## Instructions

1. Read and understand the target ({{ARGS.target}})
2. Apply the methodology above systematically
3. Document findings using the output format ({{ARGS.output}}):
   - **summary**: Brief overview with key points
   - **detailed**: Full analysis with all sections
   - **checklist**: Checklist format with pass/fail for each item

## Output

Provide your analysis following the templates in the methodology.
