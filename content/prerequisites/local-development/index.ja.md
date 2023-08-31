---
title: "ローカル開発の設定"
weight: 300
---

_セットアップ時間 : 15分程度_

:::alert{type="info"}
こちらの手順は、ワークショップで Cloud9 IDE を使用していない場合にのみ必要です。
:::

このワークショップのローカル開発を行うには、いくつかの開発ツールが必要です。ワークショップを続行する前に、それらのツールインストールして、正しくインストールされていることを確認してください。

### AWS CLI のインストール

[AWS CLI](https://aws.amazon.com/jp/cli/) を使用すると、ターミナルセッションから AWS のサービスとやり取りができます。システムに AWS CLI の最新バージョンがインストールされていることを確認してください。

[AWS CLI の最新バージョンを使用してインストールまたは更新を行う](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html) にてご使用のオペレーティングシステムのインストール手順のページをご参照ください。

### 認証情報の設定

ターミナルウィンドウを開き、`aws configure` を実行して環境を設定します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws configure
:::

[前のステップ](/prerequisites/account) で作成した **access key ID** と **secret key** を入力し、デフォルトのリージョン (たとえば `us-east-1`) を指定します。できれば、リソースがまだデプロイされていないリージョンの使用をお勧めします。

:::code{language=shell showLineNumbers=false showCopyAction=false}
AWS Access Key ID [None]: <ここに access key ID を入力>
AWS Secret Access Key [None]: <ここに secret key を入力>
Default region name [None]: <AWS リージョン ID を入力 (例 : "us-east-1", "eu-west-1")>
Default output format [None]: <空白で大丈夫>
:::

### `git` を使ってラボのリソースをクローン

リポジトリを作業ディレクトリにクローンします。

:::code{language=shell showLineNumbers=false showCopyAction=true}
git clone https://github.com/aws-samples/cfn101-workshop
:::

### コードエディタのインストール

[YAML](https://yaml.org/) の編集をサポートしている任意のコードエディターまたは IDE を使用できますが、このワークショップでは macOS、Linux、および Windows で動作する [Visual Studio Code](https://code.visualstudio.com/) の使用を前提としています。

VS Code をインストールするには、オペレーティングシステムのパッケージマネージャーを使用するか (例 : macOS では `brew cask install visual-studio-code`)、[VS code の Web サイト](https://code.visualstudio.com/) の説明に従ってインストールしてください。

### CloudFormation リンター

[AWS CloudFormation Linter](https://github.com/aws-cloudformation/cfn-lint) のインストールをお勧めします。
[linter](https://en.wikipedia.org/wiki/Lint_(software)) は、CloudFormation テンプレートをデプロイする前に、テンプレートの基本的なエラーを事前に検出してくれます。

Visual Studio Code を使用している場合は、[cfn-lint](https://marketplace.visualstudio.com/items?itemName=kddejong.vscode-cfn-lint) プラグインをインストールする必要があります。

:::alert{type="info"}
Visual Studio Code の `cfn-lint` プラグインをインストールしても、`cfn-lint` が自動的にインストールされないことにご注意ください。[インストール手順](https://github.com/aws-cloudformation/cfn-lint#install) に従って個別にインストールしてください。
:::

### ワークショップのファイルを開く

作業するテンプレートとコードは、**code** フォルダーにあります。
ダウンロードしたファイルから **code** セクションをコードエディターで開きます。

![vscode-png](/static/prerequisites/local-development/vscode.png)
