# marry-lambda 💍λ

A mission-critical, highly available marriage proposal service.

Some people propose with a ring. We're both developers, so this is an AWS
Lambda behind a public Function URL that returns an over-engineered JSON
marriage proposal. The answer is cached, the operation is idempotent, and the
SLA is forever.

```console
$ curl https://<your-function-url>.lambda-url.us-east-1.on.aws/
{
  "question": "Will you marry me?",
  "answer": "yes",
  "status": "ENGAGED",
  "confidence": 1.0,
  "consistencyModel": "immediately consistent (no eventual about it)",
  "breakingChange": true,
  "breakingChangeNotes": "single -> married requires a major version bump",
  "idempotent": true,
  "idempotencyNotes": "ask as many times as you like; the answer is cached",
  "ring": {
    "delivered": true,
    "shape": "circle",
    "shapeRationale": "no edge cases",
    "lookupComplexity": "O(1) — it's on your finger"
  },
  "metadata": {
    "loveVersion": "2.0.0",
    "uptime": "since the day we met",
    "sla": "99.999% — the remaining 0.001% covers when I'm hangry",
    "license": "Till Death Do Us Part (perpetual, non-transferable)",
    "deprecations": ["single()", "swiping", "splitting the bill"],
    "coldStarts": 0,
    "region": "wherever you are"
  },
  "_links": {
    "self": { "href": "/", "rel": "proposal" },
    "honeymoon": { "href": "/honeymoon", "rel": "next", "status": "PLANNING" },
    "forever": { "href": "/forever", "rel": "final" }
  }
}
```

Saying no is not supported at the API level:

```console
$ curl "https://<your-function-url>.lambda-url.us-east-1.on.aws/?answer=no"
{
  "error": "invalid state transition",
  "detail": "'no' is not a reachable state from 'hopelessly in love'",
  "currentState": "hopelessly in love",
  "requestedState": "no",
  "allowedTransitions": ["yes", "YES", "obviously"],
  "retryAfter": "whenever you're ready (I'll wait)"
}
```

(That one is a `409 Conflict`, naturally.)

## Setup

Anyone with an AWS account can deploy this. You need `bash`, `curl`, and an
AWS access key — the scripts handle the rest, including installing the AWS
CLI v2 on macOS and Linux (x86_64 and ARM).

```bash
git clone https://github.com/DaanyaalSobani/marry-lambda.git
cd marry-lambda

# 1. Configure credentials (see the comments in .env.example)
cp .env.example .env
$EDITOR .env

# 2. Install/verify the AWS CLI and check your credentials
./bootstrap.sh

# 3. Package + create the IAM role and the Lambda function
./deploy.sh

# 4. Expose it publicly and print the URL
./add-url.sh

# 5. Propose
curl <the printed URL>
curl "<the printed URL>?answer=no"   # 409 Conflict
```

All scripts are idempotent — rerunning them updates rather than duplicates.
Rerun `./deploy.sh` after editing `handler.py` to ship a new proposal.

## Security notes

- `.env` holds **long-lived AWS access keys**. That's acceptable for a
  personal joke project, but **never commit `.env`** — it's git-ignored here
  on purpose. Double-check with `git status` before your first commit.
- If a key ever leaks, deactivate it immediately in the AWS console
  (IAM > Users > Security credentials > deactivate the access key), then
  create a new one.
- Scope the IAM user to least privilege rather than admin: it only needs
  Lambda management plus the ability to create/delete the one execution role
  and pass it to Lambda (`iam:CreateRole`, `iam:AttachRolePolicy`,
  `iam:PassRole`, etc. on `marry-lambda-exec-role`).
- The Function URL is intentionally public (`--auth-type NONE`). It exposes
  nothing but your feelings.

## Teardown

If you ever need to undeploy the proposal (the engagement itself is
non-revocable — see `metadata.license`):

```bash
./teardown.sh
```

This deletes the Function URL config, the function, and the IAM role
(detaching its policies first). Safe to rerun.
