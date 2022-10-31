---
title: "動的参照"
weight: 300
---

### 概要
このモジュールでは、CloudFormationテンプレートの[動的な参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html)を使用して、[AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html)(SSM)、[Paramater Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)、[AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)を含むAWSサービスに保存されている外部値を参照する方法を学びます。

前に説明したように、CloudFormationテンプレートでは、AWSリソースの[ライフサイクルと所有権] (https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/best-practices.html)の基準とベストプラクティスを考慮すると、一元化された場所に保存されている設定値を参照することもできます。Parameter Storeは、構成データ管理のための安全な階層型ストレージを提供します。

また、AWS CloudFormationテンプレート内の機密情報を参照する必要がある場合もあります。[AWS Secrets Manager](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/intro.html) を使用すると、データベースやその他のサービスの認証情報をプログラムで安全に暗号化、保存、取得できます。SSM [Secure Stringパラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-secure-strings)を使用して機密データを保存および参照することもできます。

動的な参照を使用すると、CloudFormation はスタックおよび [変更セット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)操作中に必要に応じて指定された参照値を取得します。ただし、CloudFormationが実際の参照値を保存することはありません。

### 取り上げるトピック
このラボを修了すると、次のことができるようになります。

* CloudFormationテンプレートの外部値にアクセスするための*動的参照文字列*を作成します。
* 特定のバージョン、または*最新*バージョンのParameter Storeパラメータを取得する。
* Secrets Managerシークレットの特定のバージョンを取得する。
    * JSON データ形式を使用するシークレットから特定のキーの値を抽出します。

### ラボを開始

#### Paramater Storeの動的リファレンス
開発チームにライフサイクル環境を提供する必要があるシナリオを考えてみましょう。このプラクティスには、多くの場合、最新のオペレーティングシステムアップデート、強化要件、および必要なサードパーティのソフトウェアエージェントを含むカスタム[Amazon Machine Images](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/AMIs.html)(AMI)の構築と配布が含まれます。

あなた (または組織のチーム) がカスタムAMIを作成したら、Parameter Storeを使用してAMIの識別子を保存することを選択できます。これにより、EC2インスタンスを起動するときに使用するAMIをプログラムで指定しやすくなり、設定ミスの可能性が低くなります。

このラボでは、AMI IDを永続化するParameter Storeパラメータを作成します。カスタムAMIの代わりに、選択したリージョンで利用できる最新の _Amazon Linux 2 AMI, 64-bit x86_ を使用します。次に、テンプレートに記述したEC2インスタンスの`ImageId`[プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-imageid)でパラメータを参照します。

それでは、始めましょう！次に示す手順に従って選択してください:

1. Amazon EC2[コンソール](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LaunchInstanceWizard:)に移動し、使用する[リージョンを選択] (https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html)します。次に、最新の*Amazon Linux 2 AMI, (64-bit x86)*を探し、AMI ID(例:`ami-abcd1234`)をメモします。この値は次のステップで使用します。

![ec2](/static/intermediate/templates/dynamic-references/ec2-console-ami-picker.png)

2. [AWS Command Line Interface](https://aws.amazon.com/cli/) (CLI) を使用してパラメータを作成します。次に示すコマンドを実行するときは、必ず`YOUR_AMI_ID`と`YOUR_REGION`のプレースホルダーを必要な値に置き換えてください。あなたは、特定のAWSリージョンを指定できます。[リージョンエンドポイント](https://docs.aws.amazon.com/ja_jp/general/latest/gr/rande.html#regional-endpoints) の表の**コード**を参照してください。前のステップで使用するAMIを選択したときに選択したリージョンと同じリージョンを必ず使用してください。

   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws ssm put-parameter \
    --name "/golden-images/amazon-linux-2" \
    --value YOUR_AMI_ID \
    --type "String" \
    --region YOUR_REGION
   :::

::alert[CloudFormationを使用して、`String`または`StringList`タイプのParamater Storeパラメータを作成できます。詳細については、[AWS::SSM::Parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html)のドキュメントをご覧ください。]{type="info"}

3. 次に示す手順に従って、テンプレートに記述したEC2インスタンスのパラメータへの動的参照を作成します。

    1. `code/workspace/dynamic-references`ディレクトリに移動します。
    2. お好みのテキストエディタで `ec2-instance.yaml` CloudFormationテンプレートを開きます。
    3. テンプレート内の `AWS::EC2::Instance`リソースタイプブロックを探し、`Properties`セクションのプロパティに `ImageId`プロパティとパラメータへの動的参照を追加してテンプレートを更新します。

       :::code{language=yaml showLineNumbers=false showCopyAction=true}
       ImageId: '{{resolve\:ssm:/golden-images/amazon-linux-2}}'
       :::

上記の動的リファレンスを使って、スタックの実行時に`/golden-images/amazon-linux-2`パラメータの`LATEST`バージョンを解決する意図を説明しました。

::alert[CloudFormationは、[動的参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm)による[パブリックパラメータ](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/parameter-store-finding-public-parameters.html)をサポートしていません。[SSMパラメータタイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types)を使用してパブリックパラメータの値を取得することができます。]{type="info"}

4. いよいよスタックを作成しましょう！ 以下の手順に従ってください。

    1. [AWS CloudFormationコンソール](https://console.aws.amazon.com/cloudformation/) に移動し、**新しいリソースを使用 (標準)**を選択します。
    2. **テンプレートの準備**セクションで、**テンプレート準備完了**を選択します。
    3. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
    4. ファイル`ec2_instance.yaml`を選択します。
    5. スタック名を入力します。例えば、`cfn-workshop-ec2-stack`を入力します。
    6. **スタックオプションの設定**ページはデフォルト値のまま、**次へ**を選択します。
    7. スタックの**レビュー**ページで、一番下までスクロールし、**スタックの作成**を選択します。
    8. スタックの作成ページを更新することで、CloudFormationコンソールでスタックの作成の進行状況を確認できます。
    9. スタックの`CREATE_COMPLETE`ステータスが表示されるまでページを更新してください。

::alert[SSMパラメータへの動的参照を使用して、特定のパラメータバージョンを指すこともできます。たとえば、CloudFormationにパラメータのバージョン`1`を解決させるには、`ImageId: '{{resolve\:ssm:/golden-images/amazon-linux-2:1}}'`を使用します。特定のバージョンへの動的参照をロックすると、スタックの更新時にリソースが意図せず更新されるのを防ぐのに役立ちます。]{type="info"}

5. EC2インスタンスに使用したイメージのIDが、Parameter Storeパラメータに保存したイメージIDと一致することを確認します。まず、CloudFormationコンソールの**リソース** タブに移動してEC2インスタンスID を確認します。EC2インスタンスの物理IDを探し、その値を書き留めます。次に、以下のコマンドを実行します (コマンドを実行する前に、`YOUR_INSTANCE_ID`と`YOUR_REGION`プレースホルダーを置き換えてください)。

   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws ec2 describe-instances \
    --instance-ids YOUR_INSTANCE_ID \
    --region YOUR_REGION \
    --query 'Reservations[0].Instances[0].ImageId'
   :::

おめでとうございます！ダイナミックリファレンスの使用方法は、Parameter Storeを使用した例で学習しました。

#### AWS シークレットマネージャーの動的リファレンス
[AWS Secrets Manager](https://aws.amazon.com/secrets-manager) は、データベース認証情報などの認証情報を保護するのに役立ちます。これにより、コードにシークレットをハードコーディングしなくても、後でプログラムで利用できるようになります。たとえば、[AWS Lambda](https://aws.amazon.com/lambda/) 関数を作成して、[Amazon Relational Database Service (RDS)](https://aws.amazon.com/rds/)データベースインスタンスのデータベース接続情報(ホスト名やポートなど)を使用します。

このラボでは、Secrets Managerを使用してデータベースの*ホスト名*、*ポート*、*ユーザー名*、および*パスワード*を保存します。次に、動的参照を使用して、テンプレートに記述する `AWS::Lambda::Function`リソースから*ホスト名*と*ポート*情報を読み取ります。

それでは、始めましょう！次に示す手順に従って選択してください。

1. まず、Amazon RDSデータベースを作成し、接続情報をAWS Secrets Managerにシークレットとして保存します。
    1. `code/workspace/dynamic-references`ディレクトリにいることを確認します。
    2. お好みのテキストエディタで`database.yaml`CloudFormationテンプレートを開きます。
    3. テンプレート内の次のリソースに注意してください。
        1. `AWS::RDS::DBInstance`タイプのリソース。これを使用して Amazon RDSインスタンスを記述します。
        2. `AWS::SecretsManager::Secret`タイプのリソース。データベース接続パラメータをJSONキーと値のペアとして、`DatabaseConnParams`という名前のシークレットに保存します。
   ```json
   {
       "RDS_HOSTNAME": "${Database.Endpoint.Address}",
       "RDS_PORT": "${Database.Endpoint.Port}",
       "RDS_USERNAME": "${DBUsername}",
       "RDS_PASSWORD": "${DBPassword}"
   }
   ```
2. データベーススタックをデプロイするには、以下の手順に従います。
    1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動し、**新しいリソースを使用 (標準)**を選択します。
    2. **テンプレートの準備**セクション内の**テンプレートの準備完了**を選択します。
    3. **テンプレートソース**において、**テンプレートファイルのアップロード**を選択します。
    4. ファイル`database.yaml`を選択します。
    5. スタック名を入力します。例えば、`cfn-workshop-database-stack`と入力します。
    6. `DBUserName`には、DBインスタンスのプライマリユーザー名を指定します。
    7. `DBPassword`には、プライマリユーザーのパスワードを指定します。
    8. **スタックオプションの設定**ページはデフォルト値のまま、**次へ**を選択します。
    9. スタックの**レビュー**ページで、一番下までスクロールして、**スタックを作成**を選択します。
    10. スタックの作成ページを更新することで、CloudFormationコンソールでスタックの作成の進行状況を確認できます。
    11. スタックの`CREATE_COMPLETE`ステータスが表示されるまでページを更新してください。
3. 次に、AWS Lambda関数を作成し、以前に作成した Secrets Managerシークレットへの動的参照を使用して、いくつかのデータベース接続パラメータを[環境変数](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html)としてLambda関数に読み取ります。
    1. `code/workspace/dynamic-references`ディレクトリにいることを確認します。
    2. お好みのテキストエディタで `lambda-function.yaml` CloudFormationテンプレートを開きます。
    3. テンプレートには `AWS::Lambda::Function`リソースタイプが記述されています。`Properties`セクションに`Environment`プロパティを追加し、先ほど作成したAWS Secret Managerシークレットへの動的参照を使用する変数を追加してテンプレートを更新します。
   ```yaml
   Environment:
     Variables:
       RDS_HOSTNAME: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_HOSTNAME}}'
       RDS_PORT: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_PORT}}'
   ```
4. Lambdaスタックをデプロイするには、以下の手順に従います。
    1.[AWS CloudFormationコンソール](https://console.aws.amazon.com/cloudformation/) に移動し、**新しいリソースを使用 (標準)**を選択します。
    2. **テンプレートの準備**セクション内の**テンプレートの準備完了**を選択します。
    3. **テンプレートソース**において、**テンプレートファイルのアップロード**を選択します。
    4. ファイル `lambda_function.yaml`を選択します。
    5. スタック名を入力します。例えば、`cfn-workshop-lambda-stack`と入力し、**次へ**を選択します。
    6. **スタックオプションの設定**ページはデフォルト値のまま、**次へ**を選択します。
    7. スタックの**レビュー**ページで、一番下までスクロールし、次の例に示すように IAM Capabilitiesチェックボックスを選択します。
       ![Acknowledge IAM Capability](/static/intermediate/templates/dynamic-references/iam-capability.png)
    8. **スタックを作成**を選択します。スタックのステータスが`CREATE_COMPLETE`になるまでページを更新します。

   先ほど使用したテンプレートでは、データベース接続パラメーターはスタックの実行時に動的文字列を使用して取得されます。`RDS_HOSTNAME`などの特定のキーの値を、`'{{resolve\:secretsmanager\:DatabaseConnParams\:SecretString\:RDS_HOSTNAME}}'`で取得しました。ここで、`DatabaseConnParams`はシークレットIDです。

   ::alert[AWS Secrets Manager のシークレットには、暗号化されたシークレット値のコピーを保持する [*versions*](https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html#term_version) があります。シークレットの値を変更すると、Secrets Managerは新しいバージョンを作成します。シークレットには常に、現在のシークレット値であるステージングラベル`AWSCURRENT`のバージョンがあります。必要に応じて、*バージョンステージ*または*バージョンID*を指定して、この文字列を次のように変更できます。`'{{resolve\:secretsmanager\:prod-DatabaseConnParams\:SecretString\:RDS_HOSTNAME:<version-stage>:<version-id>}}'`。バージョンを指定しない場合、CloudFormationはステージ `AWSCURRENT`に関連するシークレットをデフォルトで解決します。]{type="info"}

5. 作成したサンプルのLambda関数を呼び出すと、関数は`RDS_HOSTNAME`と`RDS_PORT`環境変数をフェッチし、それらの値を出力します。まず、CloudFormationコンソールの**リソース** タブに移動してLambda 関数名を見つけます。Lambda関数の物理IDを探し、その値を書き留めます。次に、次のコマンドを使用してデータベース接続パラメーターを Lambda関数に渡していることを確認します (`YOUR_FUNCTION_NAME`を Lambda関数名に、`YOUR_REGION`を必要な値に置き換えてください)。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws lambda invoke \
    --function-name YOUR_FUNCTION_NAME \
    --region YOUR_REGION \
    output.json
   :::

   Print the output for the above command using the following command:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cat output.json
   "Database: db.us-east-1.rds.amazonaws.com:3306"
   :::

おめでとうございます！ AWS Secrets Managerで動的参照を使用する方法を学びました。

### チャレンジ

この演習では、*動的参照*についての理解を深めます。

AWS Lambda では、`MemorySize`[プロパティ](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize)で、[関数](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html)のメモリ構成をサポートします。ここでのタスクは、AWS CLI でParamater Storeパラメータを作成することです。ここで、`Lambda_memory_size.yaml`テンプレートに記述するLambda関数に使用するメモリサイズを設定します。次に、作成したパラメーターのバージョン`1`への動的参照を作成し、テンプレートを使用してスタックを作成してビルドした内容が機能することを確認します。`cfn-workshop-lambda-memory-size-stack`スタックを呼び出します。Parameter Storeパラメータは、スタックの作成時に選択したものと同じAWSリージョンに作成します。

:::expand{header= "ヒントが必要ですか？"}
* CloudFormation[ユーザーガイド](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize) を参照し、Lambda関数の`MemorySize`設定を指定する方法を理解してください。
* 特定のバージョンのParameter Storeパラメータへの動的参照文字列を作成する方法については、CloudFormation[ユーザーガイド](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-pattern)を参照してください。
:::

::::expand{header="解決策を見たいですか？"}
* 以下のコマンドを使用して、必要なメモリ設定を指定するParameter Storeパラメータを作成します (この例では`us-east-1`リージョンを使用しています。この値を適宜更新してください)。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
aws ssm put-parameter \
    --name "/lambda/memory-size" \
    --value "256" \
    --type "String" \
    --region YOUR_REGION
:::

* お好みのテキストエディタで `code/workspace/動的参照/lambda-memory-size.yaml`テンプレートを開きます。パラメータへの動的参照を使用して `MemorySize`プロパティを含む以下の例を`Resources`セクションに追加して、テンプレートを更新します。
```yaml
HelloWorldFunction:
  Type: AWS::Lambda::Function
  Properties:
    Role: !GetAtt FunctionExecutionRole.Arn
    Handler: index.handler
    Runtime: python3.7
    MemorySize: '{{resolve:ssm:/lambda/memory-size:1}}'
    Code:
      ZipFile: |
        import os
        def handler(event, context):
            return "Hello World!"
```

テンプレートで説明および更新したリソースをプロビジョニングするには、`cfn-workshop-lambda-memory-size-stack` CloudFormationスタックを作成します。

解決策は、`code/solutions/dynamic-references/lambda-memory-size.yaml`サンプルテンプレートにあります。
::::

### クリーンアップ
1. `cfn-workshop-lambda-stack`と`cfn-workshop-lambda-memory-size-stack`で作成した Lambda関数に関連付けられたCloudWatchロググループを削除します (チャレンジセクションのLambda関数を呼び出した場合は、関連するロググループが存在しているはずです)。スタックごとに、CloudFormationコンソールの**リソース**タブに移動してLambda関数名を検索し、Lambda関数の物理IDを探して、その値を書き留めます。次に、作成した各Lambda関数に対して以下のコマンドを使用します (`YOUR_FUNCTION_NAME`をLambda関数名に置き換え、`YOUR_REGION`を必要な値に置き換えてください)。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws logs delete-log-group \
    --log-group-name /aws/lambda/YOUR_FUNCTION_NAME \
    --region YOUR_REGION
   :::
2. 次のコマンドを使用して、AMI IDと`MemorySize`設定を保存するために作成した2つのParameter Storeパラメータを削除します (`YOUR_REGION` は必要な値に置き換えてください)。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws ssm delete-parameters \
    --names "/golden-images/amazon-linux-2" "/lambda/memory-size" \
    --region YOUR_REGION
   :::
3. 次に、CloudFormationコンソールで、最後に作成したスタック (例:`cfn-workshop-lambda-memory-size-stack`) を選択します。
4. **削除**を選択した後、**スタックの削除**を押して確定します。
5. このラボで作成した他のスタックについても上記の手順を繰り返します。例えば、`cfn-workshop-lambda-stack`、`cfn-workshop-database-stack`、`cfn-workshop-ec2-stack`です。

---
### まとめ
これで、動的参照を使用して、AWS Systems ManagerパラメータストアやAWS Secrets Managerなどのサービスで保存および管理する外部値を指定する方法がわかりました。詳しい情報については、[動的な参照を使用してテンプレート値を指定する](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html)を参照ください。
