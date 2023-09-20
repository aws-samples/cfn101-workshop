---
title: "出力"
weight: 700
---

_ラボ実施時間 : 10分程度_

---

### 概要

このラボでは、**[出力](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)** について学びます。_出力_ はスタック内のリソースの情報にアクセス可能にするセクションです。例えば、作成された EC2 インスタンスのパブリック DNS 名を出力することができます。

さらに、出力値は他のスタックにインポートできます。クロススタック参照と呼びます。

##### YAML 形式:
_出力_ のセクションは `Outputs` のキー名とコロンから始まります。

:::code{language=yaml showLineNumbers=false showCopyAction=false}
Outputs:
  Logical ID:
    Description: Information about the value
    Value: Value to return
    Export:
      Name: Value to export
:::

::alert[1 つのテンプレートで使用できる出力値の最大数については、[AWS CloudFormation のクォータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html)の出力の欄を参照してください。]{type="info"}

### カバーするトピック
このラボでは、次のことを実施します。

+ Output セクションをテンプレートに作成し、インスタンスのパブリック DNS 名を出力します。
+ Elastic IP リソースを作成し、EC2 インスタンスにアタッチします。
+ AWS コンソールの CloudFormation で出力値をどのように見るかを学びます。

### ラボの開始

1. `code/workspace/` ディレクトリへ移動します。
1. `outputs.yaml` ファイルを開きます。
1. 以下のトピックを進みながら、コードをコピーしていきます。\
インスタンスの _PublicDnsName_ を取得するには、`Fn::GetAtt` 組み込み関数を使う必要があります。
1. まずは使用可能な属性について、[AWS ドキュメント](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values) を確認しましょう。_PublicDnsName_ は `Fn::GetAtt` で入手できるプロパティであることを確認できます。

    以下のセクションをテンプレートに追加してください。
    ```yaml
    Outputs:
      EC2PublicDNS:
        Description: 'Public DNS of EC2 instance'
        Value: !GetAtt WebServerInstance.PublicDnsName
    ```

1. この新しいテンプレートでスタックを作成します。

    :::::tabs{variant="container"}
    ::::tab{id="cloud9" label="Cloud9"}
    1. **Cloud9 のターミナル** で `code/workspace` に移動します。
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    cd cfn101-workshop/code/workspace
    :::
    1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。`ParameterValue` の **MyAmiId** 値を先ほど `resources.yaml` で記載した値に置き換えます。
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws cloudformation create-stack --stack-name cfn-workshop-outputs --template-body file://outputs.yaml --parameters ParameterKey="AmiID",ParameterValue="MyAmiId"
    :::
    1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
    :::code{language=shell showLineNumbers=false showCopyAction=false}
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-outputs/739fafa0-e4d7-11ed-a000-12d9009553ff"
    :::
    1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
    ::::
    ::::tab{id="local" label="ローカル開発"}
    1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
    1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
    1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
    1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
    1. **ファイルの選択** をクリックして、作業ディレクトリに移動します。
    1. `outputs.yaml` ファイルを指定し、**次へ** をクリックします。
    1. **スタックの名前** (例: `cfn-workshop-outputs`) を入力し、**次へ** をクリックします。
    1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
    1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
    1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
    ::::
    :::::

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)の _出力_ タブから出力値を確認します。

### チャレンジ

この練習問題では、Elastic IP リソースを作成し、EC2 インスタンスにアタッチします。そして、Elastic IP の出力値をテンプレートの _Outputs_ セクションに追加します。
引き続き、`outputs.yaml` テンプレートを使用してください。

1. `AWS::EC2::EIP` リソースを作成し、既存の EC2 インスタンスにアタッチしてください。
1. `ElasticIP` と呼ばれる論理 ID を作成し、テンプレートの Outputs セクションに追加してください。
1. テンプレートの変更をテストするために、スタックを更新してください。

::expand[[AWS::EC2::EIP リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-eip.html) の AWS ドキュメントを確認してください。]{header="ヒントが必要ですか？"}

::::::expand{header="解決策を確認しますか？"}
  ```yaml
  Resources:
    WebServerInstance:
      Type: AWS::EC2::Instance
      Properties:
        ImageId: !Ref AmiID
        InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
        Tags:
          - Key: Name
            Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]

    WebServerEIP:
      Type: 'AWS::EC2::EIP'
      Properties:
        Domain: vpc
        InstanceId: !Ref WebServerInstance

  Outputs:
    WebServerPublicDNS:
      Description: 'Public DNS of EC2 instance'
      Value: !GetAtt WebServerInstance.PublicDnsName

    WebServerElasticIP:
      Description: 'Elastic IP assigned to EC2'
      Value: !Ref WebServerEIP
  ```
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace
  :::
1. AWS CLI でスタックを更新します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。`ParameterValue` の **MyAmiId** 値を先ほど `resources.yaml` で記載した値に置き換えます。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-outputs --template-body file://outputs.yaml --parameters ParameterKey="AmiID",ParameterValue="MyAmiId"
  :::
1. `update-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-outputs/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)の _出力_ タブから出力値を確認します。
::::
::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例: `cfn-workshop-outputs`) をクリックします。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** をクリックし、作業用ディレクトリに移動します。
1. `outputs.yaml` を指定し、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** ページで、一番下までスクロールし、**送信** をクリックします。
1. スタックが **UPDATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)の _出力_ タブから出力値を確認します。
::::
:::::
::::::

### クリーンアップ

以下の手順で作成したリソースの削除を行います。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動します。
1. CloudFormation の **スタック** ページで `cfn-workshop-outputs` を選択します。
1. スタックの詳細で **削除** を選択し、ポップアップ上で **削除** で確定します。
1. スタックが **DELETE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。

---

### まとめ

すばらしいです！これで CloudFormation テンプレートで **出力** を使う方法を学ぶことができました。
