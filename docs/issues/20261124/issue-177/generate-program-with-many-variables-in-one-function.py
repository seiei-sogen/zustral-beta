"""issue #177 の測定に使うプログラムを書き出す。

    python3 generate-program-with-many-variables-in-one-function.py SHAPE N > program.zum

SHAPE は次のどれかである。

- variables-in-main: #143 のプログラム。レコードを N 個宣言し、main に変数を N 個置く。
- function-per-type: 同じレコードを、型ごとに1つの関数で汎用の関数に通す。main の変数は1個もない。
- if-after-each-variable: variables-in-main の各変数の後に if 文を置く。分岐の後で表を比べる処理を測る。
"""

import sys

SHAPES = ("variables-in-main", "function-per-type", "if-after-each-variable")

HEADER = """module body Test is
    record Box[T: Free]: Free is value: T; end;
    generic [T: Free] function ident(x: T): T is let y: T := x; return y; end;
    generic [T: Free] function wrap(x: T): Box[T] is let y: T := ident(x); return Box(value => y); end;
    generic [T: Free] function wrap2(x: T): Box[Box[T]] is let b: Box[T] := wrap(x); return wrap(b); end;
"""


def program(shape: str, n: int) -> str:
    lines = [HEADER]
    lines += [f"    record R{i}: Free is n: Int32; end;\n" for i in range(n)]
    if shape == "function-per-type":
        lines += [
            f"    function use{i}(): Unit is let v: Box[Box[R{i}]] := wrap2(R{i}(n => {i})); return nil; end;\n"
            for i in range(n)
        ]
    lines.append("    function main(): ExitCode is\n")
    for i in range(n):
        if shape == "function-per-type":
            lines.append(f"        use{i}();\n")
        else:
            lines.append(f"        let v{i}: Box[Box[R{i}]] := wrap2(R{i}(n => {i}));\n")
        if shape == "if-after-each-variable":
            lines.append(f"        if v{i}.value.value.n = {i} then skip; else skip; end if;\n")
    lines.append("        return ExitSuccess();\n    end;\nend module body.\n")
    return "".join(lines)


if __name__ == "__main__":
    shape, n = sys.argv[1], int(sys.argv[2])
    if shape not in SHAPES:
        sys.exit(f"unknown shape: {shape}; one of {', '.join(SHAPES)}")
    sys.stdout.write(program(shape, n))
