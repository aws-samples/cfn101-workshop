---
title: "マルチリージョンの最新の AMI"
weight: 100
---

_ラボ実施時間 : 10分程度_

---

### 概要
現在のテンプレートをさまざまなリージョンにデプロイするユースケースを考えてみましょう。各 AWS リージョンの AMI ID と一致するために、 手動で `AmiId` を変更する必要があります。同じく、Amazon Machine Image にアップデートがある場合、最新のイメージを使用するために、同じ手動処理が発生します。

これを解決するには、CloudFormation テンプレートの既存の _Parameters_ セクションを使用して、System Manager パラメータータイプを定義します。Systems Manager パラメータタイプを使用すると、Systems Manager Parameter Store に保持されているパラメータを参照できます。

### カバーするトピック
このラボでは、次のことを学びます。

+ CloudFormation で **[AWS Systems Manager Parameter Store](https://aws.amazon.com/jp/blogs/news/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/)** から最新の Amazon Linux AMI ID を取得する方法。

### ラボの開始

1. `code/workspace` ディレクトリに移動します。
1. `multi-region-latest-ami.yaml` ファイルを開きます。
1. `AmiID` パラメータを次のように更新します。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
AmiID:
   Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
   Description: The ID of the AMI.
   Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'
:::

AWS コンソールに移動し、新しいテンプレートでスタックを更新します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-multi-region-latest-ami \
--template-body file://multi-region-latest-ami.yaml
:::
1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-multi-region-latest-ami/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。
::::
::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** をクリックして、作業ディレクトリに移動します。
1. `multi-region-latest-ami.yaml` ファイルを指定し、**次へ** をクリックします。
1. **スタックの名前** (例: `cfn-workshop-multi-region-latest-ami`) を入力し、**次へ** をクリックします。
1. **Amazon Machine Image ID** には `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2` をコピーします。
1. **EnvironmentType** にはドロップダウンから環境の種類を選択します。例えば **Test** を選択して、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::
:::::

### チャレンジ
使用していたものとは別のAWSリージョンにテンプレートをデプロイします。

::::::expand{header="解決策を確認しますか？"}
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。`--region` パラメータは最初にスタックを作成したリージョン以外のリージョンを指定します。例えば、最初に `us-east-1` で作成されていたら、 `us-east-2` を指定します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-multi-region-latest-ami \
--template-body file://multi-region-latest-ami.yaml \
--region us-east-2
:::
1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-2:123456789012:stack/cfn-workshop-multi-region-latest-ami/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。
::::
::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. 画面右上のリージョン名 (例: **バージニア北部**) をクリックし、別のリージョンを選択します。
1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** をクリックして、作業ディレクトリに移動します。
1. `multi-region-latest-ami.yaml` ファイルを指定し、**次へ** をクリックします。
1. **スタックの名前** (例: `cfn-workshop-multi-region-latest-ami`) を入力し、**次へ** をクリックします。
1. **Amazon Machine Image ID** には `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2` をコピペします。
1. **EnvironmentType** にはドロップダウンから環境の種類を選択します。例えば **Test** を選択して、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::
:::::
:::alert{type="info"}
AMI ID パラメータを更新する必要がなかったことに注意してください。Systems Manager Parameter Store を利用し CloudFormation をインテグレーションすることで、テンプレートがより汎用的で再利用可能になりました。
:::
::::::

### クリーンアップ
以下の手順の通りに、このラボで作成した [スタックの削除](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html) を行ってください。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動します。
1. CloudFormation の **スタック** ページで `cfn-workshop-multi-region-latest-ami` を選択します。
1. スタックの詳細で **削除** を選択し、ポップアップ上で **削除** で確定します。
1. CloudFormation のスタックを作成した全てのリージョンで上記の手順を切り返します。

---
### まとめ

おめでとうございます！これで、最新の Amazon Linux AMI を使用するようにテンプレートを正常に更新できました。さらに、テンプレートは、AMI ID パラメータを追加しなくても、どのリージョンにもデプロイできるようになりました。
