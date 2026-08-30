# App icon / アプリアイコン

The icon is authored as SVG and rendered with macOS built-in tools only —
no ImageMagick, no Inkscape, nothing to install.

アイコンは SVG で作り、macOS 標準ツールだけで PNG 化する。
追加インストールは不要。

## Concept / 意図

開いた本（READ）を、途中で止まったリング（MOVE の週ペース）が囲む。

**リングを閉じないことがこのアイコンの主張**で、満タンにすると「毎日やらないと
いけない」という逆のメッセージになる。変更時もここは埋めないこと。

要素は「本 + リング」の1組だけに保つ。実際に「本 + 走る人」「本 + 足跡」を試したが、
要素が2つになると 120px で崩れた。Apple HIG と Michael Flarup がともに
「単一の焦点に絞れ」としているのはこのため。

チェックマークは使わない。習慣トラッカーで最も混雑した記号であり、
「達成／未達成」の二値は「自分のペース」という思想とも噛み合わない。

`render.sh` は検討用に 512px と 120px を書き出す。**判断は必ず 120px で行う**
（ホーム画面の実寸。1024px では何でも良く見える）。生成物は gitignore 済み。

```bash
./render.sh              # design/*.svg を全部
./render.sh AppIcon.svg  # 個別
```

## Regenerating / 再生成

```bash
cd design

# Render at 2x, then downscale: smoother antialiasing than rendering at 1024.
# 2倍でレンダリングしてから縮小する。1024 で直接描くよりエッジが滑らかになる。
qlmanage -t -s 2048 -o . AppIcon.svg

sips -Z 1024 AppIcon.svg.png --out _big.png

# qlmanage always emits an alpha channel, which App Store Connect rejects.
# Round-tripping through JPEG is the only way to drop it with sips alone.
# qlmanage の出力は必ずアルファ付きになり、App Store Connect に弾かれる。
# sips だけでアルファを落とすには JPEG を経由するしかない。
sips -s format jpeg -s formatOptions best _big.png --out _flat.jpg
sips -s format png _flat.jpg --out ../Paceria/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png

rm -f AppIcon.svg.png _big.png _flat.jpg

# Verify: must be 1024x1024 with hasAlpha: no
# 検証: 1024x1024 かつ hasAlpha: no であること
sips -g pixelWidth -g pixelHeight -g hasAlpha \
  ../Paceria/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png
```

## Constraints / 制約

| Rule | Why |
|---|---|
| No alpha channel | App Store Connect rejects icons with transparency / 透過があるとアップロードが弾かれる |
| No rounded corners | iOS applies the squircle mask itself; baking one in leaves a hairline at the edge / OS が角丸マスクを適用するため、自分でつけると縁に線が残る |
| Fill the full square | Same reason as above / 同上 |
| One 1024x1024 file only | `actool` generates 120x120, 152x152 and the rest at build time / 残りのサイズはビルド時に自動生成される |
| Keep the subject inside the middle 80% | The corners are cropped by the mask / 角はマスクで削られる |
| Outline any text to paths | `<text>` breaks if the rendering host lacks the font / フォントが無い環境で壊れる |

## The 120x120 error / 120x120 エラーについて

An upload failing with:

```
Missing required icon file. The bundle does not contain an app icon for
iPhone / iPod Touch of exactly '120x120' pixels
```

does **not** mean a 120x120 file is missing. It means the asset catalog has no
image at all — `Contents.json` carried the slots but no `filename` key. Adding
the single 1024 entry fixes every size at once.

このエラーは 120x120 のファイルが必要という意味ではない。アセットカタログに
画像が1枚も無い（`Contents.json` に `filename` が無い）状態を指す。
1024 を1件登録すれば全サイズが解決する。
