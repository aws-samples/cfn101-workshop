---
title: "リソース依存関係"
weight: 200
---

### 概要

[AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) を使用して、テンプレートに記述したリソースをプログラム的にプロビジョニングする際、あるリソースが 1 つ以上のリソースに依存する場合があります。例えば、[Amazon Elastic Compute Cloud](https://aws.amazon.com/jp/ec2/) (Amazon EC2) インスタンスは、Amazon EC2 インスタンスに使用するセキュリティグループに依存します。CloudFormation スタックにおいて、EC2 がセキュリティグループを参照するように記述することで、最初にセキュリティグループが作成され、次に Amazon EC2 インスタンスが作成されます。

テンプレートで定義したリソース間に依存関係がない場合、CloudFormation はすべてのリソースの作成を並行して開始します。リソースの作成順序を定義、もしくは、[必須](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html#gatewayattachment)である場合、CloudFormation は、一部のリソースを他のリソースよりも先に作成します。

このラボでは、`DependsOn` [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html)を使用して、リソースの作成順序を明示的に定義する方法を学びます。また、`Ref` と `Fn::GetAtt` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)を使用して、依存関係が確立されている場合に、CloudFormation に作成順序を処理させる方法も学びます。

### 対象トピック

このラボを修了すると、次のことができるようになります。

* `DependsOn` [リソース属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html)の使い方を理解して、リソースの作成順序を明示的に定義
* `Ref` と `Fn::GetAtt` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)を使用して、リソース間の依存関係を作成

### ラボを開始

#### ラボ 1

* `code/workspace/resource-dependencies` ディレクトリに移動します。
* `resource-dependencies-without-dependson.yaml` ファイルを開きます。
* ラボの手順に従ってテンプレートの内容を更新します。

ラボ 1 では、次のことを学習します。

* 依存関係が定義されていない場合に CloudFormation のリソース作成順序の処理
* リソースの作成順序を明示的に定義する方法


リソース間に依存関係がない場合に、CloudFormation がリソースの作成順序をどのように処理するかを見てみましょう。

次に示すテンプレートの抜粋にある 2 つのリソースに注目してください。1 つは [Amazon Simple Storage Service](https://aws.amazon.com/jp/s3/) (Amazon S3) [Buket](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html)、もう1つは [Amazon Simple Notification Service](https://aws.amazon.com/jp/sns/) (Amazon SNS) [Topic](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html) です。両方のリソースには、相互に依存関係が定義されていません。

::alert[次の例には、Amazon S3バケットのための `BucketName` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-properties)とAmazon SNSトピックのための `TopicName` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html#aws-resource-sns-topic-properties)は含まれていません。どちらの場合も、CloudFormation は指定されたリソースに一意の名前を生成します。]{type="info"}

`resource-dependencies-without-dependson.yaml` ファイルに、以下のコンテンツをコピーし追加します。次に、スタックを作成し、スタックイベントを確認してリソースが作成される順序を確認します。

```yaml
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop
```

AWS CloudFormation コンソールにて、`resource-dependencies-without-dependson.yaml` を使用し、[スタックを作成](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html)します。


1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. **スタックの作成**、**新しいリソースを使用 (標準)** を選択します。
3. **テンプレート準備完了**オプションを選択します。**テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。`resource-dependencies-without-dependson.yaml` テンプレートをアップロードし、**次へ**をクリックします。
4. スタック名を入力します。例えば、`resource-dependencies-lab` と入力します。準備ができたら、**次へ**をクリックします。
5. **スタックオプションの設定**ページはデフォルト値のまま、ページの一番下までスクロールして**次へ**をクリックします。
6. **レビュー**ページを一番下までスクロールして**送信**をクリックします。


スタックの `CREATE_COMPLETE` ステータスが表示されるまでページを更新します。それでは、スタックイベントを確認しましょう。次に示す画像のようになるはずです。

![resource-dependencies-lab.png](/static/intermediate/templates/resource-dependencies/resource-dependencies-lab.ja.png)

スタックイベントを見ると、`SNSTopic` リソースと `S3Bucket` リソースの作成が同時に開始されたことがわかります。2つのリソース間には依存関係がないため、CloudFormation は両方のリソースの作成を並行して開始しました。

ここで、最初に Amazon S3 バケットを作成し、バケットが正常に作成されて初めて Amazon SNS トピックの作成を開始するシナリオを考えてみましょう。シナリオを実現するために、`DependsOn` 属性の使用が役立ちます。`DependsOn` を使用して `SNStopic` リソースの依存関係を明示的に定義し、`DependsOn` 属性の値として Amazon S3 バケットリソースの論理 ID (例では、`S3Bucket` を指定) を使用します。`DependsOn` を利用すると、CloudFormation は S3 バケットの作成が完了するのを待ってから、トピックの作成を開始します。それでは、見てみましょう！

* `code/workspace/resource-dependencies` ディレクトリにいることを確認します。
* `resource-dependencies-with-dependson.yaml` ファイルを開きます。
* ラボの手順に従ってテンプレートの内容を更新します。

次に示すテンプレートをコピーして、`resource-dependencies-with-dependson.yaml` ファイルに貼り付けます。次のステップでは、スタックを作成してスタックイベントを確認します。

```yaml
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SNSTopic:
    Type: AWS::SNS::Topic
    DependsOn: S3Bucket
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop
```


上記と同じ手順に従って、`resource-dependencies-with-dependson.yaml` テンプレートファイルを使用して新しいスタックを作成します。その際、別のスタック名 (例: `resource-dependencies-lab-dependson`) を指定し、スタックを作成します。

前回とは、スタックイベントが違って見えるはずです。

![resource-dependencies-lab-dependson.png](/static/intermediate/templates/resource-dependencies/resource-dependencies-lab-dependson.ja.png)

次に、新しいスタックのスタックイベントを確認しましょう。テンプレートで説明されている Amazon SNS トピックに `DependsOn` 属性を追加し、その属性の値として Amazon S3 バケットの論理 ID を指定しました。その結果、CloudFormation は、最初に `S3Bucket` リソースを作成し、次に `SNSTopic` リソースを作成しました。スタックを削除する場合、最初に作成されたリソースが最後に削除されることに注目してください。

::alert[`DependsOn` 属性には文字列または文字列のリストを指定できます。 詳細については、[DependsOn 属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html)を参照してください。]{type="info"}

おめでとうございます！ これで、`DependsOn` 属性を使用してリソースの作成順序を明示的に定義する方法を学習しました。


#### ラボ 2

このラボでは、別のリソースの戻り値を参照するリソースプロパティを記述するときに、CloudFormation がリソースの依存関係をどのように処理するかを学びます。リソースの戻り値は、ユースケースに応じて `Ref` や `Fn::GetAtt` などの組み込み関数を使用して参照します。例えば、Amazon SNS [Topic](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html#aws-resource-sns-topic-return-values) と Amazon S3 [Bucket](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values) で使用可能な戻り値を確認できます。

スタックを作成して、実際のリソース作成順序を見てみましょう。

* `code/workspace/resource-dependencies` ディレクトリにいることを確認します。
* `resource-dependencies-with-intrinsic-functions.yaml` ファイルを開きます。
* ラボの手順に従ってテンプレートの内容を更新します。

`resource-dependencies-with-intrinsic-functions.yaml` ファイルに、サンプルテンプレートをコピーして追加します。

```yaml
Parameters:
  EmailAddress:
    Description: Enter an email address to subscribe to your Amazon SNS topic.
    Type: String

Resources:
  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SNSTopicSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Endpoint: !Ref EmailAddress
      Protocol: email
      TopicArn: !Ref SNSTopic

  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Workshop Security Group
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupId: !GetAtt SecurityGroup.GroupId
      IpProtocol: tcp
      FromPort: 80
      ToPort: 80
      CidrIp: 0.0.0.0/0
```


テンプレートに貼り付けたテンプレートスニペットには、Amazon SNS [Topic](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html)、Amazon SNS [Topic Subscription](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic-subscription.html)、Amazon EC2 [SecurityGroup](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html)、[SecurityGroup Ingress](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-rule-1.html) の 4 つのリソースがあります。次の点にご注目ください。

* Topic リソースの論理 ID である `SNSTopic` は、`SNSTopicSubscription` リソースの `TopicArn` プロパティの `Ref` で参照されます。`TopicArn` プロパティには、サブスクライブする Topic の [Amazon Resource Name](https://docs.aws.amazon.com/ja_jp/general/latest/gr/aws-arns-and-namespaces.html) (ARN) が必要です。`AWS::SNS::Topic` リソースタイプは、`Ref` 組み込み関数を使用するときに Topic の ARN を返します。詳細については、Amazon SNS Topic [戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html#aws-resource-sns-topic-return-values)をご参照ください。つまり、CloudFormation は SNSTopic の作成を開始する前に `SNSTopicSubscription` の作成が完了するのを待ちます。
* セキュリティグループリソース `SecurityGroup` の論理 ID は、`SecurityGroupIngress` リソースの `Fn::GetAtt` で参照されます。ここでの目的は、`SecurityGroupIngress` リソースの `GroupId` プロパティに `SecurityGroup` リソースの ID を指定することです。`AWS::EC2::SecurityGroup` リソースタイプは、`Fn::GetAtt` 組み込み関数を使用して `GroupID` 属性を `Fn::GetAtt` に渡すと、セキュリティグループの ID を返します。代わりに `Ref` 関数はリソース ID を返すか、EC2-Classic やデフォルト VPC の場合はリソース名を返します。詳細については、[EC2 セキュリティグループの戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-return-values)をご参照ください。
* `SecurityGroup` リソースが `CREATE_COMPLETE` ステータスになると、`SecurityGroupIngress` の作成が開始されます。同様に、`SNSTopicSubscription` リソースの作成が開始されます。
* `SNSTopic` と `SecurityGroup` リソースの間には依存関係がないことにご注目ください。つまり、CloudFormation は両方のリソースの作成を並行して開始します。

スタックを作成して、上記の動作を確認してみましょう。AWS CloudFormation コンソールにて、`resource-dependency-with-intrinsic-functions.yaml` を使用し、[スタックを作成](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html)します。


1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. **スタックの作成**、**新しいリソースを使用 (標準)**を選択します。
3. **テンプレート準備完了**オプションを選択します。**テンプレートを指定**セクションで、**テンプレートファイルのアップロード**を選択します。`resource-dependencies-with-intrinsic-functions.yaml` テンプレートをアップロードし、**次へ**をクリックします。
4. スタック名を入力します。例えば、`resource-dependencies-lab-ref-getatt` と入力します。準備ができたら、**次へ**をクリックします。
5. **パラメータ**セクションで、Amazon SNS トピックサブスクリプションのメールアドレスを入力します。準備ができたら、**次へ**をクリックします。
6. **スタックオプションの設定**ページはデフォルト値のまま、ページの一番下までスクロールして**次へ**をクリックします。
7. **レビュー**ページを一番下までスクロールして**送信**をクリックします。


スタックが作成されると、スタックのイベントは次のようになります。

![resource-dependencies-lab-ref-getatt.png](/static/intermediate/templates/resource-dependencies/resource-dependencies-lab-ref-getatt.ja.png)

`resource-dependencies-lab-ref-getatt` スタックのスタックイベントを確認しましょう。`SNSTopic` リソースと `SecurityGroup` リソースの作成は、両方のリソースには相互に依存関係がないことから、並行して開始されます。また、`SecurityGroupIngress` リソースの作成は `SecurityGroup` リソースが `CREATE_COMPLETE` ステータスになった後にのみ開始され、`SNSTopicSubscription` の作成は、`SNSTopic` リソースが正常に作成された後に開始されます。

スタックを削除すると、CloudFormation は作成順序が逆になります。この場合、`SNSTopicSubscription` と `SecurityGroupIngress` リソースが最初に削除され、続いて `SecurityGroup` と `SNSTopic` が削除されます。

::alert[作成した Amazon SNS トピックへのサブスクリプションを確認するための E メールが、指定したメールアドレスに送信されているはずです。作成したトピックについて受信したサブスクリプション確認メールに記載されているサブスクリプションリンクをたどって、トピックを購読します。購読しなかった場合、スタックを削除してもサブスクリプションは保留状態のままになり、削除することはできません。Amazon SNS は未確認のサブスクリプションを 3 日後に自動削除します。詳細については、[Amazon SNS サブスクリプションおよびトピックを削除する](https://docs.aws.amazon.com/ja_jp/sns/latest/dg/sns-delete-subscription-topic.html)をご参照ください。]{type="info"}

おめでとうございます！これで、`Ref` または `Fn::GetAtt` を使用してリソースの依存関係を定義するときに、CloudFormation がリソースの作成順序をどのように処理するかについて学習しました。


### チャレンジ

このセクションでは、Amazon EC2 [インスタンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-properties)、[セキュリティグループ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-properties)、Amazon S3 [バケット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-properties)を記述した既存のサンプルテンプレートを更新する作業を行います。Amazon EC2 インスタンスリソースの `SecurityGroups` プロパティでセキュリティグループの論理 ID を参照する必要があります。また、Amazon EC2 インスタンスリソースが正常に作成された後にのみ、CloudFormation が Amazon S3 バケットリソースの作成を開始するようにします。上記の要件例に従ってテンプレートを正しく設計すれば、スタックイベントが次のようになることを確認できるはずです。

* CloudFormation はセキュリティグループリソースの作成を開始します。
* セキュリティグループが `CREATE_COMPLETE` としてマークされると、Amazon EC2 インスタンスリソースの作成が開始されます。
* Amazon EC2 インスタンスが正常に作成されると、CloudFormation は Amazon S3 バケットの作成を開始します。

はじめに、`code/workspace/resource-dependencies` ディレクトリにある `resource-dependencies-challenge.yaml` テンプレートを、お好みのコードエディターで開きます。上記の要件例に従い、必要に応じてリソースの依存関係を確立します。準備ができたら、`resource-dependencies-challenge` という名前の新しいスタックを作成し、スタックイベントが、学んできた一連の流れと一致することを確認します。

:::expand{header="ヒントが必要ですか？"}
* Amazon EC2 インスタンスの `SecurityGroups` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-properties)で、セキュリティグループを[参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)する方法を確認してください。
* セキュリティグループを参照するときは、`SecurityGroups` プロパティの値の `Type` が _List of String_ であることにも注意してください。この値を YAML 形式でどのように表現しますか？
* リソースの作成は別のリソースに従うべきだと[指定](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html)するにはどうすればよいでしょうか。
:::

:::expand{header="解決策を確認しますか？"}
* `Ref` 組み込み関数を使用して、セキュリティグループの論理 ID を `SecurityGroups` EC2 インスタンスリソースプロパティのリスト項目として参照します。その後、CloudFormation は最初にセキュリティグループが作成されるのを待ってから、Amazon EC2 インスタンスの作成を開始する必要があります。
* Amazon EC2 インスタンスリソース定義を次に示すように変更します。

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
        Value: Resource-dependencies-workshop
```

* Amazon EC2 インスタンスとAmazon S3 バケットリソースの間には依存関係がないため、Amazon S3 バケットリソースの `DependsOn` 属性を使用し、Amazon EC2 インスタンスの論理 ID を `DependsOn` 属性の値として指定します。
* 次に示すように、Amazon S3 バケットリソースの `DependsOn` 属性を追加します。

```yaml
S3Bucket:
  Type: AWS::S3::Bucket
  DependsOn: Ec2Instance
  Properties:
    Tags:
      - Key: Name
        Value: Resource-dependencies-workshop
```
:::

更新した`resource-dependencies-challenge.yaml` テンプレートを使用して、`resource-dependencies-challenge` という名前の新しいスタックを作成し、スタックイベントが前述の順序で表示されることを確認します。

この課題の解決策は、`code/solutions/resource-dependencies/resource-dependencies-challenge.yaml` テンプレートの中にあります。

### クリーンアップ

以下の手順に従って、このラボで作成した[スタックを削除](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html)します。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. CloudFormation コンソールのスタックページで、`resource-dependencies-lab` スタックを選択します。
3. スタックの詳細ペインで、**削除**を選択した後、**スタックの削除**を押して確定します。
4. 上記の手順を繰り返して、作成した他のスタック `resource-dependencies-lab-dependson`、`resource-dependencies-lab-ref-getatt`、`resource-dependencies-challenge` を削除します。

---
### まとめ

`Ref` と `Fn::GetAtt` 組み込み関数を使用してリソースの依存関係を定義する方法と、`DependsOn` 属性を使用してリソースの依存関係を明示的に定義する方法を学びました。
