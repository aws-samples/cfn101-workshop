---
title: "パッケージ化とデプロイ"
weight: 600
---

_ラボ実施時間 : 15分程度_

---

### 概要

このワークショップの [基本](/basics)で、CloudFormation コンソールを介して単一の YAML テンプレートをデプロイしました。
基本編は、非常に簡単な作業でしたが、CloudFormation テンプレートが他のファイルまたはアーティファクトを参照する場合もあります。

例えば、Lambda のソースコードや ZIP ファイル、またはネストされた CloudFormation テンプレートファイルは、アーティファクトです。
[ネストされたスタックのラボ](/intermediate/templates/nested-stacks)で学んだように、 メインの CloudFormation テンプレートをデプロイする前に、これらのファイルが S3 で利用可能になっている必要があります。

より複雑なスタックのデプロイは多段階のプロセスが必要ですが、AWS CLI には、他のファイルを参照して CloudFormation テンプレートをデプロイする方法が用意されています。

このセクションでは、AWS CLI で CloudFormation テンプレートをパッケージ化、検証、デプロイするために使用する 3 つの主要なコマンドについて説明します。



### 取り上げるトピック

このラボを修了すると、次のことができるようになります。
* テンプレートをパッケージ化する必要があるケースを確認
* `aws cloudformation package` コマンドを使ってテンプレートをパッケージ化
* `aws cloudformation validate-template` コマンドを使用して CloudFormation テンプレートを検証
* `aws cloudformation deploy` コマンドを使用してテンプレートをデプロイ

### ラボを開始

`code/workspace/package-and-deploy` ディレクトリにあるサンプルプロジェクトを見てください。

プロジェクトの構成は以下のとおりです。

* インフラストラクチャをスピンアップするための CloudFormation テンプレート
* 1 つの Lambda 関数
* 関数の依存関係をインストールするための要件ファイル

:::code{language=shell showLineNumbers=false showCopyAction=false}
cfn101-workshop/code/workspace/package-and-deploy
├── infrastructure.template
└── lambda/
    ├── lambda_function.py
    └── requirements.txt
:::

#### CloudFormation テンプレート内のローカルファイルを参照

従来は、すべての Lambda ソースを圧縮して S3 にアップロードし、次にテンプレートで S3 ロケーションを参照する必要がありました。この作業はかなり面倒です。

ただし、[aws cloudformation package](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/package.html) を使えば、ローカルファイルを直接参照できます。直接参照の方が、S3 を参照する従来の方法と比較し利用が簡単です。

`infrastructure.template` スニペットを見ると、`Code` プロパティのローカルディレクトリの [9] 行目への参照が分かります。

:::code{language=yaml showLineNumbers=true showCopyAction=false lineNumberStart=19}
PythonFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: cfn-workshop-python-function
    Description: Python Function to return specific TimeZone time
    Runtime: python3.8
    Role: !GetAtt LambdaBasicExecutionRole.Arn
    Handler: lambda_function.handler
    Code: lambda/ # <<< This is a local directory
:::

#### アーティファクトをパッケージ化してアップロード

`aws cloudformation package` は以下のアクションを実行します。

1. ローカルファイルを ZIP で圧縮します。
1. 指定された S3 バケットにアップロードします。
1. ローカルパスが S3 URI に置き換えられた新しいテンプレートを生成します。

##### 1. S3 バケットの作成

一番最初に、CloudFormation テンプレートをデプロイする AWS リージョンを決定します。Lambda がパッケージ化されたアーティファクトにアクセスできるようにするには、S3 バケットが Lambda と同じリージョンにある必要があります。

::alert[`s3://` の後のバケット名は必ず一意の名前に置き換えてください！]{type="info"}

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 mb s3://example-bucket-name --region us-east-1
:::

##### 2. インストール機能の依存関係

私たちの関数は外部ライブラリ [pytz](https://pypi.org/project/pytz/) に依存しているため、ローカルにインストールする必要があります。
関数のパッケージに含むために、[pip](https://pypi.org/project/pip/) でローカルフォルダーにインストールする必要があります。

`code/workspace/package-and-deploy` ディレクトリ内から以下を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install pytz --target lambda
:::

`python 3` がお使いの場合は、上記のコマンドで `pip` の代わりに `pip3` を使う必要があるかもしれません。

`lambda/` フォルダの中に `pytz` パッケージがあるはずです。

##### 3. `package` コマンドの実行

`code/workspace/package-and-deploy` ディレクトリ内から以下を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation package \
--template-file infrastructure.template \
--s3-bucket example-bucket-name \
--s3-prefix cfn-workshop-package-deploy \
--output-template-file infrastructure-packaged.template
:::

上記のコマンドで使った個々の `package` オプションを詳しく見てみましょう。

* `--template-file` - これは CloudFormation テンプレートが置かれているパス
* `--s3-bucket` - アーティファクトがアップロードされる S3 バケットの名前
* `--s3-prefix` - プレフィックス名は S3 バケットのパス名 (フォルダ名)
* `—output-template-file` - 出力される AWS CloudFormation テンプレートの書き込み先ファイルパス

##### 4. パッケージファイルを確認する

新しく生成されたファイル `infrastructure-packaged.template` を見てみましょう。

`Code` プロパティが [12-14] 行目の `S3Bucket` と `S3Key` の 2 つの新しい属性で更新されていることが分かります。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=16 highlightLines=12-14}
PythonFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: cfn-workshop-python-function
    Description: Python Function to return specific TimeZone time
    Runtime: python3.8
    Role:
      Fn::GetAtt:
      - LambdaBasicExecutionRole
      - Arn
    Handler: lambda_function.handler
    Code:
      S3Bucket: example-bucket-name
      S3Key: cfn-workshop-package-deploy/1234567890
:::

アップロードされたファイルの内容も見てみましょう。上記のリストから、ダウンロードするバケットとオブジェクト名が判明しています。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 cp s3://example-bucket-name/cfn-workshop-package-deploy/1234567890 .
:::

`package` はファイルを ZIP 形式で圧縮することがわかっているので `.zip` 拡張子がなくても `unzip` できます。

:::::tabs{variant="container"}
::::tab{id="shell" label="Cloud9/Unix/Linux"}
:::code{language=shell showLineNumbers=false showCopyAction=false}
unzip -l ce6c47b6c84d94bd207cea18e7d93458

Archive:  ce6c47b6c84d94bd207cea18e7d93458
  Length      Date    Time    Name
---------  ---------- -----   ----
       12  02-12-2020 17:21   requirements.txt
      455  02-12-2020 17:18   lambda_function.py
     4745  02-13-2020 14:36   pytz/tzfile.py
:::
::::
::::tab{id="powershell" label="Powershell"}
:::code{language=powershell showLineNumbers=false showCopyAction=false}
rename-item ce6c47b6c84d94bd207cea18e7d93458 packagedLambda.zip

Expand-Archive -LiteralPath packagedLambda.zip -DestinationPath packagedLambda

ls packagedLambda

Directory: C:\Users\username\cfn101-workshop\code\workspace\package-and-deploy\tmp
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        10/29/2021   4:25 PM                pytz
d-----        10/29/2021   4:25 PM                pytz-2021.3.dist-info
-a----        10/29/2021  11:19 AM            475 lambda_function.py
-a----        10/29/2021  11:19 AM             14 requirements.txt
:::
::::
:::::

### テンプレートの検証

CloudFormation テンプレートのデプロイは、テンプレートの構文エラーが原因で失敗することがあります。

[`aws cloudformation validate-template`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/validate-template.html) で CloudFormation テンプレートをチェックして、有効な JSON または YAML であることを確認します。これは開発時間を短縮するのに役立ちます。

パッケージ化されたテンプレートを検証しましょう。`code/workspace/package-and-deploy` ディレクトリ内で以下を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation validate-template \
    --template-body file://infrastructure-packaged.template
:::

成功すると、CloudFormation はパラメータ、テンプレートの説明、機能のリストを含むレスポンスを送信します。

:::code{language=json showLineNumbers=false showCopyAction=false}
{
    "Parameters": [],
    "Description": "AWS CloudFormation workshop - Package and deploy.",
    "Capabilities": [
        "CAPABILITY_IAM"
    ],
    "CapabilitiesReason": "The following resource(s) require capabilities: [AWS::IAM::Role]"
}
:::

### 「パッケージ化された」テンプレートのデプロイ

[`aws cloudformation deploy`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html) コマンドは、CLI を使用して CloudFormation テンプレートをデプロイするために使用されます。

パッケージ化されたテンプレートをデプロイしましょう。

`code/workspace/package-and-deploy` ディレクトリ内で以下を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deploy \
--template-file infrastructure-packaged.template \
--stack-name cfn-workshop-package-deploy-lambda \
--region eu-west-1 \
--capabilities CAPABILITY_IAM
:::

::alert[S3 のアーティファクトを参照するパッケージテンプレート `infrastructure-packaged.template` を利用した点に注意してください。ローカルパスを持つオリジナルのものではありません！]{type="info"}

`--parameter-overrides` オプションを設定してテンプレート内のパラメータを指定することもできます。
`'key=value'` のペアを含む文字列や、[提供された json ファイル](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-usage-parameters.html#cli-usage-parameters-json) などを用いて指定します。

##### Capabilities

コンソールを使用する際に、このテンプレートをデプロイするとリソースが作成される可能性があることを認識する必要があります。
アカウントの権限に影響する可能性があり、意図せずに誤って権限を変更しないようにするためです。

CLI を使用する際には、このスタックによって IAM の権限に影響するリソースが作成される可能性があることも確認する必要があります。
そのためには、前の例で示したように、`--capabilities` フラグを使います。capabilities については、
[`aws cloudformation deploy` のドキュメント](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html)をご参照ください。

#### Lambda のテスト

Lambda 関数をテストするには、[aws lambda invoke](https://docs.aws.amazon.com/cli/latest/reference/lambda/invoke.html) コマンドを使用します。

Lambda 関数は、現在の UTC の日付と時刻を取得します。次に、UTC 時刻をペイロードオプションで指定されたタイムゾーンに変換します。

ターミナルから以下を実行します。

:::::tabs{variant="container"}
::::tab{id="sh" label="Cloud9/Unix/Linux"}
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws lambda invoke \
--function-name cfn-workshop-python-function \
--payload "{\"time_zone\": \"Asia/Tokyo\"}" \
--cli-binary-format raw-in-base64-out \
response.json
:::
::::
::::tab{id="cmd" label="CMD"}
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws lambda invoke ^
--function-name cfn-workshop-python-function ^
--payload "{\"time_zone\": \"Asia/Tokyo\"}" ^
--cli-binary-format raw-in-base64-out ^
response.json
:::
::::
::::tab{id="powershell" label="Powershell"}
:::code{language=powershell showLineNumbers=false showCopyAction=true}
aws lambda invoke `
    --function-name cfn-workshop-python-function `
    --payload "{\`"time_zone\`": \`"Asia/Tokyo\`"}" `
    --cli-binary-format raw-in-base64-out `
    response.json
:::
::::
:::::

Lambda がトリガーされ、Lambda からのレスポンスが `response.json` ファイルに保存されます。

以下のコマンドを実行すると、ファイルの結果を確認できます。

:::::tabs{variant="container"}

::::tab{id="sh" label="Cloud9/Unix/Linux"}
:::code{language=shell showLineNumbers=false showCopyAction=true}
cat response.json
:::
::::

::::tab{id="cmd" label="CMD/Powershell"}
:::code{language=powershell showLineNumbers=false showCopyAction=true}
more response.json
:::
::::
:::::

---

### クリーンアップ

次の手順に従ってこのラボで作成したリソースをクリーンアップしてください。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを使用して S3 バケットを削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 rb s3://example-bucket-name --force
:::
1. 次の AWS CLI コマンドを使用してスタックを削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
 --stack-name cfn-workshop-package-deploy-lambda
:::
1. 次の AWS CLI コマンドを使用して、スタックの削除が完了するのを待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--stack-name cfn-workshop-package-deploy-lambda
:::
::::
::::tab{id="LocalDevelopment" label="ローカル開発"}
1. [AWS S3 コンソール](https://s3.console.aws.amazon.com/s3/)に移動します。
1. このラボで作成した S3 バケットを選択し、 **空にする** を選択します。
1. コンソールの指示に従って、バケット内のオブジェクトの削除を確認します。
1. 次に S3 コンソールに戻り、このラボで作成した S3 バケットを選択し、 **削除** を選択します
1. コンソールの指示に従って、S3 バケットの削除を確認します。
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
1. `cfn-workshop-package-deploy-lambda` という名前のスタックを選択し、 **削除** を選択します。
1. ポップアップウィンドウで、 **削除** を選択します。
1. **DELETE_COMPLETE** というステータスが表示されるまで、画面を更新します。
::::
:::::

---

### まとめ

おめでとうございます。コマンドラインを使用して CloudFormation テンプレートを正常にパッケージ化およびデプロイしました。

* `package` コマンドは、ネストされたスタック等を使用するテンプレートや、ローカルアセットを参照するテンプレートのデプロイを簡略化します。
* `validate` コマンドは、エラーをより迅速に検出することでテンプレートの開発をスピードアップできます。
* `deploy` コマンドを使うと、CloudFormation テンプレートをデプロイすることができます。
