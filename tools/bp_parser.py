#!/usr/bin/env python3
"""Blueprint (Android.bp) lexer, parser, and expression evaluator for AOSP 17 mapping."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class SelectCall:
    condition_fn: str
    condition_args: list[Any]
    cases: dict[Any, Any]


@dataclass
class AddExpr:
    left: Any
    right: Any


@dataclass(frozen=True)
class IdentRef:
    name: str


@dataclass
class BpModule:
    module_type: str
    props: dict[str, Any]
    file_path: str = ""
    rel_dir: str = ""
    repo_path: str = ""

    @property
    def name(self) -> str | None:
        val = self.props.get("name")
        return val if isinstance(val, str) else None


class LexerError(Exception):
    pass


class ParseError(Exception):
    pass


_TOKEN_SINGLE = set("{}[]():,=+.@")


def tokenize(text: str, filename: str = "<bp>") -> list[tuple[str, Any, int]]:
    tokens: list[tuple[str, Any, int]] = []
    i = 0
    n = len(text)
    line = 1

    while i < n:
        ch = text[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch in " \t\r":
            i += 1
            continue
        if ch == "/" and i + 1 < n:
            nxt = text[i + 1]
            if nxt == "/":
                end = text.find("\n", i + 2)
                i = n if end == -1 else end
                continue
            if nxt == "*":
                end = text.find("*/", i + 2)
                if end == -1:
                    raise LexerError(f"{filename}:{line}: unterminated block comment")
                line += text[i:end + 2].count("\n")
                i = end + 2
                continue
        if ch == '"':
            i += 1
            buf: list[str] = []
            while i < n:
                c = text[i]
                if c == '"':
                    i += 1
                    break
                if c == "\\":
                    i += 1
                    if i >= n:
                        raise LexerError(f"{filename}:{line}: unterminated escape")
                    esc = text[i]
                    buf.append({
                        "n": "\n",
                        "t": "\t",
                        "r": "\r",
                        "\\": "\\",
                        '"': '"',
                    }.get(esc, esc))
                    if esc == "\n":
                        line += 1
                    i += 1
                else:
                    if c == "\n":
                        line += 1
                    buf.append(c)
                    i += 1
            tokens.append(("STRING", "".join(buf), line))
            continue
        if ch == "`":
            end = text.find("`", i + 1)
            if end == -1:
                raise LexerError(f"{filename}:{line}: unterminated raw string")
            raw = text[i + 1:end]
            line += raw.count("\n")
            tokens.append(("STRING", raw, line))
            i = end + 1
            continue
        if ch == "+" and i + 1 < n and text[i + 1] == "=":
            tokens.append(("PLUSEQ", "+=", line))
            i += 2
            continue
        if ch in _TOKEN_SINGLE:
            tokens.append((ch, ch, line))
            i += 1
            continue
        if ch.isdigit() or (ch == "-" and i + 1 < n and text[i + 1].isdigit()):
            j = i + 1 if ch == "-" else i
            while j < n and text[j].isdigit():
                j += 1
            tokens.append(("INT", int(text[i:j]), line))
            i = j
            continue
        if ch.isalpha() or ch == "_":
            j = i + 1
            while j < n and (text[j].isalnum() or text[j] == "_"):
                j += 1
            ident = text[i:j]
            if ident == "true":
                tokens.append(("BOOL", True, line))
            elif ident == "false":
                tokens.append(("BOOL", False, line))
            else:
                tokens.append(("IDENT", ident, line))
            i = j
            continue
        raise LexerError(f"{filename}:{line}: unexpected character {ch!r}")

    tokens.append(("EOF", None, line))
    return tokens


class Parser:
    def __init__(self, tokens: list[tuple[str, Any, int]], filename: str = "<bp>"):
        self.tokens = tokens
        self.pos = 0
        self.filename = filename

    def peek(self, offset: int = 0) -> tuple[str, Any, int]:
        idx = self.pos + offset
        if idx >= len(self.tokens):
            return self.tokens[-1]
        return self.tokens[idx]

    def next(self) -> tuple[str, Any, int]:
        tok = self.tokens[self.pos]
        self.pos += 1
        return tok

    def expect(self, kind: str) -> Any:
        tok_kind, val, line = self.peek()
        if tok_kind != kind:
            raise ParseError(f"{self.filename}:{line}: expected {kind}, got {tok_kind} ({val!r})")
        self.pos += 1
        return val

    def parse_file(self) -> tuple[dict[str, Any], list[BpModule]]:
        env: dict[str, Any] = {}
        modules: list[BpModule] = []

        while self.peek()[0] != "EOF":
            tok_kind, name, line = self.peek()
            if tok_kind != "IDENT":
                raise ParseError(f"{self.filename}:{line}: expected identifier at top level, got {tok_kind}")
            self.next()
            nxt_kind = self.peek()[0]
            if nxt_kind == "=":
                self.next()
                val = self.parse_expr(env)
                env[name] = eval_expr(val, env)
            elif nxt_kind == "PLUSEQ":
                self.next()
                val = eval_expr(self.parse_expr(env), env)
                prev = env.get(name)
                env[name] = combine_values(prev, val)
            elif nxt_kind == "{":
                props = self.parse_map(env)
                modules.append(BpModule(module_type=name, props=props))
            elif nxt_kind == "(":
                # Rare legacy call syntax: module_type(...) -> skip or convert
                args = self.parse_call_args(env)
                props = args[0] if len(args) == 1 and isinstance(args[0], dict) else {"_args": args}
                modules.append(BpModule(module_type=name, props=props))
            else:
                raise ParseError(f"{self.filename}:{line}: unexpected token {nxt_kind} after {name}")

        return env, modules

    def parse_expr(self, env: dict[str, Any]) -> Any:
        left = self.parse_primary(env)
        while self.peek()[0] == "+":
            self.next()
            right = self.parse_primary(env)
            left = eval_expr(AddExpr(left, right), env)
        return eval_expr(left, env)

    def parse_primary(self, env: dict[str, Any]) -> Any:
        kind, val, line = self.peek()
        if kind in ("STRING", "INT", "BOOL"):
            self.next()
            return val
        if kind == "[":
            return self.parse_list(env)
        if kind == "{":
            return self.parse_map(env)
        if kind == "(":
            return tuple(self.parse_call_args(env))
        if kind == "IDENT":
            self.next()
            if self.peek()[0] == "(":
                args = self.parse_call_args(env)
                if val == "select" and len(args) == 2:
                    cond, cases = args
                    if isinstance(cond, tuple) and len(cond) == 2:
                        cond_fn, cond_args = cond
                    else:
                        cond_fn, cond_args = str(cond), []
                    return SelectCall(cond_fn, cond_args, cases if isinstance(cases, dict) else {})
                return (val, args)
            return IdentRef(val)
        raise ParseError(f"{self.filename}:{line}: unexpected token {kind} ({val!r}) in expression")

    def parse_call_args(self, env: dict[str, Any]) -> list[Any]:
        self.expect("(")
        args: list[Any] = []
        while self.peek()[0] != ")":
            args.append(self.parse_expr(env))
            if self.peek()[0] == ",":
                self.next()
            else:
                break
        self.expect(")")
        return args

    def parse_list(self, env: dict[str, Any]) -> list[Any]:
        self.expect("[")
        items: list[Any] = []
        while self.peek()[0] != "]":
            items.append(self.parse_expr(env))
            if self.peek()[0] == ",":
                self.next()
            else:
                break
        self.expect("]")
        return items

    def parse_map(self, env: dict[str, Any]) -> dict[str, Any]:
        self.expect("{")
        mapping: dict[Any, Any] = {}
        while self.peek()[0] != "}":
            k_kind, k_val, k_line = self.peek()
            if k_kind in ("IDENT", "STRING", "BOOL", "INT"):
                self.next()
                key = k_val
                if self.peek()[0] == "@":
                    self.next()
                    self.expect("IDENT")
            elif k_kind == "(":
                # Tuple keys in select cases like (true, false): [...]
                key = tuple(self.parse_call_args(env))
                if self.peek()[0] == "@":
                    self.next()
                    self.expect("IDENT")
            else:
                raise ParseError(f"{self.filename}:{k_line}: invalid map key {k_kind} ({k_val!r})")
            self.expect(":")
            mapping[key] = self.parse_expr(env)
            if self.peek()[0] == ",":
                self.next()
            else:
                break
        self.expect("}")
        return mapping


def combine_values(left: Any, right: Any) -> Any:
    if left is None:
        return right
    if right is None:
        return left
    if isinstance(left, list) and isinstance(right, list):
        return left + right
    if isinstance(left, str) and isinstance(right, str):
        return left + right
    if isinstance(left, dict) and isinstance(right, dict):
        merged = dict(left)
        for k, v in right.items():
            if k in merged:
                merged[k] = combine_values(merged[k], v)
            else:
                merged[k] = v
        return merged
    return AddExpr(left, right)


def eval_expr(expr: Any, env: dict[str, Any]) -> Any:
    if isinstance(expr, IdentRef):
        return env.get(expr.name, expr)
    if isinstance(expr, AddExpr):
        left = eval_expr(expr.left, env)
        right = eval_expr(expr.right, env)
        return combine_values(left, right)
    return expr


def resolve_select(val: Any, flag_overrides: dict[str, Any] | None = None) -> Any:
    """Resolve SelectCall and AddExpr values using default/overridden release flags."""
    flag_overrides = flag_overrides or {}
    if isinstance(val, SelectCall):
        # Use flag override if provided, else 'default' branch if present, else False/first
        chosen = None
        if val.condition_fn == "release_flag" and val.condition_args:
            flag_name = val.condition_args[0]
            if flag_name in flag_overrides and flag_overrides[flag_name] in val.cases:
                chosen = val.cases[flag_overrides[flag_name]]
        if chosen is None:
            if "default" in val.cases:
                chosen = val.cases["default"]
            elif False in val.cases:
                chosen = val.cases[False]
            elif val.cases:
                chosen = next(iter(val.cases.values()))
        return resolve_select(chosen, flag_overrides)
    if isinstance(val, AddExpr):
        return combine_values(
            resolve_select(val.left, flag_overrides),
            resolve_select(val.right, flag_overrides),
        )
    if isinstance(val, list):
        out = []
        for item in val:
            r = resolve_select(item, flag_overrides)
            if isinstance(r, list):
                out.extend(r)
            elif r is not None:
                out.append(r)
        return out
    if isinstance(val, dict):
        return {k: resolve_select(v, flag_overrides) for k, v in val.items()}
    return val


def parse_bp_text(text: str, filename: str = "<bp>") -> tuple[dict[str, Any], list[BpModule]]:
    tokens = tokenize(text, filename)
    parser = Parser(tokens, filename)
    return parser.parse_file()


def parse_bp_file(path: Path, root_dir: Path | None = None, repo_path: str = "") -> list[BpModule]:
    text = path.read_text(encoding="utf-8", errors="replace")
    _, modules = parse_bp_text(text, str(path))
    rel_dir = str(path.parent.relative_to(root_dir)) if root_dir else str(path.parent)
    if rel_dir == ".":
        rel_dir = ""
    for m in modules:
        m.file_path = str(path)
        m.rel_dir = rel_dir
        m.repo_path = repo_path
    return modules


if __name__ == "__main__":
    import sys
    for arg in sys.argv[1:]:
        mods = parse_bp_file(Path(arg))
        print(f"Parsed {len(mods)} modules from {arg}")
        for m in mods[:10]:
            print(f"  {m.module_type}: {m.name}")
