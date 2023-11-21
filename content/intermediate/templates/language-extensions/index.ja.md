---
title: "言語拡張"
weight: 640
---

_ラボ実施時間 : 30分程度_

---

### 概要

AWS CloudFormation 言語を拡張することを目指して、CloudFormation チームは [RFC](https://github.com/aws-cloudformation/cfn-language-discussion) を通じてして CloudFormation コミュニティとオープンな議論を交わしてきました。これらの議論の結果、CloudFormation のための新しい言語拡張がリリースされました。リリースされた新しい言語拡張は変換機能で CloudFormation によって実行されるマクロです。2022 年の初期リリースでは、3 つの新しい言語拡張が追加されました。

1. JSON 文字列変換([Fn::ToJsonString](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ToJsonString.html)): オブジェクトまたは配列を対応する JSON 文字列に変化します。
2. Length([Fn::Length](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-length.html)): 配列内の要素数を返却します。
3. [組み込み関数と擬似パラメータのリファレンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/function-refs-in-policy-attributes.html): ユーザが定義した `DeletionPolicy` と `UpdateReplacePolicy` [リソース属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-product-attribute-reference.html) の値をパラメータなどから取得できるようにします。


詳細については、[Introducing new language extensions in AWS CloudFormation](https://aws.amazon.com/blogs/mt/introducing-new-language-extensions-in-aws-cloudformation/) をご参照ください。

このラボでは、 これらの言語拡張を活用してどのように開発者体験を向上させるのかを探り、学習します。


### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* `AWS::LanguageExtensions` トランスフォームを CloudFormation テンプレートに組み込む方法の理解
* CloudFormation テンプレートでの言語拡張の使用

### ラボを開始

### 事前準備

AWS アカウントに付属するデフォルト VPC を使用できる状態にあります。


### ラボパート 1

このラボのパート 1 では、サンプルの CloudFormation テンプレート `language-extentions.yaml` を使用して、`us-east-1` リージョンにスタックを作成します。開始するには、以下に示すステップに進んでください。

1. `code/workspace/language-extensions` のディレクトリに移動します。
2. ご自身のエディターで `language-extensions.yaml` の CloudFormation テンプレートを開きます。
3. テンプレート内のリソースの設定を確認します。このテンプレートは `Dev` 環境リソースとしてタグづけされた [Amazon Elastic Compute Cloud (Amazon EC2)](https://aws.amazon.com/ec2/) インスタンスを作成します。この時点のテンプレートでは EC2 インスタンスの `DeletionPolicy` [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) が指定されていないことに注目してください。

デフォルトでは、CloudFormation はリソースの `DeletionPolicy` 属性のデフォルト値として `Delete` を使用します。ただし、 `AWS::RDS::DBCluster` リソースと、`DBClusterIdentifier` プロパティを指定しない `AWS::RDS::DBInstance` リソースは例外です。上記のテンプレートを使用してスタックを作成した場合、スタック自体を削除すると EC2 インスタンスは終了します。一般的な使用例の 1 つは、本番環境で作成されたリソースを保持しながら、必要に応じてテストリソースを柔軟に破棄して開発アクティビティ用に再作成することです。テンプレートの `AWS::LanguageExtensions` トランスフォームを使用すると、必要な `DeletionPolicy` の値をパラメータから参照できます。`DeletionPolicy` や `UpdateReplacePolicy` のようなリソース属性は通常は文字列の指定が必要ですが、言語拡張を使用すると値をパラメータから参照する機能が追加されます。

この例では、`DEV` 環境のインスタンスの `DeletionPolicy` を `Delete` として指定することを意図しています。次の手順に進んでください。

1. `code/workspace/language-extensions` ディレクトリに移動します。
1. `language-extensions.yaml` テンプレートを開きます。`AWS::LanguageExtensions` のトランスフォーマ行を追加するには、`AWSTemlateFormatVersion: "2010-09-09"` の行の下に、以下のコンテンツをコピーして貼り付けます。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=3}
Transform: AWS::LanguageExtensions
:::
1. 既存の `Parameters` セクションの配下に、例えば `DeletionPolicyParameter` という名前のパラメータを次のコードのように追加します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=13}
DeletionPolicyParameter:
  Type: String
  AllowedValues: [Delete, Retain]
  Default: Delete
:::
1. `Resource` セクションの配下にある EC2 インスタンスのリソース設定を変更します。`Type` プロパティと同じレベルに `DeletionPolicy` を追加し、先ほど設定した `DeletionPolicyParameter` を参照させます。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=18 highlightLines=20}
Resources:
  EC2Instance:
    DeletionPolicy: !Ref DeletionPolicyParameter
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      Tags:
        - Key: Environment
          Value: DEV
:::

テンプレートファイルを保存し、次の手順に進みます。

次に、変更したテンプレートを使用して `us-east-1` リージョンに新しいスタックを作成します。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを実行してスタックを作成します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-language-extensions \
--template-body file://language-extensions.yaml \
--capabilities CAPABILITY_AUTO_EXPAND
1. CloudFormation は次のアウトプットを返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-language-extensions/466df9e0-0dff-08e3-8e2f-5088487c4896"
:::
1. [wait stack-create-complete] (https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI コマンドを使用して、`CREATE` 操作が完了するまでお待ちください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-language-extensions
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール] (https://console.aws.amazon.com/cloudformation/) に移動します。
1. 左側のナビゲーションパネルから **スタック** を選択します。ページの右側から **スタックの作成** を選択し、**新しいリソースを使用 (標準)** を選択します。
1. **前提条件 - テンプレートの準備** から **テンプレートの準備完了** を選択します。
1. **テンプレートの指定** セクションで、**テンプレートソース** で **テンプレートファイルのアップロード** を選択します。**ファイルの選択** を選択し、更新した `language-extentions.yaml` テンプレートを指定して、**次へ** を選択します。
1. **スタック詳細を指定** のページで
    1. **スタック名** を指定します。例えば `cfn-workshop-language-extensions` を入力します。
    1. **パラメータ** で、テンプレートのデフォルト値として設定されている `DeletionPolicyParameter` の値に `Delete` を選択し、`LatestAmiId` の値をそのままにしておきます。**次へ** を選択します。
1. **スタックオプションの設定** では、設定をそのままにしておきます。**次へ** を選択します。
1. **レビュー** ページで、設定内容を確認します。ページの下部に **機能と変換** セクションに表示されている機能をすべて承認するように選択してください。**送信** を選択します。
1. スタックが `CREATE_COMPLETE` ステータスになるまで、スタック作成ページを更新します。
::::
:::::

おめでとうございます！これで `DeletionPolicy` 属性用の組み込み関数リファレンスを使用する方法を学びました。`UpdateReplacePolicy` 属性と一緒に使用することもできます。次のパートでは、`Fn::ToJsonString` という別の言語拡張の使い方を学びます。

### ラボパート 2

EC2 インスタンスを実行できたので、AWS リソースのメトリクスとアラームをカスタマイズして表示する [Amazon CloudWatch ダッシュボード](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html) を作成してモニタリングすることとします。`CPUUtilization` や `DiskReadOps` などのメトリクスを [ウィジェット](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/create-and-work-with-widgets.html) としてダッシュボードに追加できます。

ダッシュボード本文は JSON 形式の文字列です。詳細については、[ダッシュボード本体の構造と構文](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html)を参照してください。CloudFormation を使用して CloudWatch ダッシュボードを記述する時は、次のようなキーとバリューを含む JSON 文字列を指定します。

:::code{language=json showLineNumbers=true showCopyAction=false}
{
    "start":"-PT6H",
    "periodOverride":"inherit",
    [...]
}
:::


ダッシュボード作成と利用をより簡単にするため (例えば、`\"` のような内部引用符のエスケープを避けるため)、また一行の文字列を保持しないようにするには、`Fn::ToJsonString` 言語拡張を使用して JSON オブジェクトを指定できます。これにより作成と管理が容易になります。この言語拡張機能を使用すると、代わりに CloudWatch ダッシュボードの構造を JSON オブジェクトとして指定できるためタスクが簡単になります。

`Fn::ToJsonString` を使用すると、開発者はオブジェクトまたは配列形式のテンプレートブロックをエスケープされた JSON 文字列に変換できます。その後、新たに変換された JSON 文字列を CloudWatch ダッシュボードリソースタイプを含むリソースの文字列型プロパティへの入力値として使用できます。これにより、テンプレート内のコードが簡略化され、読みやすくなります。

ラボのこのパート 2 では、前に作成した `language-extensions` スタックを更新し、 EC2 インスタンスの `CPUUtilization` メトリクスを含む CloudWatch ダッシュボードを追加します。

作業をシンプルにするため、この演習ではダッシュボードを既存のテンプレートに追加して、使用する言語拡張機能に焦点を当てれるようにします。通常、[ライフサイクルと所有権](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/best-practices.html#organizingstacks)によるスタックの整理を含むベストプラクティスを考慮して、ダッシュボード用に別のテンプレートを作成します。例えば、CloudWatch ダッシュボードのライフサイクルを EC2 インスタンスのライフサイクルから切り離すために、別のテンプレートを作成したいと考えることがあると思います。

`language-extensions.yaml` テンプレートを更新して、パート 1 で作成した EC2 インスタンスの CPU 使用率データを含む CloudWatch ダッシュボードを追加します。そのためには以下のステップに沿って実施します。

1. `language-extensions.yaml` テンプレートを開きます。`Resources` セクション配下に `Dashboard` を追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=29}
Dashboard:
  Type: AWS::CloudWatch::Dashboard
  Properties:
    DashboardBody:
      Fn::ToJsonString:
        start: -PT6H
        periodOverride: inherit
        widgets:
          - type: metric
            x: 0
            "y": 7
            width: 3
            height: 3
            properties:
              metrics: [[AWS/EC2, CPUUtilization, InstanceId, !Ref EC2Instance]]
              period: 300
              stat: Average
              region: !Ref AWS::Region
              title: EC2 Instance CPU
:::

上記のスニペットでは、`CPUUtilization` メトリックが `properties` セクション配下に `metrics` フィールドを介して反映されていることを注目してください。EC2 インスタンスの参照のための `!Ref` を利用し、インスタンス ID を取得しています。また、現在のリージョンを参照するには `!Ref AWS::Region` を使用しています。`AWS::Region` CloudFormation 擬似パラメータを使用して、スタックと EC2 インスタンスを作成するリージョンの名前で取得します。(このラボでは `us-east-1`)

テンプレートファイルを保存し、次の手順に進みます。

パート 1 で作成した既存のスタックを更新します。そのためには、以下に示す手順を実施します。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを実行して、スタック `cfn-workshop-language-extensions` を更新します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-language-extensions \
--template-body file://language-extensions.yaml \
--capabilities CAPABILITY_AUTO_EXPAND
1. CloudFormation は次の出力を返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-language-extensions/466df9e0-0dff-08e3-8e2f-5088487c4896"
:::
1. [wait stack-update-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-update-complete.html) AWS CLI コマンドを使用して `UPDATE` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-language-extensions
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. 左側のナビゲーションパネルから、**スタック** を選択します。前に作成した `cfn-workshop-language-extensions` スタックを選択します。
1. 右上のメニューから **更新** を選択します。
1. **前提条件 - テンプレートの準備**で、**既存テンプレートを置き換える** を選択し、**テンプレートファイルのアップロード**を選択します。**ファイルの選択** を選択し、更新した `language-extensions.yaml` テンプレートを指定して **次へ** を選択します。
1. **スタックの詳細を指定** ページでは、設定をそのままにしておきます。 **次へ** を選択します。
1. **スタックオプションの設定** では、設定をデフォルトのままにしておきます。**次へ** を選択します。
1. **レビュー** ページで、ページの内容を確認します。ページの下部で、**機能と変換** セクションに表示されている機能をすべて承認するように選択してください。
1. **送信** を選択します。スタックのステータスが `UPDATE_COMPLETE` になるまでスタック作成ページを更新します。
::::
:::::

* [CloudWatch コンソール](https://console.aws.amazon.com/cloudwatch/)に移動します。左側のナビゲーションパネルから、**ダッシュボード** を選択します。
* 作成した **ダッシュボード** を選択し、右上から **アクション** を選択します。
* **ソースを表示 / 編集** を選択すると、`language-extensions.yaml` の `YAML` と同等の `JSON` がダッシュボードに表示されるはずです。

おめでとうございます！`Fn::ToJsonString` を使用して JSON オブジェクトをリソースプロパティへの入力としてエスケープされた JSON 文字列に変換する方法を学習しました。

### チャレンジ

この演習では、このラボで得た知識を使用します。あなたのタスクは、削除ポリシーを `Delete` というパラメータ値に設定した [Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) バケットを作成し、バケット内のオブジェクト数を反映する CloudWatch ダッシュボードを作成することです。`language-extensions-challenge.yaml` テンプレートを使用して、コンテンツを追加してください。

CloudFormation テンプレートでダッシュボードを記述する時には、ラボのパート 2 で記述した [CloudWatch ダッシュボード構造](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html)を参照してください。`properties` 配下の `metrics` フィールドには、`[[AWS/S3, NumberOfObjects, StorageType, AllStorageTypes, BucketName, !Ref S3Bucket]]` を使用してください。[S3 ストレージメトリクスは 1 日に 1 回報告されます](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/cloudwatch-monitoring.html)。追加料金は発生しないため、ラボを実行しているときには表示されない場合があることにご注意ください。


:::expand{header="ヒントが必要ですか？"}
* ラボのパート 1 で説明した言語拡張を使用して、削除ポリシーのパラメータを使用したことを思い返してください。
* S3 バケットリソースの削除ポリシーパラメータを参照することを忘れないでください。
* さらに、以前 CloudWatch ダッシュボードを追加した方法を思い出してください。関連フィールドに `NumberOfObjects` メトリクスを使用することを追加してください。
:::

::::::expand{header="解決策を確認しますか？"}
* ラボのパート 1 で行ったように、テンプレートの `Transform: AWS::LanguageExtensions` の行を追加します。
* ラボのパート 1 で行ったように、`Parameters` セクションを編集して `DeletionPolicyParameter` を追加します。
* `S3Bucket` リソースの `Resources` セクション配下に、パラメータへの参照を含む `DeletionPolicy` 属性を追加します。
* `Resource` セクション配下に、`Dashboard` リソースを追加します。
* チャレンジソリューションの全文は、`code/solutions/language-extensions` ディレクトリにある `language-extensions-solutions.yaml` というテンプレートにあります。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを実行してスタックを作成しましょう。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-language-extensions-solution \
--template-body file://language-extensions-challenge.yaml \
--capabilities CAPABILITY_AUTO_EXPAND
1. CloudFormation は次の出力を返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-language-extensions-solution/466df9e0-0dff-08e3-8e2f-5088487c4896"
:::
1. [wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI コマンドを使用して、`CREATE` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-language-extensions-solution
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. 左側のナビゲーションパネルから、**スタック** を選択します。ページの右側から、**スタックの作成** を選択し、**新しいリソースを使用 (標準)** を選択します。
3. **前提条件 - テンプレートの準備** から、**テンプレートの準備完了** を選択します。
4. **テンプレートの指定** セクションで、**テンプレートソース** で **テンプレートファイルのアップロード** を選択します。**ファイルの選択** を選択し、先ほど更新した `language-extensions-challenge.yaml` テンプレートを指定して、**次へ**　を選択します。
5. **スタックの詳細を指定**ページで
   1. **スタック**名を指定します。例えば、`cfn-workshop-language-extensions-solution` を選択します。
   2. **パラメータ** で、テンプレートのデフォルト値として設定されている `DeletionPolicyParameter` の値が `Delete` であることを確認し、**次へ** を選択します。
6. **スタックオプションの設定** では、設定をそのままにしておきます。**次へ** を選択します。
7. **レビュー** ページで、ページの内容を確認します。ページの下部で、**機能と変換** セクションに表示されている機能をすべて承認するように設定してください。**送信** を選択します。
8. スタックが `CREATE_COMPLETE` ステータスになるまで、スタック作成ページを更新します。
::::
:::::
::::::

### クリーンアップ

このラボで作成したリソースを削除します。以下の手順を実行してください。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを実行して、スタック `cfn-workshop-language-extensions` を削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-language-extensions
:::
1. [wait stack-delete-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-delete-complete.html) AWS CLI コマンドを使用して、`DELETE` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--stack-name cfn-workshop-language-extensions
:::
1. 上記のステップ (1-2) を繰り返して、スタック `cfn-workshop-language-extensions-solution` を削除します。
::::
::::tab{id="LocalDevelopment" label="ローカル開発"}
1. [AWS CloudFormaiton コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
1. CloudForamtion コンソールの **スタック** ページで、パート 1 で作成した `cfn-workshop-language-extensions` スタックを選択します。
1. スタックの詳細ペインで、**削除**　を選択します。プロンプトが表示されたら、**削除** を選択します。
1. CloudFormation コンソールの　**スタック**　ページで、チャレンジセクションで作成した `cfn-workshop-language-extensions-solution` スタックを選択します。
1. スタックの詳細ペインで、**削除**　を選択します。プロンプトが表示されたら、**削除**　を選択します。
::::
:::::

---

### まとめ

`AWS::LanguageExtensions` を CloudFormation テンプレートに組み込む方法を学びました。 RFC に関するフィードバックは [Language Discussion GitHub repository](https://github.com/aws-cloudformation/cfn-language-discussion) にお気軽にお寄せください。皆さんのコントリビューションをお待ちしています！
