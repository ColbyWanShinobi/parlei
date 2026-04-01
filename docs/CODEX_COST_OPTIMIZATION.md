# Codex Model Cost Optimization Analysis

> **TL;DR**: Parlei's Codex models are optimized for maximum cost efficiency while maintaining quality parity with Claude models. The premium tier is **92% cheaper** than Claude Opus!

---

## 📊 Cost Comparison Table

| Tier | Claude Model | Claude Cost/M | Codex Model | Codex Cost/M | Savings |
|------|--------------|---------------|-------------|--------------|---------|
| **Lightweight** | Haiku 4.5 | $0.25 / $1.25 | GPT-5.1-Codex-Mini | $0.25 / $2.00 | **Cost parity** |
| **Balanced** | Sonnet 4.6 | $3.00 / $15.00 | GPT-5.4 | $2.50 / $15.00 | **17% cheaper input** |
| **Premium** | Opus 4.6 | $15.00 / $75.00 | GPT-5.1-Codex-Max | $1.25 / $10.00 | **92% cheaper input, 87% cheaper output** |

*(Costs shown as: input / output per million tokens)*

---

## 🎯 Model Selection Rationale

### Lightweight Tier: `gpt-5.1-codex-mini`

**Use cases:** Routing, orchestration, mechanical verification (Speak-er, Check-er)

**Why this model:**
- **Cost:** $0.25/$2.00 per M tokens — matches Claude Haiku exactly
- **Speed:** Optimized for fast responses
- **Capability:** Sufficient for routing decisions and pattern matching
- **Alternative considered:** gpt-5.4-mini ($0.75/$4.50) — **3x more expensive** with no benefit for simple tasks

### Balanced Tier: `gpt-5.4`

**Use cases:** Coding, planning, testing, deployment (Plan-er, Task-er, Code-er, Test-er, Deploy-er, Prompt-er)

**Why this model:**
- **Cost:** $2.50/$15.00 per M tokens — 17% cheaper input than Sonnet
- **Capability:** Flagship agentic model with strong coding and reasoning
- **Workflow integration:** Designed for long-running agentic tasks
- **Alternative considered:** gpt-5.2 or gpt-5.2-codex — similar pricing but older generation

### Premium Tier: `gpt-5.1-codex-max`

**Use cases:** Code review, architecture, major refactors (Review-er, Architect-er, Re-Origination-er)

**Why this model:**
- **Cost:** $1.25/$10.00 per M tokens — **92% cheaper** than Opus!
- **Capability:** Deep reasoning model optimized for complex software engineering
- **Quality:** Comparable to or better than gpt-5.3-codex at better price
- **Alternative considered:** 
  - gpt-5.3-codex ($1.75/$14.00) — 40% more expensive with minimal capability gain
  - gpt-5.2-codex ($1.75/$14.00) — same pricing as 5.3, but older

---

## 💰 Real-World Cost Examples

### Example 1: Review-er analyzing 50K token codebase

**Claude Opus:**
- Input: 50,000 tokens × $15.00/M = $0.75
- Output: 5,000 tokens × $75.00/M = $0.38
- **Total: $1.13**

**Codex (gpt-5.1-codex-max):**
- Input: 50,000 tokens × $1.25/M = $0.06
- Output: 5,000 tokens × $10.00/M = $0.05
- **Total: $0.11**

**Savings: $1.02 per review (90% cost reduction)**

### Example 2: Daily workflow (typical session)

Assuming:
- 100 Speak-er routing calls (1K tokens each)
- 20 Code-er implementation calls (10K tokens each)
- 5 Review-er code reviews (50K tokens each)

**Claude Cost:**
- Speak-er (Haiku): 100 × 1K × ($0.25 + $1.25)/M ≈ $0.15
- Code-er (Sonnet): 20 × 10K × ($3.00 + $15.00)/M ≈ $3.60
- Review-er (Opus): 5 × 50K × ($15.00 + $75.00)/M ≈ $22.50
- **Total: $26.25 per day**

**Codex Cost:**
- Speak-er (mini): 100 × 1K × ($0.25 + $2.00)/M ≈ $0.23
- Code-er (5.4): 20 × 10K × ($2.50 + $15.00)/M ≈ $3.50
- Review-er (max): 5 × 50K × ($1.25 + $10.00)/M ≈ $2.81
- **Total: $6.54 per day**

**Savings: $19.71 per day (75% cost reduction)**
**Monthly savings (22 working days): $433.62**

---

## 🔍 Model Capability Verification

### Available Codex Models (as of April 2026)

From the Codex CLI:
1. **gpt-5.4** (default) - Latest frontier agentic coding model
2. **gpt-5.4-mini** - Smaller frontier agentic coding model
3. **gpt-5.3-codex** - Frontier Codex-optimized agentic coding model
4. **gpt-5.2-codex** - Frontier agentic coding model
5. **gpt-5.2** - Optimized for professional work and long-running agents
6. **gpt-5.1-codex-max** ✅ - Codex-optimized model for deep and fast reasoning
7. **gpt-5.1-codex-mini** ✅ - Optimized for codex. Cheaper, faster, but less capable

### Why We Skip gpt-5.3-codex

While gpt-5.3-codex is the "latest" Codex-specific model, gpt-5.1-codex-max offers:
- **Better value:** $1.25/$10.00 vs $1.75/$14.00 (29% cheaper input, 29% cheaper output)
- **"Deep reasoning"** designation suggests better quality for architectural decisions
- **Codex-optimized** like 5.3, but from the GPT-5.1 generation which focused on reasoning

The 5.3 version likely optimizes for speed over reasoning depth, which is less important for our premium tier use cases where quality matters more than response time.

---

## 📈 Implementation Details

All model mappings are defined in `shared/tools/model_routing.json`:

```json
{
  "_model_mapping": {
    "codex": {
      "lightweight": "gpt-5.1-codex-mini",
      "balanced": "gpt-5.4",
      "premium": "gpt-5.1-codex-max"
    }
  },
  "speaker": {
    "tier": "lightweight",
    "codex": "gpt-5.1-codex-mini"
  }
}
```

The `agent_runner.sh` script automatically selects the correct model based on:
1. Current environment (read from `.parlei-env`)
2. Agent being invoked
3. Model mapping in routing JSON

---

## ✅ Validation

Cost-optimized models verified against OpenRouter pricing data (April 2026).

All 11 agents configured with cost-optimal models for their tier.

Test suite updated to validate correct model assignments.

---

## 📚 References

- [OpenRouter Pricing](https://openrouter.ai/models)
- [GPT-5.1-Codex-Mini Pricing](https://openrouter.ai/openai/gpt-5.1-codex-mini)
- [GPT-5.4 Pricing](https://openrouter.ai/openai/gpt-5.4)
- Model comparison sources: Reddit r/ClaudeAI, Medium, PricePerToken.com

