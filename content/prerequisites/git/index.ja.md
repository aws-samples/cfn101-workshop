---
title: "Gitのインストール"
weight: 400
---

Git がすでにインストールされている可能性があります。確認するために、ターミナルで `git --version` を実行します。インストールされていない場合は、自分のオペレーティングシステムに合わせて以下の手順に沿ってインストールしてください。

## macOS で Git のインストール

macOS で Git をインストールするために、二つの方法があります。[Xcode](https://developer.apple.com/jp/xcode/) か [Homebrew](https://brew.sh/) でインストールできます。

### Xcode で Git のインストール

1. ターミナルで以下のコマンドを実行してください。

   :::code{language=shell showLineNumbers=false showCopyAction=true}
    xcode-select --install
   :::

1. 表示されるソフトウェアアップデートウィンドーの指示に従ってインストールしてください。

## Linux で Git のインストール

全ての Linux ディストリビューションのメインパッケージリポジトリに Git が含まれています。パッケージマネージャを使ってインストールしてください (例えば、`apt install git`)。

ターミナルで `git --version` を実行すると、インストールの確認ができます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
git --version
git version 2.30.0
:::

## Windows で Git をインストール

### Git for Windows のスタンドアローンインストーラ

1. 最新の [Git for Windows](https://git-for-windows.github.io/) のインストーラをダウンロードしてください。
1. インストーラを実行したら、Git のセットアップウィザードの画面が表示されます。Next や Finish を使って、インストールを完了させてください。デフォルトのオプションはほとんどのユーザで問題ありません。
1. コマンドプロンプトを開いてください（それとも、インストール時に Git を Windows のコマンドプロンプトから実行しないオプションを選んだ場合は、 Git Bash を実行してください）。
1. `git --version` コマンドを実行してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
git --version
git version 2.23.0.windows.1
:::
