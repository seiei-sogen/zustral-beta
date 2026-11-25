---
name: zustral-software-factory
description: The Stral Software Factory。issue を1件ずつ、事前調査、計画、セルフレビュー、実装、コードレビュー、PR、CI が通ったらマージ、と回して次の issue へ進む。引数がなければ、README の「次にやること」から issue を取る。issue をこのファクトリーで片付けるよう頼まれたときに使う。
---

# The Stral Software Factory

issue を1件ずつ直してマージし、次の issue へ進む。扱う issue がなくなるまで繰り返す。
1つの issue に1つの PR を立てる。

扱う issue は、引数に番号があればその issue だけである。
引数がなければ、`README.md` の「いまの進み具合と、次にやること」節の「次にやること」から取る。1回目の手順1でこの一覧を上から読み、番号が挙がっていて、まだ開いている issue を、書かれた順に扱う。「#73 から #83」のような範囲は、その間の番号をすべて含む。issue の番号がない項目（所有者が確かめる項目など）は、扱わずに飛ばす。
「次にやること」に開いている issue が1件も挙がっていなければ、何もせずに「終わるとき」へ進み、そう報告する。
途中で立てた issue は、この実行では扱わない。手順7が「次にやること」に書くので、次の実行が拾う。

計画と実行は、pstack の poteto-mode で行う。始める前に、Skill ツールで `pstack:poteto-mode` を呼ぶ。
手順3から6は、issue に合う poteto-mode の playbook（Bug fix、Feature、Refactoring など）に従って進め、その計画を `fix-plan.adoc` に書く。
PR とマージは、poteto-mode の Opening a PR、Babysit、Shipping ではなく、このスキルの手順8と9に従う。

## 置き場

```
docs/issues/<日付>/                          1回の実行。日付は TZ=Asia/Tokyo date +%Y%m%d
└── issue-<番号>/
    ├── preliminary-investigation.json     その issue の事前調査
    └── fix-plan.adoc                      修正の計画と、そのセルフレビュー
```

事前調査は、issue ごとに1ファイルにする。実行の全体で1つのファイルにすると、どの PR もそれを書き換えるので、コンフリクトの原因になる。
1つの PR に入れるのは、その issue のディレクトリと、前の PR のあとに `skipped` にした issue のディレクトリだけである。ほかの issue のファイルは書き換えない。
`docs/issues/20261124/` は、実行の全体で1つの JSON を置いていたころの記録である。そのままにする。

その日のディレクトリが既にあれば、それを使う。
途中から再開するときは、日付が変わっていても、いちばん新しい日付のディレクトリを使う。事前調査の `status` が `next` の issue、または PR がまだマージされていない `done` の issue について、計画、ブランチ、PR のどこまで済んだかを見て、済んでいない最初の手順から続ける。

## 1つの issue の流れ

### 1. 次の issue を選んで、事前調査を書く

毎回、開いている issue を取り直す。

```bash
gh api 'repos/seiei-sogen/zustral-beta/issues?state=open&per_page=100&page=1' \
  --jq '.[] | select(.pull_request | not) | [.number, .title] | @tsv'
```

1ページが100件で埋まっていたら、`page` を増やして次のページも取る。

扱う issue のうち、まだ開いていて、この実行で `skipped` にも `done` にもしていないものが候補である。
引数がないときの候補の並びは、1回目に読んだ `README.md` の「次にやること」の順である。

候補を前から見て、次の issue を1件選ぶ。

- 所有者の判断が要る issue と、1つの PR に収まらない issue は `skipped` にする。`skipped` の issue に依存する issue も `skipped` にする。
- 引数がないときは、`skipped` でない最初の候補を選ぶ。ただし、それが依存する候補が後ろにあれば、そちらを先にする。
- 引数があるときは、依存される issue を先に、小さい issue を先にする。

`skipped` にした issue には、`number`、`title`、`summary`、`depends_on`、`status`、`reason` だけの事前調査を書く。
選んだ issue には、`issue-<番号>/preliminary-investigation.json` を、次の形で書く。

```json
{
  "number": 171,
  "title": "issue の題",
  "base_commit": "調査したときの origin/master の SHA",
  "summary": "issue が求めていること",
  "depends_on": [],
  "status": "next",
  "reason": "この status にした理由",
  "current_behavior": "いまの振る舞いと、それを確かめたコマンドと出力",
  "how_it_works_now": "入口から、問題の起きる場所までの、コードの流れ。読んだファイルと関数を挙げる",
  "why_it_is_this_way": [
    {
      "claim": "いまの形になった理由",
      "source": "コミットの SHA、PR や issue の番号、文書のパス",
      "kind": "quoted か inferred"
    }
  ],
  "unanswered_by_the_record": ["記録を探しても分からなかったこと"],
  "related_code": ["lib/…: 関数名"],
  "related_tests": ["test-programs/suites/…"],
  "affected_ci_checks": ["tools/refactoring/measure.sh の記録"],
  "risks": []
}
```

- `status` は `next`、`skipped`、`done` のどれかである。`done` は PR を立てたことを表す。
- 不具合の issue は、いまのコンパイラで再現してから `current_behavior` に書く。
- `how_it_works_now` は、pstack の `how` スキルに従って調べる。この issue に関係する範囲に絞る。
- `why_it_is_this_way` は、pstack の `why` スキルに従って調べる。コードからではなく、記録から答える。関係するコードを入れたコミットと、その PR、issue、`docs/` の文書を、`git log -S`、`git blame`、`gh api` で辿る。書いた人の言葉は `quoted`、自分の推測は `inferred` にする。直そうとしている振る舞いが、わざと選ばれたものでないかを、ここで確かめる。わざと選ばれていたら、所有者の判断が要るので `skipped` にする。
- `how` と `why` は Skill ツールでは呼べない。poteto-mode の `SKILL.md` と同じ階層の `../how/SKILL.md` と `../why/SKILL.md` を読んで、それに従う。

選べる issue が1件もなければ、「終わるとき」へ進む。

この手順は、選んだ issue の事前調査の各項目が、読んだコードか、実行したコマンドか、引用元のある記録に基づいていれば終わりである。

### 2. 作業ブランチを用意する

最新の `origin/master` から作る。名前は、セッションに指定されたブランチがあればそれ、なければ `issue-<番号>` にする。
前の issue と同じ名前を使い回すこともあるので、作り直す形にする。
`--prune` を付けて全体を取るのは、手順8の `--force-with-lease` がリモートのブランチのいまの位置を知っている必要があるからである。

```bash
git fetch --prune origin
git checkout -B <ブランチ> origin/master
```

### 3. 計画を立てる

`issue-<番号>/fix-plan.adoc` に AsciiDoc で書く。その issue の事前調査をもとにする。節は次の通りである。

- `== 目的`: issue が求めていることと、終わりの条件。
- `== 現状`: いまの振る舞いと、関係するコードとテスト。
- `== 変更`: 変えるファイルと関数、新しく作るファイル。AGENTS.md の命名、ディレクトリ構造、ファイルの分け方に従う。
- `== テスト`: 最初に書く、失敗するテスト。
- `== 確認`: CI の検査への影響。計測値の記録し直し、エラーメッセージのテスト、カバレッジ。
- `== 範囲外`: この PR でしないこと。

### 4. 計画をセルフレビューする

issue の本文とコメントに照らして、計画を3回見直す。毎回、次の3つをすべて見る。

- issue が求めることの一つ一つに、変更とテストが対応しているか。
- 変更が届くべき呼び出し元、テスト、記録がすべて挙がっているか。
- AGENTS.md の約束に沿っているか。

1回ごとに計画を直し、見つけたことと直したことを、末尾の `== セルフレビュー` の `=== 1回目`、`=== 2回目`、`=== 3回目` に書く。
2回目と3回目は、前の回で直した箇所も含めて、計画を頭から読み直す。何も見つからなかった回も、そう書く。途中の回で何も見つからなくても、3回やる。

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

### 7. 進み具合を記録する

この PR がマージされた後の状態として、次の2つを書き直す。
PR を立てる前のコミットに入れるのは、記録のためだけに CI をもう1周回さないためである。

- この issue の事前調査の `status` を `done` にする。
- `README.md` の「いまの進み具合と、次にやること」節。いまの書き方に合わせて、次のように直す。
  - 冒頭の「… の時点の状態である」の日付を、今日にする。
  - 「終わったこと」には、この実行の項目を1つ置き、`docs/issues/<日付>/` にリンクする。直した issue は、その項目に書き足す。
  - 「次にやること」から、直した issue を消す。まだ扱っていない issue、`skipped` のうち判断が要る issue、手順6で立てた issue を、進める順に書く。

### 8. PR を立てる

残りを日本語でコミットして push し、PR を立てる。
リモートに前の issue のマージ済みのブランチが残っていることがあるので、`--force-with-lease` で上書きする。手順2のあとに誰かが push していれば、push は断られる。そのときは止める。

```bash
git push --force-with-lease -u origin <ブランチ>
gh api repos/seiei-sogen/zustral-beta/pulls -f base=master -f head=<ブランチ> \
  -f title='…' -F body=@<本文のファイル>
```

本文には次を書く。

- `Closes #<番号>`
- 何を、どう直したか。
- 計画のパス。
- 手順5の検査の結果。
- コードレビューで直したことと、立てた issue。

### 9. CI が通ったらマージする

CI を待つ。クラウド環境では `subscribe_pr_activity` で PR を購読してターンを終え、CI の通知で再開する。手元では `gh pr checks <PR 番号> --watch` で待つ。

CI が落ちたら、原因を直して push し、PR の本文をいまの内容に合わせて更新する（`gh api -X PATCH repos/seiei-sogen/zustral-beta/pulls/<PR 番号> -F body=@<本文のファイル>`）。そしてまた待つ。

push した最後のコミットの check run が1件以上あり、そのすべてが `completed` で `success` になったら、squash でマージする。
手元では、作業ブランチ `issue-<番号>` をリモートから消す。クラウド環境ではブランチを消せないので残し、購読をやめる。残したブランチは、次の issue の手順8で上書きされる。

```bash
gh api repos/seiei-sogen/zustral-beta/commits/<SHA>/check-runs \
  --jq '.check_runs[] | [.name, .status, .conclusion] | @tsv'
gh api -X PUT repos/seiei-sogen/zustral-beta/pulls/<PR 番号>/merge -f merge_method=squash -f sha=<SHA>
gh api -X DELETE repos/seiei-sogen/zustral-beta/git/refs/heads/issue-<番号>  # 手元だけ
```

手順1に戻る。

## 終わるとき

選べる issue がなくなったら終わる。原因の分からないまま CI が落ち続けるときも、そこで止める。
最後に次を報告する。

- マージした PR と、閉じた issue。
- `skipped` にした issue と、その理由。
- 新しく立てた issue。
- 止めたなら、止めた手順と、その理由。
