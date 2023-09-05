---
title: "スタックリソースの更新動作"
weight: 100
---

### 概要
このラボでは、インフラストラクチャの設計および更新への対応方法に関する重要なポイントを学びます。アプリケーションと環境が進化するにつれて、テンプレートに記述されているリソース構成に更新を適用します。

CloudFormation は、変更が適用されたテンプレートと、以前のバージョンのテンプレートで記述したリソース構成との変更を比較することによってリソースを更新します。変更されていないリソース構成は、更新プロセス中も影響を受けません。それ以外の場合、CloudFormation は次のいずれかの[更新動作](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html)を使用します。**中断を伴わない更新**、**一時的な中断を伴う更新**、**置換**の各更新動作は、特定の[リソースタイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)に従い、テンプレートに追加する新しいプロパティや、変更するプロパティ値によって決まります。

### 対象トピック
このラボを修了すると、次のことができるようになります。

* スタックリソースの更新動作を学びます。
* 更新動作がプロビジョニングされたスタックリソースにどのように影響するかについての重要な考慮事項について学びます。

**ラボを開始**
* `code/workspace/update-behaviors-of-stack-resources` ディレクトリに移動します。
* お好みのテキストエディタで `update-behaviors-of-stack-resources.yaml` ファイルを開きます。
* ラボを進めながら、コンテンツをコピーしてファイルに追加します。

テンプレートに [Amazon Elastic Compute Cloud](https://aws.amazon.com/jp/ec2/)(Amazon EC2) インスタンスを記述することから始めましょう。`update-behaviors-of-stack-resources.yaml` テンプレートに以下の `Paramaters` セクションをコピーして追加します。

```yaml
Parameters:
  InstanceType:
    Description: WebServer EC2 instance type
    Type: String
    Default: t2.micro
    AllowedValues: [t2.micro, t2.small, t2.medium]
    ConstraintDescription: must be a valid EC2 instance type.
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
```

次に、`Resources` セクションと Amazon EC2 インスタンス定義をコピーしてテンプレートに追加します。

```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: !Ref LatestAmiId
      Tags:
        - Key: Name
          Value: cfn-workshop
```


変更をファイルに保存します。次に、`update-behaviors-of-stack-resources.yaml` テンプレートを使用してスタックを作成します。

1. [AWS CloudFormationコンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. 使用したい[リージョン](https://docs.aws.amazon.com/ja_jp/awsconsolehelpdocs/latest/gsg/select-region.html)を選択します。
3. **スタックの作成**、**新しいリソースを使用 (標準)** を選択します。
4. **テンプレートの準備**セクションで、**テンプレートの準備完了**を選択します。
5. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。前述の`update-behaviors-of-stack-resources.yaml` テンプレートを選択し、**次へ**をクリックします。
6. スタック名を指定します。例えば、`cfn-workshop-update-behaviors-of-stack-resources` と入力します。`InstanceType` パラメータと `LatestAmiID` パラメータのデフォルト値をそのまま使用し、**次へ**をクリックします。
7. **スタックオプションの設定**ページはデフォルト値のまま、**次へ**をクリックします。
8. **レビュー**ページで一番下までスクロールし、**送信**をクリックします。
9. スタックの作成が完了するまでお待ちください。スタックのステータスが `CREATE_COMPLETE` になるまで、コンソールのビューを更新します。


**置換**

ここまで、スタックを使用して Amazon EC2 インスタンスを作成しました。インスタンスの [Amazon Machine Image](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/AMIs.html) (AMI) には、このラボで最新の `x86-64` Amazon Linux 2 AMI を使用しました。次に、Amazon EC2 インスタンスに別の AMI を使用する必要があるシナリオを考えてみましょう。このラボでは、前に作成した CloudFormation スタック`cfn-workshop-update-behaviors-of-stack-resources` を更新し、`LatestAmiId` のパラメータ値を `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs` でオーバーライドします。

::alert[リソースのプロパティ値を変更するときは、必ずドキュメント内の特定のリソースプロパティの [Update requires](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-imageid)の値を確認してください。この場合、`ImageID` プロパティの値を更新すると、リソース[置換 (Replacement)](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement) 動作が実行されます。]{type="info"}

いよいよスタックを更新しましょう！[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動し、`cfn-workshop-update-behaviors-of-stack-resources` スタックを更新します。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. `cfn-workshop-update-behaviors-of-stack-resources` スタックを作成した[リージョン](https://docs.aws.amazon.com/ja_jp/awsconsolehelpdocs/latest/gsg/select-region.html)を必ず選択してください。
3. 先ほど作成したスタック (例えば、`cfn-workshop-update-behaviors-of-stack-resources`) を選択します。
4. **更新**を選択します。
5. **テンプレートの準備**で**現在のテンプレートの使用**を選択し、**次へ**をクリックします。
6. **パラメータ**ページで、`InstanceType`のデフォルト値をそのまま使用し、`LatestAmiID` パラメータの既存の値を `/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-ebs` という新しい値に置き換えます。準備ができたら、**次へ**をクリックします。
7. **スタックオプションの設定**ページでデフォルト値のまま、**次へ**をクリックします。
8. **レビュー**ページで一番下までスクロールし、**送信**を選択します。

スタックの更新中に、[Amazon EC2 コンソール](https://console.aws.amazon.com/ec2/)に移動し、**インスタンス**を選択します。新しいインスタンスが起動され、このラボで以前に作成したインスタンスが終了することを確認できます。上記で行った AMI の変更によるスタック更新を実施すると、CloudFormation は最初に新しいインスタンスを作成し、前のインスタンスを削除しました。この例では、**置換**動作を示しています。

おめでとうございます！ **置換**動作を学習しました。


**一時的な中断を伴う更新**


ワークロードの要件が変わり、CPU とメモリの要件に合わせて新しい [Amazon EC2](https://aws.amazon.com/jp/ec2/instance-types/) インスタンスタイプが必要だと判断した例を見てみましょう。例えば、`cfn-workshop-update-behaviors-of-stack-resources` スタックで管理するインスタンスのタイプを、`t2.micro` から `t2.small` に変更します。

::alert[インスタンスの `InstanceType` プロパティ値を変更する場合、まず [Update requires](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype) で説明されている動作を確認し、スタックを更新するとどうなるのかを理解する必要があります。]{type="info"}

さっそくスタックを更新しましょう:

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. `cfn-workshop-update-behaviors-of-stack-resources` スタックを作成した[リージョン](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html)を必ず選択してください。
3. 先ほど作成したスタック (例えば、`cfn-workshop-update-behaviors-of-stack-resources`) を選択します。
4. **更新**を選択します。
5. **テンプレートの準備**で**現在のテンプレートの使用**を選択し、**次へ**をクリックします。
6. 次のページで、`LatestAmiId` パラメータのデフォルト値をそのまま使用し、`InstanceType` パラメータ値として `t2.small` を選択します。**次へ**をクリックします。
7. **スタックオプションの設定**ページでデフォルト値のまま、**次へ**をクリックします。
8. **レビュー**ページで一番下までスクロールし、**送信**をクリックします。

スタックの更新中に、[Amazon EC2 コンソール](https://console.aws.amazon.com/ec2/)に移動し、**インスタンス**を選択します。インスタンスは最初に停止されるため、一時的に使用できなくなります。インスタンスタイプが `t2.small` に変更されると、まもなく running ステータスになることを確認できます。この例は、**一時的な中断を伴う更新**の動作を示しています。

おめでとうございます！**一時的な中断を伴う更新**動作について学習しました。


**中断を伴わない更新**


前の例を続けてみましょう。インスタンスは現在、[基本モニタリング](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/using-cloudwatch-new.html)を使用しており、インスタンスのメトリクスデータが 5 分間隔で[Amazon CloudWatch](https://aws.amazon.com/jp/cloudwatch/) に送信されます。ワークロードのメトリクスデータを 1 分間隔で利用できるようにする必要があり、インスタンスの[詳細モニタリング](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/using-cloudwatch-new.html)を有効にします。

次に、`update-behaviors-of-stack-resources.yaml` テンプレートに記載したインスタンスに `Monitoring` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-monitoring)を `true` に設定して追加します。

::alert[この新しいプロパティを追加する際は、`Monitoring` の [Update requires](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-monitoring) の値を見て、スタックを更新するとどうなるかを確認してください。]{type="info"}

既存の `update-behaviors-of-stack-resources.yaml` テンプレートを更新し、`EC2Instance` の定義に `Monitoring` プロパティを指定します。

```yaml
EC2Instance:
  Type: AWS::EC2::Instance
  Properties:
    InstanceType: !Ref InstanceType
    ImageId: !Ref LatestAmiId
    Monitoring: true
    Tags:
      - Key: Name
        Value: cfn-workshop
```

変更をファイルに保存します。次に、スタックを更新します。

1. [AWS CloudFormationコンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. `cfn-workshop-update-behaviors-of-stack-resources` スタックを作成した[リージョン](https://docs.aws.amazon.com/ja_jp/awsconsolehelpdocs/latest/gsg/select-region.html)を選択してください。
3. 先ほど作成したスタック (例えば、`cfn-workshop-update-behaviors-of-stack-resources`) を選択します。
4. **更新**を選択します。
5. **テンプレートの準備**セクションで**既存テンプレートを置き換える**を選択し、**テンプレートの指定**セクションの**テンプレートファイルのアップロード**で、`update-behaviors-of-stack-resources.yaml` テンプレートファイルを選択します。準備ができたら、**次へ**をクリックします。
6. パラメータページで、`LatestAmiId` パラメータと `InstanceType` パラメータのデフォルト値をそのまま使用し、**次へ**をクリックします。
7. **スタックオプションの設定**ページでデフォルト値のまま、**次へ**をクリックします。
8. **レビュー**ページで一番下までスクロールし、**送信**をクリックします。

[Amazon EC2 コンソール](https://console.aws.amazon.com/ec2/)に移動し、**インスタンス**を選択します。スタックが更新されている間、インスタンスは実行中の状態のままであることに注意してください。これは、**中断を伴わない更新**の動作を示しています。

おめでとうございます！ **中断を伴わない更新**の動作を学習しました。

### チャレンジ
このラボで使用したテンプレートの `EC2Instance` の `Name` タグキーの `Value` を更新する任務があります。この情報をインスタンスの `Tags` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-tags)に記述します。`update-behaviors-of-stack-resources.yaml` テンプレートで、`Name` タグの `Value` に `cfn-workshop-new-value` を指定します。スタックを更新するときに、3つの更新動作のうちどれが適用されるかわかりますか?

::expand[* CloudFormation ドキュメントのどこで、特定のリソースタイプ (この場合 `AWS::EC2::Instance` [リソース](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html))について、特定のリソースプロパティの更新動作について知ることができますか？]{header="ヒントが必要ですか？"}

:::expand{header="解決策を確認しますか？"}
次に示すように、テンプレートの `Value` 情報を更新します。

```yaml
EC2Instance:
  Type: AWS::EC2::Instance
  Properties:
    InstanceType: !Ref InstanceType
    ImageId: !Ref LatestAmiId
    Monitoring: true
    Tags:
      - Key: Name
        Value: cfn-workshop-new-value
```

変更内容を `update-behaviors-of-stack-resources.yaml` テンプレートに保存します。更新したテンプレートでスタックを更新する前に、`Tags` プロパティの **Update requires** [セクション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-tags)を参照してください。この場合、[中断を伴わない更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-no-interrupt)になります。

スタックの更新:

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. `cfn-workshop-update-behaviors-of-stack-resources` スタックを作成した[リージョン](https://docs.aws.amazon.com/ja_jp/awsconsolehelpdocs/latest/gsg/select-region.html)を選択してください。
3. 先ほど作成したスタック (例えば、`cfn-workshop-update-behaviors-of-stack-resources`) を選択します。
4. **更新**を選択します。
5. **テンプレートの準備**セクションで**既存テンプレートを置き換える**を選択し、次に `update-behaviors-of-stack-resources.yaml` テンプレートを選択します。準備ができたら、**次へ**をクリックします。
6. 次のページで、`LatestAmiId` と `InstanceType` パラメータのデフォルト値をそのまま使用し、**次へ**をクリックします。
7. **スタックオプションの設定**ページでデフォルト値のまま、**次へ**をクリックします。
8. **レビュー**ページで一番下までスクロールし、**送信**をクリックします。
:::

### クリーンアップ
次に示す手順に従って、このラボで作成したリソースをクリーンアップしてください。

* CloudFormation コンソールで、このラボで作成した `cfn-workshop-update-behaviors-of-stack-resources` スタックを選択します。
* **削除**を選択した後、**削除**を押して確定します。

---

### まとめ
おめでとうございます！ これで、スタックリソースの更新動作がわかりました！
