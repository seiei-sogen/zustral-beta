# 作業役は、渡された issue を1件ずつ、調査からマージまで進める

The Stral Software Factory（[`SKILL.md`](SKILL.md)）の調整役から、issue の番号の並びと、作業記録のディレクトリ `docs/issues/<日付>/` を渡されて始める。
渡された順に、issue を1件ずつ直してマージし、次の issue へ進む。1つの issue に1つの PR を立てる。

同じときに、もう1つの作業役が、別の issue を別のブランチで直している。master は、作業の途中で進む。
`README.md` の「いまの進み具合と、次にやること」節と、`docs/issues/<日付>/preliminary-investigation.json` は書かない。調整役が、実行の終わりに書く。

計画と実行は、pstack の poteto-mode で行う。始める前に、Skill ツールで `pstack:poteto-mode` を呼ぶ。
手順2から5は、issue に合う poteto-mode の playbook（Bug fix、Feature、Refactoring など）に従って進め、その計画を `fix-plan.adoc` に書く。
PR の題と本文、CI の待ち方、マージは、poteto-mode の Opening a PR、Babysit、Shipping や pstack の `worker.md` ではなく、このファイルの手順6と7に従う。

## 1つの issue の流れ

### 1. 作業ブランチを用意する

最新の `origin/master` から作る。名前は、調整役に渡された名前があればそれ、なければ `issue-<番号>` にする。
前の issue と同じ名前を使い回すこともあるので、作り直す形にする。
`--prune` を付けて全体を取るのは、手順6の `--force-with-lease` がリモートのブランチのいまの位置を知っている必要があるからである。

```bash
git fetch --prune origin
git checkout -B <ブランチ> origin/master
```

その issue の PR が開いたまま残っていれば、ブランチを作り直さない。計画、ブランチ、PR のどこまで済んだかを見て、済んでいない最初の手順から続ける。

### 2. 調べて、計画を立てる

issue の本文とコメントを読み、関係するコードとテストを調べる。不具合の issue は、いまのコンパイラで再現する。

調べた結果、所有者の判断が要る issue と、1つの PR に収まらない issue は、直さずに飛ばす。渡された issue のうち、それに依存する issue も飛ばす。

計画は `docs/issues/<日付>/issue-<番号>/fix-plan.adoc` に AsciiDoc で書く。節は次の通りである。

- `== 目的`: issue が求めていることと、終わりの条件。
- `== 現状`: いまの振る舞いと、それを確かめたコマンドと出力。関係するコードとテスト。リスク。
- `== 変更`: 変えるファイルと関数、新しく作るファイル。AGENTS.md の命名、ディレクトリ構造、ファイルの分け方に従う。
- `== テスト`: 最初に書く、失敗するテスト。
- `== 確認`: CI の検査への影響。計測値の記録し直し、エラーメッセージのテスト、カバレッジ。
- `== 範囲外`: この PR でしないこと。

### 3. 計画をセルフレビューする

issue の本文とコメントに照らして、計画を1回見直す。見るのは次の3つである。

- issue が求めることの一つ一つに、変更とテストが対応しているか。
- 変更が届くべき呼び出し元、テスト、記録がすべて挙がっているか。
- AGENTS.md の約束に沿っているか。

計画を直し、見つけたことと直したことを、末尾の `== セルフレビュー` に書く。

### 4. 実装する

計画に従い、`/superpowers:test-driven-development` で実装する。計画と違うことをしたら、計画にそう書き足す。

この手順は、次の検査がすべて `ok` になれば終わりである。

```bash
nix-shell --command 'tools/refactoring/run-every-ci-check-locally.sh'
```

### 5. コードレビューで直す

`git fetch origin master` のあと、Claude Code の `/code-review` を実行する。Skill ツールなら、スキル `code-review` に次の引数を渡す。
最後の3語を落とすと、コミットしていない差分がレビューから漏れる。

```
high --fix origin/master...HEAD plus uncommitted changes
```

直したら、手順4の検査をもう一度すべて通す。

この issue の範囲外の指摘で、直す価値があるものは、新しい issue にする。

```bash
gh api repos/seiei-sogen/zustral-beta/issues -f title='…' -F body=@<本文のファイル>
```

### 6. PR を立てる

残りを日本語でコミットし、下の「master を取り込む」を行ってから push して、PR を立てる。
リモートに前の issue のマージ済みのブランチが残っていることがあるので、`--force-with-lease` で上書きする。手順1のあとに誰かが push していれば、push は断られる。そのときは止める。

```bash
git push --force-with-lease -u origin <ブランチ>
gh api repos/seiei-sogen/zustral-beta/pulls -f base=master -f head=<ブランチ> \
  -f title='…' -F body=@<本文のファイル>
```

本文には次を書く。

- `Closes #<番号>`
- 何を、どう直したか。
- 計画のパス。
- 手順4の検査の結果。
- コードレビューで直したことと、立てた issue。

### 7. CI が通ったらマージする

push するたびに、まず、PR が master と衝突していないかを見る。

```bash
gh api repos/seiei-sogen/zustral-beta/pulls/<PR 番号> --jq '.mergeable | tostring'
```

- `null` なら、GitHub が計算している途中である。数秒おいて取り直す。
- `false` なら、「master を取り込む」を行って push し、見直す。衝突している PR では CI が走らないので、待っても終わらない。
- `true` なら、CI を待つ。

クラウド環境では `subscribe_pr_activity` で PR を購読してターンを終え、CI の通知で再開する。手元では `gh pr checks <PR 番号> --watch` で待つ。

CI が落ちたら、原因を直して push し、PR の本文をいまの内容に合わせて更新する（`gh api -X PATCH repos/seiei-sogen/zustral-beta/pulls/<PR 番号> -F body=@<本文のファイル>`）。そしてまた待つ。
もう1つの作業役のマージと合わさって初めて壊れたものも、この PR で直す。PR の CI は、push したときの master と合わせた結果を検査している。

push した最後のコミットの check run が1件以上あり、そのすべてが `completed` で `success` になったら、もう一度 `mergeable` を見る。`true` なら、squash でマージする。
待つあいだに master が進んでいても、衝突していなければ、取り込み直さずにマージする。
手元では、作業ブランチ `issue-<番号>` をリモートから消す。クラウド環境ではブランチを消せないので残し、購読をやめる。残したブランチは、次の issue の手順6で上書きされる。

```bash
gh api repos/seiei-sogen/zustral-beta/commits/<SHA>/check-runs \
  --jq '.check_runs[] | [.name, .status, .conclusion] | @tsv'
gh api -X PUT repos/seiei-sogen/zustral-beta/pulls/<PR 番号>/merge -f merge_method=squash -f sha=<SHA>
gh api -X DELETE repos/seiei-sogen/zustral-beta/git/refs/heads/issue-<番号>  # 手元だけ
```

次の issue の手順1へ進む。

## master を取り込む

もう1つの作業役が先にマージした変更を、自分のブランチへ入れる。

```bash
git fetch origin master
git merge --no-edit origin/master
```

何も取り込まれなければ、ここで終わりである。取り込まれたら、次のようにする。

- `tools/refactoring/expected/` の衝突は、手で混ぜない。どちらかの側を取り、その記録を書くスクリプトの `--record` で作り直す（`metrics.tsv` は `tools/refactoring/measure.sh --record`）。作り直した記録は、両方の側の変更を合わせたものになる。どちらの側にもない行が増えていたら、記録せずに、原因を直す。
- ほかの衝突は、両方の変更が生きるように解く。master の側が何をしたかは、そのコミットの PR の本文と、`docs/issues/` の計画で分かる。
- 手順4の検査をもう一度すべて通して、コミットする。
- 解いても検査が通らなければ、`origin/master` からブランチを作り直し、計画に従って実装し直す。作り直したあとの push は、`--force-with-lease` にする。

## 終わるとき

渡された issue がなくなったら終わる。原因の分からないまま CI が落ち続けるときも、そこで止める。
最後に、次を調整役へ報告する。クラウド環境では、`send_message` で、依頼にあったセッションへ送る。

- マージした PR と、閉じた issue。
- 飛ばした issue と、その理由。
- 新しく立てた issue。
- 止めたなら、止めた手順と、その理由。
