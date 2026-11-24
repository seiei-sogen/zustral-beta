---
name: verify-decimal-runtime-128-bit-headroom
description: Decimal の実行時の算術（docs/research/decimal-prototype/runtime/decimal.c、のちに D1 で書く本番の実行時）が、どの入力でも 128 ビットの途中結果をあふれさせず、C の未定義動作を起こさず、結果の精度に収まる係数だけを返すことを、CBMC で検証する。decimal.c や decimal.h を変えたとき、本番の実行時を書いたり移したりしたとき、除算・丸め・加減算・Float64 からの変換の実装に手を入れたときに使う。
---

# Decimal の実行時の 128 ビットの余裕を検証する

## 何を保証するか

- **性質。** コンパイラが渡しうるどの入力でも、Decimal の実行時の関数は、128 ビット（と 64 ビット）の途中結果を折り返さず、C の未定義動作（符号付きのあふれ、幅を超えるシフト、配列の外の読み書き）を起こさない。成功したときの係数は、結果の型の精度に収まる。
- **壊れたときの害。** 途中の値が黙って折り返すと、桁あふれのエラーにならずに、間違った金額が計算され、そのまま出力される。

ふつうのテスト（`docs/research/decimal-prototype/runtime/run.sh` の突き合わせ）は、生成した入力の範囲でしか確かめない。符号なしの折り返しは、UBSan も検出しない。この検証は、決めた入力の範囲の全体を確かめる。

## 実行する

リポジトリのルートで、1コマンドで実行する。CBMC は `shell.nix` が nixpkgs 23.05 から入れる（CBMC 5.76.1）。

```bash
nix-shell --command 'tools/formal-verification/decimal-runtime-128-bit-headroom/check-decimal-runtime-headroom.sh'
```

クラウド環境では、先に `tools/coding-agent-setup/fetch-pinned-nixpkgs-with-git.sh` を1回実行する（AGENTS.md）。

- 期待する出力は、ハーネスごとの `verified <ハーネス> <秒>` と、最後の `all checks as expected` である。終了コードは 0 である。
- ハーネスは、コアの数だけ並べて実行する。4 コアの機械で、全体は約 6 分かかる。`zd-round`、`zd-exact`、`zd-from-double` が、それぞれ約 5 分半かかる（2026-11-24 に測った）。
- `--mutants` を付けると、実行時をわざと壊した 11 個の変種でも実行し、どれも検出されることを確かめる。検証やハーネスを変えたときは、必ず付けて実行する。全体で約 17 分かかる。
- `--keep` を付けると、CBMC のログを消さずに、その場所を表示する。
- `--runtime <ディレクトリ>` で、`decimal.h` と `decimal.c` のある別のディレクトリを検証する。本番の実行時を書いたら、これで向け先を変える。

## 対象と記録

**同期したコミット：`74ebd020d18a34db802d3c1bc3cca69ab0374186`。**
このコミットで、下の表の関数を読み、検証がそのとおりに書かれていることを確かめた。

| ハーネス（`harnesses/`） | 検証する関数（`decimal.c`） | 確かめること | 時間 |
|---|---|---|---|
| `zd-add.c` | `zd_add`、`zd_abs`、`zd_pow10` | あふれと未定義動作がない。和が精度に収まらないときに限って失敗し、成功すれば正確な和を返す | 2 秒 |
| `zd-sub.c` | `zd_sub` | 同上（差） | 4 秒 |
| `zd-mul.c` | `zd_mul` | P1 + P2 ≤ 38 のとき、積があふれない | 13 秒 |
| `zd-div.c` | `zd_div`、`zd_classify`、`zd_finish`、`zd_rounds_away` | すべての k = s2 + s3 − s1（−38 から 76）で、あふれと未定義動作がない。割る数が 0 なら失敗する。成功した結果は精度に収まる | 50 秒 |
| `zd-round.c` | `zd_round`、`zd_rescale` | あふれと未定義動作がない。成功した結果は精度に収まる | 341 秒 |
| `zd-exact.c` | `zd_exact`、`zd_rescale` | 同上 | 342 秒 |
| `zd-widen.c` | `zd_widen` | s2 ≥ s で結果が Decimal[38, s2] に収まるとき、あふれない | 81 秒 |
| `zd-from-double.c` | `zd_from_double` | NaN と無限大を含むすべての Float64 で、あふれ、幅を超えるシフト、配列の外の読み書きがない。成功した結果は精度に収まる | 317 秒 |
| `au-dec-lit.c` | `au_dec_lit` | hi と lo が 10^19 未満のとき、あふれず、符号を保ち、10^38 未満の係数を返す | 1 秒 |
| `zd-format.c` | `zd_format` | 48 バイトのバッファと 40 バイトの桁の配列の外に書かない | 3 秒 |

### 変更が検証に触れるかの見分け方

次のどれかを変えたら、触れている。検証を実行する。

- `docs/research/decimal-prototype/runtime/decimal.c` と `decimal.h`。
- コンパイラが実行時に渡す値の範囲。精度は 1 以上 38 以下、スケールは 0 以上で精度以下、`zd_mul` では P1 + P2 ≤ 38、`zd_widen` では s2 ≥ s で結果が収まる。どれもハーネスの `__CPROVER_assume` に書いてある。
- `tools/formal-verification/decimal-runtime-128-bit-headroom/` の中のファイル。

同期したコミットから後に、対象のファイルが変わったかは、次で分かる。

```bash
git log --oneline 74ebd020d18a34db802d3c1bc3cca69ab0374186..HEAD -- docs/research/decimal-prototype/runtime/decimal.c docs/research/decimal-prototype/runtime/decimal.h tools/formal-verification/decimal-runtime-128-bit-headroom
```

### 同期したコミットを進める

上の表の関数を読み直し、ハーネスの前提と、`inject-long-division-loop-invariant.py` の不変条件が、新しいコミットのコードを正しく書いていると確かめてから、`--mutants` を付けて実行する。すべて期待どおりなら、上の「同期したコミット」を新しいコミットに書き換える。検証を実行しただけで、読み直していないなら、進めない。

## 失敗を読む

失敗したハーネスの下に、CBMC が破られたと報告した性質が、`decimal.c` の行番号つきで出る。行番号は、不変条件を入れた写しのものである。`decimal.c` の 79 行目（筆算のループの見出し）より後は 2 行、83 行目（内側のループの見出し）より後は 4 行、`decimal.c` より大きい。写しは、`--keep` で残したディレクトリの `runtime/decimal.c` にある。性質の名前がなく、ログの末尾だけが出たときは、CBMC かその前の段が止まっている。下の見分け方の最後の3つを見る。`--keep` を付けて再実行し、ログ（`<ハーネス>.log`）を読む。反例のトレースが要るなら、ログにある `cbmc` のコマンドに `--trace` を足して実行する。トレースの入力（`a`、`b`、`s1` など）を、どの演算が、どの値で折り返すかの手順に直して報告する。

本物のバグか、検証の誤りかは、次で見分ける。

- **`overflow`、`undefined-shift`、`array_bounds` の失敗、または `fits the result precision`、`exact sum` などのハーネスの表明の失敗。** トレースの入力が、コンパイラが実際に渡しうる値なら、本物のバグである。渡しえない値なら、ハーネスの前提が広すぎる。前提を狭めるのは、コンパイラがその範囲を保証している根拠（`docs/decimal.md` の節、型検査のコード）を示せるときだけである。
- **`loop invariant is preserved` または `established` の失敗。** `zd_div` の筆算の不変条件（`inject-long-division-loop-invariant.py`）が、コードと合っていない。ループの中身を変えたなら、不変条件を書き直す。変えていないなら、コードが不変条件の保っていた事実（余りは割る数より小さい、商は 10^38 未満、1桁は 9 以下）を壊している。これは本物のバグである。
- **`the long-division digit loop is not found exactly once`。** `zd_div` の筆算のループの見出しの行が変わった。新しいループに合わせて、`inject-long-division-loop-invariant.py` の見出しと不変条件を書き直す。
- **`unwinding assertion` の失敗。** ループの回数の上限（`zd_pow10` は 40、それ以外は 41、`zd_from_double` は 257）が足りない。コードのループが長くなったなら、スクリプトの `--unwind` と `--unwindset` を上げる。
- **`Inner loop ... does not have contracts`。** 筆算のループの中に、新しいループか、ループのある関数の呼び出しが入った。その関数を `--unwindset` で先に展開するか、そのループにも不変条件を書く。

性質が破られたときに、性質やハーネスの前提を弱めて通してはいけない。反例をそのまま報告する。実行時のコードを直すのは、ユーザーが頼んだときだけである。

## 意図した変更に検証を合わせる

- **関数を足したとき。** `harnesses/` に、その関数のハーネスを1ファイル足す。共通の部分は `decimal-runtime-under-check.h` にある。スクリプトの `HARNESSES` に名前を足す。その関数を壊す変種を、スクリプトの `mutant` の行に1つ以上足し、`--mutants` で検出されることを確かめる。上の表に行を足す。
- **入力の範囲が変わったとき。** ハーネスの `__CPROVER_assume` を、`docs/decimal.md` の新しい範囲に合わせる。
- **`zd_div` の筆算を書き換えたとき。** 不変条件を書き直す。書き直したら、`--mutants` を付けて実行し、`div-times-ten-wraps` と `div-no-early-overflow-exit` が検出されることを確かめる。
- **本番の実行時（D1、issue #73）を書いたとき。** `--runtime` でその場所を指す。関数の名前や引数が変わったなら、ハーネスと変種の断片を合わせる。終わったら、スクリプトの既定の場所と、上の「変更が検証に触れるかの見分け方」のパスを、本番の場所に変える。

## 範囲と前提

- **検証する範囲。** 上の表の関数ごとに、精度と スケールのすべての組と、それに収まるすべての係数（`zd_from_double` は Float64 のすべてのビットの並び）。範囲を小さく切ってはいない。`zd_div` は、P1 = P2 = 38 の係数とすべてのスケールを入れる。どの精度の係数も 10^38 未満なので、すべての精度を含む。
- **筆算のループ。** 回数で展開せず、不変条件で検証する。CBMC は、ループに入るときに不変条件が成り立つことと、任意の1回の繰り返しが不変条件を保つことを確かめる。だから k の値によらない。不変条件は注釈で、コードの計算を変えない。
- **検証しないこと。**
  - **計算した値が正しいこと**（丸めモードどおりに丸めた商になっているか）。これは `run.sh` の突き合わせが、Python の有理数計算と比べて確かめる。CBMC で値まで確かめると、128 ビットの除算や乗算の等しさを示すことになり、`zd_round` も `au_dec_lit` も 10 分を超えて終わらなかった（2026-11-24 に試した）。
  - 失敗すべきときに失敗すること。ただし `zd_add` と `zd_sub` と、`zd_div` の割る数が 0 の場合は確かめる。
  - 符号付きと符号なしの間の変換。`zd_abs` と `zd_from_double` は、わざと変換で値を切り詰めるので、CBMC の `--conversion-check` は使わない。結果が精度に収まることの表明が、変換で値が変わった場合を捕まえる。
  - 符号なしの値の左シフトで、上の桁が落ちること。CBMC の `--unsigned-overflow-check` は、符号なしの `<<` を見ない（CBMC 5.76.1 で確かめた）。`zd_from_double` の `(zd_u128)mantissa << exponent`、`whole << shift`、`kept << 1` は、コードの上の打ち切り（`exponent > 74` など）で収まると読んで確かめた。この打ち切りを変えたら、読み直す。
  - `zd_to_double`（libc の `strtod` を呼ぶ）、`au_dec_debug_print`、止まる形の入口（`au_dec_*`）のうち、`zd_*` を呼んで止めるだけのもの。
  - C コンパイラが CBMC と同じ意味で `__int128` と `__builtin_*_overflow` を訳すこと。CBMC は、64 ビットの gcc と clang の意味（issue #68）で解釈する。
- **前提。** コンパイラが、上の範囲の外の値を実行時に渡さないこと。

## 検証が失敗しうることの確認

`--mutants` は、`decimal.c` の断片を1つずつ置き換えた 11 個の変種を作り、それぞれ決めたハーネスが失敗することを確かめる。どれかが検出されなければ、終了コードは 0 にならない。たとえば、`div-times-ten-wraps` は余りを 10 倍して 128 ビットを折り返させ、`div-no-early-overflow-exit` は商の早めの打ち切りを消し、`literal-high-part-wraps-in-64-bits` は 64 ビットで掛け算させる。
