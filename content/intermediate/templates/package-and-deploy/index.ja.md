---
title: "パッケージ化とデプロイ"
weight: 600
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

従来は、すべての Lambda ソースを圧縮して S3 にアップロードし、次にテンプレートでS3 ロケーションを参照する必要がありました。この作業はかなり面倒です。

ただし、[aws cloudformation package](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/package.html) を使えば、ローカルファイルを直接参照できます。直接参照の方が、S3を参照する従来の方法と比較し利用が簡単です。

`infrastructure.template` スニペットを見ると、`Code` プロパティのローカルディレクトリの [9] 行目への参照が分かります。

:::code{language=yaml showLineNumbers=true showCopyAction=false}
PythonFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: cfn-workshop-python-function
    Description: Python Function to return specific TimeZone time
    Runtime: python3.8
    Role: !GetAtt LambdaBasicExecutionRole.Arn
    Handler: lambda_function.handler
    Code: lambda/                                 # <<< This is a local directory
:::

#### アーティファクトをパッケージ化してアップロード

`aws cloudformation package` は以下のアクションを実行します。

1. ローカルファイルを ZIP で圧縮します。
2. 指定された S3 バケットにアップロードします。
3. ローカルパスが S3 URI に置き換えられた新しいテンプレートを生成します。

##### 1. S3 バケットの作成

一番最初に、CloudFormation テンプレートをデプロイする AWS リージョンを決定します。Lambda がパッケージ化されたアーティファクトにアクセスできるようにするには、S3 バケットが Lambda と同じリージョンにある必要があります。

::alert[`s3://` の後のバケット名は必ず一意の名前に置き換えてください！]{type="info"}

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 mb s3://example-bucket-name --region eu-west-1
:::

##### 2. インストール機能の依存関係

私たちの関数は外部ライブラリ [pytz](https://pypi.org/project/pytz/) に依存しているため、ローカルにインストールする必要があります。
関数のパッケージに含むために、[pip](https://pypi.org/project/pip/) でローカルフォルダーにインストールする必要があります。

`code/workspace/package-and-deploy` ディレクトリ内から以下を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install pytz --target lambda
:::

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

```yaml {hl_lines=[12,13,14]}
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
    TracingConfig:
      Mode: Active
```

アップロードされたファイルの内容も見てみましょう。上記のリストから、ダウンロードするバケットとオブジェクト名が判明しています。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 cp s3://example-bucket-name/cfn-workshop-package-deploy/1234567890 .
:::

`package` はファイルを圧縮することがわかっているので、`.zip` 拡張子がなくても `unzip` できます。

##### Unix/Linux
:::code{language=shell showLineNumbers=false showCopyAction=false}
unzip -l ce6c47b6c84d94bd207cea18e7d93458

Archive:  ce6c47b6c84d94bd207cea18e7d93458
  Length      Date    Time    Name
---------  ---------- -----   ----
       12  02-12-2020 17:21   requirements.txt
      455  02-12-2020 17:18   lambda_function.py
     4745  02-13-2020 14:36   pytz/tzfile.py
:::
##### Powershell
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

### テンプレートの検証

CloudFormation テンプレートのデプロイは、テンプレートの構文エラーが原因で失敗することがあります。

[`aws cloudformation validate-template`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/validate-template.html) で CloudFormation テンプレートをチェックして、有効な JSON または YAML であることを確認します。これは開発時間を短縮するのに役立ちます。

パッケージ化されたテンプレートを検証しましょう。`code/workspace/package-and-deploy` ディレクトリ内で以下を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation validate-template \
    --template-body file://infrastructure-packaged.template
:::

成功すると、CloudFormation はパラメータ、テンプレートの説明、機能のリストを含むレスポンスを送信します。

:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "Parameters": [],
    "Description": "CFN 201 Workshop - Lab 12 Helper Scripts. ()",
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
    --stack-name cfn-workshop-lambda \
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

::::tab{id="sh" label="Unix/Linux"}
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

::::tab{id="sh" label="Unix/Linux"}
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
### まとめ

おめでとうございます。コマンドラインを使用して CloudFormation テンプレートを正常にパッケージ化およびデプロイしました。

* `package` コマンドは、ネストされたスタック等を使用するテンプレートや、ローカルアセットを参照するテンプレートのデプロイを簡略化します。
* `validate` コマンドは、エラーをより迅速に検出することでテンプレートの開発をスピードアップできます。
* `deploy` コマンドを使うと、CloudFormation テンプレートをデプロイすることができます。
