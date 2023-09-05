---
title: "マルチリージョンの最新の AMI"
weight: 100
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

```yaml
   AmiID:
      Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
      Description: The ID of the AMI.
      Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'
```

AWS コンソールに移動し、新しいテンプレートでスタックを更新します。

1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例: **cfn-workshop-ec2**) をクリックします。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
1. ステップ1で作成した `multi-region-latest-ami.yaml` を指定し、**次へ** をクリックします。
1. **Amazon Machine Image ID** には `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2` をコピーアンドペーストしてください。
1. **EnvironmentType** には、リストされているものとは異なる環境を選択します。たとえば、**Dev** が選択されている場合は、**Test** を選択し、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
1. ステータスが **UPDATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックします。

### チャレンジ
使用していたものとは別のAWSリージョンにテンプレートをデプロイします。

::expand[コンソールの右上のリージョンをクリックして、別のリージョンを選択します。]{header="解決策を確認しますか？"}

:::alert{type="info"}
AMI ID パラメータを更新する必要がなかったことに注意してください。クラウドフォーメーションとシステムとのインテグレーションを利用することで
Manager Parameter Store では、テンプレートがより汎用的で再利用可能になりました。
:::

---
### まとめ

おめでとうございます！これで、最新の Amazon Linux AMI を使用するようにテンプレートが正常に更新できました。さらに、テンプレートは、AMI ID パラメータを追加しなくても、どのリージョンにもデプロイできるようになりました。
