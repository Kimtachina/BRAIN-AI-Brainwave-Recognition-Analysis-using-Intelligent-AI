"""Test ของ gemini_code_reviewer.py โดยจำลอง git, Gemini API และ GitHub API (ไม่มีการเรียกเน็ตจริง)"""

import io
import json
import subprocess
import urllib.error
from email.message import Message

import pytest

import gemini_code_reviewer as gcr


class FakeResponse:
    def __init__(self, body):
        self._body = body if isinstance(body, bytes) else json.dumps(body).encode("utf-8")

    def read(self):
        return self._body

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def fake_urlopen(body=None, error=None, calls=None):
    def _urlopen(req):
        if calls is not None:
            calls.append(req)
        if error is not None:
            raise error
        return FakeResponse(body)
    return _urlopen


def gemini_reply(text):
    return {"candidates": [{"content": {"parts": [{"text": text}]}}]}


# ---------- API key ----------

def test_load_api_key_from_env_file(tmp_path, monkeypatch):
    work = tmp_path / "work"
    work.mkdir()
    (work / ".env").write_text('# comment\nOTHER=1\nGEMINI_API_KEY="abc123"\n', encoding="utf-8")
    monkeypatch.chdir(work)
    assert gcr.load_api_key_from_env_file() == "abc123"


def test_load_api_key_returns_none_without_env_file(tmp_path, monkeypatch):
    work = tmp_path / "work"
    work.mkdir()
    monkeypatch.chdir(work)
    assert gcr.load_api_key_from_env_file() is None


def test_get_api_key_prefers_environment(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "from-env")
    monkeypatch.setattr(gcr, "load_api_key_from_env_file", lambda: "from-file")
    assert gcr.get_api_key() == "from-env"


def test_get_api_key_falls_back_to_file_then_prompt(monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.setattr(gcr, "load_api_key_from_env_file", lambda: None)
    monkeypatch.setattr("builtins.input", lambda _prompt: "  typed-key  ")
    assert gcr.get_api_key() == "typed-key"


def test_get_api_key_returns_none_when_prompt_is_empty(monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.setattr(gcr, "load_api_key_from_env_file", lambda: None)
    monkeypatch.setattr("builtins.input", lambda _prompt: "")
    assert gcr.get_api_key() is None


# ---------- git diff ----------

def test_get_git_diff_staged_uses_cached_flag(monkeypatch):
    commands = []

    def fake_run(cmd, **kwargs):
        commands.append(cmd)
        return subprocess.CompletedProcess(cmd, 0, stdout="diff text", stderr="")

    monkeypatch.setattr(gcr.subprocess, "run", fake_run)
    assert gcr.get_git_diff(staged=True) == "diff text"
    assert commands[-1] == ["git", "diff", "--cached"]


def test_get_git_diff_against_branch(monkeypatch):
    commands = []
    monkeypatch.setattr(gcr.subprocess, "run", lambda cmd, **kw: (
        commands.append(cmd) or subprocess.CompletedProcess(cmd, 0, stdout="x", stderr="")))
    gcr.get_git_diff(branch="main")
    assert commands[-1] == ["git", "diff", "main"]


def test_get_git_diff_outside_repo_returns_none(monkeypatch):
    def fake_run(cmd, **kwargs):
        raise subprocess.CalledProcessError(128, cmd)

    monkeypatch.setattr(gcr.subprocess, "run", fake_run)
    assert gcr.get_git_diff() is None


# ---------- Gemini ----------

def test_review_returns_text_and_sends_diff(monkeypatch):
    calls = []
    monkeypatch.setattr(gcr.urllib.request, "urlopen",
                        fake_urlopen(gemini_reply("# รีวิว"), calls=calls))

    assert gcr.review_code_with_gemini("+ new line", "KEY", model="m1") == "# รีวิว"

    req = calls[0]
    assert "models/m1:generateContent?key=KEY" in req.full_url
    prompt = json.loads(req.data)["contents"][0]["parts"][0]["text"]
    assert "+ new line" in prompt


def test_review_malformed_response_returns_none(monkeypatch):
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen({"candidates": []}))
    assert gcr.review_code_with_gemini("diff", "KEY") is None


def test_review_http_error_returns_none(monkeypatch):
    err = urllib.error.HTTPError("url", 403, "Forbidden", Message(), io.BytesIO(b'{"error": "denied"}'))
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen(error=err))
    assert gcr.review_code_with_gemini("diff", "KEY") is None


def test_review_network_error_returns_none(monkeypatch):
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen(error=OSError("offline")))
    assert gcr.review_code_with_gemini("diff", "KEY") is None


# ---------- GitHub ----------

def test_get_pr_diff(monkeypatch):
    calls = []
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen(b"pr diff", calls=calls))
    assert gcr.get_github_pr_diff("o/r", 7, "TOKEN") == "pr diff"
    assert calls[0].full_url == "https://api.github.com/repos/o/r/pulls/7"
    assert calls[0].get_header("Authorization") == "Bearer TOKEN"


def test_get_commit_diff_error_returns_none(monkeypatch):
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen(error=OSError("down")))
    assert gcr.get_github_commit_diff("o/r", "abc", "T") is None


def test_post_pr_comment(monkeypatch):
    calls = []
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen(b"{}", calls=calls))
    assert gcr.post_github_comment("o/r", 7, "hello", "T") is True
    assert calls[0].full_url.endswith("/repos/o/r/issues/7/comments")
    assert json.loads(calls[0].data) == {"body": "hello"}


def test_post_commit_comment_failure_returns_false(monkeypatch):
    monkeypatch.setattr(gcr.urllib.request, "urlopen", fake_urlopen(error=OSError("down")))
    assert gcr.post_github_commit_comment("o/r", "abc", "hi", "T") is False


# ---------- GitHub Actions flow ----------

def set_actions_env(monkeypatch, tmp_path, event_name, event):
    event_file = tmp_path / "event.json"
    event_file.write_text(json.dumps(event), encoding="utf-8")
    monkeypatch.setenv("GITHUB_EVENT_NAME", event_name)
    monkeypatch.setenv("GITHUB_EVENT_PATH", str(event_file))
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")
    monkeypatch.setenv("GITHUB_TOKEN", "T")
    monkeypatch.setenv("GEMINI_API_KEY", "K")


def test_actions_pull_request_posts_review(monkeypatch, tmp_path):
    set_actions_env(monkeypatch, tmp_path, "pull_request", {"number": 5})
    posted = []
    monkeypatch.setattr(gcr, "get_github_pr_diff", lambda repo, pr, tok: "diff\n")
    monkeypatch.setattr(gcr, "review_code_with_gemini", lambda d, k, model: "review")
    monkeypatch.setattr(gcr, "post_github_comment", lambda *a: posted.append(a))

    gcr.handle_github_actions("m")
    assert posted == [("o/r", 5, "review", "T")]


def test_actions_push_posts_commit_review(monkeypatch, tmp_path):
    set_actions_env(monkeypatch, tmp_path, "push", {})
    monkeypatch.setenv("GITHUB_SHA", "abc")
    posted = []
    monkeypatch.setattr(gcr, "get_github_commit_diff", lambda repo, sha, tok: "diff\n")
    monkeypatch.setattr(gcr, "review_code_with_gemini", lambda d, k, model: "review")
    monkeypatch.setattr(gcr, "post_github_commit_comment", lambda *a: posted.append(a))

    gcr.handle_github_actions("m")
    assert posted == [("o/r", "abc", "review", "T")]


def test_actions_empty_diff_posts_nothing(monkeypatch, tmp_path):
    set_actions_env(monkeypatch, tmp_path, "pull_request", {"number": 5})
    monkeypatch.setattr(gcr, "get_github_pr_diff", lambda *a: "   ")
    monkeypatch.setattr(gcr, "post_github_comment", lambda *a: pytest.fail("should not post"))
    gcr.handle_github_actions("m")


def test_actions_missing_token_exits(monkeypatch, tmp_path):
    set_actions_env(monkeypatch, tmp_path, "pull_request", {"number": 5})
    monkeypatch.delenv("GITHUB_TOKEN")
    with pytest.raises(SystemExit):
        gcr.handle_github_actions("m")


def test_actions_failed_review_exits(monkeypatch, tmp_path):
    set_actions_env(monkeypatch, tmp_path, "pull_request", {"number": 5})
    monkeypatch.setattr(gcr, "get_github_pr_diff", lambda *a: "diff\n")
    monkeypatch.setattr(gcr, "review_code_with_gemini", lambda d, k, model: None)
    with pytest.raises(SystemExit):
        gcr.handle_github_actions("m")


# ---------- CLI ----------

def test_main_writes_review_file(monkeypatch, tmp_path):
    out = tmp_path / "review.md"
    monkeypatch.setattr("sys.argv", ["gcr", "--staged", "--output", str(out)])
    monkeypatch.setattr(gcr, "get_git_diff", lambda staged, branch: "diff\nline\n")
    monkeypatch.setattr(gcr, "get_api_key", lambda: "K")
    monkeypatch.setattr(gcr, "review_code_with_gemini", lambda d, k, model: "# ผลรีวิว")

    gcr.main()
    assert out.read_text(encoding="utf-8") == "# ผลรีวิว"


def test_main_without_diff_skips_review(monkeypatch):
    monkeypatch.setattr("sys.argv", ["gcr"])
    monkeypatch.setattr(gcr, "get_git_diff", lambda staged, branch: "")
    monkeypatch.setattr(gcr, "review_code_with_gemini", lambda *a, **k: pytest.fail("should not call"))
    gcr.main()


def test_main_without_api_key_exits(monkeypatch):
    monkeypatch.setattr("sys.argv", ["gcr"])
    monkeypatch.setattr(gcr, "get_git_diff", lambda staged, branch: "diff\n")
    monkeypatch.setattr(gcr, "get_api_key", lambda: None)
    with pytest.raises(SystemExit):
        gcr.main()


# ---------- open_api_request ----------

@pytest.mark.parametrize("url", [
    "file:///etc/passwd",
    "http://api.github.com/repos/o/r",
    "https://evil.example.com/x",
    "ftp://api.github.com/x",
])
def test_open_api_request_blocks_other_schemes_and_hosts(url, monkeypatch):
    monkeypatch.setattr(gcr.urllib.request, "urlopen", lambda req: pytest.fail("should not open"))
    with pytest.raises(ValueError):
        gcr.open_api_request(gcr.urllib.request.Request(url))


def test_blocked_url_is_reported_as_failure(monkeypatch):
    monkeypatch.setattr(gcr, "ALLOWED_API_HOSTS", set())
    monkeypatch.setattr(gcr.urllib.request, "urlopen", lambda req: pytest.fail("should not open"))
    assert gcr.get_github_pr_diff("o/r", 7, "T") is None
