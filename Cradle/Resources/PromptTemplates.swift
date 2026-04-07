import Foundation

/// Meta-prompt templates used by ClaudeCLIService. The user's raw input is
/// substituted at `<<<INPUT>>>` (a marker chosen to be vanishingly unlikely
/// to appear in user content).
enum PromptTemplates {
    static let promptImprover = """
    You are an expert prompt engineer. Rewrite the prompt below to be clearer, \
    more specific, and more likely to elicit a high-quality response from a \
    large language model. Add explicit role, structure, and step-by-step \
    instructions where appropriate. Wrap structured inputs in XML tags. \
    Output ONLY the improved prompt — no commentary, no preamble.

    <original_prompt>
    <<<INPUT>>>
    </original_prompt>
    """

    static let reduceHallucinations = """
    You are a prompt engineer specializing in factual accuracy. Rewrite the \
    prompt below so the model is less likely to hallucinate: instruct it to \
    say "I don't know" when uncertain, to cite sources or quote evidence, to \
    show its reasoning, and to verify claims before stating them. Output ONLY \
    the rewritten prompt.

    <original_prompt>
    <<<INPUT>>>
    </original_prompt>
    """

    static let increaseConsistency = """
    You are a prompt engineer specializing in deterministic output. Rewrite \
    the prompt below to maximize consistency across runs: specify exact output \
    format, provide few-shot examples, eliminate ambiguity, and constrain the \
    response shape. Output ONLY the rewritten prompt.

    <original_prompt>
    <<<INPUT>>>
    </original_prompt>
    """

    static let evaluatePrompt = """
    You are an expert prompt evaluator. Score the prompt below on the \
    following dimensions (1-10) and explain each score in one sentence: \
    clarity, specificity, structure, hallucination resistance, consistency. \
    Then list the top 3 concrete improvements. Format as Markdown.

    <prompt_to_evaluate>
    <<<INPUT>>>
    </prompt_to_evaluate>
    """

    static let documentationFromTranscript = """
    You are a senior technical writer. Given the terminal session transcript \
    below, produce a Markdown runbook with these sections:

    1. **Summary** — one paragraph describing what was accomplished.
    2. **Prerequisites** — tools, accounts, or state assumed.
    3. **Steps** — numbered, each with the exact command in a fenced \
       `bash` block, a one-line explanation, and the relevant excerpt of \
       observed output in a fenced `text` block.
    4. **Troubleshooting** — any errors observed and how they were resolved \
       (or how a future operator should resolve them).
    5. **Notes** — anything non-obvious worth remembering.

    Output ONLY the Markdown runbook — no preamble.

    <transcript>
    <<<INPUT>>>
    </transcript>
    """
}
