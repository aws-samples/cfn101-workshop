---
title: "擬似パラメータ"
weight: 500
---

### 概要
このラボでは、[擬似パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)を使って再利用可能なテンプレートの作り方について学びます。

### カバーされるトピック
このラボの完了までに次のことができるようになります。

+ 疑似パラメータを活用してテンプレートの可搬性のベストプラクティスに則れるようになります。
+ 疑似パラメータを活用するいくつかのサンプルユースケースを理解できます。

CloudFormation テンプレートを使うとき、目的とすべきことの 1 つは AWS アカウントとリージョンをまたがってテンプレートを再利用しやすくするため、モジュラー化と再利用可能な CloudFormation テンプレートを作ることです。[CloudFormation パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)に加えて、[疑似パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)を使うようにテンプレートを作ることもできます。疑似パラメータとは CloudFormation で定義されたパラメータです。

疑似パラメータはパラメータと同じ様に使えます。例えば、[Ref 組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html)の引数として使うことができます。

このモジュールでは、次の 3 つの疑似パラメータを使います。

* [AWS::AccountId](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-accountid) - テンプレートからスタックを作る際に使用する AWS アカウントのアカウント ID を返します。
* [AWS::Region](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-region) - テンプレートからスタックを作る際に使用するリージョンを返します。
* [AWS::Partition](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-partition) - AWS パーティション名を返します。パーティションは、標準の AWS リージョンの場合、`aws` です。中国 (北京および寧夏) リージョンのパーティションは `aws-cn` で、AWS GovCloud (US-West) リージョンのパーティションは `aws-us-gov` です。

::alert[利用可能な疑似パラメータについては、ドキュメントの [擬似パラメータ参照](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)を参照してください。]{type="info"}

それでは疑似パラメータを活用する方法について例を見ていきましょう。

### ラボの開始
* `code/workspace/pseudo-parameters` ディレクトリへ移動します。
* `pseudo-parameters.yaml` ファイルを開きます。
* ラボの以下のステップに沿って、テンプレートの内容を更新します。

次の例では、[AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html#what-is-a-parameter) を使って、データベースのユーザ名など集中的に設定情報を保存します。このために、CloudFormation テンプレートでユーザ名の値を保存する `AWS::SSM::Parameter` リソースを記述します。

そして、この Parameter Store の値を取得する [AWS Lambda 関数](https://aws.amazon.com/lambda/)に許可したいアクションを記述した IAM ポリシーを作成します。まず IAM ポリシーの記述からはじめ、作成した SSM パラメータを参照します。そのためには SSM パラメータの [Amazon リソースネーム (ARN)](https://docs.aws.amazon.com/ja_jp/general/latest/gr/aws-arns-and-namespaces.html) を知る必要があります。

まず、リソース (この場合は SSM パラメータ) の戻り値のセクションを確認します。関連する[ドキュメントページ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html#aws-resource-ssm-parameter-return-values)で、`Ref` がパラメータ名を返すことと、`Fn::GetAtt` がタイプや値を返すことを確認することができます。今日の時点では、そのリソースタイプの ARN は出力値として返すことができないので、ARN を構築するために擬似パラメータを活用することができます。

擬似パラメータを使って、以下の例のような ARN を組み立てます。例えば、`dbUsername` と呼ばれるサンプルパラメータがあり、`us-east-1` リージョンで、`111122223333` AWS アカウントで構築をすることとします。サンプルパラメータの ARN は次の例のポリシースニペットのように組み立てられます。

:::code{language=json showLineNumbers=false showCopyAction=false}
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:us-east-1:111122223333:parameter/dbUsername"
        }
    ]
}
:::
それでは、CloudFormation テンプレートに必要なリソースの記述をしていきます。

まず、SSM パラメータの値として使えるように、テンプレートに[テンプレートパラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)を定義します。`Parameters` セクションに `DatabaseUsername` というテンプレートパラメータとします。

`Resources` セクションでは `Ref` 組み込み関数を使ってテンプレートパラメータを参照します。下記の内容をコピーし、`pseudo-parameters.yaml` ファイルの既存の内容に追加します。
```yaml
Parameters:
  DatabaseUsername:
    AllowedPattern: ^[a-z0-9]{5,12}$
    Type: String
    Default: alice
    Description: Value to be used with the dbUsername SSM parameter. The default value is set to 'alice', which users can override when creating a CloudFormation stack.
```

次に、SSM パラメータの記述をしましょう。`Name` プロパティに `dbUsername` を指定し、`Value` プロパティに `Ref` を使って `DatabaseUsername` テンプレートパラメータを参照するように定義します。

次のコードを既存のファイルの内容に追加してください。
```yaml
Resources:
  BasicParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: dbUsername
      Type: String
      Value: !Ref DatabaseUsername
      Description: SSM Parameter for database username.
```

次に、上記で定義した SSM パラメータを参照するための IAM ロールとポリシーを指定します。
次の内容をコピーし、`pseudo-parameters.yaml` ファイル の `Resources` セクションに追加してください。
```yaml
DemoRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Version: "2012-10-17"
      Statement:
        - Effect: Allow
          Principal:
            Service:
              - lambda.amazonaws.com
          Action:
            - sts:AssumeRole
    Path: /
    Policies:
      - PolicyName: ssm-least-privilege
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Effect: Allow
              Action: ssm:GetParameter
              Resource: '*'
```

上のスニペットの例では、デプロイする予定の Lambda 関数に関連付けする [実行ロール](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-intro-execution-role.html)を記述しています。このロールは Lambda 関数が SSM パラメータに対して `GetParameter` の実行を許可するものです。最小権限のベストプラクティスに沿うためには、IAM ポリシーのアクションのスコープを狭くし、上記で定義した SSM パラメータにはこの Lambda 関数からのアクセスしか許可しないようにする必要があります。

上記の `Resource` 定義で `Resource: '*'` を使う代わりに、`AWS::Partition`、`AWS::Region`、`AWS::AccountId` 擬似パラメータを使って、組み立てるパラメータの ARN を指定します。[Fn::Sub](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) 組み込み関数は指定の文字列内の変数をその値に置換する関数です。この組み込み関数 (YAML 短縮形は `!Sub`) を使って、それぞれの擬似パラメータの値を置換していきます。組み立てる ARN には、Parameter Store リソースの名前も指定するので、`BasicParameter` というテンプレート内で記述している Parameter Store の[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) を参照します。

`DemoRole` の `Policies` セクションを特定し、`Resouce: *` を含むすべての行を次で置き換えてください。
```yaml
              Resource: !Sub 'arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:parameter/${BasicParameter}'
```

最後に、`pseudo-parameters.yaml` テンプレートファイルの `Resources` セクションに以下のサンプルスニペットを追加します。このスニペットは、上記で定義した IAM ロールを使って、定義したばかりの SSM パラメータの読み取り権限を持つ Lambda 関数を定義しています。この Lambda 関数は `dbUsername` という SSM パラメータにアクセスできるかをテストするために、Lambda 関数を実行します。
```yaml
DemoLambdaFunction:
  Type: AWS::Lambda::Function
  Properties:
    Handler: index.lambda_handler
    Role: !GetAtt DemoRole.Arn
    Runtime: python3.8
    Code:
      ZipFile: |
        import boto3

        client = boto3.client('ssm')


        def lambda_handler(event, context):
            response = client.get_parameter(Name='dbUsername')
            print(f'SSM dbUsername parameter value: {response["Parameter"]["Value"]}')
```
上記の内容を使って、テンプレートを更新してください。次に [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation) を開き、このテンプレートを使ってスタックを作成してください。
* 画面右上の **スタックの作成** をクリックし、_新しいリソースを使用 (標準)_ をクリックしてください。
* **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
* **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
* **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
* `pseudo-parameters.yaml` を指定し、**次へ** をクリックします。
* **スタックの名前** (例: **cfn-workshop-pseudo-parameters**) を入力し、**次へ** をクリックします。
* **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
* **レビュー** のページで、ページの下部までスクロールし、*機能* セクションに **AWS CloudFormation によって IAM リソースが作成される場合があることを承認します。** の文言のチェックボックスにチェックを入れます。
* **送信** をクリックします。 作成されたスタックの進捗は CloudFormation コンソールで確認できます。
* スタックの作成が完了するまで待ってください。ステータスが `CREATE_COMPLETE` になるまでコンソールの表示を更新してください。

![resources-png](/static/basics/templates/pseudo-parameters/resources.ja.png)

記述した IAM の許可が期待どおりであることを確認します。上記の画像に表示されているように、CloudFormation スタックの _リソース_ タブに `pseudo-parameters.yaml` テンプレートに記述した `DemoRole` を確認できます。`DemoRole` の物理 ID のリンクをクリックして開きます。ポリシー名の下のインラインポリシー `ssm-least-privilege` を展開します。

![role-png](/static/basics/templates/pseudo-parameters/role.ja.png)

CloudFormation テンプレートで記述した IAM ポリシーが表示されるはずです。パラメータの ARN も期待通りに組み立てられていることを確認してください。

![policy-png](/static/basics/templates/pseudo-parameters/policy.ja.png)

_リソース_ タブには、テンプレートで記述した Lambda 関数も確認できます。

Lambda 関数がテンプレートに定義した SSM パラメータにアクセスできる許可を持っていることを確かめるためには、手動で Lambda 関数を[実行](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/testing-functions.html)します。

CloudFormation スタックの _リソース_ タブに Lambda 関数の物理 ID のリンクをクリックして開きます。Lambda 関数のテスト実行のためには、まずテストイベントを作成する必要があります。`テスト`タブでデフォルトで提供されているテンプレートを使って、新しいテストイベントに名前を設定します。

テストイベントを**保存**し、**テスト**をクリックして Lambda 関数を実行します。

![lambda-test](/static/basics/templates/pseudo-parameters/lambda-test.ja.png)
Lambda 関数の実行後、**実行結果**の下の _詳細_ を開くと、**ログ出力** のセクションに以下のような出力結果が表示されるはずです。

![lambda-png](/static/basics/templates/pseudo-parameters/lambda.ja.png)

上記のように `dbUsername` パラメータが `alice` であることを示す行を確認できます。これで、Lambda 関数に追加したロジックが期待通りパラメータにアクセスし、値を取得、表示していることを確認できました。

### チャレンジ
このラボでは CloudFormation テンプレートで擬似パラメータを使う方法について学びました。それでは、[Amazon S3 バケット](https://aws.amazon.com/jp/s3/) を CloudFormation テンプレートに追加したいとします。例えば、S3 バケットの名前として
`YOUR_BUCKET_NAME_PREFIX-AWS_REGION-YOUR_ACCOUNT_ID` (例: `my-demo-bucket-us-east-1-111122223333`) のような形式になるように検討します。

**タスク:** S3 バケットのリソースをテンプレートで記述してください。バケット名にプレフィックスを指定し、CloudFormation テンプレートパラメータで渡すようにしてください。テンプレートパラメータと擬似パラメータを使い、前述の形式になるようにバケット名を組み立ててください。

:::expand{header="ヒントが必要ですか？"}
- [テンプレートのパラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)のドキュメントを参考し、テンプレートで S3 バケット名のプレフィックスのためのパラメータを定義します。
- バケット名を組み立てるときは、このラボで `!Sub` 組み込み関数で擬似パラメータを参照したように、テンプレートパラメータを参照します。例えば、テンプレートパラメータが `S3BucketNamePrefix` の場合、`!Sub '${S3BucketNamePrefix}'` となるように `!Sub` 組み込み関数で参照します。
:::

:::expand{header="解決策を確認しますか？"}
まず、_Parameters_ セクションに S3 バケットプレフィックスとして使うテンプレートパラメータ `S3BucketNamePrefix` を追加します。

```yaml
S3BucketNamePrefix:
  Description: The prefix to use for your S3 bucket
  Type: String
  Default: my-demo-bucket
  AllowedPattern: ^[0-9a-zA-Z]+([0-9a-zA-Z-]*[0-9a-zA-Z])*$
  ConstraintDescription: Bucket name prefix can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-).
  MinLength: 3
```

そして、`DemoBucket` リソースをテンプレートの _Resources_ セクションに追加します。

```yaml
DemoBucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Sub '${S3BucketNamePrefix}-${AWS::Region}-${AWS::AccountId}'
```
完成した解答コードは、`code/solutions/pseudo-parameters/pseudo-parameters.yaml` を見てください。
:::

動作が期待通りになることを確認するために、解答をテストしてください。まず、先程作成した[スタックの更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html)をします。スタック更新の際に内容を変更したテンプレートを選択します。スタックの更新が成功するまでしばらく待ち、S3 バケットが `YOUR_BUCKET_NAME_PREFIX-AWS_REGION-YOUR_ACCOUNT_ID` の形式を使っていることを確認してください。

### クリーンアップ
次のステップに従って、作成したリソースを削除してください。

  * **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** で、このラボで作成したスタック (例: `cfn-workshop-pseudo-parameters`) を選択してください。
  * ラボで作ったスタックを削除するため **削除** をクリックし、ポップアップで **削除** をクリックしてください。

---
### まとめ
すばらしいです！これでより再利用可能な CloudFormation テンプレートを作るために擬似パラメータの使い方について学びました。より詳しい情報については、[擬似パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)を参照してください。
