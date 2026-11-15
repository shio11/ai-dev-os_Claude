# Refactoring Prompt

A prompt template for making guideline-based decisions when improving existing code.

---

## Prompt

```markdown
Please refactor the following code.

## Refactoring Decision Criteria (02_decision-criteria/abstraction.md)

### Refactoring You Should Do
1. **3+ places of duplication** → Extract into factory functions or helper functions
2. **5+ similar view builders** → Create a shared builder in `lib` or `views`
3. **Files exceeding 200–300 lines** → Split by responsibility
4. **Functions with 3+ positional arguments** → Use an options object

### Refactoring You Should Not Do
1. **Abstracting code used in only 1 place** → Leave it as is
2. **Generalizing for "might use in the future"** → YAGNI
3. **Forcing unification of similar but not identical code** → Only increases conditional branches
4. **Unnecessarily rewriting working code** → Not worth the risk

## AI-Generated Code Awareness
When refactoring AI-generated code, pay attention to:
- AI tends to over-abstract — verify each abstraction has 3+ actual use sites
- AI-generated utility functions may duplicate existing project utilities — check first
- AI may introduce inconsistent patterns — align with the dominant pattern in the module

## Output Format

### Change Summary
| Change | Reason | Reference Guideline |
|--------|--------|-------------------|

### Things Not Changed
| Target | Reason for Deferral |
|--------|-------------------|
```
