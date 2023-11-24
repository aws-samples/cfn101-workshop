---
title: "テンプレートとスタック"
weight: 200
---

_ラボ実施時間 : 10分程度_

---

### 概要
このラボでは、1 つの S3 バケットの宣言を含む、`Resources` セクションだけで構成された最も基礎的なテンプレートから始めます。

### カバーするトピック
このラボを完了すると、以下のことができるようになります。
+ [S3](https://aws.amazon.com/jp/s3/) バケットを記述した簡単な CloudFormation テンプレートの作成
+ テンプレートのデプロイと CloudFormation スタックの作成

### ラボの開始

1. `code/workspace/` ディレクトリを開きます。
2. `template-and-stack.yaml` ファイルをコードエディタで開きます。
3. 以下は S3 バケットを定義する CloudFormation テンプレートのサンプルです。S3 バケットを含む単一のリソースを持っています。以下のコードをコピーし、`template-and-stack.yaml` ファイルに追加してください。
   ```yaml
   Resources:
     S3Bucket:
       Type: AWS::S3::Bucket
       Properties:
         BucketEncryption:
           ServerSideEncryptionConfiguration:
             - ServerSideEncryptionByDefault:
                 SSEAlgorithm: AES256
   ```
4. 以下の手順の通りにスタックを作成します。

  :::::tabs{variant="container"}
	::::tab{id="cloud9" label="Cloud9"}
  1. **Cloud9 のターミナル** で `code/workspace` に移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace
  :::
  1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation create-stack --stack-name cfn-workshop-template-and-stack --template-body file://template-and-stack.yaml
  :::
  1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-template-and-stack/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
  1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
  ::::
  ::::tab{id="local" label="ローカル開発"}
  1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
  1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
  1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
  1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
  1. **ファイルの選択** をクリックして、作業ディレクトリに移動します。
  1. `template-and-stack.yaml` ファイルを指定し、**次へ** をクリックします。
  1. **スタックの名前** (例: `cfn-workshop-template-and-stack`) を入力します。
     + _スタック名_ はスタックを識別します。スタックの目的がわかるような名前を使ってください。
     + **次へ** をクリックします。
  1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
  1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
  1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
  ::::
  ::::::

### チャレンジ
この練習問題では、S3 バケットのオブジェクトの誤った削除や上書きを防止したり、バージョニングを有効にします。アーカイブすることで以前のバージョンのオブジェクトを取得できるようになります。

1. S3 リソースの `Properties` セクションに、`VersioningConfiguration` プロパティを追加します。
2. `Status` を `Enabled` に設定します。
3. テンプレートの変更を反映するために、スタックを更新します。

::expand[ [AWS::S3::Bucket](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) リソースの AWS ドキュメントをご確認ください。]{header="ヒントが必要ですか？"}

::::::expand{header="解決策を確認しますか？"}
1. 次のコードで、テンプレートのコードを置き換えてください。
   ```yaml
   Resources:
     S3Bucket:
       Type: AWS::S3::Bucket
       Properties:
         VersioningConfiguration:
           Status: Enabled
         BucketEncryption:
           ServerSideEncryptionConfiguration:
             - ServerSideEncryptionByDefault:
                 SSEAlgorithm: AES256
   ```
1. 次は、以下の手順の通りにスタックを更新します。

  :::::tabs{variant="container"}
	::::tab{id="cloud9" label="Cloud9"}
  1. **Cloud9 のターミナル** で `code/workspace` に移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace
  :::
  1. AWS CLI でスタックを更新します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-template-and-stack --template-body file://template-and-stack.yaml
  :::
  1. `update-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-template-and-stack/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
  1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
  ::::
  ::::tab{id="local" label="ローカル開発"}
  1. **[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** を新しいタブで開き、必要に応じて AWS アカウントにログインします。
  1. スタック名 (例: `cfn-workshop-template-and-stack`) を選択します。
  1. 画面右上の **更新** ボタンをクリックします。
  1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
  1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
  1. **ファイルの選択** ボタンをクリックし、ワークショップのディレクトリに移動します。
  1. `code/workspace/template-and-stack.yaml` ファイルを指定し、**次へ** をクリックします。
  1. **スタックの詳細を指定** では **次へ** をクリックします。
  1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
  1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**変更セットのプレビュー** の内容が表示されることをしばらく待ち、**送信** をクリックします。
  1. スタックが **UPDATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
  ::::
  :::::
::::::

### クリーンアップ

次のステップに従って、作成したリソースを削除してください。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動します。
1. CloudFormation の **スタック** ページで `cfn-workshop-template-and-stack` を選択します。
1. スタックの詳細で **削除** を選択し、ポップアップ上で **削除** で確定します。
1. スタックが **DELETE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。

---

### まとめ

おめでとうございます！ これで最初の CloudFormation テンプレートと最初のスタックの作成ができました。
