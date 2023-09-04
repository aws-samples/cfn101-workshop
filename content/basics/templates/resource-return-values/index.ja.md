---
title: "戻り値の特定"
weight: 800
---

### 概要
[AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) を使って、テンプレートによってリソースをプログラムで表現することができます。そうした場合、リソースを構成するために、同じテンプレートで定義されている特定のリソースの戻り値の参照が必要な場合があります。

テンプレートの`出力`[セクション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)で特定のリソースの戻り値を表示することもできます。その場合、出力値を[エクスポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html)することで、同じリージョンの他のスタックから参照可能にすることもできます。

### カバーするトピック
このラボの完了までに次のことができるようになります。

* 戻り値の使い方について理解します。
* リソースタイプに応じて、戻り値を特定する方法を学びます。
* 戻り値を使うときの `Ref`、`Fn::GetAtt`、`Fn::Sub` の[組み込み関数の](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) 違いを理解します。

戻り値については、リソースタイプ毎に [AWS リソースおよびプロパティタイプのリファレンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)に記載されています。任意のリソースタイプをリストから選び、ページの右側の **Return values** から `Ref` や `Fn::GetAtt` の[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)でどの値が利用可能かを見ることができます。

[Amazon Simple Storage Service](https://aws.amazon.com/jp/s3/) (Amazon S3) バケットのリソースタイプ `AWS::S3::Bucket` を例として見てみましょう。[AWS リソースおよびプロパティタイプのリファレンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)のリストから **Amazon S3** を選びます。次のページで **AWS::S3::Bucket** を選び、このリソースタイプのリファレンスドキュメントを見ます。ページ右側の **Return values** から `AWS::S3::Bucket` リソースタイプで使用可能な戻り値を見ることができます。

ドキュメントにて、`Ref` や `Fn::GetAtt` の組み込み関数を使う場合に、どのような値が利用可能で返ってくるかを確認しましょう。例えば、バケット名を参照したい場合、バケットリソースの `Ref` に [論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) を指定することで参照できます。もしバケットの [Amazon リソースネーム](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) (ARN) を取得したい場合は、`Fn::GetAtt` を `Arn` 属性と一緒にすることで取得できます。

このラボでは、テンプレートで与えられているリソースタイプから、同じテンプレートにある別のリソースタイプの戻り値を参照する方法について学びます。

### ラボの開始
* `code/workspace/resource-return-values` ディレクトリへ移動します。
* `resource-return-values.yaml` ファイルを開きます。
* ラボの以下のトピックを進みながら、コードをコピーしていきます。

このラボでは、次のことを実施します。
* １つのリソースのから同じテンプレート内の他のリソースの戻り値を活用する方法について学びます。
* `Ref`、`Fn::GetAtt`、`Fn::Sub` の[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)を使って、リソースの戻り値を活用して、どのようにスタックの出力値を定義するかを学びます。

::alert[次の例では、Amazon S3 バケット名を表す `BucketName` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#cfn-s3-bucket-name) を定義していません。この場合、CloudFormation はリソースに一意の名前を生成します。]{type="info"}

次で例のバケットポリシーでは、リクエストが `aws:SecureTransport: false` の条件に当てはまる場合に Amazon S3 へのアクセスを拒否します。次のポリシーは、リクエストが HTTPS の代わりに HTTP で行われたときに `Deny` の効果を持ちます。

次のサンプルのテンプレートスニペットをコピーして `resource-return-values.yaml` ファイルに追記してください。

```yaml
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Purpose
          Value: AWS CloudFormation Workshop

  S3BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref S3Bucket
      PolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Action:
              - s3:*
            Effect: Deny
            Resource:
              - !GetAtt S3Bucket.Arn
              - !Sub '${S3Bucket.Arn}/*'
            Principal: '*'
            Condition:
              Bool:
                aws:SecureTransport: false

Outputs:
  S3BucketDomainName:
    Description: IPv4 DNS name of the bucket.
    Value: !GetAtt S3Bucket.DomainName
```

テンプレートに貼り付けたテンプレートスニペットには Amazon S3 [バケット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) とバケット[ポリシー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-policy.html)の 2 つのリソースがあります。次に解説します。

* バケットリソースの[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) (つまり `S3Bucket`) は、`S3BucketPolicy` リソースの `Bucket` プロパティで `Ref` 組み込み関数で参照されています。`Bucket` プロパティはポリシーを適用する Amazon S3 バケットの名前が必要です。バケットリソースの論理 ID を `Ref` 関数で指定した場合、バケットリソースはバケット名を返します。詳細は、Amazon S3 バケットの [戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values) を参照してください。
* `S3BucketPolicy` リソースの `PolicyDocument` プロパティの `Resource` セクションはバケットの  [Amazon リソースネーム](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) (ARN) が必要です。そして、`AWS::S3::Bucket` リソースタイプは、`Fn::GetAtt` 組み込み関数をバケットの論理 ID と `Arn` 属性を使うことでバケットの ARN を返します。
* Amazon S3 バケットの [戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values)を参照してください。`AWS::S3::Bucket` リソースタイプには `Fn::GetAtt` 組み込み関数と共に必要な属性を指定することで返される多くの値があります。例えば、上述のテンプレートスニペットの `Outputs` [セクション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) の `S3BucketDomainName` の出力値を見てください。ここでは、テンプレートに記述されたバケットの DNS 名を出力することを意味しています。バケットの IPv4 DNS 名は `Fn::GetAtt` 組み込み関数に対し、バケットリソースの論理 ID と `DomainName` 属性を指定することで取得できます。
* ここで、`S3BucketPolicy` リソースの `PolicyDocument` プロパティの `Resource` 属性で使われた `Fn::Sub` 組み込み関数について議論します。`Fn::Sub` 組み込み関数は、`Ref` と `Fn::GetAtt` が特定のリソースに対し論理 ID と戻り値の属性という同じ形式を使って、返す値を取得するのに使うことができます。`Fn::Sub` を戻り値と一緒に使う主目的は、文字列と戻り値を結合することです。上記の例では、`Fn::Sub` を `/*` と戻り値のバケット ARN と結合するために使っています。バケット ARN の最後に `/*` を足す理由は、ポリシーで定義されているアクションがバケット内のすべてのオブジェクトに適用されることを確実にすることです。

それでは、`resource-return-values.yaml` テンプレートを使ってスタックを作成し、ここまで説明してきた動作を実際に見ていきます。

1. **[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動します。
1. **スタックの作成** から、_新しいリソースを使用 (標準)_ をクリックします。
1. **テンプレートの準備完了** を選びます。**テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。`resource-return-values.yaml` をアップロードし、**次へ** を選択します。
1. **スタックの名前** (例: **resource-return-values**) を入力し、準備ができたら **次へ**を選択します。
1. **スタックオプションの設定** はデフォルトの設定のままとし、ページの下部までスクロールし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**スタックの作成** をクリックします。

スタックのステータスが `CREATE_COMPLETE` になるまで、ページをリフレッシュします。それでは、スタックイベントと出力値を見ていきます。スタックイベントは次の画像のようになっているはずです。

![resource-return-values.png](/static/basics/templates/resource-return-values/resource-return-values.ja.png)

スタックイベントを見ていると、バケットとバケットポリシーが無事に作られていることがわかります。ここで、スタックの**リソース**タブに移動して `S3Bucket` の物理 ID を見つけ、リンクをクリックしてください。[Amazon S3 コンソール](https://console.aws.amazon.com/s3/)のバケットの詳細ページに移動できます。次に、バケットのページで**アクセス許可**を選び**バケットポリシー**セクションのバケットポリシーを確認してください。バケットポリシーの `Resource` セクションで戻り値がどのように置換されているかを見てください。次に、AWS CloudFormation コンソールのスタックの**出力**タブに移動し、表示されているスタックで作成した Amazon S3 バケットの IPv4 DNS 名を確認してください。

おめでとうございます！これで特定のリソースの戻り値を見つける方法と、それらを他のリソースで `Ref`、`Fn::GetAtt`、`Fn::Sub` の[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)で使う方法を学びました。

### チャレンジ
このチャレンジでは、既存の Amazon EC2 [インスタンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html)と [セキュリティグループ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html)が記述されたテンプレートを更新することがタスクになります。Amazon EC2 インスタンスリソースの `SecurityGroups` プロパティでセキュリティグループの論理 ID を参照することになります。また、テンプレートの `Outputs` セクションを更新し、次の値を出力することになります。

* スタックで作成された Amazon EC2 インスタンスのインスタンス ID
* 作成された Amazon EC2 インスタンスのパブリック IP
* スタックで作成されたセキュリティグループの ID

初めに、`code/workspace/resource-return-values` ディレクトリ内の `resource-return-values-challenge.yaml` テンプレートをお好みのエディタで開いてください。上記のサンプルの要件に従い、テンプレートを適切に更新してください。

準備ができたら、更新した `resource-return-values-challenge.yaml` テンプレートで `resource-return-values-challenge` と呼ばれる新しいスタックを作成し、要件を満たしているかを確認してください。

:::expand{header="ヒントが必要ですか？"}
* Amazon EC2 インスタンスの `SecurityGroups` プロパティでセキュリティグループをどのように[参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)できるでしょうか？
* セキュリティグループを参照する際、`SecurityGroups` プロパティの `Type` の値が *List of String* であることに気をつけてください。YAML 形式でどのように表現するでしょうか？
* Amazon EC2 インスタンスの[戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values) とセキュリティグループの[戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-return-values)を確認し、`Ref` や `Fn::GetAtt` の[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)でどのような値が返るかを見てください。
:::

:::expand{header="解決策を確認しますか？"}
* `Ref` 組み込み関数を使って、インスタンスリソースの `SecurityGroups` プロパティにセキュリティグループの論理 ID をリストアイテムとして指定してください。
* Amazon EC2 インスタンスリソースを次の定義のように修正してください。

```yaml
Ec2Instance:
  Type: AWS::EC2::Instance
  Properties:
    ImageId: !Ref LatestAmiId
    InstanceType: t2.micro
    SecurityGroups:
      - !Ref InstanceSecurityGroup
    Tags:
      - Key: Name
        Value: Resource-return-values-workshop
```

* `Ref` 組み込み関数を使い、インスタンス ID を取得するために Amazon EC2 インスタンスリソースの論理 ID を渡してください。同様にインスタンスのパブリック IP を取得するために、Amazon EC2 インスタンスリソースの論理 ID と `PublicIp` 属性を `Fn::GetAtt` 関数に渡します。
* セキュリティグループの ID を取得するために、セキュリティグループリソースの論理 ID と `GroupId` 属性を `Fn::GetAtt` 関数に渡します。
* テンプレートの `Outputs` セクションを次のように修正します。

```yaml
Outputs:
  InstanceID:
    Description: The ID of the launched instance
    Value: !Ref Ec2Instance

  PublicIP:
    Description: Public IP of the launched instance
    Value: !GetAtt Ec2Instance.PublicIp

  SecurityGroupId:
    Description: ID of the security group created
    Value: !GetAtt InstanceSecurityGroup.GroupId
```
:::

このチャレンジの完全な解答は `code/solutions/resource-return-values/resource-return-values-challenge.yaml` テンプレートにあります。

### クリーンアップ
次のステップに従って、このラボの各パートで作成した[スタックを削除](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html)してください。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動してください。
2. CloudFormation コンソールの **スタック**ページで、`resource-return-values` を選択してください。
3. 詳細ページでスタックを削除するため **削除** を選択し、ポップアップで **削除** を選択してください。
4. 同様の手順で　`resource-return-values-challenge` スタックを削除してください。

---
### まとめ
すばらしいです！これで特定のリソースの戻り値を見つける方法と、それらを他のリソースで `Ref`、`Fn::GetAtt`、`Fn::Sub` の[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)で使う方法を学びました。
