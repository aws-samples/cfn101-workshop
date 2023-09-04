---
title: "AWS Cloud9 セットアップ (推奨)"
weight: 200
---

_セットアップ時間 : 10分程度_

## 概要

[AWS Cloud9](https://aws.amazon.com/jp/cloud9/) はクラウドベースの IDE で、ブラウザーだけでコードの記述、実行、デバッグを行うことができます。コードエディター、デバッガー、ターミナルが含まれています。Cloud9 IDE はクラウドベースなので、インターネットに接続されたパソコンがあれば、オフィス、自宅など、どこからでもアクセスできて、タボを実施できます。

最高のエクスペリエンスと最小限のセットアップ作業を実現するために、このワークショップの実行には Cloud9 の使用をおすすめします。なぜなら、必要なツールセットがプリインストールされているからです。ローカルでの作業をご希望の場合は、代わりに[ローカル開発セットアップ](/prerequisites/local-development)の手順をご参考ください。

:::alert{type="info"}
ワークショップに **us-east-1 (N. Virginia)** _AWS リージョン_ の使用をお勧めします。
:::

## AWS コンソールから Cloud9 インスタンスを作成

1. [EC2 環境を作成する](https://docs.aws.amazon.com/ja_jp/cloud9/latest/user-guide/create-environment-main.html) ガイドの手順に従って、**AWS コンソール** から Cloud9 インスタンスを作成します。
1. 作成したインスタンスは AWS Cloud9 [環境](https://console.aws.amazon.com/cloud9/home) ページに表示されるはずです。**開く** リンクで環境を開きます。
1. ワークショップの進行中にコマンドを実行するターミナルエリアが下部に表示されます。メインワークエリアでは、コードとテンプレートファイルを開いて編集します。

:::alert{type="info"}
Cloud9 環境の使用に際に問題がある場合は、ユーザーガイドの [AWS Cloud9 のトラブルシューティング](https://docs.aws.amazon.com/ja_jp/cloud9/latest/user-guide/troubleshooting.html) ページを参照してください。
:::

### `git` を使ってラボのリソースをクローン
リポジトリを作業ディレクトリに複製します。Cloud9 のターミナルで以下のコマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
git clone https://github.com/aws-samples/cfn101-workshop
:::

### 最新バージョンの AWS CLI をインストール

Cloud9 インスタンスには [AWS CLI バージョン 1](https://docs.aws.amazon.com/ja_jp/cli/v1/userguide/install-linux-al2017.html) がプリインストールされています。ワークショップでは [AWS CLI バージョン 2](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html) を使用する必要があります。
バージョン 1 からバージョン 2 への [移行](https://docs.aws.amazon.com/cli/latest/userguide/cliv2-migration-instructions.html) を簡単にするにはスクリプトを提供しています。

このスクリプトは以下の作業を行います。
* システムアーキテクチャを確認して、正しいバンドルをダウンロードします。
* AWS CLI バージョン 1 がインストールされているかどうかを確認し、インストールされている場合は削除します。
* AWS CLI バージョン 2 をインストールします。
* インストール用のファイルを削除します。

1. **Cloud9 のターミナル** で `cfn101-workshop/code/solutions/cloud9` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/solutions/cloud9
:::
1. スクリプトを実行可能にします。
:::code{language=shell showLineNumbers=false showCopyAction=true}
chmod +x awscliv2.sh
:::
1. スクリプトを実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
source awscliv2.sh
:::
1. インストールの正常終了を確認できれば、最新バージョンの AWS CLI がインストールされています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws --version
:::

### ワークショップのファイルを開く
作業するテンプレートとコードは、**code** フォルダーにあります。
左側のツリーを展開して、**code** フォルダを開きます。

![toggletree-png](/static/prerequisites/cloud9/toggletree.png)

---

おめでとうございます。これで、ワークショップの開発環境の準備が整いました。
