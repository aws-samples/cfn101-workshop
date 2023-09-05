---
title: "テンプレートとスタック"
weight: 200
---

### 概要
このラボでは、1 つの S3 バケットの宣言を含む、Resources セクションだけで構成された最も基礎的なテンプレートから始めます。

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
4. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、AWS アカウントにログインします。
5. **スタックの作成** をクリックします。 (画面右上をクリックした場合、_新しいリソースを使用 (標準)_ をクリックしてください。)
6. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
7. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
8. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
9. ステップ 1で作成した `template-and-stack.yaml` を指定します。
10. **次へ** をクリックします。
11. **スタックの名前** (例: **cfn-workshop-s3**) を入力します。
     + _スタック名_ はスタックを識別します。スタックの目的がわかるような名前を使ってください。
     + **次へ** をクリックします。
12. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
13. **レビュー <スタック名>** のページで、ページの下までスクロールし、**スタックの作成** をクリックします。
14. ステータスが **CREATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックできます。

### チャレンジ
この練習問題では、S3 バケットのバージョニングを有効にします。バージョニングを有効にすることにより、誤った削除や上書きを防止したり、アーカイブすることで以前のバージョンのオブジェクトを取得したりできるようになります。

1. S3 リソースの `Properties` セクションに、 `VersioningConfiguration` プロパティを追加します。
2. `Status` を `Enabled` に設定します。
3. テンプレートの変更を反映するために、スタックを更新します。

::expand[ [AWS::S3::Bucket](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) リソースの AWS ドキュメントをご確認ください。]{header="ヒントが必要ですか？"}

:::expand{header="解決策を確認しますか？"}
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
1. 次のデモのように、スタックを更新します。

   1. **[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** を新しいタブで開き、必要に応じて AWS アカウントにログインします。
   1. スタック名 (例: **cfn-workshop-s3**) を選択します。
   1. 画面右上の **更新** ボタンをクリックします。
   1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
   1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
   1. **ファイルの選択** ボタンをクリックし、ワークショップのディレクトリに移動します。
   1. `code/workspace/template-and-stack.yaml` ファイルを指定し、**次へ** をクリックします。
   1. **スタックの詳細を指定** では **次へ** をクリックします。
   1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
   1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**変更セットのプレビュー** の内容が表示されることをしばらく待ち、**送信** をクリックします。
   1. ステータスが **UPDATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックします。
:::

### クリーンアップ

次のステップに従って、作成したリソースを削除してください。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** で、このラボで作成したスタック (例: `cfn-workshop-s3`) を選択してください。
1. 画面の右上から **削除** をクリックしてください。
1. ポップアップウィンドウで、**削除** をクリックします。
1. ステータスが **DELETE_COMPLETE** になるまで **リフレッシュ** ボタンを数回クリックできます。

---

### まとめ

おめでとうございます！ これで最初の CloudFormation テンプレートと最初のスタックの作成ができました。
