#!/usr/bin/env python3
"""langfuse_tracer.py — Langfuse tracing for prompt-graph skill runs.

Subcommands (all exit 0 on soft failure so they never block the pipeline):

  init           --mode <mode> --flags <flags> --input-title <text>
                 [--input-type A|B|C|D]
  input-analysis --inventory-size N --constraint-count N --type-d-frozen 0|1
                 [--complexity-tier simple|moderate|complex]
  verification   --preservation <PASS|FAIL> --fidelity <PASS|FAIL> --quality <PASS|FAIL>
                 [--pass-number <1|2>]
  anti-fragility --hard-breaks N --soft-breaks N --exposures N
                 [--vectors-triggered N] [--hg2-blocked N]
  aggregation    --branch-width N --strategies "s1,s2,s3"
                 [--reverted-to-baseline 0|1]
  repair-triggered --repair-family A|B|C|Mixed --repair-path sendmessage|respawn
                   --failing-checks "6a,6h,..."
  finalize       --output-path <path> --final-result <PASS|FAIL|FAIL_CAPPED>
                 --repair-count <0|1> --mode <mode>

Config: ~/.claude/skills/prompt-graph/langfuse.env
  PROMPT_GRAPH_LANGFUSE_PUBLIC_KEY=pk-lf-...
  PROMPT_GRAPH_LANGFUSE_SECRET_KEY=sk-lf-...
  PROMPT_GRAPH_LANGFUSE_HOST=http://localhost:3000
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import uuid
from pathlib import Path
from datetime import datetime, timezone

sys.path.insert(0, "/home/myuser/miniconda3/lib/python3.13/site-packages")

import warnings
warnings.filterwarnings("ignore")

# ── Config ────────────────────────────────────────────────────────────────────

_SKILL_DIR = Path(__file__).resolve().parents[1]
_CONFIG_FILE = _SKILL_DIR / "langfuse.env"
_STATE_FILE = _SKILL_DIR / ".last_run.json"


def _load_config() -> dict[str, str]:
    cfg: dict[str, str] = {}
    if _CONFIG_FILE.exists():
        for line in _CONFIG_FILE.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            cfg[k.strip()] = v.strip()
    for key in ("PROMPT_GRAPH_LANGFUSE_PUBLIC_KEY", "PROMPT_GRAPH_LANGFUSE_SECRET_KEY",
                "PROMPT_GRAPH_LANGFUSE_HOST"):
        if key in os.environ:
            cfg[key] = os.environ[key]
    return cfg


def _get_langfuse(cfg: dict[str, str]):
    from langfuse import Langfuse  # type: ignore
    pk = cfg.get("PROMPT_GRAPH_LANGFUSE_PUBLIC_KEY", "")
    sk = cfg.get("PROMPT_GRAPH_LANGFUSE_SECRET_KEY", "")
    host = cfg.get("PROMPT_GRAPH_LANGFUSE_HOST", "http://localhost:3000")
    if not pk or not sk:
        return None
    return Langfuse(public_key=pk, secret_key=sk, host=host)


def _ingest(cfg: dict[str, str], batch: list) -> None:
    """Send events directly to Langfuse ingestion API (for name and tags the SDK doesn't expose)."""
    import requests  # type: ignore
    pk = cfg.get("PROMPT_GRAPH_LANGFUSE_PUBLIC_KEY", "")
    sk = cfg.get("PROMPT_GRAPH_LANGFUSE_SECRET_KEY", "")
    host = cfg.get("PROMPT_GRAPH_LANGFUSE_HOST", "http://localhost:3000")
    auth = base64.b64encode(f"{pk}:{sk}".encode()).decode()
    requests.post(
        f"{host}/api/public/ingestion",
        headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"},
        json={"batch": batch},
        timeout=10,
    )


# ── Helpers ───────────────────────────────────────────────────────────────────

def _slugify(text: str) -> str:
    text = re.sub(r'\s+', ' ', text.strip())
    if len(text) > 50:
        truncated = text[:50].rsplit(' ', 1)[0]
        text = truncated if len(truncated) > 10 else text[:50]
    return text


def _read_file_truncated(path: Path, max_chars: int = 8000) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
        if len(text) > max_chars:
            return text[:max_chars] + f"\n… [truncated at {max_chars} chars]"
        return text
    except Exception:
        return ""


def _read_state() -> dict:
    if not _STATE_FILE.exists():
        return {}
    try:
        return json.loads(_STATE_FILE.read_text())
    except Exception:
        return {}


def _write_state(state: dict) -> None:
    tmp = _STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2))
    tmp.replace(_STATE_FILE)


def _now_iso() -> str:
    return datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ── Subcommands ───────────────────────────────────────────────────────────────

def cmd_init(args: argparse.Namespace) -> None:
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        print("[langfuse_tracer] no credentials — tracing disabled", file=sys.stderr)
        return

    from langfuse import Langfuse  # type: ignore
    from langfuse.types import TraceContext  # type: ignore

    input_title = (args.input_title or "").strip()
    slug = _slugify(input_title) if input_title else "unknown"
    mode = args.mode or "normal"
    flags = (args.flags or "").strip()

    session_id = str(uuid.uuid4())
    trace_id = Langfuse.create_trace_id(seed=f"prompt-graph-{session_id}")

    tags = ["skill:prompt-graph", f"mode:{mode}"]
    for flag_token in flags.split():
        tags.append(f"flag:{flag_token.lstrip('-')}")

    _ingest(cfg, [{
        "id": str(uuid.uuid4()),
        "type": "trace-create",
        "timestamp": _now_iso(),
        "body": {
            "id": trace_id,
            "name": f"prompt-graph: {slug[:60]}",
            "tags": tags,
            "metadata": {
                "session_id": session_id,
                "mode": mode,
                "flags": flags,
                "slug": slug,
            },
        },
    }])

    input_type = (args.input_type or "").upper()

    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name="session-start",
        as_type="span",
        input={"mode": mode, "flags": flags, "input_title": input_title, "input_type": input_type},
        metadata={"mode": mode, "flags": flags, "session_id": session_id, "slug": slug,
                  "input_type": input_type},
    )
    span.set_trace_io(input={"topic": slug, "mode": mode, "flags": flags,
                             "input_title": input_title, "input_type": input_type})
    if input_type:
        type_d = 1.0 if input_type == "D" else 0.0
        span.score_trace(name="input_type_d", value=type_d,
                         comment=f"input classified as type {input_type}")
    span.end()
    lf.flush()

    state = {
        "trace_id": trace_id,
        "session_id": session_id,
        "slug": slug,
        "mode": mode,
        "flags": flags,
        "input_type": input_type,
        "init_ts": _now_iso(),
        "trace_url": lf.get_trace_url(trace_id=trace_id),
        "verification_count": 0,
    }
    _write_state(state)
    print(f"[langfuse_tracer] trace created: {lf.get_trace_url(trace_id=trace_id)}")


def cmd_verification(args: argparse.Namespace) -> None:
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        return

    from langfuse.types import TraceContext  # type: ignore

    state = _read_state()
    trace_id = state.get("trace_id")
    if not trace_id:
        print("[langfuse_tracer] no trace_id — skipping verification", file=sys.stderr)
        return

    p_raw = (args.preservation or "").upper()
    f_raw = (args.fidelity or "").upper()
    q_raw = (args.quality or "").upper()
    pass_num = int(args.pass_number or 1)

    p_score = 1.0 if p_raw == "PASS" else 0.0
    f_score = 1.0 if f_raw == "PASS" else 0.0
    q_score = 1.0 if q_raw == "PASS" else 0.0
    overall = (p_score + f_score + q_score) / 3.0

    span_name = f"verification-pass-{pass_num}"
    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name=span_name,
        as_type="span",
        input={"pass_number": pass_num},
        output={
            "preservation_6ab": p_raw,
            "fidelity_6f": f_raw,
            "quality_6hl": q_raw,
            "overall": "PASS" if overall == 1.0 else ("PARTIAL" if overall > 0 else "FAIL"),
        },
        metadata={
            "preservation": p_raw,
            "fidelity": f_raw,
            "quality": q_raw,
            "pass_number": pass_num,
        },
    )
    span.end()

    span.score_trace(name=f"verification_preservation_p{pass_num}", value=p_score,
                     comment=f"pass {pass_num} — checks 6a-6b: {p_raw}")
    span.score_trace(name=f"verification_fidelity_p{pass_num}", value=f_score,
                     comment=f"pass {pass_num} — check 6f: {f_raw}")
    span.score_trace(name=f"verification_quality_p{pass_num}", value=q_score,
                     comment=f"pass {pass_num} — checks 6h-6l: {q_raw}")
    span.score_trace(name=f"verification_overall_p{pass_num}", value=round(overall, 3),
                     comment=f"pass {pass_num} — {p_raw}/{f_raw}/{q_raw}")

    lf.flush()

    state["verification_count"] = state.get("verification_count", 0) + 1
    _write_state(state)


def cmd_input_analysis(args: argparse.Namespace) -> None:
    """Post-Wave-2 input complexity signals — inventory size, constraint density, type-D freeze."""
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        return
    from langfuse.types import TraceContext  # type: ignore
    state = _read_state()
    trace_id = state.get("trace_id")
    if not trace_id:
        return

    inventory_size = int(args.inventory_size or 0)
    constraint_count = int(args.constraint_count or 0)
    type_d_frozen = int(args.type_d_frozen or 0)
    tier = (args.complexity_tier or "").lower() or (
        "complex" if inventory_size > 12 or constraint_count > 5 else
        "moderate" if inventory_size > 6 or constraint_count > 2 else "simple"
    )
    tier_numeric = {"simple": 1, "moderate": 2, "complex": 3}.get(tier, 0)

    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name="input-analysis",
        as_type="span",
        output={
            "inventory_size": inventory_size,
            "constraint_count": constraint_count,
            "type_d_frozen": type_d_frozen,
            "complexity_tier": tier,
        },
        metadata={"complexity_tier": tier},
    )
    span.score_trace(name="inventory_size", value=float(inventory_size),
                     comment="total INVENTORY items collected by N04")
    span.score_trace(name="constraint_count", value=float(constraint_count),
                     comment="explicit constraint statements in input")
    span.score_trace(name="complexity_tier", value=float(tier_numeric),
                     comment=f"1=simple 2=moderate 3=complex → {tier}")
    span.score_trace(name="type_d_frozen", value=float(type_d_frozen),
                     comment="1 if HG3 freeze signal emitted for executable input patterns")
    span.end()
    lf.flush()


def cmd_anti_fragility(args: argparse.Namespace) -> None:
    """N34 anti-fragility attack results — hard/soft/exposure counts and robustness score.

    Key quality signal: hard_breaks > 0 means the synthesis produced a prompt that breaks under
    adversarial reading. If this persists across runs, investigate N13 synthesis or N09 contracts.
    """
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        return
    from langfuse.types import TraceContext  # type: ignore
    state = _read_state()
    trace_id = state.get("trace_id")
    if not trace_id:
        return

    hard_breaks = int(args.hard_breaks or 0)
    soft_breaks = int(args.soft_breaks or 0)
    exposures = int(args.exposures or 0)
    vectors_triggered = int(args.vectors_triggered or 0)
    hg2_blocked = int(args.hg2_blocked or 0)
    total = hard_breaks + soft_breaks + exposures

    # Robustness: 1.0 = no hard breaks, 0.5 = soft/exposure only, 0.0 = hard breaks present
    if hard_breaks > 0:
        robustness = 0.0
    elif soft_breaks > 0 or exposures > 0:
        robustness = 0.5
    else:
        robustness = 1.0

    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name="anti-fragility",
        as_type="span",
        output={
            "hard_breaks": hard_breaks,
            "soft_breaks": soft_breaks,
            "exposures": exposures,
            "vectors_triggered": vectors_triggered,
            "hg2_blocked": hg2_blocked,
            "total_findings": total,
        },
        level="WARNING" if hard_breaks > 0 else "DEFAULT",
    )
    span.score_trace(name="af_hard_breaks", value=float(hard_breaks),
                     comment="N34 hard breaks — synthesis failures that needed auto-repair")
    span.score_trace(name="af_soft_breaks", value=float(soft_breaks),
                     comment="N34 soft breaks — edge-case gaps surfaced")
    span.score_trace(name="af_exposures", value=float(exposures),
                     comment="N34 exposures — annotation-only findings")
    span.score_trace(name="af_vectors_triggered", value=float(vectors_triggered),
                     comment="attack vectors (of 5) that found at least one issue")
    span.score_trace(name="af_hg2_blocked", value=float(hg2_blocked),
                     comment="hard breaks downgraded to soft due to zero-information-loss constraint")
    span.score_trace(name="af_robustness", value=robustness,
                     comment="1.0=clean 0.5=soft-only 0.0=hard-breaks-present")
    span.end()
    lf.flush()

    state["af_hard_breaks"] = hard_breaks
    state["af_soft_breaks"] = soft_breaks
    _write_state(state)


def cmd_aggregation(args: argparse.Namespace) -> None:
    """N33 MetaAggregator results — branch width, strategies, revert-to-baseline.

    Key quality signal: reverted_to_baseline=1 means multi-path synthesis failed to improve
    over the N13 first-pass baseline. If this recurs, the branch strategy selection or agent
    diversity in N27/N28-N32 needs tuning.
    """
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        return
    from langfuse.types import TraceContext  # type: ignore
    state = _read_state()
    trace_id = state.get("trace_id")
    if not trace_id:
        return

    branch_width = int(args.branch_width or 0)
    strategies = (args.strategies or "").strip()
    reverted = int(args.reverted_to_baseline or 0)
    strategy_list = [s.strip() for s in strategies.split(",") if s.strip()]
    strategy_count = len(strategy_list)

    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name="aggregation",
        as_type="span",
        output={
            "branch_width": branch_width,
            "strategies": strategy_list,
            "strategy_count": strategy_count,
            "reverted_to_baseline": bool(reverted),
        },
        level="WARNING" if reverted else "DEFAULT",
    )
    span.score_trace(name="agg_branch_width", value=float(branch_width),
                     comment="N27 branch width — number of parallel synthesis agents")
    span.score_trace(name="agg_strategy_count", value=float(strategy_count),
                     comment="distinct synthesis strategies used in PG5")
    span.score_trace(name="agg_reverted_to_baseline", value=float(reverted),
                     comment="1 = N33 aggregation failed to improve over N13 first-pass; reverted")
    span.score_trace(name="agg_improvement", value=float(1 - reverted),
                     comment="1 = aggregated XML was a strict improvement over first-pass baseline")
    span.end()
    lf.flush()


def cmd_repair_triggered(args: argparse.Namespace) -> None:
    """N17 back-edge repair — failure family, path, and which checks triggered it.

    Key quality signal: recurring Family-C (quality) repairs point to synthesis weakness;
    Family-A (preservation) suggests the INVENTORY is being dropped during synthesis;
    sendmessage path is cheaper than respawn.
    """
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        return
    from langfuse.types import TraceContext  # type: ignore
    state = _read_state()
    trace_id = state.get("trace_id")
    if not trace_id:
        return

    family = (args.repair_family or "Unknown").strip()
    path = (args.repair_path or "unknown").lower()
    failing_checks = (args.failing_checks or "").strip()
    family_numeric = {"A": 1, "B": 2, "C": 3, "Mixed": 4}.get(family, 0)

    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name="repair-triggered",
        as_type="span",
        input={"failing_checks": failing_checks},
        output={
            "repair_family": family,
            "repair_path": path,
            "failing_checks": failing_checks,
        },
        level="WARNING",
        metadata={"repair_family": family, "repair_path": path},
    )
    span.score_trace(name="repair_triggered", value=1.0,
                     comment=f"N17 back-edge fired — family={family} path={path}")
    span.score_trace(name="repair_family_numeric", value=float(family_numeric),
                     comment="1=A(preservation) 2=B(fidelity) 3=C(quality) 4=Mixed")
    span.score_trace(name="repair_via_sendmessage", value=1.0 if path == "sendmessage" else 0.0,
                     comment="1=cheaper SendMessage resume; 0=fresh agent respawn")
    span.end()
    lf.flush()

    state["repair_family"] = family
    state["repair_path"] = path
    _write_state(state)


def cmd_advisory(args: argparse.Namespace) -> None:
    """Emit a one-line advisory string when 3+ prior runs show persistent
    repair_triggered or af_hard_breaks > 0. Inputs are pre-aggregated counts
    passed by the orchestrator from Langfuse trace queries; this subcommand
    does NOT itself query Langfuse — that's the orchestrator's job (and may
    silently fail without affecting the pipeline).

    Per AP-V6: this subcommand never raises and never blocks. Called via the
    main() try/except — any exception is swallowed to stderr.
    """
    threshold = 3
    if args.repair_runs >= threshold:
        print(
            f"[prompt-graph-v2 advisory] repair has triggered in {args.repair_runs} "
            f"recent runs — consider running with --strict-verify=full"
        )
        return
    if args.af_runs >= threshold:
        print(
            f"[prompt-graph-v2 advisory] anti-fragility hard-breaks observed in "
            f"{args.af_runs} recent runs — consider running with --deep"
        )
        return
    # Below threshold: silent.


def cmd_finalize(args: argparse.Namespace) -> None:
    cfg = _load_config()
    lf = _get_langfuse(cfg)
    if lf is None:
        return

    from langfuse.types import TraceContext  # type: ignore

    state = _read_state()
    trace_id = state.get("trace_id")
    if not trace_id:
        print("[langfuse_tracer] no trace_id — skipping finalize", file=sys.stderr)
        return

    output_content = ""
    output_path = (args.output_path or "").strip()
    if output_path:
        output_content = _read_file_truncated(Path(output_path).expanduser(), max_chars=8000)

    final_result = (args.final_result or "UNKNOWN").upper()
    repair_count = int(args.repair_count or 0)
    mode = args.mode or state.get("mode", "normal")
    slug = state.get("slug", "")
    flags = state.get("flags", "")
    verification_count = state.get("verification_count", 0)

    is_pass = final_result == "PASS"
    final_score = 1.0 if is_pass else 0.0

    span_name = "session-finalized" if is_pass else "session-completed"
    span = lf.start_observation(
        trace_context=TraceContext(trace_id=trace_id),
        name=span_name,
        as_type="span",
        input={"mode": mode, "flags": flags, "repair_count": repair_count},
        output={
            "final_result": final_result,
            "output_path": output_path,
            "repair_count": repair_count,
            "verification_passes": verification_count,
            "output_content": output_content,
        },
        metadata={
            "final_result": final_result,
            "output_path": output_path,
            "repair_count": repair_count,
            "mode": mode,
            "slug": slug,
            "flags": flags,
            "verification_passes": verification_count,
        },
        level="DEFAULT" if is_pass else "WARNING",
    )
    span.set_trace_io(output={
        "result": final_result,
        "output_path": output_path,
        "enhanced_content": output_content,
        "repair_count": repair_count,
    })
    span.end()

    span.score_trace(name="verified", value=final_score, comment=f"final_result={final_result}")
    span.score_trace(name="repair_needed", value=float(repair_count > 0),
                     comment=f"repair_count={repair_count}")
    if is_pass:
        span.score_trace(name="finalized", value=1.0, comment="output saved")

    lf.flush()
    print(f"[langfuse_tracer] trace finalized: {state.get('trace_url', trace_id)}")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    p = argparse.ArgumentParser(description="Langfuse tracer for prompt-graph")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init")
    p_init.add_argument("--mode",        default="normal")
    p_init.add_argument("--flags",       default="")
    p_init.add_argument("--input-title", default="")
    p_init.add_argument("--input-type",  dest="input_type", default="")

    p_ia = sub.add_parser("input-analysis")
    p_ia.add_argument("--inventory-size",   dest="inventory_size",   type=int, default=0)
    p_ia.add_argument("--constraint-count", dest="constraint_count", type=int, default=0)
    p_ia.add_argument("--type-d-frozen",    dest="type_d_frozen",    type=int, default=0)
    p_ia.add_argument("--complexity-tier",  dest="complexity_tier",  default="")

    p_ver = sub.add_parser("verification")
    p_ver.add_argument("--preservation", required=True)
    p_ver.add_argument("--fidelity",     required=True)
    p_ver.add_argument("--quality",      required=True)
    p_ver.add_argument("--pass-number",  default=1, type=int)

    p_af = sub.add_parser("anti-fragility")
    p_af.add_argument("--hard-breaks",       dest="hard_breaks",       type=int, default=0)
    p_af.add_argument("--soft-breaks",       dest="soft_breaks",       type=int, default=0)
    p_af.add_argument("--exposures",         type=int, default=0)
    p_af.add_argument("--vectors-triggered", dest="vectors_triggered", type=int, default=0)
    p_af.add_argument("--hg2-blocked",       dest="hg2_blocked",       type=int, default=0)

    p_agg = sub.add_parser("aggregation")
    p_agg.add_argument("--branch-width",        dest="branch_width",        type=int, default=0)
    p_agg.add_argument("--strategies",          default="")
    p_agg.add_argument("--reverted-to-baseline",dest="reverted_to_baseline",type=int, default=0)

    p_rt = sub.add_parser("repair-triggered")
    p_rt.add_argument("--repair-family",  dest="repair_family",  default="Unknown")
    p_rt.add_argument("--repair-path",    dest="repair_path",    default="unknown")
    p_rt.add_argument("--failing-checks", dest="failing_checks", default="")

    p_fin = sub.add_parser("finalize")
    p_fin.add_argument("--output-path",   default="")
    p_fin.add_argument("--final-result",  default="UNKNOWN")
    p_fin.add_argument("--repair-count",  default=0, type=int)
    p_fin.add_argument("--mode",          default="normal")

    p_adv = sub.add_parser("advisory")
    p_adv.add_argument("--repair-runs", dest="repair_runs", type=int, default=0)
    p_adv.add_argument("--af-runs",     dest="af_runs",     type=int, default=0)

    args = p.parse_args()

    dispatch = {
        "init":             cmd_init,
        "input-analysis":   cmd_input_analysis,
        "verification":     cmd_verification,
        "anti-fragility":   cmd_anti_fragility,
        "aggregation":      cmd_aggregation,
        "repair-triggered": cmd_repair_triggered,
        "finalize":         cmd_finalize,
        "advisory":         cmd_advisory,
    }
    try:
        dispatch[args.cmd](args)
    except Exception as exc:
        print(f"[langfuse_tracer] error (non-fatal): {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
