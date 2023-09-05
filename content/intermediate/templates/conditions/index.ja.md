---
title: "条件"
weight: 100
---

### 概要

[AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) を使用してインフラストラクチャを記述する場合、CloudFormation テンプレートでリソースとリソースプロパティを宣言します。リソースを作成したり、条件に基づいてリソースプロパティ値を指定するようなユースケースで利用します。

ベストプラクティスの一環として、アプリケーションのインフラストラクチャ用に作成したテンプレートを、`テスト`や`本番`などのライフサイクル環境全体で最大限に再利用します。例えば、コスト削減のため、`テスト`環境でリソースを少ない容量で実行するケースを想定しましょう。`本番`環境には `t2.small` [Amazon Elastic Compute Cloud](https://aws.amazon.com/jp/ec2/) (Amazon EC2) [インスタンスタイプ](https://aws.amazon.com/jp/ec2/instance-types/)、`テスト`環境には `t2.micro` インスタンスタイプを選択します。また、`本番`インスタンスでは 2 GiB の [Amazon Elastic Block Store](https://aws.amazon.com/jp/ebs/) (Amazon EBS) [ボリューム](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ebs-volumes.html) を作成し、`テスト`インスタンスでは 1 GiB のボリュームを作成します。その他にも、条件が満たされたときだけリソースを作成するといったユースケースがあります。

条件付きでリソースを作成するには、オプションの [Conditions](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html) セクションをテンプレートに追加します。条件と関連する基準を決めたら、[Resources](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) と [Outputs](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) のテンプレートセクションで条件を使用します。例えば、Conditions を Resources またはテンプレートに記述した Outputs に関連付けると、条件付きで特定のリソースを作成したり、条件が満たされた場合は指定された出力を作成したりできます。リソースプロパティ値 (EC2 インスタンスのインスタンスタイプなど) を条件付きで指定するには、[条件関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html) を使用します。

テンプレートで条件を使用するには、次のテンプレートセクションにステートメントを含めます。
* **Parameters** : 条件を評価したいテンプレート入力パラメータを指定
* **Conditions** : [組み込み条件関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html)を使用して条件を定義
* **Resources と Outputs** :
   * 条件付きで作成したい Resources または Outputs に条件を関連付け
   * `Fn::If` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#intrinsic-function-reference-conditions-if)を使用して、定義した条件に基づいてリソースプロパティ値を条件付きで指定


CloudFormation は、スタックの作成時またはスタックの更新時にリソースを作成する前に、テンプレート内のすべての条件を評価します。条件が満たされたリソースは、スタックの作成中または更新時にのみ作成されます。

### 対象トピック

このラボを修了すると、次のことができるようになります。

* Condition 関数を活用するためのサンプルユースケースを定義
* 条件評価に基づいてリソースをプロビジョニング
* Condition 関数を使用してリソースプロパティ値を指定

条件関数の利用例を見ていきましょう！

### ラボを開始

#### **リソースレベルでの条件の定義**

* `code/workspace/conditions` ディレクトリに移動します。
* `condition-resource.yaml` テンプレートを開きます。
* ラボの手順に従ってテンプレートの内容を更新します。

それでは、始めましょう！

まず、テンプレートを再利用可能にすることに集中しましょう。テンプレートに、ライフサイクル環境の入力パラメータを含む `Parameters` セクションを追加します。`EnvType` パラメータを呼び出し、使用可能な入力値として `test` と `prod` という2つの環境名の例を記述します。使用する [Amazon Machine Image](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/AMIs.html) (AMI) の入力パラメータを定義します。この例では、[AWS Systems Manager](https://aws.amazon.com/jp/systems-manager/) [Paramater Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html) を使用して、使用可能な最新の Amazon Linux AMI を参照し、`LatestAmiId` というパラメータを呼び出しています。

::alert[詳細については、[AWS Systems Manager Parameter Store を使用して最新の Amazon Linux AMI ID を取得する](https://aws.amazon.com/jp/blogs/news/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/)をご参照ください。]{type="info"}

以下に示すコンテンツをコピーし、`condition-resource.yaml` ファイルに貼り付けます。

```yaml
Parameters:
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

  EnvType:
    Description: Specify the Environment type of the stack.
    Type: String
    AllowedValues:
      - test
      - prod
    Default: test
    ConstraintDescription: Specify either test or prod.
```
次に、[テンプレート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-anatomy.html)の `Conditions` セクションの条件の例である `IsProduction` について説明します。この条件では、`EnvType` パラメータ値が `prod` に等しいかどうかを評価します。

既存のファイルに次のコンテンツを追加します。

```yaml
Conditions:
  IsProduction: !Equals
    - !Ref EnvType
    - prod
```
次に、`IsProduction` 条件に基づいて条件付きでプロビジョニングするリソースに条件を関連付けます。次の例では、`Volume` リソースと `MountPoint` リソースを `IsProduction` に関連付けます。`Volume` および `MountPoint` リソースが作成されるのは、`IsProduction` 条件が満たされた場合、つまり、`EnvType` パラメータ値が `prod` と等しい場合だけです。それ以外の場合は、EC2 インスタンスリソースのみがプロビジョニングされます。

以下のコンテンツをコピーし、`condition-resource.yaml` ファイルに貼り付けます。

```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro

  MountPoint:
    Type: AWS::EC2::VolumeAttachment
    Properties:
      InstanceId: !Ref EC2Instance
      VolumeId: !Ref Volume
      Device: /dev/sdh
    Condition: IsProduction

  Volume:
    Type: AWS::EC2::Volume
    Properties:
      Size: 2
      AvailabilityZone: !GetAtt EC2Instance.AvailabilityZone
      Encrypted: true
    Condition: IsProduction
```

ソリューションをデプロイしましょう！

スタックを作成する時に、`test` を `EnvType` の値として渡すと、CloudFormation によって EC2 インスタンスリソースのみがプロビジョニングされることがわかります。更新したテンプレートを保存します。次に、AWS CloudFormation [コンソール](https://console.aws.amazon.com/cloudformation) に移動し、スタックを作成します。

* CloudFormation コンソールで、**スタックの作成**、**新しいリソースを使用 (標準)** を選択します。
* **テンプレートの準備**セクションで、**テンプレートの準備完了**を選択します。
* **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
* `condition-resource.yaml` テンプレートを選択します。
* **スタックの名前**を入力します。例えば、`cfn-workshop-condition-test` と入力します。
* `EnvType` パラメータの値として `test` を選択します。**次へ**をクリックします。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**をクリックします。
* レビューページで、**送信**をクリックします。CloudFormation コンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが `CREATE_COMPLETE` になるまで、コンソールのビューを更新します。

スタックが `CREATE_COMPLETE` ステータスになったら、スタックの**リソース**タブに移動します。`EnvType` に渡した `test` 値と、テンプレート内の他の2つのリソースに追加して関連付けた条件に基づき作成したロジックをベースに、プロビジョニングされているリソースがEC2インスタンスだけであることを確認します。

![condition-test](/static/intermediate/templates/conditions/condition-test.ja.png)

次のステップでは、同じテンプレートを使用して新しいスタックを作成します。今回は、`envType` パラメータの値として `prod` を渡し、`Volume` と `MountPoint` リソースもプロビジョニングされることを確認します。AWS CloudFormation [コンソール](https://console.aws.amazon.com/cloudformation)に移動し、既存のテンプレートを使用してスタックを作成します。

* CloudFormation コンソールで、**スタックの作成**、**新しいリソースを使用 (標準)** を選択します。
* **テンプレートの準備**セクションで、**テンプレートの準備完了**を選択します。
* **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
* `condition-resource.yaml` テンプレートを選択します。
* **スタックの名前**を入力します。例えば、`cfn-workshop-condition-prod` と入力します。
* `EnvType` パラメータの値として `prod` を選択します。**次へ**をクリックします。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**をクリックします。
* レビューページで、**送信**をクリックします。CloudFormation コンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが `CREATE_COMPLETE` になるまで、コンソールのビューを更新します。

今回は `IsProduction` 条件が満たされます。スタックの**リソース**タブに移動し、EC2インスタンスリソースと共に、`Volume` および `MountPoint` リソースもプロビジョニングされていることを確認します。

![condition-prod](/static/intermediate/templates/conditions/condition-prod.ja.png)

おめでとうございます！条件付きでリソースを作成する方法を学びました！


#### **プロパティレベルでの条件の定義**

リソースプロパティ値を条件付きで定義するユースケースの例を見てみましょう。例えば、`test` 環境用に `t2.micro` タイプの EC2 インスタンスを作成し、`prod` 環境用に `t2.small` タイプの EC2 インスタンスを作成するとします。`InstanceType` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype)として、リソースプロパティレベルで関連付ける条件を定義します。

まず、条件を設計します。例えば、`EnvType` パラメータの入力パラメータとして `prod` を指定した場合、条件は満たされます。次に、条件を EC2 インスタンスに関連付け、希望する動作を次のように記述します。条件が当てはまる場合、インスタンスはインスタンスタイプとして `t2.small` を使用し、それ以外の場合は `t2.micro` を使用します。次の例で、これがどのように機能するか見てみましょう。

1. `code/workspace/conditions` ディレクトリにいることを確認します。
2. `condition-resource-property.yaml` ファイルを開きます。
3. ラボの手順に従ってテンプレートの内容を更新します。

それでは、始めましょう！この例では、前の例と同様に、`EnvType` パラメータと `IsProduction` 条件を定義して、渡したパラメータ値に基づいてリソースを作成します。以下に示すコンテンツをコピーし、`condition-resource-property.yaml` ファイルに貼り付けます。

```yaml
Parameters:
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

  EnvType:
    Description: Specify the Environment type of the stack.
    Type: String
    AllowedValues:
      - test
      - prod
    Default: test
    ConstraintDescription: Specify either test or prod.

Conditions:
  IsProduction: !Equals
    - !Ref EnvType
    - prod
```

次に、`IsProduction` 条件により、条件付きでプロパティ値を指定します。この例では、`Fn::If` [条件関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#intrinsic-function-reference-conditions-if)を使用して、`IsProduction` 条件が満たされるかどうかを評価します。条件が満たされる場合、`t2.small` プロパティの値が `InstanceType` に使用されます。条件を満たさない場合は `t2.micro` が使用されます。次のコードをコピーしてテンプレートに追加します。

```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !If [IsProduction, t2.small, t2.micro]
```

リソースをデプロイしましょう！

このセクションでは、`EnvType` パラメータの値として `test` を指定、EC2 インスタンスのタイプが `t2.micro` であることを確認します。AWS CloudFormation [コンソール](https://console.aws.amazon.com/cloudformation)に移動し、次のテンプレートを使用してスタックを作成します。

* CloudFormation コンソールで、**スタックの作成**、**新しいリソースを使用 (標準)** を選択します。
* **テンプレートの準備**セクションで、**テンプレートの準備完了**を選択します。
* **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
* `condition-resource-property.yaml` テンプレートを選択します。
* **スタックの名前**を入力します。例えば、`cfn-workshop-condition-property-test` と入力します。
* `EnvType` パラメータの値として `test` を渡します。**次へ**をクリックします。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**をクリックします。
* レビューページで、**送信**をクリックします。CloudFormation コンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが `CREATE_COMPLETE` になるまで、コンソールのビューを更新します。

スタックのステータスが `CREATE_COMPLETE` になったら、スタックの**リソース**タブに移動し、スタックで作成した EC2 インスタンスを探します。

次に、インスタンスタイプが想定通りであることを確認します。インスタンスの物理 ID のリンクをクリックして、Amazon EC2 コンソールでインスタンスを表示します。
![condition-test-property](/static/intermediate/templates/conditions/condition-test-property.ja.png)

次の例のように、インスタンスタイプが `t2.micro` であることを示すビューが表示されます。
![ec2-instance](/static/intermediate/templates/conditions/ec2-instance.ja.png)

同じテンプレートで新しいスタックを作成し、`EnvType` の値として `prod` を指定すると、インスタンスのタイプは代わりに `t2.small` になります。

おめでとうございます！これで、リソースプロパティ値を条件付きで指定する方法がわかりました。

### **チャレンジ**

ここまで、CloudFormation テンプレート内のリソースとプロパティ値で条件を使用する方法を学んできました。このチャレンジでは、`condition-resource.yaml` CloudFormation テンプレートの [Outputs](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) セクションに条件付きで出力を作成します。

**タスク:** `condition-resource.yaml` テンプレートに [Outputs](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) セクションを記述してください。出力の論理IDとして `VolumeId` を指定し、`Ref` 組み込み関数を使用して [VolumeID を返します](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-volume.html#aws-resource-ec2-volume-return-values)。このチャレンジのゴールは、`IsProduction` 条件が満たされた場合にのみ出力を作成することです。チャレンジのゴールに向けて、どのようにテンプレートに反映させますか？準備ができたら、更新したテンプレートで既存の `cfn-workshop-condition-prod` スタックを更新し、変更によって期待どおりの出力が作成されたことを確認します。

:::expand{header="ヒントが必要ですか？"}
* [スタック出力](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html#outputs-section-structure-examples)のドキュメントを参照し、テンプレートで `VolumeId` 出力を定義してください。
* [条件](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)と[条件の関連付け](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#associating-a-condition)のドキュメントを確認してください。どのように条件付きで出力を作成しますか？
:::

:::expand{header="解決策を確認しますか？"}
`condition-resource.yaml` ファイルに次の内容を追加します。

```yaml
Outputs:
  VolumeId:
    Value: !Ref Volume
    Condition: IsProduction
```

次に、AWS CloudFormation [コンソール](https://console.aws.amazon.com/cloudformation)に移動して、`cfn-workshop-condition-prod` スタックの更新を選択します。

* CloudFormation コンソールで、**更新**をクリックします。
* **テンプレートの準備**セクションで、**既存のテンプレート置き換える**を選択します。
* **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
* `condition-resource.yaml` テンプレートを選択します。
* `EnvType` は既に `prod` に設定されているはずです。**次へ**をクリックします。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**をクリックします。
* レビューページで、**送信**をクリックします。CloudFormation コンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが `UPDATE_COMPLETE` になるまで、コンソールのビューを更新します。


スタックの`出力`セクションに移動し、`VolumeId` の出力が存在することを確認します。
![condition-prod-update](/static/intermediate/templates/conditions/condition-prod-update.ja.png)
:::

解決策は、`code/solutions/conditions/condition-output.yaml` テンプレートファイルでも入手できます。

### クリーンアップ

次に示す手順に従って、このラボで作成したリソースをクリーンアップしてください。

* CloudFormation コンソールで、このラボで作成した `cfn-workshop-condition-test` スタックを選択します。
* このラボで作成したスタックの**削除**を選択した後、**スタックの削除**をクリックして確定します。


このラボで作成した他のスタック `cfn-workshop-condition-prod`、`cfn-workshop-condition-property-test` に対して、上記と同じクリーンアップ手順を実行します。

---
### まとめ

おめでとうございます！リソースを条件付きで作成する方法と、リソースプロパティ値を条件付きで指定する方法を学習しました。詳細については、[条件](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)と[条件関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html)をご参照ください。
