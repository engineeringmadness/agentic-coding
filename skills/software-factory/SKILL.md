---
name: software-factory
description: >
  Overall orchestrator for implementing a software factory within your coding harness of choice.
metadata:
  author: engineeringmadness
  version: "0.1.0"
argument-hint: "[github issue ID]"
---

## What is a Software Factory

A software factory is an automated, end-to-end development system where AI coding agents or streamlined pipelines handle production tasks like coding, testing, and reviewing, while human engineers focus on architecture, intent, and final approval.

## Workflow

1. Ensure you know what to work on in terms of a specific Issue ID from GitHub
2. Use the `gh` CLI to pull the issue details
3. Look for any notion link present in the issue details. This notion link holds the detailed PRD (Requirements document) for the issue you will be working on
4. Pull the content of the PRD using the `Notion MCP`
5. Now that you have the PRD, prepare a spec file using the `brainstorming` skill and specifically capture a TODO list of phases
6. Once brainstorming is complete and spec is ready and reviewed start implementing the changes in phases
8. Initialize a stacked PR using `gh` CLI by invoking the `gh-stack` skill
9. For each phase 
  a. implement the changes on a new branch. By default use the `ponytail` skill in lite mode 
  b. Run any tests to verify changes
  c. Add the branch to stack using `gh` CLI by involing the `gh-stack` skill
11. Once all phases are implemented and added to the stack submit the stack using `gh` cli by invoking the `gh-stack` skill
12. In case a change is requested us the `gh-stack` skill to move up and down the stack to the correct entry containing the relevant code changes. Then modify the stack accordingly.