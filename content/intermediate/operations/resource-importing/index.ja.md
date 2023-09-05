---
title: "リソースインポート"
weight: 400
---

### 概要

[AWS CloudFormation](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/Welcome.html) を使用して、コードで記述したインフラストラクチャをプログラムで管理します。例えば、[AWS マネジメントコンソール](https://aws.amazon.com/jp/console/) や [AWS Command Line Interface](https://aws.amazon.com/jp/cli/) (CLI) を使用して AWS アカウントでリソースを作成した場合は、リソースを CloudFormation スタックに[インポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html)すると、CloudFormation でリソースのライフサイクルを管理できます。

[スタック間でリソースを移動する](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/refactor-stacks.html) 場合は、インポート機能を使用することもできます。これにより、スタックとリソースを [ライフサイクルと所有権](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/best-practices.html#organizingstacks) 別に整理できます。例えば、[Amazon Elastic Compute Cloud](https://aws.amazon.com/jp/ec2/) (Amazon EC2) セキュリティグループなどのリソースを、セキュリティグループのリソース専用の 1 つのスタック (または複数のスタック) に再編成します。

::alert[インポート操作でサポートされるリソースの詳細については、 [インポートおよびドリフト検出オペレーションをサポートするリソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-supported-resources.html) をご参照ください。]{type="info"}


### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* リソースをスタックにインポートする方法を学びます。
* リソースインポートのさまざまなユースケースに関する重要な考慮事項を学び、実践します。



### ラボを開始

* ディレクトリを  `code/workspace/resource-importing` に変更します。
* `resource-importing.yaml`ファイルを開きます。
* このラボの手順に従って、テンプレートのコンテンツを更新します。

### ラボパート 1

このラボでは、まず [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) を使用して [Amazon Simple Notification Service](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html) (Amazon SNS) トピックを作成します。次に、新しい CloudFormation スタックを作成し、SNS トピックをインポートします。さらに、Amazon SNS コンソールで 2 つ目のトピックを作成し、それを既存のスタックにインポートします。

開始するには、次に示す手順に従ってください。

1. [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) に移動し、**トピック**を選択します。次に、**トピックの作成**を選択します。
2. **タイプ**セクションで、`スタンダード`を選択します。
3. トピックの**名前** (`Topic1` など) を指定します。
4. 準備ができたら、**トピックの作成**を選択します。
5. トピックが正常に作成されたら、`Topic1` の**詳細**セクションの下にある [Amazon リソースネーム (ARN)](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) をメモします。この ARN 値は、このラボの後半で使用します。Amazon SNS トピックの ARN パターンの例は `arn:aws:sns:us-east-1:123456789012:MyTopic` です。

次に、リソースのインポート機能を使用して、新しく作成したトピックを、これから作成する新しいスタックにインポートします。そのためには、CloudFormation テンプレートを使用して、既存のトピックを `AWS::SNS::Topic` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html) で次のように記述します。

* `TopicName` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html#aws-resource-sns-topic-properties) には、既存のトピックの名前、つまり `Topic1` を指定します。この値を `Topic1Name` と呼ぶテンプレート[パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) で渡します。次に、このパラメータの値を `Ref` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) で参照します。
* インポートする各リソースには、`DeletionPolicy` [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) が記述されている必要があります。トピックにはこの属性を指定し、属性値には `Retain` を指定します。`DeletionPolicy` 属性に `Retain` 値を使用するときは、スタックからリソースを削除するとき、またはスタックを削除するときにリソースを保持するように指定します。
* 以下のコードをコピーして `resource-importing.yaml` ファイルに追加し、ファイルを保存します。

```yaml
Parameters:
  Topic1Name:
    Type: String
    Default: Topic1
    Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
Resources:
  SNSTopic1:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref Topic1Name
```


::alert[インポート操作を成功させるには、インポートするすべてのリソースのテンプレートの記述に [DeletionPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) 属性が設定されている必要があります。詳しい情報については、[インポートオペレーション中の考慮事項](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-considerations) をご参照ください。]{type="info"}

この次のステップでは、AWS CloudFormation コンソールを使用して、`resource-importing.yaml` テンプレートを使用して [スタックを作成](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html) します。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
2. **スタックの作成**から、**既存のリソースを使用 (リソースをインポート)** を選択します。
3. **必要なもの**を読み、**次へ**をクリックします。
4. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**をクリックします。`resource-importing.yaml` テンプレートをアップロードし、**次へ**をクリックします。
5. [識別子の値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic1` を作成した後にメモしたトピック ARN の値を指定します。
6. **スタックの名前**を入力します。例えば、`resource-importing` と指定します。`Topic1Name` パラメータ値には必ず `Topic1` を指定します。
7. 次のページで、**リソースをインポート**をクリックします。

Amazon SNS トピックがスタックに正常にインポートされると、スタックのステータスに `IMPORT_COMPLETE` と表示されます。

おめでとうございます！ Amazon SNS コンソールで以前に作成したリソースを、新しいスタックにインポートしました。 [AWS Command Line Interface](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-welcome.html) を使用して既存のリソースを新しいスタックにインポートする方法については、[AWS CLI を使用した既存のリソースからのスタックの作成](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html#resource-import-new-stack-cli) をご参照ください。

### ラボパート 2

このラボでは、リソースを既存のスタックにインポートする方法を学びます。開始するには、以下の手順に従ってください。

1. [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) に移動して 2 つ目のトピックを作成します。ラボパート1で使用した手順に従い、新しいトピックの名前として **Topic2** を指定します。
2. トピックが正常に作成されたら、`Topic2` の**詳細**セクションの下にある [Amazon リソースネーム (ARN)](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) をメモします。この情報は、後でこのラボで使用します (ARN パターンの例: `arn:aws:sns:us-east-1:123456789012:MyTopic`)。
3. 以下の例をコピーして、前のラボで使用した `resource-importing.yaml` テンプレートの `Parameters` セクションに追加します。

```yaml
Topic2Name:
  Type: String
  Default: Topic2
  Description: Name of the second Amazon SNS topic you created with the Amazon SNS console.
```

4. 次に、以下の例をコピーして、`resource-importing.yaml` テンプレートの `Resources` セクションに追加します。完了したら、テンプレートファイルを保存します。

```yaml
SNSTopic2:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic2Name
```

5. 先ほど更新した `resource-importing.yaml` テンプレートには、2 つのパラメータ (`Topic1Name` と `Topic2Name`) と 2 つのリソース (`SNSTopic1` と `SNSTopic2`) が含まれるようになりました。新しいトピックを既存のスタックにインポートしましょう！
6. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
7. `resource-importing` という名前のスタックを選択し、**スタックアクション** から**リソースへのスタックのインポート** を選択します。
8. **必要なもの**を読み、**次へ**をクリックします。
9. **テンプレートの指定**から、**テンプレートファイルのアップロード**を選択します。このラボパートで更新した `resource-importing.yaml` テンプレートをアップロードし、**次へ**をクリックします。
10. [識別子の値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic2` を作成した後に書き留めたトピックの ARN 値を指定します。
11. パラメータについては、必ず `Topic1Name` に `Topic1` を指定し、`Topic2Name` に `Topic2` を指定します。**次へ**をクリックします。
12. 次のページで、**リソースをインポート**をクリックします。

Amazon SNS トピックがスタックに正常にインポートされると、スタックのステータス `IMPORT_COMPLETE` と表示されます。

おめでとうございます！ これで、リソースを既存のスタックにインポートする方法がわかりました。 追加の情報については、[AWS CLI を使用した既存のリソースのスタックへのインポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html#resource-import-existing-stack-cli) をご参照ください。


### ラボパート 3

ラボのこの部分では、[スタック間でリソースを移動する](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/refactor-stacks.html) 方法を学びます。`SNSTopic1` リソースを `resource-importing` スタックから削除し、新しいリソースにインポートします。`SNSTopic1` の `DeletionPolicy` 属性に `Retain` を指定したので、スタックを更新しても `SNSTopic1` リソースは削除されないことに注意します。さっそく始めましょう。


1. ラボパート 2 で使用した `resource-importing.yaml` テンプレートの **Parameters** セクションから以下のコードを削除します。

```yaml
Topic1Name:
  Type: String
  Default: Topic1
  Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
```

2. `resource-importing.yaml` テンプレートの **Resources** セクションから以下のコードを削除し、テンプレートファイルを保存します。

```yaml
SNSTopic1:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic1Name
```

3. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
4. `resource-importing`という名前のスタックを選択し、**更新**を選択します。
5. **既存テンプレートを置き換える**を選択し、`resource-importing.yaml` テンプレートをアップロードします。**次へ**をクリックします。
6. パラメータセクションで、`Topic2Name` のパラメータ値を `Topic2` のままにします。**次へ**をクリックします。
7. **スタックオプションの設定**ページでデフォルト値のまま、**次へ**をクリックします。
8. 次のページで**送信**をクリックします。
9. スタックからの `SNSTopic1` リソースの削除を確認するには、`resource-importing` スタックを選択し、**リソース**を選択します。表示されるリソースは `SNSTopic2` のみです。


`SNSTopic1` リソースを新しいスタックにインポートします。

1. `code/workspace/resource-importing` ディレクトリにいることを確認します。
2. お好みのテキストエディタで `moving-resources.yaml` テンプレートファイルを開きます。
3. 以下の例を `moving-resources.yaml` テンプレートに追加して保存します。

```yaml
Parameters:
  Topic1Name:
    Type: String
    Default: Topic1
    Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
Resources:
  SNSTopic1:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref Topic1Name
```

4. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
5. **スタックの作成**から、**既存のリソースを使用 (リソースをインポート)** を選択します。
6. **概要をインポート**を読み、**次へ**をクリックします。
7. **テンプレートの指定**セクションで、**テンプレートファイルをアップロード**を選択します。`moving-resources.yaml` テンプレートをアップロードし、**次へ**をクリックします。
8. [識別子の値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic1` を作成した後にメモしたトピック ARN 値を指定します。
9. **スタック名**を入力します。例えば、`moving-resources` と指定します。`Topic1Name` パラメータには必ず `Topic1` を指定します。
10. 次のページで**リソースをインポート**をクリックします。

Amazon SNS トピックがスタックに正常にインポートされると、スタックのステータスには `IMPORT_COMPLETE` と表示されます。

おめでとうございます！ スタック間でリソースを移動する方法を学習しました。


::alert[特定のリソースのインポート操作を元に戻すには、まずテンプレート内のリソースの `DeletionPolicy` を `Retain` に設定し、次にスタックを更新して変更を適用します。次に、テンプレートからリソースを削除し、スタックを再度更新します。その際、スタックからリソースを削除しますが、リソースはそのまま残ります。]{type="info"}

### **リソースをインポートする際のベストプラクティス**

1. 既存のリソースのプロパティを取得するには、関連する AWS サービスの AWS マネジメントコンソールページを使用するか、_Describe_ API 呼び出しを使用してリソースを説明し、リソース定義に含めるプロパティを取得します。例えば、`aws ec2 describe-instances` [CLI コマンド](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html) を使用して、次の例に示すようなインスタンス ID を使用して、インポートする Amazon EC2 インスタンスを記述します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ec2 describe-instances --instance-ids i-1234567890abcdef0
:::

::alert[予期しない変更を避けるため、テンプレートで定義するリソースプロパティがリソースの実際の設定と一致することを確認してください。]{type="info"}

2. インポートするリソースをテンプレートに記述するときは、リソースに必要なすべてのプロパティを必ず指定します。例えば、[AssumeRolePolicyDocument](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html#cfn-iam-role-assumerolepolicydocument) は [AWS::IAM::Role](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html) リソースタイプの必須プロパティです。
3. リソースのインポートが成功したら、[ドリフト検出](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html)を実行して、テンプレート内のリソースプロパティがリソースの実際の設定と一致することを確認します。

詳細については、[インポートオペレーション中の考慮事項](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-considerations) を参照してください。

### チャレンジ

この演習では、ラボパート1、2、3で得た知識を使用して、提供されたタスクを完了する必要があります。CloudFormation テンプレートのリソースの 1 つである EC2 インスタンスに、人為的ミスの結果として CloudFormation の外部で変更されたプロパティ値が存在する問題を解決する必要があります。この問題のトラブルシューティングと解決を行い、CloudFormation で希望するリソース構成を引き続き維持できるようにします。

EC2 インスタンスと Amazon S3 バケットを定義するサンプルテンプレートから始めましょう。

はじめに、以下の手順に従ってください。

1. `code/workspace/resource-importing` というディレクトリにいることを確認します。
2. `resource-import-challenge.yaml` ファイルを開きます。
3. 以下の例を `resource-import-challenge.yaml` テンプレートに追加し、ファイルを保存します。

```yaml
Parameters:
  LatestAmiId:
    Description: Fetching the latest AMI ID for Amazon Linux
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
  InstanceType:
    Description: Select the type of the EC2 instance.
    Type: String
    AllowedValues:
      - t2.nano
      - t2.micro
      - t2.small
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
  Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      Tags:
        - Key: Name
          Value: InstanceImport
```

4. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
5. **スタックの作成**から、**新しいリソースを使用 (標準)** を選択します。
6. **テンプレートを指定**セクションで、**テンプレートファイルのアップロード**を選択します。`resource-import-challenge.yaml` テンプレートをアップロードし、**次へ**をクリックします。
7. **スタックの名前**を入力します。例えば、`resource-import-challenge` と指定します。`InstanceType` には `t2.nano` を指定します。[**次へ**]をクリックします。
8. **スタックオプションの設定**ページはデフォルト値のまま、**次へ**をクリックします。
9. 次のページで、**送信**を選択します。
10. スタックを作成したら、`resource-import-challenge` スタックを選択し、**リソース**を確認します。`i-12345abcd6789` という形式の `インスタンス`の**物理 ID** をメモしておきましょう。

次に、スタックの管理範囲外でインスタンスタイプを変更して、ヒューマンエラーを再現してみましょう。以下の手順に従って [既存の EBS-backed インスタンスのインスタンスタイプを変更](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-instance-resize.html#change-instance-type-of-ebs-backed-instance) を実行します。

1. [Amazon EC2 コンソール](https://console.aws.amazon.com/ec2/) に移動します。
2. **インスタンス**セクションを見つけて、`InstanceImport` という名前のインスタンスを選択し、**インスタンスの状態**、**インスタンスを停止**を選択します。
3. 同じインスタンスで、インスタンスが**停止**状態になったことを確認したら、**アクション**、**インスタンスの設定**、**インスタンスタイプを変更**を選択します。
4. `t2.micro` を選択し、**適用**を選択します。
5. `InstanceImport` インスタンスを再度選択し、**インスタンスの状態**、**インスタンスを開始**を選択します。


最初に Amazon EC2 インスタンスをスタックで作成しました。ヒューマンエラーを再現するために、テンプレートの [InstanceType](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype) プロパティを使用する代わりに、(CloudFormation を使用せずに) インスタンスを更新し、次にスタックを更新しました。

::alert[インスタンスタイプを変更すると、インスタンスが停止して再起動するなど、 [一時的な中断を伴う更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-some-interrupt) が発生します。インスタンスのサイズ変更の詳細については、[インスタンスタイプを変更する](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-instance-resize.html) をご参照ください。]{type="info"}

今回のタスクは、スタックを更新するときに `InstanceType` プロパティに追加の変更を加えることなく、スタック内で現在 `t2.nano` に設定されているインスタンスタイプ値を、CloudFormation 以外の方法で設定された新しいインスタンス設定である `t2.micro` と一致させることです。

::expand[* ラボパート 3 で学んだ概念の利用を検討します。]{header="ヒントが必要ですか？"}

:::expand{header= "解決策を確認しますか？"}
1. `resource-import-challenge.yaml` テンプレートを更新します。`Instance` リソースに、値が `Retain` の `DeletionPolicy` 属性を追加し、ファイルを保存します。

2. パラメータ値を変更せずに、更新された `resource-import-challenge.yaml` テンプレートを使用してスタックを更新します。
3. スタックを更新し、インスタンスの `DeletionPolicy` 属性が `Retain` に設定されたら、インスタンスリソース定義と Parameters セクションにある関連パラメータをテンプレートから削除します。今回の例では、書くべきパラメーターが特に存在しないため、`Parameters` セクション自体を削除します。具体的には、`resource-import-challenge.yaml` テンプレートから次の 2 つのコードブロックを削除します。

```yaml
Parameters:
  LatestAmiId:
    Description: Fetching the latest AMI ID for Amazon Linux
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
  InstanceType:
    Description: Select the type of the EC2 instance.
    Type: String
    AllowedValues:
      - t2.nano
      - t2.micro
      - t2.small
```

```yaml
  Instance:
    DeletionPolicy: Retain
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      Tags:
        - Key: Name
          Value: InstanceImport
```

4. テンプレートファイルを保存します。更新された `resource-import-challenge.yaml` テンプレートを使用してスタックを再度更新します。このテンプレートにはパラメータセクションもインスタンスリソース定義もありません。このアクションはスタックからインスタンスを削除しますが、`Retain` に設定された `DeletionPolicy` 属性を記述して適用したため、インスタンスは削除されません。
5. このスタックの更新後、ステップ 3 で削除した 2 つのコードブロックを `resource-import-challenge.yaml` テンプレートに追加して保存します。
6. `resource-import-challenge`という名前のスタックを選択し、**スタックアクション**から**スタックへのリソースのインポート**を選択します。
7. **必要なもの**を読み、**次へ**を選択してください。
8. **テンプレートを指定**から、**テンプレートファイルのアップロード**を選択します。更新した`resource-import-challenge.yaml` テンプレートをアップロードし、**次へ**をクリックします。
9. [識別子の値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、このチャレンジの一部として先ほど書き留めたインスタンスの**物理 ID** を指定します。
10. インスタンスタイプパラメータとして `t2.micro` を選択します。ここでは、実際のインスタンスタイプ設定である `t2.micro` と一致しています。
11. 次のページで、**リソースをインポート**をクリックします。
:::



ソリューションのテンプレートは、`code/solutions/resource-import/resource-import-challenge-solution.yaml` サンプルテンプレートにあります。

以上で、CloudFormation 以外の方法で変更があった場合に CloudFormation スタック構成をリソースの実際の設定と一致させる方法を学習しました。

**リソースインポートのユースケース**

1. 以前に AWS マネジメントコンソールや AWS CLI などを使用して AWS リソース (Amazon S3 バケットなど) を作成していて、CloudFormation を使用してリソースを管理したい。
2. ライフサイクルと所有権ごとにリソースを 1 つのスタックに再編成して管理しやすくしたい (セキュリティグループのリソースなど)。
3. 既存のスタックを既存のスタックにネストしたい。詳しい情報については、[既存のスタックのネスト化](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-nested-stacks.html) をご参照ください。
4. CloudFormation 以外の方法で更新されたリソースの CloudFormation 設定と一致させたい。

### クリーンアップ

このラボで作成したリソースをクリーンアップするには、次に示すクリーンアップ手順に従ってください。

1. `code/workspace/resource-importing` というディレクトリにいることを確認します。
2. `resource-importing.yaml` テンプレートファイルを更新して、`SNSTopic2` リソース定義から `deletionPolicy: Retain` 行を削除し、テンプレートを保存します。
3. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
4. `resource-importing` という名前のスタックを選択し、**更新**を選択します。
5. **現在テンプレートを置き換える**を選択し、`resource-importing.yaml` テンプレートをアップロードします。**次へ**をクリックします。
6. パラメータセクションで、既存のパラメータ値を受け入れることを選択します。**次へ**をクリックします。
7. **スタックオプションの設定**ページでデフォルトのまま、**次へ**をクリックします。
8. 次のページで**送信**を選択します。
9. スタックの更新が完了したら、`resource-importing` スタックを選択し、**削除** を選択します。
10. `moving-resources.yaml` テンプレートを更新して `SNSTopic1` リソース定義から `deletionPolicy: Retain` 行を削除し、スタックを更新します。正常に更新されたら、手順2～9を繰り返し、スタックを削除します。スタックの更新時には、既存のパラメータ値を受け入れます。
11. `resource-import-challenge.yaml` テンプレートを更新して `Instance` リソース定義から `DeletionPolicy: Retain` 行を削除し、スタックを更新します。正常に更新されたらスタック `resource-import-challenge` について上記のステップ (2～9) を繰り返し、スタック削除します。 スタックの更新時には、既存のパラメータ値を受け入れます。

### まとめ

これで、リソースをインポートする方法と、リソースをインポートする際の使用例と考慮事項について学習しました。
