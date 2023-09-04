---
title: "出力"
weight: 700
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

5. AWS コンソールに移動し、新しいテンプレートでスタックを更新します。

6.  [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)の _出力_ タブから出力値を確認します。

### チャレンジ

この練習問題では、Elastic IP リソースを作成し、EC2 インスタンスにアタッチします。そして、Elastic IP の出力値をテンプレートの _Outputs_ セクションに追加します。
引き続き、`outputs.yaml` テンプレートを使用してください。

1. `AWS::EC2::EIP` リソースを作成し、既存の EC2 インスタンスにアタッチしてください。
1. `ElasticIP` と呼ばれる論理 ID を作成し、テンプレートの Outputs セクションに追加してください。
1. テンプレートの変更をテストするために、スタックを更新してください。

::expand[[AWS::EC2::EIP リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-eip.html) の AWS ドキュメントを確認してください。]{header="ヒントが必要ですか？"}

:::expand{header="解決策を確認しますか？"}
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
:::

---
### まとめ

すばらしいです！これで CloudFormation テンプレートで **出力** を使う方法を学ぶことができました。
