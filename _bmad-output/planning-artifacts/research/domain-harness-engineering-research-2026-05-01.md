# Harness Engineering para Agentes IA Autónomos

## Investigación de Dominio — 1 Mayo 2026

> **Nota del autor**: Esta investigación nace de la pregunta "¿qué comandos BMad uso para investigar harness engineering?" — pero evolucionó en algo más ambicioso: sintetizar todo el conocimiento disponible sobre la disciplina que mantiene a los agentes IA bajo control sin matar su creatividad.

---

## 1. Definición Core

**Harness Engineering** es la disciplina de diseñar el andamiaje — contexto, herramientas, planning artifacts, loops de verificación, memoria, y sandboxing — que rodea a un agente IA y determina si succeeds o fail en tareas reales.

La metáfora del usuario: IA = pura sangre, arneses = control para que no salga desbocado.

> Insight clave de OpenAI: "Every component here exists because the model can't do it alone — and the best harnesses are designed knowing those components will become unnecessary as models improve."

La implicación directa: **el harness es un documento de deuda técnica** — cada componente que añades hoy es una muleta que debería poder retirarse mañana.

---

## 2. Componentes Fundamentales del Harness

### 2.1 Agent Loop (El Ciclo Fundamental)

Todo agente funciona en un ciclo observe → plan → act → verify. El harness controla:

- **Termination conditions**: cuándo parar
- **Branch on tool results**: qué hacer si una herramienta falla
- **Checkpoint persistence**: cómo resumir si el loop se interrumpe

**Papers clave**:
- [ReAct: Synergizing Reasoning and Acting](https://arxiv.org/abs/2210.03629) — el paper fundacional del patrón Thought/Action/Observation
- [Unrolling the Codex Agent Loop](https://openai.com/index/unrolling-the-codex-agent-loop/) — la descomposición canónica de qué pasa en cada iteración

### 2.2 Context Delivery & Compaction

El context window es un recurso finito y caro. El harness debe decidir:

- Qué entra en el context en cada momento
- Cuándo comprimir history
- Qué información debe sobrevivir a la compresión

**Hallazgo crítico** (de Claude Code Compaction):
> Lo que sobrevive: current task, recent errors, filenames. Lo que se pierde: initial instructions, intermediate decisions, style rules.

**Regla práctica**: Nunca confíes en compaction para reglas críticas — ponlas en CLAUDE.md donde sobreviven a cualquier compresión.

**Herramientas relevantes**:
- LLMLingua (hasta 20x compresión con pérdida mínima)
- Prompt Caching (hasta 90% descuento en tokens cacheados)
- Autonomous Context Compression (el agente decide cuándo comprimir estratégicamente)

### 2.3 Tool Design

El diseño de herramientas es **UX del agente**. Las guidelines de Anthropic:

- Naming consistente y predecible
- Schemas estrictos con error surfaces claras
- Valor de retorno que no requiere parsing ad-hoc

**Descubrimiento clave**: Code Execution with MCP demuestra que hasta 98.7% de reducción de tokens es posible cuando los agentes escriben código para interactuar con MCP servers en lugar de llamar herramientas directamente.

### 2.4 Memory & State

Patrón de 3 capas (según Letta/MemGPT):
1. **Core memory**: facts activos de la sesión actual
2. **Archival memory**: hechos que pueden retrievearse
3. **Recall memory**: procedural — cómo hacer cosas

**Problema crítico documentado**: 
- 60% de destrucción de facts durante compaction
- 54% de behavioral drift por constraint erosion en summarizations encadenadas
- Knowledge Objects (hash-addressed discrete fact tuples) logran 100% accuracy a 252× menor costo que in-context storage

---

## 3. El Panorama de Herramientas

### 3.1 Frameworks de Orquestación

| Framework | Stars | Fortalezas |
|-----------|-------|-----------|
| LangGraph | ~30K | Graph-based state machine, checkpoint persistence, supervisor/subagent topologies |
| OpenAI Agents SDK | ~9K | Lightweight, handoffs y guardrails, production successor to Swarm |
| Google ADK | — | Code-first, built-in multi-agent, tool registration, eval pipeline |
| AutoGen | — | Microsoft, multi-agent conversation, complete AgentChat layer |
| CrewAI | — | Dual-layer: autonomous delegation + Flow para deterministic control |
| PydanticAI | — | Type-safe, RunContext dependency injection,tool definitions as Pydantic models |
| Mastra | 22K+ | TypeScript-native, 40+ providers, workflows, RAG pipelines |
| Vercel AI SDK | — | 20M+ monthly downloads, Agent abstraction, ToolLoopAgent |

### 3.2 Memory Systems

| Sistema | Tipo | Diferenciador |
|---------|------|---------------|
| mem0 | Universal | Drop-in, YC-backed, AWS Agent SDK exclusive provider |
| Letta | Stateful | Tres-tier memory (core/archival/recall), agent loop redesign público |
| Zep | Purpose-built | Summarization automático, entity extraction, semantic search |
| Stash | Self-hosted | 8-stage consolidation pipeline, built-in MCP server |
| OpenViking (ByteDance) | Context DB | Hierarchical context delivery, self-evolving layer |

### 3.3 Sandbox & Security

| Solución | Tipo | cold start |
|----------|------|-----------|
| E2B | Firecracker microVMs | ~150ms |
| Daytona | OCI containers | sub-90ms |
| AWS Cloudflare Dynamic Workers | V8 isolates | milliseconds (100x faster than containers) |
| Kubernetes Agent Sandbox | K8s CRD | configurable (gVisor, Kata) |
| OpenShell (NVIDIA) | Kernel-level (Landlock, seccomp) | policy-driven enforcement |

### 3.4 Observability

| Plataforma | Tipo | Diferenciador |
|-------------|------|---------------|
| OpenLLMetry | OpenTelemetry | No business logic changes needed |
| Arize Phoenix | Trace UI + eval runtime | Self-hostable, offline audit |
| Langfuse | Self-hostable | Prompts versioning + evals en una tool |
| Weights & Biases Weave | Experiment tracking | Dataset versioning, LLM-as-judge |
| Helicone | LLM proxy | 300+ models pricing DB, SOC2/GDPR compliant |
| Braintrust | Evaluation-first | Full-trace search without sampling |

---

## 4. Patrones de Diseño Emergent

### 4.1 Plan-and-Execute

Separación entre planner LLM (genera steps una vez) y executor agent (trabaja a través de ellos, replanning solo cuando necesario). El planner puede usar modelo más pequeño o diferente.

Implementaciones:
- LangChain Plan-and-Execute agents
- microsoft/TaskWeaver (code-first, plugin system para domain knowledge)
- LATS (Language Agent Tree Search) — usa Monte Carlo Tree Search sobre trayectorias

### 4.2 Meta-Harnesses

El harness que optimiza otros harnesses. Patrón:
1. Mining de failures de benchmark runs
2. Optimización through iterative edits
3. Regression guards antes de apply

**Implementaciones destacadas**:
- `harness-evolver` — multi-agent proposers en isolated git worktrees, LangSmith-backed evaluation
- `auto-harness` — trae tu propio coding agent, mining automático de failures
- `meta-agent` (canvas-org) — 67% → 87% en tau-bench con no labeled training data
- `AutoAgent` — #1 en SpreadsheetBench (96.5%) en 24h run

### 4.3 Context Engineering

La disciplina de curar qué sabe el agente vs. qué retrievea. Hallazgos clave:

- Exposing everything as files (source, runbooks, query schemas, past notes) outperforms specialized tooling
- "Intent Met" score rose from 45% to 75% on novel incidents cuando se usa filesystem-based context
- Token Savior (MCP server): 77% reduction en active tokens, 76% reduction en benchmark wall time

### 4.4 Structured Authorization

Dejar de confiar en prompts para permisos y usar sistemas estructurados:

- OWASP LLM06:2025 — Excessive Agency: define el checklist para auditing permission scope
- Claude Agent SDK: cinco-layer evaluation (hooks → deny rules → permission mode → allow rules → canUseTool)
- Authorization Fabric (Microsoft): PEP + PDP, decisiones ALLOW/DENY/REQUIRE_APPROVAL/MASK

---

## 5. Lo Que No Existe Todavía (Gaps)

1. **Estandarización de skill definitions** — aunque Microsoft Skills Framework intenta serlo, la interoperabilidad entre Claude Code, Copilot, y otros está lejos
2. **Meta-harness accesible** — las implementaciones actuales requieren infrastructure pesado; el sueño de "describe tu objetivo, el sistema optimiza el harness" no está resuelto
3. **Evaluación de memory quality** — nadie mide bien si los facts persistidos siguen siendo verdaderos después de semanas
4. **Observabilidad para decision-making** — las herramientas miden tokens y latency, no la calidad de las decisiones de planificación

---

## 6. Implicaciones para Smart Ralph

### 6.1 Relevancia Directa

El proyecto ya tiene:
- `loop-safety-infra/` — investigación sobre circuit breakers y checkpointing
- `spec-executor.md` — reglas de ejecución de tareas
- `stop-watcher.sh` — mecanismo de control (hook-based)

Esto es **harness engineering rudimentario**. La oportunidad es formalizarlo.

### 6.2 Comandos BMad Relevantes

| Comando | Qué hace | Por qué es útil aquí |
|---------|----------|---------------------|
| `bmad-technical-research` | Technical feasibility, architecture options | Para investigar qué componentes de harness son viables en el contexto del proyecto |
| `bmad-domain-research` | Industry deep dive, terminology | Ya activado — este documento es output |
| `bmad-create-story` | Story creation para implementation | Una vez que se defina el spec, implementar como story |
| `bmad-quick-dev` | Intent-in → code-out | Para prototipar componentes de harness rápidamente |

### 6.3 Siguiente Paso Sugerido

Crear un spec de "harness engineering for Smart Ralph" que mapee:

1. Qué componentes de harness existen ya (stop-watcher, spec-executor, state files)
2. Qué gaps hay (memory? verification loops? structured authorization?)
3. Qué priorizar basándose en el 20% de esfuerzo que resuelve el 80% de problemas

El spec debería cover al menos:
- Loop control (cómo el agente sabe cuándo parar o continuar)
- Context management (qué persiste entre tasks, qué se pierde)
- Verification hooks (cómo se valida que el código generado es correcto antes decommit)
- Permission model (qué puede hacer el agente sin preguntar)

---

## 7. Recursos Clave para Profundizar

### Lectura Obligatoria
1. [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/) — el documento fundacional
2. [Anthropic — Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — cuando usar workflows vs. agents
3. [Martin Fowler — Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) — tres interlocking systems
4. [LangChain — Improving Deep Agents with Harness Engineering](https://blog.langchain.com/improving-deep-agents-with-harness-engineering/) — caso de estudio: rank 30 → top 5 con solo harness changes

### Repositorios de Referencia
- `ai-boost/awesome-harness-engineering` — el recurso más completo (689 stars, actualizado hace 2 horas)
- `rasbt/mini-coding-agent` — Python-only, 6 core harness components en un file
- `smolagents` (HuggingFace) — ~1,000 líneas de core code, legible en una tarde

---

*Generado: 2026-05-01*
*Herramienta: bmad-domain-research via Playwright browsing*
*Fuente principal: [awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) (689 stars, actualizado hace 2 horas al momento de la investigación)*