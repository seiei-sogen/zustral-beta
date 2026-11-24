---
name: stral-software-factory
description: The Stral Software Factory。issue を1件ずつ、事前調査、計画、セルフレビュー、実装、コードレビュー、PR、CI が通ったらマージ、と回して次の issue へ進む。issue をこのファクトリーで片付けるよう頼まれたときに使う。
---

# The Stral Software Factory

issue を1件ずつ直してマージし、次の issue へ進む。扱う issue がなくなるまで繰り返す。
1つの issue に1つの PR を立てる。

扱う issue は、引数に番号があればその issue だけ、なければ開いている issue のすべてである。

計画と実行は、pstack の poteto-mode で行う。始める前に、Skill ツールで `pstack:poteto-mode` を呼ぶ。
手順3から6は、issue に合う poteto-mode の playbook（Bug fix、Feature、Refactoring など）に従って進め、その計画を `fix-plan.adoc` に書く。
PR とマージは、poteto-mode の Opening a PR、Babysit、Shipping ではなく、このスキルの手順7と8に従う。

## 置き場

```
docs/issues/<日付>/                     1回の実行。日付は TZ=Asia/Tokyo date +%Y%m%d
├── preliminary-investigation.json    事前調査。issue ごとに更新する
└── issue-<番号>/fix-plan.adoc        修正の計画と、そのセルフレビュー
```

その日のディレクトリが既にあれば、それを使う。
途中から再開するときは、JSON で `next` の issue について計画、ブランチ、PR のどこまで済んだかを見て、済んでいない最初の手順から続ける。

## 1つの issue の流れ

### 1. 事前調査の JSON を作る、または更新する

1回目は作る。2回目からは、前の `next` を `done` にして PR の番号を書き、開いている issue を取り直して、次の issue に合わせて書き直す。

```bash
gh api 'repos/seiei-sogen/zustral-beta/issues?state=open&per_page=100&page=1' \
  --jq '.[] | select(.pull_request | not) | [.number, .title] | @tsv'
```

```json
{
  "base_commit": "調査したときの origin/master の SHA",
  "issues": [
    {
      "number": 171,
      "title": "issue の題",
      "summary": "issue が求めていること",
      "depends_on": [],
      "status": "next",
      "reason": "この status にした理由",
      "pull_request": null
    }
  ],
  "next_issue": {
    "number": 171,
    "current_behavior": "いまの振る舞いと、それを確かめたコマンドと出力",
    "related_code": ["lib/…: 関数名"],
    "related_tests": ["test-programs/suites/…"],
    "affected_ci_checks": ["tools/refactoring/measure.sh の記録"],
    "risks": []
  }
}
```

- `status` は `next`、`queued`、`skipped`、`done` のどれかである。
- 所有者の判断が要る issue と、1つの PR に収まらない issue は `skipped` にする。
- `next` は1件だけにする。依存される issue を先に、小さい issue を先にする。
- 不具合の issue は、いまのコンパイラで再現してから `current_behavior` に書く。

`queued` が1件もなければ、「終わるとき」へ進む。

この手順は、扱う issue のすべてに `status` と `reason` があり、`next_issue` の各項目が読んだコードか実行したコマンドに基づいていれば終わりである。

### 2. 作業ブランチを用意する

最新の `origin/master` から作る。名前は、セッションに指定されたブランチがあればそれ、なければ `issue-<番号>` にする。

### 3. 計画を立てる

`issue-<番号>/fix-plan.adoc` に AsciiDoc で書く。JSON の `next_issue` をもとにする。節は次の通りである。

- `== 目的`: issue が求めていることと、終わりの条件。
- `== 現状`: いまの振る舞いと、関係するコードとテスト。
- `== 変更`: 変えるファイルと関数、新しく作るファイル。AGENTS.md の命名、ディレクトリ構造、ファイルの分け方に従う。
- `== テスト`: 最初に書く、失敗するテスト。
- `== 確認`: CI の検査への影響。計測値の記録し直し、エラーメッセージのテスト、カバレッジ。
- `== 範囲外`: この PR でしないこと。

### 4. 計画をセルフレビューする

issue の本文とコメントに照らして、計画を1回見直す。見るのは次の3つである。

- issue が求めることの一つ一つに、変更とテストが対応しているか。
- 変更が届くべき呼び出し元、テスト、記録がすべて挙がっているか。
- AGENTS.md の約束に沿っているか。

計画を直し、見つけたことと直したことを、末尾の `== セルフレビュー` に書く。

### 5. 実装する

計画に従い、`/superpowers:test-driven-development` で実装する。計画と違うことをしたら、計画にそう書き足す。

この手順は、次の検査がすべて `ok` になれば終わりである。

```bash
nix-shell --command 'tools/refactoring/run-every-ci-check-locally.sh'
```

### 6. コードレビューで直す

`git fetch origin master` のあと、Claude Code の `/code-review` を実行する。Skill ツールなら、スキル `code-review` に次の引数を渡す。
最後の3語を落とすと、コミットしていない差分がレビューから漏れる。

```
high --fix origin/master...HEAD plus uncommitted changes
```

直したら、手順5の検査をもう一度すべて通す。

この issue の範囲外の指摘で、直す価値があるものは、新しい issue にする。

```bash
gh api repos/seiei-sogen/zustral-beta/issues -f title='…' -F body=@<本文のファイル>
```

### 7. PR を立てる

残りを日本語でコミットし、push して、PR を立てる。

```bash
gh api repos/seiei-sogen/zustral-beta/pulls -f base=master -f head=<ブランチ> \
  -f title='…' -F body=@<本文のファイル>
```

本文には次を書く。

- `Closes #<番号>`
- 何を、どう直したか。
- 計画のパス。
- 手順5の検査の結果。
- コードレビューで直したことと、立てた issue。

### 8. CI が通ったらマージする

CI を待つ。クラウド環境では `subscribe_pr_activity` で PR を購読してターンを終え、CI の通知で再開する。手元では `gh pr checks <PR 番号> --watch` で待つ。

CI が落ちたら、原因を直して push し、PR の本文をいまの内容に合わせて更新する（`gh api -X PATCH repos/seiei-sogen/zustral-beta/pulls/<PR 番号> -F body=@<本文のファイル>`）。そしてまた待つ。

push した最後のコミットの check run がすべて `success` になったら、squash でマージし、作業ブランチをリモートから消す。クラウド環境では購読もやめる。

```bash
gh api repos/seiei-sogen/zustral-beta/commits/<SHA>/check-runs \
  --jq '.check_runs[] | [.name, .status, .conclusion] | @tsv'
gh api -X PUT repos/seiei-sogen/zustral-beta/pulls/<PR 番号>/merge -f merge_method=squash
gh api -X DELETE repos/seiei-sogen/zustral-beta/git/refs/heads/<ブランチ>
```

手順1に戻る。

## 終わるとき

`queued` がなくなったら終わる。原因の分からないまま CI が落ち続けるときも、そこで止める。
最後に次を報告する。

- マージした PR と、閉じた issue。
- `skipped` にした issue と、その理由。
- 新しく立てた issue。
- 止めたなら、止めた手順と、その理由。
