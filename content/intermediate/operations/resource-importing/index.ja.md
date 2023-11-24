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
* `code/workspace/resource-importing` ディレクトリに移動します。
* `resource-importing.yaml`ファイルを開きます。
* このラボの手順に従って、テンプレートのコンテンツを更新します。

### ラボパート 1

このラボでは、まず [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) を使用して [Amazon Simple Notification Service](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html) (Amazon SNS) トピックを作成します。次に、新しい CloudFormation スタックを作成し、SNS トピックをインポートします。さらに、Amazon SNS コンソールで 2 つ目のトピックを作成し、それを既存のスタックにインポートします。

開始するには、次に示す手順に従ってください。

1. [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) に移動し、 **トピック** を選択します。次に、 **トピックの作成** を選択します。
1. **タイプ** セクションで、`スタンダード`を選択します。
1. トピックの **名前** (`Topic1` など) を指定します。
1. 準備ができたら、 **トピックの作成** を選択します。
1. トピックが正常に作成されたら、`Topic1` の **詳細** セクションの下にある [Amazon リソースネーム (ARN)](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) をメモします。この ARN 値は、このラボの後半で使用します。Amazon SNS トピックの ARN パターンの例は `arn:aws:sns:us-east-1:123456789012:MyTopic` です。

次に、リソースのインポート機能を使用して、新しく作成したトピックを、これから作成する新しいスタックにインポートします。そのためには、CloudFormation テンプレートを使用して、既存のトピックを `AWS::SNS::Topic` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html) で次のように記述します。

* `TopicName` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html#aws-resource-sns-topic-properties) には、既存のトピックの名前、つまり `Topic1` を指定します。この値を `Topic1Name` と呼ぶテンプレート[パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) で渡します。次に、このパラメータの値を `Ref` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) で参照します。
* インポートする各リソースには、`DeletionPolicy` [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) が記述されている必要があります。トピックにはこの属性を指定し、属性値には `Retain` を指定します。`DeletionPolicy` 属性に `Retain` 値を使用するときは、スタックからリソースを削除するとき、またはスタックを削除するときにリソースを保持するように指定します。
* 以下のコードをコピーして `resource-importing.yaml` ファイルに追加し、ファイルを保存します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
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
:::


::alert[インポート操作を成功させるには、インポートするすべてのリソースのテンプレートの記述に [DeletionPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) 属性が設定されている必要があります。詳しい情報については、[インポートオペレーション中の考慮事項](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-considerations) をご参照ください。]{type="info"}

この次のステップでは、AWS CloudFormation コンソールを使用して、`resource-importing.yaml` テンプレートを使用して [スタックを作成](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html) します。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. `IMPORT` 操作のためリソースを記述するテキストファイルを作成します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch resources-import.txt
:::
1. 次のコードを `resources-import.txt` ファイルにコピーペーストして保存してください。[**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic1` を作成した後にメモしたトピック ARN の値を指定します。
:::code{language=json showLineNumbers=false showCopyAction=true}
[
  {
    "ResourceType":"AWS::SNS::Topic",
    "LogicalResourceId":"SNSTopic1",
    "ResourceIdentifier": {
      "TopicArn":"arn:aws:sns:us-east-1:123456789012:Topic1"
    }
  }
]
:::
1. 次のコマンドを実行してリソースインポートのためのテンプレートから `IMPORT` タイプの変更セットを作成しましょう。テンプレートは `Topic1Name` を入力パラメータとして必要とします。例えばスタック名を `cfn-workshop-resource-importing` とし変更セットを `cfn-workshop-resource-import-change-set` として `Topic1Name` の値を `Topic1` とします。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set \
--change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://resource-importing.yaml \
--parameters ParameterKey=Topic1Name,ParameterValue=Topic1
:::
1. 変更セットから正しいリソースがインポートされることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. リソースをインポートするために変更セットを実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) コマンドを使って `IMPORT` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-resource-importing
:::
1. [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) コマンドを使ってインポートが完了していることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stacks --stack-name cfn-workshop-resource-importing
:::
1. `describe-stacks` コマンドを実行すると、17 行目で示されるように CloudFormation は `"StackStatus": "IMPORT_COMPLETE"` を返却します。
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=17}
{
  "Stacks": [
    {
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
      "StackName": "cfn-workshop-resource-importing",
      "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-resource-import-change-set/3f86b48d-a0bf-434b-96de-2ec316a04134",
      "Description": "AWS CloudFormation workshop - Resource Importing.",
      "Parameters": [
        {
          "ParameterKey": "Topic1Name",
          "ParameterValue": "Topic1"
        }
      ],
      "CreationTime": "2023-05-17T01:00:50.284000+00:00",
      "LastUpdatedTime": "2023-05-17T01:05:31.414000+00:00",
      "RollbackConfiguration": {},
      "StackStatus": "IMPORT_COMPLETE",
      "DisableRollback": false,
      "NotificationARNs": [],
      "Tags": [],
      "EnableTerminationProtection": false,
      "DriftInformation": {
          "StackDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. **スタックの作成** から、 **既存のリソースを使用 (リソースをインポート)** を選択します。
1. **必要なもの** を読み、 **次へ** をクリックします。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** をクリックします。`resource-importing.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
1. [**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic1` を作成した後にメモしたトピック ARN の値を指定します。
1. **スタックの名前** を入力します。例えば、`cfn-workshop-resource-importing` と指定します。`Topic1Name` パラメータ値には必ず `Topic1` を指定します。
1. 次のページで、 **リソースをインポート** をクリックします。

Amazon SNS トピックがスタックに正常にインポートされると、スタックのステータスに `IMPORT_COMPLETE` と表示されます。

既存のリソースを新しいスタックにインポートする方法の関する詳しい説明は、[AWS CLI を使用した既存のリソースからのスタックの作成](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html#resource-import-new-stack-cli) をご参照ください。
::::
:::::

おめでとうございます！ Amazon SNS コンソールで以前に作成したリソースを、新しいスタックにインポートしました。

### ラボパート 2

このラボでは、リソースを既存のスタックにインポートする方法を学びます。開始するには、以下の手順に従ってください。

1. [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) に移動して 2 つ目のトピックを作成します。ラボパート 1 で使用した手順に従い、新しいトピックの名前として **Topic2** を指定します。
1. トピックが正常に作成されたら、`Topic2` の **詳細** セクションの下にある [Amazon リソースネーム (ARN)](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) をメモします。この情報は、後でこのラボで使用します (ARN パターンの例: `arn:aws:sns:us-east-1:123456789012:MyTopic`)。
1. 以下の例をコピーして、前のラボで使用した `resource-importing.yaml` テンプレートの `Parameters` セクションに追加します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=17}
Topic2Name:
  Type: String
  Default: Topic2
  Description: Name of the second Amazon SNS topic you created with the Amazon SNS console.
:::
1. 次に、以下の例をコピーして、`resource-importing.yaml` テンプレートの `Resources` セクションに追加します。完了したら、テンプレートファイルを保存します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=29}
SNSTopic2:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic2Name
:::
1. 先ほど更新した `resource-importing.yaml` テンプレートには、2 つのパラメータ (`Topic1Name` と `Topic2Name`) と 2 つのリソース (`SNSTopic1` と `SNSTopic2`) が含まれるようになりました。新しいトピックを既存のスタックにインポートしましょう！
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. 次のコードを `resources-import.txt` ファイルにコピーペーストして保存してください。[**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic2` を作成した後にメモしたトピック ARN の値を指定します。
   :::code{language=json showLineNumbers=false showCopyAction=true}
   [
  {
    "ResourceType":"AWS::SNS::Topic",
    "LogicalResourceId":"SNSTopic2",
    "ResourceIdentifier": {
    "TopicArn":"arn:aws:sns:us-east-1:123456789012:Topic2"
    }
  }
]
   :::
   1. 次のコマンドを実行してリソースインポートのためのテンプレートから `IMPORT` タイプの変更セットを作成します。パラメータを `Topic1Name` を `Topic1` 、`Topic2Name` を `Topic2` とします。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set \
--change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://resource-importing.yaml \
--parameters ParameterKey=Topic1Name,ParameterValue=Topic1 ParameterKey=Topic2Name,ParameterValue=Topic2
   :::
   1. 変更セットから正しいリソースがインポートされることを確認します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
   :::
   1. リソースをインポートするために変更セットを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
   :::
   1. [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) コマンドを使って `IMPORT` 操作が完了するまで待ちます。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-resource-importing
   :::
   1. [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) コマンドを使ってインポートが完了していることを確認します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stacks --stack-name cfn-workshop-resource-importing
   :::
   1. `describe-stacks` コマンドを実行すると、21 行目で示されるように CloudFormation は `"StackStatus": "IMPORT_COMPLETE"` を返却します。
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=21}
   {
  "Stacks": [
    {
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
      "StackName": "cfn-workshop-resource-importing",
      "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-resource-import-change-set/b45266b6-01c9-4c23-99d6-d65731fc575c",
      "Description": "AWS CloudFormation workshop - Resource Importing (uksb-1q9p31idr).",
      "Parameters": [
        {
          "ParameterKey": "Topic2Name",
          "ParameterValue": "Topic2"
        },
        {
          "ParameterKey": "Topic1Name",
          "ParameterValue": "Topic1"
        }
      ],
      "CreationTime": "2023-05-17T01:00:50.284000+00:00",
      "LastUpdatedTime": "2023-05-17T01:35:38.408000+00:00",
      "RollbackConfiguration": {},
      "StackStatus": "IMPORT_COMPLETE",
      "DisableRollback": false,
      "NotificationARNs": [],
      "Tags": [],
      "EnableTerminationProtection": false,
      "DriftInformation": {
          "StackDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
   :::
   ::::
   ::::tab{id="local" label="ローカル開発"}
   1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
   1. `cfn-workshop-resource-importing` という名前のスタックを選択し、 **スタックアクション** から **リソースへのスタックのインポート** を選択します。
   1. **必要なもの** を読み、 **次へ** をクリックします。
   1. **テンプレートの指定** から、 **テンプレートファイルのアップロード** を選択します。このラボパートで更新した `resource-importing.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
   1. [**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic2` を作成した後に書き留めたトピックの ARN 値を指定します。
   1. パラメータについては、必ず `Topic1Name` に `Topic1` を指定し、`Topic2Name` に `Topic2` を指定します。 **次へ** をクリックします。
   1. 次のページで、 **リソースをインポート** をクリックします。

   Amazon SNS トピックがスタックに正常にインポートされると、スタックのステータス `IMPORT_COMPLETE` と表示されます。
   ::::
   :::::

おめでとうございます！ これで、リソースを既存のスタックにインポートする方法がわかりました。 追加の情報については、[AWS CLI を使用した既存のリソースのスタックへのインポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html#resource-import-existing-stack-cli) をご参照ください。

### ラボパート 3

ラボのこの部分では、[スタック間でリソースを移動する](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/refactor-stacks.html) 方法を学びます。`SNSTopic1` リソースを `cfn-workshop-resource-importing` スタックから削除し、新しいリソースにインポートします。`SNSTopic1` の `DeletionPolicy` 属性に `Retain` を指定したので、スタックを更新しても `SNSTopic1` リソースは削除されないことに注意します。さっそく始めましょう。

1. ラボパート 2 で使用した `resource-importing.yaml` テンプレートの **Parameters** セクションから以下のコードを削除します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=12}
Topic1Name:
  Type: String
  Default: Topic1
  Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
:::
1. `resource-importing.yaml` テンプレートの **Resources** セクションから以下のコードを削除し、テンプレートファイルを保存します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=23}
SNSTopic1:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic1Name
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次のコマンドを実行してスタックから `SNSTopic1` リソースを削除するための `UPDATE` タイプの変更セットを作成しましょう。スタック名を `cfn-workshop-resource-importing` とし、変更セット名を `cfn-workshop-resource-import-change-set` とし `Topic2Name` パラメータの値を `Topic2` にします。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set \
--change-set-type UPDATE \
--template-body file://resource-importing.yaml \
--parameters ParameterKey=Topic2Name,ParameterValue=Topic2
:::
1. 変更セットから正しいリソースが削除されることを確認してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. リソースをインポートするために変更セットを実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) コマンドを使って `UPDATE` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-resource-importing
:::
1. [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) コマンドを使ってインポートが完了していることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stacks --stack-name cfn-workshop-resource-importing
:::
1. `describe-stacks` コマンドを実行すると、17 行目で示されるように CloudFormation は `"StackStatus": "IMPORT_COMPLETE"` を返却します。
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=17}
{
  "Stacks": [
    {
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
   "StackName": "cfn-workshop-resource-importing",
   "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-resource-import-change-set/11e65a07-b12b-4430-ba7a-d06edf53d2d5",
   "Description": "AWS CloudFormation workshop - Resource Importing (uksb-1q9p31idr).",
   "Parameters": [
     {
       "ParameterKey": "Topic2Name",
       "ParameterValue": "Topic2"
     }
   ],
   "CreationTime": "2023-05-17T01:00:50.284000+00:00",
   "LastUpdatedTime": "2023-05-17T02:00:46.392000+00:00",
   "RollbackConfiguration": {},
   "StackStatus": "UPDATE_COMPLETE",
   "DisableRollback": false,
   "NotificationARNs": [],
   "Tags": [],
   "EnableTerminationProtection": false,
   "DriftInformation": {
     "StackDriftStatus": "NOT_CHECKED"
   }
    }
  ]
}
:::
1. [describe-stack-resources](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-resources.html) コマンドを使って更新が完了していることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources --stack-name cfn-workshop-resource-importing
:::
1. `describe-stack-resources` コマンドを実行すると、CloudFormation は `SNSTopic2` リソースの情報のみを返却します。
:::code{language=json showLineNumbers=true showCopyAction=false}
{
  "StackResources": [
    {
      "StackName": "cfn-workshop-resource-importing",
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
      "LogicalResourceId": "SNSTopic2",
      "PhysicalResourceId": "arn:aws:sns:us-east-1:123456789012:Topic2a.fifo",
      "ResourceType": "AWS::SNS::Topic",
      "Timestamp": "2023-05-17T01:35:50.535000+00:00",
      "ResourceStatus": "UPDATE_COMPLETE",
      "DriftInformation": {
        "StackResourceDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. `cfn-workshop-resource-importing`という名前のスタックを選択し、 **更新** を選択します。
1. **既存テンプレートを置き換える** を選択し、`resource-importing.yaml` テンプレートをアップロードします。 **次へ** をクリックします。
1. パラメータセクションで、`Topic2Name` のパラメータ値を `Topic2` のままにします。 **次へ** をクリックします。
1. **スタックオプションの設定** ページでデフォルト値のまま、 **次へ** をクリックします。
1. 次のページで **送信** をクリックします。
1. スタックからの `SNSTopic1` リソースの削除を確認するには、`cfn-workshop-resource-importing` スタックを選択し、 **リソース** を選択します。表示されるリソースは `SNSTopic2` のみです。
::::
:::::
`SNSTopic1` リソースを新しいスタックにインポートします。

1. `code/workspace/resource-importing` ディレクトリにいることを確認します。
1. お好みのテキストエディタで `moving-resources.yaml` テンプレートファイルを開きます。
1. 以下の例を `moving-resources.yaml` テンプレートに追加して保存します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
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
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 以下のコードをコピーして `resources-import.txt` ファイルの内容を置き換えてください。
:::code{language=json showLineNumbers=false showCopyAction=true}
[
  {
    "ResourceType":"AWS::SNS::Topic",
    "LogicalResourceId":"SNSTopic1",
    "ResourceIdentifier": {
      "TopicArn":"arn:aws:sns:us-east-1:123456789012:Topic1"
    }
  }
]
:::
1. [**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、 **ラボ 1** で `Topic1` を作成した後にメモしたトピック ARN の値を指定します。
1. 次のコマンドを実行してリソースをインポートするために `IMPORT` タイプの変更セットを作成しましょう。スタック名は `cfn-workshop-moving-resources` とし、変更セット名は  `cfn-workshop-moving-resources` として `Topic1Name` パラメータの値を `Topic1` とします。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-moving-resources \
--change-set-name cfn-workshop-moving-resources-change-set \
--change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://moving-resources.yaml \
--parameters ParameterKey=Topic1Name,ParameterValue=Topic1
:::
1. 変更セットから正しいリソースがインポートされることを確認してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-change-set \
--stack-name cfn-workshop-moving-resources \
--change-set-name cfn-workshop-moving-resources-change-set
:::
1. リソースをインポートするために変更セットを実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-moving-resources \
--change-set-name cfn-workshop-moving-resources-change-set
:::
1. [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) コマンドを使って `IMPORT` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-moving-resources
:::
1. [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) コマンドを使ってインポートが完了していることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stacks --stack-name cfn-workshop-moving-resources
:::
1. `describe-stacks` コマンドを実行すると、17 行目で示されるように CloudFormation は `"StackStatus": "IMPORT_COMPLETE"` を返却します。
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=17}
{
  "Stacks": [
    {
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-moving-resources/70f207d0-f459-11ed-9c39-123ae332d1a1",
      "StackName": "cfn-workshop-moving-resources",
      "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-moving-resources-change-set/695b51cd-6d16-49e8-99f7-7b93a932f1fe",
      "Description": "AWS CloudFormation workshop - Resource Importing (uksb-1q9p31idr).",
      "Parameters": [
        {
          "ParameterKey": "Topic1Name",
          "ParameterValue": "Topic1"
        }
      ],
      "CreationTime": "2023-05-17T02:20:50.451000+00:00",
      "LastUpdatedTime": "2023-05-17T02:21:03.424000+00:00",
      "RollbackConfiguration": {},
      "StackStatus": "IMPORT_COMPLETE",
      "DisableRollback": false,
      "NotificationARNs": [],
      "Tags": [],
      "EnableTerminationProtection": false,
      "DriftInformation": {
        "StackDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
1. [describe-stack-resources](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-resources.html) コマンドを使って更新が完了していることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources --stack-name cfn-workshop-moving-resources
:::
1. `describe-stack-resources` コマンドを実行すると、CloudFormation は `SNSTopic1` リソースの情報のみを返却します。
:::code{language=json showLineNumbers=true showCopyAction=false}
{
  "StackResources": [
    {
      "StackName": "cfn-workshop-moving-resources",
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-moving-resources/70f207d0-f459-11ed-9c39-123ae332d1a1",
      "LogicalResourceId": "SNSTopic1",
      "PhysicalResourceId": "arn:aws:sns:us-east-1:123456789012:Topic1.fifo",
      "ResourceType": "AWS::SNS::Topic",
      "Timestamp": "2023-05-17T02:21:15.205000+00:00",
      "ResourceStatus": "UPDATE_COMPLETE",
      "DriftInformation": {
        "StackResourceDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. **スタックの作成** から、 **既存のリソースを使用 (リソースをインポート)** を選択します。
1. **概要をインポート** を読み、 **次へ** をクリックします。
1. **テンプレートの指定** セクションで、 **テンプレートファイルをアップロード** を選択します。`moving-resources.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
1. [**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、`Topic1` を作成した後にメモしたトピック ARN 値を指定し、**次へ** をクリックします。
1. **スタック名** を入力します。例えば、`cfn-workshop-moving-resources` と指定します。`Topic1Name` パラメータには必ず `Topic1` を指定します。
1.  次のページで **リソースをインポート** をクリックします。

Amazon SNS トピックがスタックに正常にインポートされると、スタックのステータスには `IMPORT_COMPLETE` と表示されます。
::::
:::::

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

この演習では、ラボパート 1、2、3 で得た知識を使用して、提供されたタスクを完了する必要があります。CloudFormation テンプレートのリソースの 1 つである EC2 インスタンスに、人為的ミスの結果として CloudFormation の外部で変更されたプロパティ値が存在する問題を解決する必要があります。この問題のトラブルシューティングと解決を行い、CloudFormation で希望するリソース構成を引き続き維持できるようにします。

EC2 インスタンスと Amazon S3 バケットを定義するサンプルテンプレートから始めましょう。

はじめに、以下の手順に従ってください。

1. `code/workspace/resource-importing` というディレクトリにいることを確認します。
1. `resource-import-challenge.yaml` ファイルを開きます。
1. 以下の例を `resource-import-challenge.yaml` テンプレートに追加し、ファイルを保存します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
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
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次のコマンドを実行して **スタックの作成** を行いましょう。 **スタック名** は `cfn-workshop-resource-import-challenge` とし `InstanceType` パラメータの値は `t2.nano` とします。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.nano
:::
1. 次のコマンドを実行して `CREATE_COMPLETE` になるまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-resource-import-challenge
:::
::::
::::tab{id="LocalDevelopment" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. **スタックの作成** から、 **新しいリソースを使用 (標準)** を選択します。
1. **テンプレートを指定** セクションで、 **テンプレートファイルのアップロード** を選択します。`resource-import-challenge.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
1. **スタックの名前** を入力します。例えば、`cfn-workshop-resource-import-challenge` と指定します。`InstanceType` には `t2.nano` を指定します。[**次へ**]をクリックします。
1. **スタックオプションの設定** ページはデフォルト値のまま、 **次へ** をクリックします。
1. 次のページで、 **送信** を選択します。
::::
:::::
スタックを作成したら、`cfn-workshop-resource-import-challenge` スタックを選択し、 **リソース** を確認します。`i-12345abcd6789` という形式の `インスタンス`の **物理 ID** をメモしておきましょう。

次に、スタックの管理範囲外でインスタンスタイプを変更して、ヒューマンエラーを再現してみましょう。以下の手順に従って [既存の EBS-backed インスタンスのインスタンスタイプを変更](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-instance-resize.html#change-instance-type-of-ebs-backed-instance) を実行します。

1. [Amazon EC2 コンソール](https://console.aws.amazon.com/ec2/) に移動します。
1. **インスタンス** セクションを見つけて、`InstanceImport` という名前のインスタンスを選択し、 **インスタンスの状態** 、 **インスタンスを停止** を選択します。
1. 同じインスタンスで、インスタンスが **停止** 状態になったことを確認したら、 **アクション** 、 **インスタンスの設定** 、 **インスタンスタイプを変更** を選択します。
1. `t2.micro` を選択し、 **適用** を選択します。
1. `InstanceImport` インスタンスを再度選択し、 **インスタンスの状態** 、 **インスタンスを開始** を選択します。


最初に Amazon EC2 インスタンスをスタックで作成しました。ヒューマンエラーを再現するために、テンプレートの [InstanceType](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype) プロパティを使用する代わりに、(CloudFormation を使用せずに) インスタンスを更新し、次にスタックを更新しました。

:::alert{type="info"}
インスタンスタイプを変更すると、インスタンスが停止して再起動するなど、 [一時的な中断を伴う更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-some-interrupt) が発生します。インスタンスのサイズ変更の詳細については、[インスタンスタイプを変更する](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-instance-resize.html) をご参照ください。
:::
今回のタスクは、スタックを更新するときに `InstanceType` プロパティに追加の変更を加えることなく、スタック内で現在 `t2.nano` に設定されているインスタンスタイプ値を、CloudFormation 以外の方法で設定された新しいインスタンス設定である `t2.micro` と一致させることです。

:::expand{header="ヒントが必要ですか？"}
ラボパート 3 で学んだ概念の利用を検討します。
:::

:::::::expand{header= "解決策を確認しますか？"}
1. `resource-import-challenge.yaml` テンプレートを更新します。`Instance` リソースに、値が `Retain` の `DeletionPolicy` 属性を追加し、ファイルを保存します。
1. パラメータ値を変更せずに、更新された `resource-import-challenge.yaml` テンプレートを使用してスタックを更新します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.nano
:::

1. スタックを更新し、インスタンスの `DeletionPolicy` 属性が `Retain` に設定されたら、インスタンスリソース定義と Parameters セクションにある関連パラメータをテンプレートから削除します。今回の例では、書くべきパラメーターが特に存在しないため、`Parameters` セクション自体を削除します。具体的には、`resource-import-challenge.yaml` テンプレートから次の 2 つのコードブロックを削除します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11 highlightLines=11-15,17-23}
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
:::
    :::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=30 highlightLines=31}
    Instance:
      DeletionPolicy: Retain
      Type: AWS::EC2::Instance
      Properties:
        ImageId: !Ref LatestAmiId
        InstanceType: !Ref InstanceType
        Tags:
          - Key: Name
            Value: InstanceImport
    :::
1. 更新された `resource-import-challenge.yaml` テンプレートファイルを使ってスタックを更新します。テンプレートファイルにはパラメータとインスタンスリソースの定義もありません。この操作によりスタックからインスタンスが取り除かれますが、リソースとしては削除されません。これは以前に `DeletionPolicy` の属性を  `Retain` に適用したためです。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml
:::
1. スタックを更新したあと、ステップ 3 で 2 つの削除したコードブロックを `resource-import-challenge.yaml` に追加して保存します。
1. **スタックにリソースをインポート** しましょう
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. 以下のコードをコピーして `resources-import.txt` にペーストします。[**識別子**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview)の値はこのパートの前に、メモをしたインスンスの **物理 ID** に置き換えます。
   :::code{language=json showLineNumbers=false showCopyAction=true}
   [
  {
    "ResourceType":"AWS::EC2::Instance",
    "LogicalResourceId":"Instance",
    "ResourceIdentifier": {
      "InstanceId":"i-12345abcd6789"
    }
  }
]
   :::
   1. 以下のコマンドを実行して **リソースのインポート** のために `cfn-workshop-resource-import-challenge` スタックを更新します。`InstanceType` パラメータは `t2.micro` を指定します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-import-challenge \
--change-set-name import-challenge --change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.micro
   :::
   1. 変更セットを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-import-challenge \
--change-set-name import-challenge
   :::
   1. AWS CLI の [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) コマンドを使って `IMPORT` 操作が完了するまで待ちます。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-resource-import-challenge
   :::
   ::::
   ::::tab{id="LocalDevelopment" label="ローカル開発"}
   1. `cfn-workshop-resource-import-challenge`という名前のスタックを選択し、 **スタックアクション** から **スタックへのリソースのインポート** を選択します。
   1. **必要なもの** を読み、 **次へ** を選択してください。
   1. **テンプレートを指定** から、 **テンプレートファイルのアップロード** を選択します。更新した `resource-import-challenge.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
   1. [**識別子の値**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview) には、このチャレンジの一部として先ほど書き留めたインスタンスの **物理 ID** を指定し、 **次へ** をクリックします。
   1.  インスタンスタイプパラメータとして `t2.micro` を選択します。ここでは、実際のインスタンスタイプ設定である `t2.micro` と一致しています。
   1.  次のページで、 **リソースをインポート** をクリックします。
   ::::
   :::::

ソリューションのテンプレートは、`code/solutions/resource-import/resource-import-challenge-solution.yaml` サンプルテンプレートにあります。
:::::::

以上で、CloudFormation 以外の方法で変更があった場合に CloudFormation スタック構成をリソースの実際の設定と一致させる方法を学習しました。

**リソースインポートのユースケース**

1. 以前に AWS マネジメントコンソールや AWS CLI などを使用して AWS リソース (Amazon S3 バケットなど) を作成していて、CloudFormation を使用してリソースを管理したい。
1. ライフサイクルと所有権ごとにリソースを 1 つのスタックに再編成して管理しやすくしたい (セキュリティグループのリソースなど)。
1. 既存のスタックを既存のスタックにネストしたい。詳しい情報については、[既存のスタックのネスト化](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resource-import-nested-stacks.html) をご参照ください。
1. CloudFormation 以外の方法で更新されたリソースの CloudFormation 設定と一致させたい。

### クリーンアップ

このラボで作成したリソースをクリーンアップするには、次に示すクリーンアップ手順に従ってください。

1. `code/workspace/resource-importing` というディレクトリにいることを確認します。
1. `resource-importing.yaml` テンプレートファイルを更新して、`SNSTopic2` リソース定義から `deletionPolicy: Retain` 行を削除し、テンプレートを保存します。
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. 次のコマンドを実行して **スタック** を更新します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation update-stack \
--stack-name cfn-workshop-resource-importing \
--template-body file://resource-importing.yaml
   :::
   1. 次のコマンドを実行して `UPDATE` 操作が完了するまで。待ちます。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-resource-importing
   :::
   1. 次のコマンドを実行してスタックを削除します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation delete-stack \
 --stack-name cfn-workshop-resource-importing
   :::
   1. スタック `cfn-workshop-moving-resources` に対して上記の手順 (1-3) を繰り返します。これには、`moving-resources.yaml` テンプレートを更新して、`SNSTopic1` リソース定義から `DeletionPolicy: Retain` 行を削除します。スタックを更新し、更新が成功した後にスタックを削除します。スタックを更新するときに、既存のパラメーター値を受け入れることを選択します。
   1. `resource-import-challenge.yaml` テンプレートを更新して `Instance` リソース定義の `DeletionPolicy: Retain` の行を削除し、スタックを更新します。次のコマンドを実行してスタックを更新しましょう。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation update-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.micro
   :::
   1. `cfn-workshop-resource-import-challenge` に対して上記の手順 (2-3) を繰り返してスタックを削除します。
   ::::
   ::::tab{id="LocalDevelopment" label="ローカル開発"}
   1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
   1. `cfn-workshop-resource-importing` という名前のスタックを選択し、 **更新** を選択します。
   1. **現在テンプレートを置き換える** を選択し、`resource-importing.yaml` テンプレートをアップロードします。 **次へ** をクリックします。
   1. パラメータセクションで、既存のパラメータ値を受け入れることを選択します。 **次へ** をクリックします。
   1. **スタックオプションの設定** ページでデフォルトのまま、 **次へ** をクリックします。
   1. 次のページで **送信** を選択します。
   1. スタックの更新が完了したら、`cfn-workshop-resource-importing` スタックを選択し、 **削除** を選択します。
   1. `moving-resources.yaml` テンプレートを更新して `SNSTopic1` リソース定義から `deletionPolicy: Retain` 行を削除し、`cfn-workshop-moving-resources` スタックを更新します。正常に更新されたら、手順 2 ～ 9 を繰り返し、`cfn-workshop-moving-resources` スタックを削除します。スタックの更新時には、既存のパラメータ値をそのままにします。
   1. `resource-import-challenge.yaml` テンプレートを更新して `Instance` リソース定義から `DeletionPolicy: Retain` 行を削除し、スタックを更新します。正常に更新されたらスタック `cfn-workshop-resource-import-challenge` について上記のステップ (2 ～ 9) を繰り返し、スタック削除します。 スタックの更新時には、既存のパラメータ値をそのままにします。
   ::::
   :::::

---

### まとめ

これで、リソースをインポートする方法と、リソースをインポートする際の使用例と考慮事項について学習しました。
