---
title: "AWS CLI のインストールと設定"
weight: 200
---

[AWS CLI](https://aws.amazon.com/cli/) によって、ターミナルのセッションから AWS のサービスを操作することができます。必ず最新版の AWS CLI がインストールされていることをご確認ください。

[AWS CLI の最新バージョンをインストールまたは更新します。](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) ページで自分のオペレーティングシステムに合う手順を確認できます。

## 認証情報の設定

ターミナルを開き、`aws configure` を実行して、環境を設定します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws configure
:::

[前のステップ](/prerequisites/account)で作成した **アクセスキー ID** と **シークレットアクセスキー** を入力し、デフォルトのAWS リージョン (例えば `ap-northeast-1`) を入力します。できれば、まだリソースが作成されていないリージョンが望ましいです。

:::code{language=shell showLineNumbers=false showCopyAction=false}
AWS Access Key ID [None]: <アクセスキー ID を入力>
AWS Secret Access Key [None]: <シークレットアクセスキーを入力>
Default region name [None]: <リージョンを入力 (e.g. "us-east-1", "ap-northeast-1")>
Default output format [None]: <空欄で結構>
:::
