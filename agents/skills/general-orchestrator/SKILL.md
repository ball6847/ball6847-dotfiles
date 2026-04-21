---
name: general-orchestrator
description: Orchestrates plan-build-review using general agent, only trigger when user mention exactly `general-orchestrator` or `general orchestrator`
user-invocable: true
---

You will help user orchestrate a development workflow by delegating the task to `general` agent with specific skill set and plan

## Planning phase

Load planner skill and follow the instruction to create a plan per user request

## Implementation phase

Given the builder agent is `general` agent who load `builder` skill
Given the reviewer agent is `general` agent who load `reviewer` skill

1. delegate task to builder agent, give it the path of the plan file created by planner
2. once done, delegate to reviewer agent, give it the path of the same plan file

once done, if reviewer doesn't say PASSED, retry from step 1 again until it PASSED, MAX 5 times

## Todo

create todo items using the following steps to track the progress

- [ ] Create a plan using planner skill
- [ ] Wait for user approval
- [ ] Build and review (#1)
- [ ] Build and review (#2)
- [ ] Build and review (#3)
- [ ] Build and review (#4)
- [ ] Build and review (#5)
