---
title: "ドリフト検出"
weight: 500
---

### 概要

[AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) を使用してリソースをプロビジョニングすることを選択した場合、必要に応じて CloudFormation を使用してリソースの設定を長期にわたって維持することになります。その後、そのようなリソースを CloudFormation の範囲外で変更した場合 (例えば、[AWS マネジメントコンソール](https://aws.amazon.com/jp/console/)、[AWS Command Line Interface](https://aws.amazon.com/jp/cli/) (AWS CLI)、[AWS SDK](https://aws.amazon.com/jp/developer/tools/)、[AWS API](https://docs.aws.amazon.com/general/latest/gr/aws-apis.html))、リソースの設定と CloudFormation の設定と差分ができてしまいます。

CloudFormation は[ドリフト検出](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html) を提供しています。これは、リソースの現在の構成と、リソースの作成または更新に使用したテンプレートで宣言した構成との違いに関する情報を提供します。ドリフト検出の結果には、対象リソースに対して、現在の状態とテンプレートの違いが表示されます。その後、リソースを元の設定に戻すか、テンプレートと CloudFormation スタックを更新して望ましい状態を反映させることができます。

### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* CloudFormation ドリフト検出を使用して、スタックリソースのドリフトを検出します。
* ドリフト検出の結果を解釈して、どのリソースプロパティが変更されたかを特定する方法を理解します。
* リソースを変更して元の構成に戻します。
* リソースの新しい構成に合わせてテンプレートを更新します。
* リソースインポートを使用して、リソースの新しい構成と一致するようにスタックとテンプレートを更新します。

### ラボを開始

[Amazon DynamoDB](https://aws.amazon.com/jp/dynamodb/) テーブルと [Amazon Simple Queue Service (SQS)](https://aws.amazon.com/jp/sqs/) キューを新しいスタックとして含む AWS CloudFormation テンプレートの例をデプロイします。次に、プロビジョニングされたリソースにいくつかの設定変更を行い、ドリフト検出を使用して変更を特定します。次に、リソース構成を修正するか、新しい構成を反映するようにテンプレートを更新することで、ドリフトを解決します。

開始するには、次の手順に従います。

1. `code/workspace/drift-detection` ディレクトリに移動します。
1. 以下のコードをコピーして `drift-detection-workshop.yaml` ファイルに追加し、ファイルを保存します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=5}
Resources:
  Table1:
    Type: AWS::DynamoDB::Table
    Properties:
      AttributeDefinitions:
        - AttributeName: Album
          AttributeType: S
        - AttributeName: Artist
          AttributeType: S
      BillingMode: PROVISIONED
      KeySchema:
        - AttributeName: Album
          KeyType: HASH
        - AttributeName: Artist
          KeyType: RANGE
      ProvisionedThroughput:
        ReadCapacityUnits: 1
        WriteCapacityUnits: 1

  Queue1:
    Type: AWS::SQS::Queue
    Properties:
      MessageRetentionPeriod: 345600
:::

1. テンプレート内のリソース例をよく確認した上で、実施してください。
    1. DynamoDB [テーブル](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html) には、正常に作成するための `KeySchema` と `AttributeDefinitions` プロパティの最小限の定義があります。ワークショップ中は、テーブルにデータを保存したり、テーブルからデータを取得したりすることはありません。
    1. SQS [キュー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html) の `MessageRetentionPeriod` は 4 日間 (秒単位で表現) です。この値は [デフォルト](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-messageretentionperiod) ですが、CloudFormation はテンプレートで明示的に宣言したプロパティに対してのみドリフトを評価することに注意してください。このプロパティを含めない場合、CloudFormation は後でリソースの変更を報告しません。
1. 次のステップでは、このテンプレートを使用して新しいスタックを作成します。
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **Cloud9 のターミナル** 上で `cfn101-workshop/code/workspace/drift-detection` ディレクトリに移動します:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/drift-detection
   :::
   1. AWS CLI コマンドを使ってスタックを作成します。例えばスタック名を `cfn-workshop-drift-detection` と入力します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-drift-detection \
--template-body file://drift-detection-workshop.yaml
   :::
   1. `create-stack` コマンドが成功すると CloudFormation は `StackId` を返却します。
   :::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/739fafa0-e4d7-11ed-a000-12d9009553ff"
   :::
   1. 新しいタブで **[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** を開いてスタックが **CREATE_COMPLETE** 状態であることを確認します。
   ::::
   ::::tab{id="local" label="ローカル開発"}
   1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
   1. **スタックの作成** から、 **新しいリソースを使用 (標準)** を選択します。
   1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。前述の `drift-detection-workshop.yaml` テンプレートを選択し、 **次へ** をクリックします。
   1. スタック名を入力します。例えば、`cfn-workshop-drift-detection-workshop` と入力します。 **次へ** をクリックします。
   1. **スタックオプションの設定** ページはデフォルト値のまま、 **次へ** をクリックします。
   1. **送信** をクリックします。
   1. スタックが `CREATE_COMPLETE` 状態になるまで、スタック作成ページを更新します。
   ::::
   :::::

### リソースの変更によるドリフトの検出と修復

次に、CloudFormation の外で DynamoDB テーブルを直接変更します。

1. [Amazon DynamoDB コンソール](https://console.aws.amazon.com/dynamodb/) に移動します。
1. メニューの **テーブル** 見出しの下で、 **アクション** 、 **設定の更新** を選択します。
1. **Table1** エントリを選択します (テーブル名の先頭にはスタックの名前が付きます)。
1. **追加の設定** タブを選択します。
1. **読み取り/書き込みキャパシティー** セクションで、 **編集** を選択します。
1. **オンデマンド** キャパシティモードを選択し、 **変更を保存** を選択します。

このステップでは、CloudFormation ドリフト検出を使用して、元のテンプレートと比較して `Table1` リソースに加えられた変更を特定します。

   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **ドリフト検出** を行うために `cfn-workshop-drift-detection` スタックに対して次のコマンドを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection
   :::
   1. CloudFormation は次の結果を返却します。
   :::code{language=json showLineNumbers=false showCopyAction=true}
  "StackDriftDetectionId": "35768f30-f947-11ed-9dc9-0eb469d3b073"
   :::
   1. ドリフト検出操作の実行結果をステップ 2 で得られた `stack-drift-detection-id` を使って確認します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-drift-detection-status \
--stack-drift-detection-id stack-drift-detection-id
   :::
   1. `describe-stack-drift-detect-status` コマンドが成功すると、CloudFormation は`"DetectionStatus":"DETECTION_COMPLETE"` と `"StackDriftStatus":"DRIFTED"` の情報を返却します。
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=4-5}
{
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/83fd7940-f945-11ed-ab77-12daf0c351ad",
    "StackDriftDetectionId": "35768f30-f947-11ed-9dc9-0eb469d3b073",
    "StackDriftStatus": "DRIFTED",
    "DetectionStatus": "DETECTION_COMPLETE",
    "DriftedStackResourceCount": 1,
    "Timestamp": "2023-05-23T08:52:55.332000+00:00"
}
   :::
   1. ドリフトしたリソースの詳細を確認するため次のコマンドを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-resource-drifts \
--stack-name cfn-workshop-drift-detection
   :::
   1. `descibe-stack-resource-drifts` コマンドの出力結果に `Table1` リソースのドリフトした内容が `Property Differences` の中で示されています。
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=21-34}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/83fd7940-f945-11ed-ab77-12daf0c351ad",
            "LogicalResourceId": "Queue1",
            "PhysicalResourceId": "https://sqs.us-east-1.amazonaws.com/123456789012/cfn-workshop-drift-detection-Queue1-LhZ9kuNmNV62",
            "ResourceType": "AWS::SQS::Queue",
            "ExpectedProperties": "{\"MessageRetentionPeriod\":345600}",
            "ActualProperties": "{\"MessageRetentionPeriod\":345600}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T08:42:44.951000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/83fd7940-f945-11ed-ab77-12daf0c351ad",
            "LogicalResourceId": "Table1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-Table1-173M9QVM1EZKE",
            "ResourceType": "AWS::DynamoDB::Table",
            "ExpectedProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"WriteCapacityUnits\":1,\"ReadCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeType\":\"S\",\"AttributeName\":\"Album\"},{\"AttributeType\":\"S\",\"AttributeName\":\"Artist\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "ActualProperties": "{\"BillingMode\":\"PAY_PER_REQUEST\",\"AttributeDefinitions\":[{\"AttributeName\":\"Album\",\"AttributeType\":\"S\"},{\"AttributeName\":\"Artist\",\"AttributeType\":\"S\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "PropertyDifferences": [
                {
                    "PropertyPath": "/ProvisionedThroughput",
                    "ExpectedValue": "{\"ReadCapacityUnits\":1,\"WriteCapacityUnits\":1}",
                    "ActualValue": "null",
                    "DifferenceType": "REMOVE"
                },
                {
                    "PropertyPath": "/BillingMode",
                    "ExpectedValue": "PROVISIONED",
                    "ActualValue": "PAY_PER_REQUEST",
                    "DifferenceType": "NOT_EQUAL"
                }
            ],
            "StackResourceDriftStatus": "MODIFIED",
            "Timestamp": "2023-05-23T09:31:32.470000+00:00"
        }
    ]
}
   :::
   ::::
   ::::tab{id="local" label="ローカル開発"}
    1. [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。必要に応じて、 **スタック** メニュー項目を選択してスタックを確認します。
    1. 前のステップで作成したスタック (例えば、`cfn-workshop-drift-detection-workshop`) を選択します。
    1. **スタックアクション** から、 **ドリフトの検出** を選択します。
    1. **スタックの情報** タブに移動し、 **ドリフトステータス** フィールドに `DRIFTED` と表示されるまでページを更新します。なお、ドリフト検出が完了するまでに少し時間がかかります。
    1. **スタックアクション** から、 **ドリフト結果を表示** を選択します。
    1. ドリフトステータスページが表示されます。画面では、`Table1` が変更され、`Queue1` がテンプレートと同期されていることがわかります。
    1. **リソースのドリフトステータス** ビューから `Table1` を選択し、次に **ドリフトの詳細を表示** を選択します。
    1. 次に、`Table1` のドリフトの詳細を確認すると、3 つの差分があります。コンソールで行った変更に応じて `BillingMode` プロパティが変更され、`ProvisionedThroughput` の値もその変更の一部として DynamoDB によって更新されました。 **違い** ビューで各プロパティを選択すると、関連するテンプレートの違いが強調表示されます。
   ::::
   :::::

これで、構成ドリフトを修正するために必要な情報が揃い、希望する構成がテンプレートと再び一致するようになりました。以下の手順に従ってテーブル設定を更新してください。

1. [DynamoDB コンソール](https://console.aws.amazon.com/dynamodb) に戻り、以前と同じように **設定の更新** を選択します。
1. **Table1** のエントリを選択し、 **追加の設定** タブに移動します。
1. **編集** を選択します。
1. **プロビジョニング** キャパシティモードを選択します。
1. **読み取りキャパシティー** と **書き込みキャパシティー** の両方で、 **Auto Scaling** を **オフ** にします。
1. 読み取りキャパシティーと書き込みキャパシティーの **プロビジョンドキャパシティーユニット** 両方に `1` を入力します。
1. **変更を保存** をクリックします。

リソースはテンプレートと同期され、元の構成に復元されました。先ほど行ったようにスタックのドリフト検出を実行すると、 **スタック情報** タブの **ドリフトステータス** フィールドに `IN_SYNC` と表示されるはずです。

### テンプレートの更新によるドリフトの検出と修復

前のセクションでデプロイしたテンプレートで Amazon SQS キューが作成されました。次に、キューのプロパティを変更し、CloudFormation がドリフトを検出していることを確認してから、新しいリソース設定と一致するようにテンプレートを更新します。まず、キューを変更します。


1. [Amazon SQS コンソール](https://console.aws.amazon.com/sqs/) に移動します。
1. 必要に応じて、左側の折りたたまれたメニューを選択して展開し、 **キュー** を選択します。
1. スタックの名前で始まる名前のキュー (例: `cfn-workshop-drift-detection-workshop`) を見つけて選択します。
1. **編集** を選択します。
1. **メッセージ保持期間** を `4` ではなく `2` 日に変更し、ページの一番下にある **保存** をクリックします。

このステップでは、CloudFormation を使用してキューリソースのドリフトを検出します。

   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **ドリフト検出** を行うために `cfn-workshop-drift-detection` スタックに対して次のコマンドを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection
   :::
   1. CloudFormation は次の結果を返却します。
   :::code{language=json showLineNumbers=false showCopyAction=true}
  "StackDriftDetectionId": "2c320c80-f954-11ed-9e69-0a031a01f375"
   :::
   1. ドリフト検出操作の実行結果をステップ 2 で得られた `stack-drift-detection-id` を使って確認します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-drift-detection-status \
--stack-drift-detection-id stack-drift-detection-id
   :::
   1. `describe-stack-drift-detect-status` コマンドが成功すると、CloudFormation は`"DetectionStatus":"DETECTION_COMPLETE"` と `"StackDriftStatus":"DRIFTED"` の情報を返却します。
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=4-5}
{
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/2c320c80-f954-11ed-9e69-0a031a01f375",
    "StackDriftDetectionId": "35768f30-f947-11ed-9dc9-0eb469d3b073",
    "StackDriftStatus": "DRIFTED",
    "DetectionStatus": "DETECTION_COMPLETE",
    "DriftedStackResourceCount": 1,
    "Timestamp": "2023-05-23T08:52:55.332000+00:00"
}
   :::
   1. ドリフトしたリソースの詳細を確認するため次のコマンドを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-resource-drifts \
--stack-name cfn-workshop-drift-detection
   :::
   1. `descibe-stack-resource-drifts` コマンドの出力結果に `Queue1` リソースのドリフトした内容が `Property Differences` の中で示されています。
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=10-17}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
            "LogicalResourceId": "Queue1",
            "PhysicalResourceId": "https://sqs.us-east-1.amazonaws.com/123456789012/cfn-workshop-drift-detection-Queue1-9vq6DP77LiCe",
            "ResourceType": "AWS::SQS::Queue",
            "ExpectedProperties": "{\"MessageRetentionPeriod\":345600}",
            "ActualProperties": "{\"MessageRetentionPeriod\":172800}",
            "PropertyDifferences": [
                {
                    "PropertyPath": "/MessageRetentionPeriod",
                    "ExpectedValue": "345600",
                    "ActualValue": "172800",
                    "DifferenceType": "NOT_EQUAL"
                }
            ],
            "StackResourceDriftStatus": "MODIFIED",
            "Timestamp": "2023-05-23T10:25:44.111000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
            "LogicalResourceId": "Table1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-Table1-1VFN7I198DR33",
            "ResourceType": "AWS::DynamoDB::Table",
            "ExpectedProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"WriteCapacityUnits\":1,\"ReadCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeType\":\"S\",\"AttributeName\":\"Album\"},{\"AttributeType\":\"S\",\"AttributeName\":\"Artist\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "ActualProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"ReadCapacityUnits\":1,\"WriteCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeName\":\"Album\",\"AttributeType\":\"S\"},{\"AttributeName\":\"Artist\",\"AttributeType\":\"S\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T10:25:44.761000+00:00"
        }
    ]
}
   :::
   ::::
   ::::tab{id="local" label="ローカル開発"}
    1. [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。必要な場合は、 **スタック** メニュー項目を選択してスタックを確認してください。
    1. 前のステップで作成したスタック (例えば、`cfn-workshop-drift-detection-workshop`) を選択します。
    1. **スタックアクション** から、 **ドリフトの検出** を選択します。
    1. ドリフト検出が完了するまで数秒待ってください。 **ドリフトステータス** フィールドに `DRIFTED` と表示されるまで、スタック情報ページを更新します。
    1. **スタックアクション** から、 **ドリフト結果を表示** を選択します。
    1. ドリフトステータスページが表示され、`Queue1` が変更されたことが示されます。
    1. `Queue1` を選択し、 **ドリフトの詳細を表示** を選択します。
    1. `Queue1` のドリフトの詳細を確認します。差分が 1 つあることが確認できます。コンソールで行った変更に応じて、`MessageRetentionPeriod` プロパティが変更されました。
   ::::
   :::::

次に、リソースの新しい状態に合わせてテンプレートを更新し、スタックを同期し直します。

1. お好みのテキストエディターで、ワークショップのテンプレートファイルを開きます。
1. `Queue1` の `MessageRetentionPeriod` を、前のステップで見たドリフト詳細ページの **現在の値** 列に表示された値と一致するように変更します。テンプレートの `MessageRetentionPeriod` の値を `172800` に設定します。これは `2` 日間の秒数です。
1. テンプレートファイルを保存します。
1. 以下の手順でスタックを更新しましょう。
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. **Cloud9 のターミナル** 上で `cfn101-workshop/code/workspace/drift-detection` ディレクトリに移動します:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/drift-detection
   :::
   1. AWS CLI コマンドを使って `cfn-workshop-drift-detection` スタックを更新します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection \
--template-body file://drift-detection-workshop.yaml
   :::
   1. `update-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
   :::code{language=json showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/739fafa0-e4d7-11ed-a000-12d9009553ff"
   :::
   1. 次のコマンドで `UPDATE` 操作が完了するまで待ちます。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-drift-detection
   :::
   1. 確認のため、`cfn-workshop-drift-detection`スタックに対して **ドリフト検出** を行います。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection
   :::
   1. ドリフトしたリソースの詳細を確認するため次のコマンドを実行します。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-resource-drifts \
--stack-name cfn-workshop-drift-detection
   :::
   1. ドリフトのステータスが`IN_SYNC`であることを確認できれば、テンプレートとリソースが一致しています。
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=11,22}
    {
        "StackResourceDrifts": [
            {
                "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
                "LogicalResourceId": "Queue1",
                "PhysicalResourceId": "https://sqs.us-east-1.amazonaws.com/123456789012/cfn-workshop-drift-detection-Queue1-9vq6DP77LiCe",
                "ResourceType": "AWS::SQS::Queue",
                "ExpectedProperties": "{\"MessageRetentionPeriod\":172800}",
                "ActualProperties": "{\"MessageRetentionPeriod\":172800}",
                "PropertyDifferences": [],
                "StackResourceDriftStatus": "IN_SYNC",
                "Timestamp": "2023-05-23T10:54:21.628000+00:00"
            },
            {
                "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
                "LogicalResourceId": "Table1",
                "PhysicalResourceId": "cfn-workshop-drift-detection-Table1-1VFN7I198DR33",
                "ResourceType": "AWS::DynamoDB::Table",
                "ExpectedProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"WriteCapacityUnits\":1,\"ReadCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeType\":\"S\",\"AttributeName\":\"Album\"},{\"AttributeType\":\"S\",\"AttributeName\":\"Artist\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
                "ActualProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"ReadCapacityUnits\":1,\"WriteCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeName\":\"Album\",\"AttributeType\":\"S\"},{\"AttributeName\":\"Artist\",\"AttributeType\":\"S\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
                "PropertyDifferences": [],
                "StackResourceDriftStatus": "IN_SYNC",
                "Timestamp": "2023-05-23T10:54:22.168000+00:00"
            }
        ]
    }
   :::
    ::::
    ::::tab{id="local" label="ローカル開発"}
   1. [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
   1. 前で実施した操作と同様に、スタックを選択します。
   1. **更新** を選択します。
   1. **既存テンプレートを置き換える** を選択し、 **テンプレートファイルのアップロード** を選択します。
   1. **ファイルを選択** を使用して、更新されたテンプレートファイルを選択します。
   1. **次へ** をクリックします。
   1. スタックの詳細ページで、 **次へ** をクリックします。
   1.  スタックのオプションページで、 **次へ** をクリックします。
   1. **送信** をクリックします。
   1. スタックの更新が完了するまでお待ちください。ページを更新して現在の状態を読み込みます。
   1. **スタックの情報** タブを選択します。
   1. **スタックアクション** から、 **ドリフトの検出** を選択します。
   1. ドリフト検出が完了するまで数秒待ってください。
   1. これで、ドリフトステータスが `IN_SYNC` になり、テンプレートとリソースが一致していることがわかります。
   ::::
   :::::


おめでとうございます！ リソースの新しい状態に一致するようにテンプレートを更新することで、スタックのずれを修復する方法を学びました。

### チャレンジ

この演習では、このラボの前半で得た知識と、前回の [リソースインポート](/intermediate/operations/resource-importing.html) のラボで得た知識を使用して、CloudFormation スタックの範囲外でリソースが更新された場合の問題を解決します。その構成に差分が出ましたが、リソースを [中断](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html) せずに CloudFormation スタックを一致するように更新することはできません。スタックからリソースを削除し、更新されたプロパティを使用してリソースをインポートする必要があります。

はじめに、以下の手順に従ってください。

1. お気に入りのエディターで `drift-detection-challenge.yaml` ファイルを開きます。
1. 以下の内容を `drift-detection-challenge.yaml` テンプレートに追加し、ファイルを保存します。このテンプレートは、最新の Amazon Linux 2 AMI を使用して [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) インスタンスを起動し、初回起動時に `Hello World` と出力されるスクリプトを実行するように設定します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=5}
Parameters:
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

Resources:
  Instance1:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello World

  Bucket1:
    Type: AWS::S3::Bucket
:::

:::alert{type="info"}
この `UserData` スクリプトは、インスタンスの初回起動時にのみ実行されます。起動のたびにスクリプトを実行するために[設定を作成する](https://repost.aws/ja/knowledge-center/execute-user-data-ec2)のも良いですが、今回のワークショップではテンプレートの複雑さを低く抑えるため、このテンプレートでは簡単な内容だけを紹介します。
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** 上で `cfn101-workshop/code/workspace/drift-detection` ディレクトリに移動します:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/drift-detection
:::
1. AWS CLI を使用してスタックを作成します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. 次のコマンドで `CREATE` 操作が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. 以下のコマンドを実行し `Instance1` の **物理 ID** を取得します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. コマンドを実行すると CloudFormation は以下の結果を返却します。`Instance1` の **物理 ID** をメモしておきます。
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=19}
{
    "StackResources": [
        {
            "StackName": "cfn-workshop-drift-detection-challenge",
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Bucket1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-challenge-bucket1-1svpxjottevmx",
            "ResourceType": "AWS::S3::Bucket",
            "Timestamp": "2023-05-23T12:27:57.391000+00:00",
            "ResourceStatus": "CREATE_COMPLETE",
            "DriftInformation": {
                "StackResourceDriftStatus": "NOT_CHECKED"
            }
        },
        {
            "StackName": "cfn-workshop-drift-detection-challenge",
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Instance1",
            "PhysicalResourceId": "i-1234567890abcdef0",
            "ResourceType": "AWS::EC2::Instance",
            "Timestamp": "2023-05-23T12:28:09.726000+00:00",
            "ResourceStatus": "CREATE_COMPLETE",
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
1. **スタックの作成** から、 **新しいリソースを使用 (標準)** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択し、`drift-detection-challenge.yaml` ファイルをアップロードして、 **次へ** をクリックします。
1. スタック名 (例えば、`cfn-workshop-drift-detection-challenge`) を入力し、 **次へ** をクリックします。
1. **スタックオプションの設定** ページで、 **次へ** をクリックします。
1. 次のページで、 **送信** をクリックします。
1. スタックが作成されたら、`cfn-workshop-drift-detection-challenge` スタックを選択し、 **リソース** を選択します。例えば、`i-1234567890abcdef0` のような形式で記述された、`Instance1` の **物理 ID** をメモしておきます。
::::
:::::

次に、ドリフトを導入した最初のラボと同様の方法でこのリソースを変更します。変更する `UserData` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-userdata) ではまずインスタンスを停止する必要があるため、この変更により中断が発生します。出力されるメッセージを `Hello Universe` に変更します。

1. [Amazon EC2 コンソール](https://console.aws.amazon.com/ec2/) に移動します。
1. **インスタンス** セクションを見つけて、上に記録された ID のインスタンスを選択します。
1. **インスタンスの状態** から、 **インスタンスを停止** を選択し、 **停止** ボタンをクリックします。
1. インスタンスの状態が `停止済み` に変わるのを待ちます。必要に応じてページを更新してください。
1. インスタンスの状態が `停止済み` になったら、必要に応じてインスタンスを再度選択し、 **アクション** から **インスタンス設定** を選択し、 **ユーザーデータを編集** を選択します。
1. **新しいユーザーデータ** として、以下のように Hello World を Hello Universe に変更します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
#!/usr/bin/env bash
echo Hello Universe
:::
1. **保存** をクリックします。
1. インスタンスをもう一度選択し、 **インスタンスの状態** から **インスタンスを開始** を選択します。
1. インスタンスの状態が `実行中` に変わるのを待ちます。必要に応じてページを更新してください。

このステップでは、CloudFormation ドリフト検出を使用して、元のテンプレートと比較して `Instance1` リソースに加えられた変更を特定します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. `Instance1` の変更を特定しましょう。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. 以下のコマンドを AWS CLI で実行して **ドリフトの検出結果** を確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resource-drift \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. `descibe-stack-resource-drifts` コマンドの出力結果でリソースのドリフトした内容が `Property Differences` に示されています。
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=21-28}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Bucket1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-challenge-bucket1-1svpxjottevmx",
            "ResourceType": "AWS::S3::Bucket",
            "ExpectedProperties": "{}",
            "ActualProperties": "{}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T12:52:07.616000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Instance1",
            "PhysicalResourceId": "i-0113f35b272b0f04e",
            "ResourceType": "AWS::EC2::Instance",
            "ExpectedProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==\"}",
            "ActualProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFVuaXZlcnNl\"}",
            "PropertyDifferences": [
                {
                    "PropertyPath": "/UserData",
                    "ExpectedValue": "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==",
                    "ActualValue": "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFVuaXZlcnNl",
                    "DifferenceType": "NOT_EQUAL"
                }
            ],
            "StackResourceDriftStatus": "MODIFIED",
            "Timestamp": "2023-05-23T12:52:08.421000+00:00"
        }
    ]
}
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。必要な場合は、 **スタック** メニュー項目を選択してください。
1. 前のステップで作成したスタック (例えば、`cfn-workshop-drift-detection-challenge`) を選択します。
1. **スタックアクション** から、 **ドリフトの検出** を選択します。
1. ドリフト検出が完了するまでに少し時間がかかります。 **ドリフトステータス** フィールドに `Drifted` と表示されるまで、スタック情報ページを更新します。
1. **スタックアクション** から、 **ドリフト結果を表示** を選択します。
1. ドリフトステータスページが表示され、`Instance1` が変更されたことが示されます。
1. `Instance1` を選択し、 **ドリフトの詳細を表示** を選択します。
1. ドリフトの詳細は、`UserData` プロパティが変更されたことを示しています。`UserData` プロパティは Base64 エンコーディングを使用して保存されるため、行った正確な変更は画面上では分かりません。
::::
:::::
:::alert{type="info"}
ツールを使って Base64 のテキストをデコードし、それが表すシェルスクリプトを見ることができます。例えば、 Linux では、`base64` コマンドラインツールを使用して次のように処理できます。macOS などの一部の実装では、`base64` コマンドのオプションとして `-d` の代わりに `-D` を使用していることに注意してください。
:::

例えば、次のコマンドを実行すると、

:::code{language=shell showLineNumbers=false showCopyAction=true}
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==" | base64 -d
:::

次の出力が表示されるはずです。
:::code{language=shell showLineNumbers=false showCopyAction=false}
#!/usr/bin/env bash
echo Hello World
:::

:::alert{type="warning"}
UserData の base64 テキストを外部の Web サイトを使用してエンコードまたはデコードする場合、特に機密情報が含まれている可能性がある場合は注意が必要です。
:::

ここでのタスクは、それ以上中断することなく、スタックをリソースの新しい状態で更新することです。

:::expand{header= "ヒントが必要ですか？"}
* リソースをスタックからデタッチし、`UserData` を修正して再度インポートする必要があります。`UserData` を Base64 に変換する必要はありません。
* 詳細なガイダンスについては、[リソースインポート](/intermediate/operations/resource-importing.html) ラボを参照してください。
:::
::::::expand{header="解決策を確認しますか？"}
1. `drift-detection-challenge.yaml` テンプレートを更新して、値が `Retain` の `DeletionPolicy` 属性を `Instance1` リソースに追加し、ファイルを保存します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=10 highlightLines=12}
Resources:
  Instance1:
    DeletionPolicy: Retain
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello World
:::
1. 更新された `drift-detection-challenge.yaml` テンプレートでスタックを更新します。これにより、CloudFormation は、テンプレートからリソースを削除しても、そのリソースは削除せず、管理を停止するだけとなります。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. スタックの更新が完了したら、テンプレートファイルをもう一度編集して Resources 宣言全体を削除し (関連する各行の先頭にある `#` 文字を使用してコメントアウトしても良いです)、ファイルを保存します。
1. 更新されたテンプレートファイルでスタックを更新します。CloudFormation はインスタンスを終了せずにスタックから削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. テンプレートファイルを編集してリソースを復元し、以前に行った変更と一致するように UserData を更新します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=10 highlightLines=19}
Resources:
  Instance1:
    DeletionPolicy: Retain
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello Universe
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. IMPORT 操作のためにリソースを記述するテキストファイルを作成します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch resources-import.txt
:::
1. 以下のコードをコピーして `resources-import.txt` にペーストします。[**識別子**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview)の値はこのパートの前に、メモをしたインスンスの **物理 ID** に置き換えます。
:::code{language=json showLineNumbers=false showCopyAction=true}
[
  {
    "ResourceType":"AWS::EC2::Instance",
    "LogicalResourceId":"Instance1",
    "ResourceIdentifier": {
      "InstanceId":"i-12345abcd6789"
    }
  }
]
:::
1. リソースのインポートを行うために、次のコマンドを使って `cfn-workshop-drift-detection-challenge` スタックを更新します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-drift-detection-challenge \
--change-set-name drift-challenge --change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://drift-detection-challenge.yaml
:::
1. 次のコマンドを使って変更セットを実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-drift-detection-challenge \
--change-set-name drift-challenge
:::
1. 次のコマンドで `IMPORT` 操作が完了するのを待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. `cfn-workshop-drift-detection-challenge` スタックのドリフト検出を確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. `descibe-stack-resource-drifts`コマンドの実行結果を確認すると、ドリフトの詳細で `Instance1` インスタンスの状態がスタックと同じであることが確認できます。
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=11,22}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Bucket1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-challenge-bucket1-1svpxjottevmx",
            "ResourceType": "AWS::S3::Bucket",
            "ExpectedProperties": "{}",
            "ActualProperties": "{}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T17:29:29.338000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:402198065244:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Instance1",
            "PhysicalResourceId": "i-0113f35b272b0f04e",
            "ResourceType": "AWS::EC2::Instance",
            "ExpectedProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==\"}",
            "ActualProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==\"}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T17:29:30.015000+00:00"
        }
    ]
}
:::
::::
::::tab{id="local" label="ローカル開発"}
1. CloudFormation コンソールでスタックを選択し、 **スタックアクション** から **スタックへのリソースのインポート** を選択します。
1. **次へ** をクリックします。
1. テンプレートファイルをアップロードします。
1. インスタンスの物理 ID を入力し、 **次へ** をクリックします。
1. **スタックの詳細を指定** で、 **次へ** をクリックします。
1. **リソースをインポート** を選択します。
1. スタックの操作が完了し、リソースがインポートされたら、ドリフト検出を実行して、インスタンスがスタックテンプレートと同期していることを確認できます。
::::
:::::
ソリューションのテンプレートは `code/solutions/drift-detection/drift-detection-workshop.yaml` にあります。

おめでとうございます！ これで、リソースを削除して再インポートすることで、影響なしにドリフトを修復する方法がわかりました。
::::::

### クリーンアップ

次に示す手順に従って、このワークショップで作成したリソースをクリーンアップしてください。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. AWS CLI を使って S3 バケットを削除します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
aws s3 rb s3://drift-detection-challenge-AWS_ACCOUNT_ID --force
:::
1. `cfn-workshoop-drift-detection-workshop` スタックを削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-drift-detection-workshop
:::
1. `cfn-workshop-drift-detection-challenge` スタックの `DeletionPolicy` を `Delete` に変更するため、テンプレートファイルを編集します。
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=10 highlightLines=12}
Resources:
  Instance1:
    DeletionPolicy: Delete
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello Universe
:::
1. AWS CLI を使用してスタックを作成します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. スタックの更新が完了した後に、スタックの削除を行います。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-drift-detection-challenge
:::
::::
::::tab{id="local" label="ローカル開発"}
1. CloudFormation コンソールに移動します。
1. 最初のラボで作成したスタック (例えば、`cfn-workshop-drift-detection-workshop`) を選択します。
1. **削除** を選択し、 **削除** をクリックします。
1. `cfn-workshop-drift-detection-challenge` スタックのために使ったテンプレートファイルを編集して `DeletionPolicy` を `Delete` に変更します。
1. スタックを選択して **更新** を選択します。次に **既存テンプレートを置き換える** を選択し、更新されたファイルをアップロードすることでスタックを更新します。 **次へ** を 3 回選択し、最後に **送信** をクリックします。スタックの更新が完了するまでお待ちください。
1. `cfn-workshop-drift-detection-challenge` スタックを選択し、 **削除** を選択後、 **削除** ボタンをクリックします。
::::
:::::

---


### まとめ

このラボでは、CloudFormation スタックのドリフトを検出して、CloudFormation の外部で変更されたリソースを見つけ、変更の詳細を確認する方法を学びました。リソースがテンプレートと一致するように正しく変更されたことを確認する方法と、リソースの望ましい状態に一致するようにスタックを更新する方法を学びました。最後に、影響を受けたリソースを削除して再インポートすることでドリフトを修正する方法を学びました。
