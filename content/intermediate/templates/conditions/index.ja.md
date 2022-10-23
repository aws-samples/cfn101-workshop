---
title: "条件"
weight: 100
---

### 概要

[AWS CloudFormation](https://aws.amazon.com/cloudformation/) を使用してインフラストラクチャを記述する場合、CloudFormationテンプレートでリソースとリソースプロパティを宣言します。リソースを作成したり、条件に基づいてリソースプロパティ値を指定したりするユースケースがあります。

ベストプラクティスの一環として、アプリケーションのインフラストラクチャ用に作成したテンプレートを、`テスト`や`本番`などのライフサイクル環境全体で最大限に再利用する必要があります。コスト削減のため、`テスト`環境でリソースを少ない容量で実行することを選択したとします。例えば、`本番`環境には`t2.small` [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) [instance type](https://aws.amazon.com/ec2/instance-types/)、`テスト`環境には `t2.micro` インスタンスタイプを選択します。また、`本番`インスタンスでは 2 GiB の [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) (Amazon EBS) [volume](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html) を作成し、`テスト`インスタンスでは 1 GiB のボリュームを作成します。その他、条件が満たされたときだけリソースを作成したいといったユースケースがあります。

条件付きでリソースを作成するには、オプションの[条件](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)セクションをテンプレートに追加します。条件と関連する基準を定義したら、[リソース](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html)と[出力](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) のテンプレートセクションで条件を使用します。たとえば、条件をリソースまたはテンプレートに記述した出力に関連付けると、条件付きで特定のリソースを作成したり、条件が満たされた場合は指定された出力を作成したりできます。リソースプロパティ値 (EC2 インスタンスのインスタンスタイプなど) を条件付きで指定するには、[条件関数](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html) を使用します。

テンプレートで条件を使用するには、次のテンプレートセクションにステートメントを含めます。
* **パラメータ**:条件を評価したいテンプレート入力パラメータを指定します。
* **条件**:[組み込み条件関数](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html)を使用して条件を定義します。
* **リソースとアウトプット**:
   * 条件付きで作成したいリソースまたは出力に条件を関連付けます。
   * `Fn:: If`[組み込み関数](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#intrinsic-function-reference-conditions-if)を使用して、定義した条件に基づいてリソースプロパティ値を条件付きで指定します。


CloudFormationは、スタックの作成時またはスタックの更新時にリソースを作成する前に、テンプレート内のすべての条件を評価します。条件が満たされたリソースは、スタックの作成中または更新時にのみ作成されます。

### 対象トピック

このラボを修了すると、次のことができるようになります。

* Condition関数を活用するためのサンプルユースケースを定義します。
* 条件評価に基づいてリソースをプロビジョニングします。
* Condition関数を使用してリソースプロパティ値を指定します。

条件関数の使い方の例を見ていきましょう！

### ラボを開始

#### **リソースレベルでの条件の定義**

* `code/workspace/conditions`ディレクトリに移動します。
* `condition-resource.yaml` テンプレートを開きます。
* このラボの手順に従ってテンプレートの内容を更新します。

それでは、始めましょう！

まず、テンプレートをより再利用可能にすることに集中しましょう。テンプレートに、ライフサイクル環境の入力パラメータを含む`Parameters`セクションを追加します。`EnvType`パラメータを呼び出し、使用可能な入力値として`test`と`prod`という2つの環境名の例を記述します。使用する[Amazon Machine Image](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (AMI)の入力パラメータを定義します。この例では、[AWS Systems Manager](https://aws.amazon.com/systems-manager/)[Paramater Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)を使用して、使用可能な最新のAmazon Linux AMIを参照し、`LatestAmiId`というパラメータを呼び出しています。

::alert[詳細については、[Query for the latest Amazon Linux AMI IDs using AWS Systems Manager Parameter Store](https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/)を参照してください。]{type="info"}

以下に示すコンテンツをコピーし、既存のファイルコンテンツに`condition-resource.yaml`を追加して、ファイルに貼り付けます。

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
次に、[テンプレート](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html)の`Conditions` セクションの条件の例である`isProduction`について説明します。この条件では、`EnvType`パラメータ値が`prod`に等しいかどうかを評価します。

既存のファイルコンテンツに次のコンテンツを追加します。

```yaml
Conditions:
  IsProduction: !Equals
    - !Ref EnvType
    - prod
```
次に、`IsProduction`条件に基づいて条件付きでプロビジョニングするリソースに条件を関連付けます。次の例では、`Volume`リソースと`MountPoint`リソースを、`IsProduction`に関連付けます。したがって、これらのリソースが作成されるのは、`IsProduction`条件がtrueの場合、つまり`EnvType`パラメータ値が` prod`と等しい場合だけです。それ以外の場合は、EC2インスタンスリソースのみがプロビジョニングされます。

以下のコンテンツをコピーし、既存のファイルコンテンツに`condition-resource.yaml`を追加して、ファイルに貼り付けます。

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

スタックを作成する時に、`test`を`envType`の値として渡すと、CloudFormationによってEC2インスタンスリソースのみがプロビジョニングされることがわかります。上記の内容で更新したテンプレートを保存します。次に、AWS CloudFormation[コンソール](https://console.aws.amazon.com/cloudformation)に移動し、このテンプレートを使用してスタックを作成します。

* CloudFormationコンソールで、**スタックの作成**、**新しいリソースを使用 (標準)**を選択します。
* **テンプレートの準備**で、**テンプレートの準備完了**を選択します。
* **テンプレートの指定**で、**テンプレートファイルのアップロード**を選択します。
* `condition-resource.yaml`テンプレートを選択します。
* **スタックの名前**を入力します。例えば、`cfn-workshop-condition-test`と指定します。
* `EnvType`パラメータの値として`test`を渡します。**次へ**を選択します。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**を選択します。
* **スタックの作成**を選択します。CloudFormationコンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが`CREATE_COMPLETE`になるまで、コンソールのビューを更新します。

スタックが`CREATE_COMPLETE`ステータスになったら、スタックの**リソース**タブに移動します。`EnvType`に渡した`test`値と、テンプレート内の他の2つのリソースに追加して関連付けた条件に基づき作成したロジックをベースに、プロビジョニングされているリソースがEC2インスタンスだけであることを確認します。

![condition-test](/static/intermediate/templates/conditions/condition-test.png)

次のステップでは、同じテンプレートを使用して新しいスタックを作成します。今回は、`envType`パラメータの値として`prod`を渡し、CloudFormationを使用して`Volume`と`MountPoint`リソースもプロビジョニングすることを確認します。AWS CloudFormation[コンソール](https://console.aws.amazon.com/cloudformation)に移動し、既存のテンプレートを使用してスタックを作成します。

* CloudFormationコンソールで、**スタックの作成**、**新しいリソースを使用 (標準)**を選択します。
* **テンプレートの準備**で、**テンプレートの準備完了**を選択します。
* **テンプレートの指定**で、**テンプレートファイルのアップロード**を選択します。
* `condition-resource.yaml`テンプレートを選択します。
* **スタックの名前**を入力します。例えば、`cfn-workshop-condition-prod`と指定します。
* `EnvType`パラメータの値として`prod`を渡します。**次へ**を選択します。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**を選択します。
* **スタックの作成**を選択します。CloudFormationコンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが`CREATE_COMPLETE`になるまで、コンソールのビューを更新します。

今回は`IsProduction`条件が真です。スタックの**リソース**タブに移動し、EC2インスタンスリソースと共に、`Volume`および`MountPoint`リソースもプロビジョニングされていることを確認します。

![condition-prod](/static/intermediate/templates/conditions/condition-prod.png)

おめでとうございます！条件付きでリソースを作成する方法を学びました！


#### **プロパティレベルでの条件の定義**

リソースプロパティ値を条件付きで定義するユースケースの例を見てみましょう。たとえば、`test`環境用に`t2.micro`タイプのEC2インスタンスを作成し、`prod`環境用に`t2.small`タイプのEC2インスタンスを作成するとします。`InstanceType`[プロパティ](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype)として、リソースプロパティレベルで関連付ける条件を定義します。

まず、条件を設計します。たとえば、`EnvType`パラメータの入力パラメータとして`prod`を指定した場合、その条件はTrueになります。次に、条件をEC2インスタンスに関連付け、希望する動作を次のように記述します。条件が当てはまる場合、インスタンスはインスタンスタイプとして`t2.small`を使用し、それ以外の場合は`t2.micro`を使用します。次の例で、これがどのように機能するか見てみましょう。

1. 次のディレクトリにいることを確認してください:`code/workspace/conditions`。
2. `condition-resource-property.yaml`ファイルを開きます。
3. このラボの手順に従ってテンプレートの内容を更新します。

それでは、始めましょう！この例では、前の例と同様に、`EnvType`パラメータと`IsProduction`条件を定義して、渡したパラメータ値に基づいてリソースを作成します。以下に示すコンテンツをコピーし、既存のファイルコンテンツに`condition-resource-property.yaml`を追加してファイルに貼り付けます。

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

次に、`IsProduction`条件をつなげて、条件付きでプロパティ値を指定しましょう。この例では、`Fn::if`[条件関数](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#intrinsic-function-reference-conditions-if)を使用して、`IsProduction`条件が真かどうかを評価します。その場合、`t2.small`プロパティの値が`InstanceType`に使用されます。条件を満たさない場合は`t2.micro`が使用されます。次のコードをコピーしてテンプレートに追加します。

```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !If [IsProduction, t2.small, t2.micro]
```

リソースをデプロイする時が来ました！

このセクションでは、`EnvType`パラメータの値として`test`を渡し、EC2 インスタンスのタイプが`t2.micro`であることを確認します。AWS CloudFormation[コンソール](https://console.aws.amazon.com/cloudformation)に移動し、次のテンプレートを使用してスタックを作成することを選択します。

* CloudFormationコンソールで、**スタックの作成**、**新しいリソースを使用 (標準)**を選択します。
* **テンプレートの準備**で、**テンプレートの準備完了**を選択します。
* **テンプレートの指定**で、**テンプレートファイルのアップロード**を選択します。
* `condition-resource-property.yaml`テンプレートを選択します。
* **スタックの名前**を入力します。例えば、`cfn-workshop-condition-property-test`と指定します。
* `EnvType`パラメータの値として`test`を渡します。**次へ**を選択します。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**を選択します。
* **スタックの作成**を選択します。CloudFormationコンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが`CREATE_COMPLETE`になるまで、コンソールのビューを更新します。

スタックのステータスが`CREATE_COMPLETE`になったら、スタックの**リソース**タブに移動し、スタックで作成したEC2インスタンスを探します。

次に、インスタンスタイプが想定通りであることを確認します。インスタンスの物理IDのリンクをクリックして、Amazon EC2 コンソールでインスタンスを表示します。
![condition-test-property](/static/intermediate/templates/conditions/condition-test-property.png)

次の例のように、インスタンスタイプが`t2.micro`であることを示すビューが表示されます。
![ec2-instance](/static/intermediate/templates/conditions/ec2-instance.png)

同じテンプレートで新しいスタックを作成し、`EnvType`の値として`prod`を指定すると、インスタンスのタイプは代わりに`t2.small`になります。

おめでとうございます！これで、リソースプロパティ値を条件付きで指定する方法がわかりました。

### **チャレンジ**

ここまで、CloudFormationテンプレート内のリソースとプロパティ値で条件を使用する方法を学んできました。このチャレンジでは、`condition-resource.yaml`CloudFormationテンプレートの[出力](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)セクションに条件付きで出力を作成します。

**タスク:**`condition-resource.yaml`テンプレートに[出力](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)セクションを記述してください。出力の論理IDとして`VolumeId`を指定し、`Ref`組み込み関数を使用して[volumeのIDを返します](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values)。このチャレンジのゴールは、`isProduction`条件が満たされた場合にのみ出力を作成することです。この意図をどのようにテンプレートに反映させることができますか？準備ができたら、更新したテンプレートで既存の`cfn-workshop-condition-prod`スタックを更新し、変更によって期待どおりの出力が作成されたことを確認します。

:::expand{header="ヒントが必要ですか？"}
* [スタック出力](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html#outputs-section-structure-examples)のドキュメントを参照し、テンプレートで`VolumeID`出力を定義してください。
* [条件](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)と[条件の関連付け](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#associating-a-condition) のドキュメントを確認してください。どのように条件付きで出力を作成しますか？
:::

:::expand{header="解決策を見たいですか？"}
`condition-resource.yaml`ファイルに次の内容を追加します。

```yaml
Outputs:
   VolumeId:
      Value: !Ref Volume
      Condition: IsProduction
```

次に、AWS CloudFormation[コンソール](https://console.aws.amazon.com/cloudformation)に移動して、`cfn-workshop-condition-prod`スタックの更新を選択します。

* CloudFormationコンソールで、**更新**を選択します。
* **テンプレートの準備**で、**既存のテンプレートを置き換える**を選択します。
* **テンプレートの指定**、**テンプレートファイルのアップロード**を選択します。
* `condition-resource.yaml` テンプレートを選択します。
* `EnvType`は既に`prod`に設定されているはずです。**次へ**を選択します。
* **スタックオプションの設定**ページはデフォルト値のまま**次へ**を選択します。
* **スタックの作成**を選択します。CloudFormationコンソールで作成中のスタックの進行状況を確認できます。
* スタックの作成が完了するまでお待ちください。スタックのステータスが`UPDATE_COMPLETE`になるまで、コンソールのビューを更新します。


スタックの`出力`セクションに移動し、` VolumeID` の出力が存在することを確認します。
![ondition-prod-update](/static/intermediate/templates/conditions/condition-prod-update.png)
:::

このソリューションは、`code/solutions/conditions/condition-output.yaml`テンプレートファイルでも入手できます。

### クリーンアップ

次に示す手順に従って、このラボで作成したリソースをクリーンアップしてください。

* CloudFormationコンソールで、このラボで作成した`cfn-workshop-condition-test`スタックを選択します。
* このラボで作成したスタックの**削除**を選択した後、**スタックの削除**を押して確定します。


このラボで作成した他のスタック、`cfn-workshop-condition-prod`と`cfn-workshop-condition-property-test`に対して上記と同じクリーンアップ手順を実行します。

---
### まとめ

おめでとうございます！リソースを条件付きで作成する方法と、リソースプロパティ値を条件付きで指定する方法を学習しました。詳細については、[条件](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)と[条件関数](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html)を参照してください。
