---
title: "動的参照"
weight: 300
---

_ラボ実施時間 : 30分程度_

---

### 概要
このモジュールでは、CloudFormation テンプレートの[動的な参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html)を使用して、[AWS Systems Manager](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/what-is-systems-manager.html) (SSM)、[Parameter Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html)、[AWS Secrets Manager](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/intro.html) を含む AWS サービスに保存されている外部値を参照する方法を学びます。

 前のセクションで説明したように、CloudFormation テンプレートでは、AWS リソースの[ライフサイクルと所有権](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/best-practices.html) の基準とベストプラクティスを考慮し、一元化された場所に保存されている設定値を参照することもできます。Parameter Store は、構成データ管理のための安全な階層型ストレージを提供します。

また、AWS CloudFormation テンプレートから機密情報を参照する必要がある場合もあります。[AWS Secrets Manager](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/intro.html) を使用すると、データベースやその他のサービスの認証情報をプログラムで安全に暗号化、保存、取得できます。SSM [Secure String パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-secure-strings)を使用して機密データを保存および参照することもできます。

動的参照を使用すると、CloudFormation はスタックおよび [変更セット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)操作中に、必要に応じて指定された参照値を取得します。ただし、CloudFormation が実際の参照値を保存することはありません。

### 取り上げるトピック
このラボを修了すると、次のことができるようになります。

* CloudFormation テンプレートの外部値にアクセスするための*動的参照文字列*を作成
* 特定のバージョン、または*最新*バージョンの Parameter Store パラメータを取得
* Secrets Manager シークレットの特定のバージョンを取得
* JSON データ形式を使用するシークレットから特定のキーの値を抽出

### ラボを開始

#### Paramater Store の動的リファレンス
開発チームにライフサイクル環境を提供する必要があるシナリオを考えてみましょう。このプラクティスには、多くの場合、最新のオペレーティングシステムアップデート、セキュリティの強化要件、必要なサードパーティのソフトウェアエージェントを含むカスタム [Amazon Machine Images](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/AMIs.html) (AMI) の構築と配布が含まれます。

あなた (または組織のチーム) がカスタム AMI を作成したら、Parameter Store を使用して AMI の識別子を保存することができます。これにより、EC2 インスタンスを起動するときに使用する AMI をプログラムで指定しやすくなり、設定ミスの可能性が低くなります。

このラボでは、AMI ID を永続化する Parameter Store パラメータを作成します。カスタム AMI の代わりに、選択したリージョンで利用できる最新の _Amazon Linux 2023 AMI, 64-bit x86_ を使用します。次に、テンプレートに記述した EC2 インスタンスの `ImageId` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-imageid)でパラメータを参照します。

それでは、始めましょう！

:::alert{type="info"}
ワークショップの _AWS リージョン_ には **us-east-1 (バージニア北部)** を使用することをお勧めします。
:::

1. Amazon EC2 [コンソール](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#LaunchInstances:)の _インスタンスを起動_ に移動し、使用する[リージョンを選択](https://docs.aws.amazon.com/ja_jp/awsconsolehelpdocs/latest/gsg/select-region.html)します。次に、最新の *Amazon Linux 2023 AMI (64 ビット x86)* を探し、AMI ID (例:`ami-abcd1234`) を書き留めます。この値は次のステップで使用します。

![ec2](/static/intermediate/templates/dynamic-references/ec2-console-ami-picker.ja.png)

2. [AWS Command Line Interface](https://aws.amazon.com/jp/cli/) (CLI) を使用してパラメータを作成します。以下に示すコマンドを実行するときは、必ず `YOUR_AMI_ID` と `YOUR_REGION` のプレースホルダーを必要な値に置き換えてください。必要値の入力時には、特定の AWS リージョンを指定します。リージョンの詳細については、[リージョンエンドポイント](https://docs.aws.amazon.com/ja_jp/general/latest/gr/rande.html#regional-endpoints) の表の **コード** をご参照ください。また、必ず、前のステップで AMI を選択したときのリージョンと同一のリージョンを使用してください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm put-parameter \
 --name "/golden-images/amazon-linux-2" \
 --value YOUR_AMI_ID \
 --type "String" \
 --region YOUR_REGION
:::

::alert[CloudFormation を使用して、`String` または `StringList` タイプの Paramater Store パラメータを作成可能です。詳細については、[AWS::SSM::Parameter](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html) のドキュメントをご覧ください。]{type="info"}

3. `put-parameter` コマンドが成功すると、SSM は `Version` と `Tier` を返します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"Version": 1,
"Tier": "Standard"
:::

4. 次の手順に従って、テンプレートに記述した EC2 インスタンスのパラメータへの動的参照を作成します。

    1. `code/workspace/dynamic-references` ディレクトリに移動します。
    1. お好みのテキストエディタで `ec2-instance.yaml` CloudFormation テンプレートを開きます。
    1. テンプレート内の `AWS::EC2::Instance` リソースタイプブロックを探し、`Properties` セクションのプロパティに `ImageId` プロパティとパラメータへの動的参照を追加してテンプレートを更新します。
       :::code{language=yaml showLineNumbers=false showCopyAction=true}
       ImageId: '{{resolve:ssm:/golden-images/amazon-linux-2}}'
       :::

上記の動的参照を使って、スタックの実行時に `/golden-images/amazon-linux-2` パラメータの `LATEST` バージョンの値を解決します。

::alert[CloudFormation は、[動的参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm)による[パブリックパラメータ](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/parameter-store-finding-public-parameters.html)をサポートしていません。[SSM パラメータタイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types)を使用してパブリックパラメータの値を取得することができます。]{type="info"}

5. いよいよスタックを作成しましょう！ 以下の手順に従ってください。
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **Cloud9 ターミナル** で `code/workspace/dynamic-references` ディレクトリに移動します
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/dynamic-references
   :::
   2. AWS CLI を使用してスタックを作成します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-dynamic-references-ec2 \
--template-body file://ec2-instance.yaml
   :::
   1. `create-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
   :::code{language=shell showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-dynamic-references-ec2/3fabc340-e74e-11ed-9b33-0a550dedb7a1"
   :::
   1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** コンソールを新しいタブで開き、スタックのステータスが **CREATE_COMPLETE** になっているかどうかを確認します。
   ::::
   ::::tab{id="local" label="ローカル開発"}
   1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移   し **新しいリソースを使用 (標準)** を選択します。
   1. **テンプレートの準備** セクションで、 **テンプレート準備完了** を選択します。
   1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
   1. ファイル `ec2-instance.yaml` を選択します。
   1. スタック名を入力します。例えば、`cfn-workshop-dynamic-references-ec2` を入力します。
   1. **スタックオプションの設定** ページはデフォルト値のまま、 **次へ** をクリックします。
   1. スタックの **レビュー <スタック名>** ページで、一番下までスクロールし、 **送信** をクリックします。
   1. スタックの **CREATE_COMPLETE** ステータスが表示されるまでページを更新してください。
   ::::
   :::::

   ::alert[SSM パラメータへの動的参照を使用して、特定のパラメータバージョンを指すこともできます。例えば、CloudFormation にパラメータのバージョン `1` を解決させるには、`ImageId: '{{resolve:ssm:/golden-images/amazon-linux-2:1}}'` を使用します。特定のバージョンへの動的参照をロックすると、スタックの更新時にリソースが意図せず更新されることを防止するのに役立ちます。]{type="info"}

6. EC2 インスタンスに使用したイメージの ID が、Parameter Store パラメータに保存したイメージ ID と一致することを確認します。まず、CloudFormation コンソールの _リソース_ タブに移動して EC2 インスタンス ID を確認します。EC2 インスタンスの物理 ID を探し、その値を書き留めます。次に、以下のコマンドを実行します (コマンドを実行する前に、`YOUR_INSTANCE_ID` と `YOUR_REGION` プレースホルダーを置き換えてください)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ec2 describe-instances \
--instance-ids YOUR_INSTANCE_ID \
--region YOUR_REGION \
--query 'Reservations[0].Instances[0].ImageId'
:::
7. `describe-instances` コマンドが正常に送信された場合、EC2 は `ImageID` を返します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"ami-02396cdd13e9a1257"
:::

おめでとうございます！Parameter Store を使用して、動的参照の利用方法の例を学習しました。

#### AWS Secrets Manager の動的参照
[AWS Secrets Manager](https://aws.amazon.com/jp/secrets-manager/) は、データベース認証情報などの認証情報を保護するのに役立ちます。AWS Secrets Manager を用いると、コードにシークレットをハードコーディングしなくても、後でプログラムで利用できるようになります。例えば、[AWS Lambda](https://aws.amazon.com/jp/lambda/) 関数を作成して、[Amazon Relational Database Service (RDS)](https://aws.amazon.com/jp/rds/) データベースインスタンスのデータベース接続情報 (ホスト名やポートなど) を使用します。

このラボでは、Secrets Manager を使用してデータベースの*ホスト名*、*ポート*、*ユーザー名*、および*パスワード*を保存します。次に、動的参照を使用して、テンプレートに記述する `AWS::Lambda::Function` リソースから*ホスト名*と*ポート*情報を読み取ります。

それでは、始めましょう！次に示す手順に従って実行します。

1. Amazon RDS データベースを作成し、接続情報を AWS Secrets Manager にシークレットとして保存します。
    1. `code/workspace/dynamic-references` ディレクトリにいることを確認します。
    1. お好みのテキストエディタで `database.yaml` CloudFormation テンプレートを開きます。
    1. テンプレート内の次のリソースに注意してください。
        1. `AWS::RDS::DBInstance` タイプのリソース。本リソースを使用して Amazon RDS インスタンスを記述します。
        :::alert{type="info"}
        `AWS::RDS::DBInstance`タイプのリソースで (このラボの例のように) `DBClusterIdentifier` プロパティを指定していない場合、[削除ポリシー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html)が明示的に定義されていない場合、削除ポリシーはデフォルトで `Snapshot` になり、CloudFormation はリソースを削除する前にリソースのスナップショットを作成します。このラボでは、リソースの `DeletionPolicy` を `Delete` に設定して、削除時にスナップショットの作成をスキップします。
        :::
        1. `AWS::SecretsManager::Secret` タイプのリソース。データベース接続パラメータを JSON キーと値のペアとして、`DatabaseConnParams` という名前のシークレットに保存します。
       :::code{language=json showLineNumbers=true showCopyAction=false lineNumberStart=47}
       {
  "RDS_HOSTNAME": "${Database.Endpoint.Address}",
  "RDS_PORT": "${Database.Endpoint.Port}",
  "RDS_USERNAME": "${DBUsername}",
  "RDS_PASSWORD": "${DBPassword}"
}
       :::
2. データベーススタックをデプロイするには、以下の手順に従います。
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **Cloud9 ターミナル** で `code/workspace/dynamic-references` ディレクトリに移動します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/dynamic-references
   :::
   1. AWS CLI を使用してスタックを作成します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。`DBUsername` パラメータと `DBPassword` パラメータの値を入力します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-dynamic-references-database \
--template-body file://database.yaml \
--parameters ParameterKey=DBUsername,ParameterValue='admin' \
ParameterKey=DBPassword,ParameterValue='wjznf74irj831o9'
   :::
   1. `create-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
   :::code{language=shell showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-dynamic-references-database/5b6b44f0-e750-11ed-af8c-12a600715c03"
   :::
   1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** コンソールを新しいタブで開き、スタックのステータスが **CREATE_COMPLETE** になっているかどうかを確認します。最新のスタックステータスを確認するには、定期的に更新を選択する必要があります。
   ::::
   ::::tab{id="local" label="ローカル開発"}
   1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移し、 **新しいリソースを使用 (標準)** を選択します。
   1. **テンプレートの準備** セクションで、 **テンプレートの準備完了** を選択します。
   1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
   1. ファイル `database.yaml` を選択します。
   1. スタック名を入力します。例えば、`cfn-workshop-database-stack` と入力します。
   1. `DBUserName` には、DB インスタンスのプライマリユーザー名を指定します。
   1. `DBPassword` には、プライマリユーザーのパスワードを指定します。
   :::alert{type="info"}
   入力したユーザー名またはパスワードが無効な場合は、テンプレートのパラメーターの詳細を確認してください。
   :::
   1. **スタックオプションの設定** ページはデフォルト値のまま、 **次へ** をクリックします。
   1. スタックの **レビュー <スタック名>** ページで、一番下までスクロールして、 **送信** をクリックします。
   1. スタックの `CREATE_COMPLETE` ステータスが表示されるまでページを更新してください。
   ::::
   :::::

1. 次に、AWS Lambda 関数を作成し、以前に作成した Secrets Manager シークレットへの動的参照を使用して、いくつかのデータベース接続パラメータを[環境変数](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/configuration-envvars.html)として Lambda 関数に読み取ります。
    1. `code/workspace/dynamic-references` ディレクトリにいることを確認します。
    1. お好みのテキストエディタで `lambda-function.yaml` CloudFormation テンプレートを開きます。
    1. テンプレートには `AWS::Lambda::Function` リソースタイプが記述されています。`Properties` セクションに `Environment` プロパティを追加し、先ほど作成した AWS Secret Manager シークレットへの動的参照を使用する変数を追加してテンプレートを更新します。
    :::code{language=yaml showLineNumbers=false showCopyAction=true}
    Environment:
  Variables:
    RDS_HOSTNAME: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_HOSTNAME}}'
    RDS_PORT: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_PORT}}'
    :::
1. Lambda スタックをデプロイするには、以下の手順に従います。
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **Cloud9 ターミナル** で `code/workspace/dynamic-references` ディレクトリに移動します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/dynamic-references
   :::
   1. AWS CLI を使用してスタックを作成します。必須パラメータ `--stack-name` と `--template-body` と `--capabilities` はあらかじめ入力されています。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-dynamic-references-lambda \
--template-body file://lambda-function.yaml \
--capabilities CAPABILITY_IAM
   :::
   1. `create-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
   :::code{language=shell showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-dynamic-references-lambda/7e465860-e751-11ed-aa31-0a674dce3c49"
   :::
   1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** コンソールを新しいタブで開き、スタックのステータスが **CREATE_COMPLETE** になっているかどうかを確認します。最新のスタックステータスを確認するには、定期的に更新を選択する必要があります。
   ::::
   ::::tab{id="local" label="ローカル開発"}
   1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動し **新しいリソースを使用 (標準)** を選択します。
   1. **テンプレートの準備** セクションで、 **テンプレートの準備完了** を選択します。
   1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** をクリックします。
   1. ファイル `lambda_function.yaml` を選択します。
   1. スタック名を入力します。例えば、`cfn-workshop-lambda-stack` と入力し、 **次へ** をクリックします。
   1. **スタックオプションの設定** ページはデフォルト値のまま、 **次へ** をクリックします。
   1. **レビュー <スタック名>** ページで、一番下までスクロールし、 **AWS CloudFormation が IAM リソースを作成する可能性があることを認識しています** チェックボックスをチェックし、 **送信** をクリックします。
   1. スタックのステータスが `CREATE_COMPLETE` になるまでページを更新します。
   ::::
   :::::

先ほど使用したテンプレートでは、データベース接続パラメーターはスタックの実行時に動的文字列を使用して取得されます。`RDS_HOSTNAME` などの特定のキーの値を、`'{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_HOSTNAME}}'` で取得しました。なお、`DatabaseConnParams` はシークレット ID を示しています。

::alert[AWS Secrets Manager のシークレットには、暗号化されたシークレット値のコピーを保持する [*versions*](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/getting-started.html#term_version) があります。シークレットの値を変更すると、Secrets Manager は新しいバージョンを作成します。シークレットには常に、現在のシークレット値であるステージングラベル `AWSCURRENT` のバージョンがあります。必要に応じて、*バージョンステージ*または*バージョン　 ID* を指定して、この文字列を次のように変更できます: `'{{resolve:secretsmanager:prod-DatabaseConnParams:SecretString:RDS_HOSTNAME:<version-stage>:<version-id>}}'`。バージョンを指定しない場合、CloudFormation はステージ `AWSCURRENT` に関連するシークレットをデフォルトで解決します。]{type="info"}

5. 作成したサンプルの Lambda 関数を呼び出すと、関数は `RDS_HOSTNAME` と `RDS_PORT` 環境変数をフェッチし、それらの値を出力します。まず、CloudFormation コンソールの _リソース_ タブに移動し、Lambda 関数名を見つけます。Lambda 関数の物理 ID を探し、その値を書き留めます。次に、次のコマンドを使用し、データベース接続パラメーターを Lambda 関数に渡していることを確認します (`YOUR_FUNCTION_NAME` を Lambda 関数名に、`YOUR_REGION` を必要な値に置き換えてください)。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws lambda invoke \
 --function-name YOUR_FUNCTION_NAME \
 --region YOUR_REGION \
 output.json
:::

次のコマンドを使用して、上記コマンドの出力を表示します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cat output.json
:::

output.json の内容が出力されます。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"Database: cfn-workshop-dynamic-references-database-database-rrxa105iggu0.csxwxntvtkdn.us-east-1.rds.amazonaws.com:3306"
:::

おめでとうございます！ AWS Secrets Manager で動的参照を使用する方法を学びました。

### チャレンジ
この演習では、*動的参照*についての理解を深めます。

AWS Lambda では、`MemorySize` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize)で、[関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html)のメモリ構成をサポートします。ここでのタスクは、AWS CLI で Paramater Store パラメータを作成することです。ここで、`Lambda_memory_size.yaml` テンプレートに記述する Lambda 関数に使用するメモリサイズを設定します。次に、作成したパラメーターのバージョン `1` への動的参照を作成し、テンプレートを使用してスタックを作成してビルドした内容が機能することを確認します。`cfn-workshop-dynamic-references-lambda-memory` スタックを呼び出します。Parameter Store パラメータは、スタックの作成時に選択したものと同じ AWS リージョンに作成します。

:::expand{header= "ヒントが必要ですか？"}
1. CloudFormation [ユーザーガイド](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize) を参照し、Lambda 関数の `MemorySize` 設定を指定する方法を理解してください。
1. 特定のバージョンの Parameter Store パラメータへの動的参照文字列を作成する方法については、CloudFormation [ユーザーガイド](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-pattern)をご参照ください。
:::

::::expand{header="解決策を確認しますか？"}
1. 以下のコマンドを使用して、必要なメモリ設定を指定する Parameter Store パラメータを作成します (`YOUR_REGION`を必要な値に置き換えてください)。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm put-parameter \
--name "/lambda/memory-size" \
--value "256" \
--type "String" \
--region YOUR_REGION
:::
1. お好みのテキストエディタで `code/workspace/dynamic-references/lambda-memory-size.yaml` テンプレートを開きます。パラメータへの動的参照を使用して `MemorySize` プロパティを含む以下の例を `Resources` セクションに追加して、テンプレートを更新します。
:::code{language=yaml showLineNumbers=false showCopyAction=true}
HelloWorldFunction:
  Type: AWS::Lambda::Function
  Properties:
    Role: !GetAtt FunctionExecutionRole.Arn
    Handler: index.handler
    Runtime: python3.9
    MemorySize: '{{resolve:ssm:/lambda/memory-size:1}}'
    Code:
      ZipFile: |
        import os
        def handler(event, context):
            return "Hello World!"
:::
1. 以前の Lambda 関数と同様に、`cfn-workshop-dynamic-references-lambda-memory` CloudFormation スタックを作成して、テンプレートに記述して更新したリソースをプロビジョニングします。
1. [AWS コマンドラインインターフェイス](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/gettingstarted-awscli.html)(CLI) を実行して、MemorySize の SSM パラメータ値を使用して Lambda 関数が作成されたことを確認します。`--query` パラメータはすでに入力されています (`YOUR_REGION` を必要な値に置き換えてください)。
:::code{language=yaml showLineNumbers=false showCopyAction=true}
aws lambda list-functions --query 'Functions[*].[FunctionName,MemorySize,Environment]' --region YOUR_REGION
:::
1. 成功すると、`aws lambda list-functions` には少なくとも 2 つの関数の詳細が表示されるはずです。1 つは RDS 環境変数を使用して作成したもので、もう 1 つは `MemorySize` を 256 に設定したものです。
:::code{language=json showLineNumbers=false showCopyAction=false}
[
    [
        "cfn-workshop-dynamic-references-HelloWorldFunction-xhsdJOc49hhX",
        256,
        null
    ],
    [
        "cfn-workshop-dynamic-references-l-DatabaseFunction-XO1tBoIQL3xT",
        128,
        {
            "Variables": {
                "RDS_HOSTNAME": "cfn-workshop-dynamic-references-database-database-eyffmthgvwih.csxwxntvtkdn.us-east-1.rds.amazonaws.com",
                "RDS_PORT": "3306"
            }
        }
    ]
]
:::

解決策は、`code/solutions/dynamic-references/lambda-memory-size.yaml` サンプルテンプレートにあります。
::::

### クリーンアップ
1. `cfn-workshop-dynamic-references-lambda` と `cfn-workshop-dynamic-references-lambda-memory` で作成した Lambda 関数に関連付けられた CloudWatch ロググループを削除します (チャレンジセクションの Lambda 関数を呼び出した場合は、関連するロググループが存在しているはずです)。

   スタックごとに、CloudFormation コンソールの **リソース** タブに移動して Lambda 関数名を検索し、Lambda 関数の物理 ID を探して、その値を書き留めます。次に、作成した各 Lambda 関数に対して以下のコマンドを使用します (`YOUR_FUNCTION_NAME` を Lambda 関数名に置き換え、`YOUR_REGION` を必要な値に置き換えてください)。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws logs delete-log-group \
--log-group-name /aws/lambda/YOUR_FUNCTION_NAME \
--region YOUR_REGION
:::
1. 次のコマンドを使用して、AMI ID と `MemorySize` 設定を保存するために作成した 2 つの Parameter Store パラメータを削除します (`YOUR_REGION` は必要な値に置き換えてください)。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm delete-parameters \
--names "/golden-images/amazon-linux-2" "/lambda/memory-size" \
--region YOUR_REGION
:::
1. 次に、CloudFormation コンソールで、最後に作成したスタック (例: `cfn-workshop-dynamic-references-lambda-memory`) を選択します。
1. **削除** を選択した後、 **スタックの削除** をクリックして確定します。
1. このラボで作成した他のスタックについても上記の手順を繰り返します。具体的には、`cfn-workshop-dynamic-references-lambda`、`cfn-workshop-dynamic-references-database`、`cfn-workshop-dynamic-references-ec2` スタックです。

---
### まとめ
動的参照を使用して、AWS Systems Manager Parameter Store や AWS Secrets Manager などのサービスで保存および管理する外部値を指定する方法がわかりました。詳しい情報については、[動的な参照を使用してテンプレート値を指定する](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html)をご参照ください。
