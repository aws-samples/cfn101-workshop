---
title: "変更セットの理解"
weight: 200
---

_ラボ実施時間 : 20分程度_

---

### 概要
[AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) スタックを更新すると、そのスタック内の 1 つ以上のリソースを目的の新しい状態に更新します。リソースの依存関係、[スタックリソースの更新動作](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html)、またはユーザーエラーなどの要因により、特定の状態と実際の新しい状態との間に違いが生じる可能性があります。

スタックを[直接](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html)更新するか、[変更セット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) で更新するかを選べます。後者では、適用前に提案された変更のプレビューが表示され、予期しないリソース変更や置換を防ぐのに役立ちます。

変更セットは、テンプレートのパラメータ値を変更するか、変更内容を記述した最新のテンプレートを提供することで作成できます。要件に最も適した変更セットを実行する前に、同じスタックに対して複数の変更セットを作成することもできます。

### 取り上げるトピック
このラボでは次のことを学びます。

* 変更セットの作成方法
* 更新後にスタックがどのようになるかを理解するための変更セットの読み方
* CloudFormation がどのリソースを置き換える必要があるかを判断する方法と、静的評価と動的評価の仕組み

### ラボを開始
サンプルテンプレートを使用して、CloudFormation スタックを作成します。次に、このスタックに 2 つの異なる変更セットを作成します。1 つはテンプレートの編集によるもので、もう 1 つはパラメータ値の変更によるものです。

それでは、始めましょう。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}

1. **Cloud9 ターミナル** で `code/workspace/understanding-changesets` ディレクトリに移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/understanding-changesets
:::
1. `Cloud9` エディターで `bucket.yaml` CloudFormation テンプレートを開き、サンプルテンプレートの内容をよく理解してください。
1. 次の手順に従ってスタックを作成します。
   1. このテンプレートでは、`BucketName` 入力パラメータに一意の値を指定する必要があります。詳細については、 [バケットの名前付け](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/bucketnamingrules.html)を参照してください。
   1. 次のコマンドを使用してテンプレートからスタックを作成しましょう (この例では AWS リージョンに `us-east-1` を使用しています。必要に応じてこの値を変更してください)。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--region us-east-1 \
--stack-name cfn-workshop-understanding-changesets \
--template-body file://bucket.yaml \
--parameters ParameterKey=BucketName,ParameterValue='YOUR_UNIQUE_BUCKET_NAME-HERE'
   :::
   1. CloudFormation は次の出力を返します。
   :::code{language=json showLineNumbers=false showCopyAction=false}
   "StackId" : "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-understanding-changesets/330b0120-1771-11e4-af37-50ba1b98bea6"
   :::
   1. CloudFormation コンソールまたは [wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) コマンドを使用して `cfn-workshop-understanding-changesets` スタックが作成されるまでお待ちください。
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-understanding-changesets
   :::
   ::::
::::tab{id="local" label="ローカル開発"}
1. `code/workspace/understanding-changesets` ディレクトリに移動します。
1. お好みのテキストエディタで `bucket.yaml` CloudFormation テンプレートを開き、サンプルテンプレートの内容をご確認ください。
1. 以下の手順に従ってスタックを作成します。
    1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
    1. **スタックの作成** から、 **新しいリソースを使用 (標準)** を選択します。
    1. **テンプレートの準備** セクションで、 **テンプレート準備完了** を選択します。
    1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。`bucket.yaml` テンプレートファイルを選択し、 **次へ** をクリックします。
    1. スタック名を指定します (例: `cfn-workshop-understanding-changesets`)。
    1. `BucketName` パラメータには必ず一意の値を指定します。詳細については、[バケットの名前付け](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/bucketnamingrules.html) をご参照ください。 **次へ** をクリックします。
    1. 次のページで、すべてのオプションをデフォルト値のままにし、 **次へ** をクリックします。
    1. レビューページで、 **送信** をクリックします。
    1. スタックのステータスが `CREATE_COMPLETE` になるまで、スタックの作成ページを更新します。
::::
:::::

### ラボパート 1
ラボのこの部分では、特定のリソースタイプについて、スタックの更新時に [中断を伴わない更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-no-interrupt) を必要とするプロパティを指定します。次に、変更セットを作成して変更をプレビューし、変更セット操作の出力を確認します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
`Cloud9` エディタで `bucket.yaml` CloudFormation テンプレートを開き、以下に示すように `VersioningConfiguration` を追加します。ファイルを保存します。
:::code{language=yaml showLineNumbers=false showCopyAction=true}
MyS3Bucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Ref BucketName
    VersioningConfiguration:
      Status: Enabled
:::
次に、最初の変更セットを作成します。
1. ターミナルから以下のコマンドを **変更セットの作成** に対して実行し、変更セットの名前を指定します (例:`bucket-versioning-update`)。次に、上の例で選択した `bucketName` パラメーターを指定します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-understanding-changesets \
--change-set-name bucket-versioning-update \
--template-body file://bucket.yaml \
--parameters ParameterKey=BucketName,ParameterValue='TYPE_UNIQUE_BUCKET_NAME-HERE'
:::
1. CloudFormation は AWS CLI の以下の出力を返します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId" : "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-understanding-changesets/330b0120-1771-11e4-af37-50ba1b98bea6",
"Id": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/bucket-versioning-update/a470cff7-cb2c-4cba-bf27-2b3b9ccc1333"
:::
::::
::::tab{id="local" label="ローカル開発"}

お好みのテキストエディタで `bucket.yaml` CloudFormation テンプレートを開き、以下に示すように `VersioningConfiguration` を追加し、ファイルを保存します。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
MyS3Bucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Ref BucketName
    VersioningConfiguration:
      Status: Enabled
:::

次に、最初の変更セットを作成します。

1. CloudFormation コンソールで `cfn-workshop-understanding-changesets` スタックを選択し、 **スタックアクション** から **既存スタックの変更セットを作成** を選択します。
1. **テンプレートの準備** セクションで、 **既存テンプレートを置き換える** を選択します。 **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択し、更新した `bucket.yaml` テンプレートを選択し、 **次へ** をクリックします。
1. **スタックの詳細を指定** ページと **スタックオプションの設定** ページの両方で **次へ** を **選択** し、 **変更セットの作成** をクリックします。
1. 変更セットの名前を指定します (例: `bucket-versioning-update`)。また、`MyS3Bucket のバケットバージョニングを有効にする`などの説明を指定し、 **送信** をクリックします。
1. 変更セットのステータスが `CREATE_COMPLETE` になるまでページを更新します。
::::
:::::

1. [AWS CloudFormation](https://console.aws.amazon.com/cloudformation/) コンソールで、このワークショップで作成したスタックを選択します。たとえば、 `cfn-workshop-understanding-changesets` などです。
1. **変更セット** タブから、 **bucket-versioning-update** を選択します。
1. **JSON の変更** タブに移動すると詳細が表示されます。このタブは次のようになっているはずです。

:::code{language=json showLineNumbers=false showCopyAction=false}
[
  {
    "resourceChange": {
      "logicalResourceId": "MyS3Bucket",
      "action": "Modify",
      "physicalResourceId": "understanding-changesets-123",
      "resourceType": "AWS::S3::Bucket",
      "replacement": "False",
      "moduleInfo": null,
      "details": [
        {
          "target": {
            "name": "VersioningConfiguration",
            "requiresRecreation": "Never",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Static",
          "changeSource": "DirectModification"
        }
      ],
      "changeSetId": null,
      "scope": [
        "Properties"
      ]
    },
    "hookInvocationCount": null,
    "type": "Resource"
  }
]
:::

`resourceChange` 構造では、リソースの論理 ID、CloudFormation が実行するアクション、リソースの物理 ID、リソースのタイプ、および CloudFormation がリソースを置き換えるかどうかが表示されます。`details` 構造では、CloudFormation は、[バージョニング設定](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-properties)プロパティを更新しても中断を必要としないため、バケットを再作成 (replacement) する必要がない直接的な変更としてラベル付けしています。

この変更セットを実行しても、CloudFormation は指定した設定に基づいてバケットを置き換えることはありません。変更セットの実行を控えて、別の変更セットを作成しましょう。

### ラボパート 2
スタックの更新時に [置換](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement) を必要とするプロパティ `BucketName` の値を変更します。次に、変更セットを作成して変更をプレビューし、変更セット操作の出力を確認します。

それでは、始めましょう。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. ターミナルから次のコマンドで **変更セットの作成** を実行し、新しい固有の[バケット名](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/bucketnamingrules.html)を指定して `bucketName` パラメータの値を変更し、前と同じように残りのプロセスを実行して変更セットの作成を完了します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-understanding-changesets \
--change-set-name replace-change-set \
--template-body file://bucket.yaml \
--parameters ParameterKey=BucketName,ParameterValue='YOUR-NEW-UNIQUE-BUCKET-NAME-HERE'
:::
::::
::::tab{id="local" label="ローカル開発"}
1. CloudFormation コンソールで `cfn-workshop-understanding-changesets` スタックを選択し、 **スタックアクション** から **既存スタックの変更セットを作成** を選択します。
1. **テンプレートの準備** セクションで、 **現在のテンプレートの使用** を選択し、 **次へ** をクリックします。
1. 新しい一意の[バケット名](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/bucketnamingrules.html)を指定して `BucketName` パラメータの値を変更し、前の手順に従って変更セットの作成を完了します。
::::
:::::

この変更セットの **JSON の変更** は次のようになります。

:::code{language=json showLineNumbers=false showCopyAction=false}
[
  {
    "resourceChange": {
      "logicalResourceId": "MyS3Bucket",
      "action": "Modify",
      "physicalResourceId": "understanding-changesets-123",
      "resourceType": "AWS::S3::Bucket",
      "replacement": "True",
      "moduleInfo": null,
      "details": [
        {
          "target": {
            "name": "BucketName",
            "requiresRecreation": "Always",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Dynamic",
          "changeSource": "DirectModification"
        },
        {
          "target": {
            "name": "BucketName",
            "requiresRecreation": "Always",
            "attribute": "Properties"
          },
          "causingEntity": "BucketName",
          "evaluation": "Static",
          "changeSource": "ParameterReference"
        }
      ],
      "changeSetId": null,
      "scope": [
        "Properties"
      ]
    },
    "hookInvocationCount": null,
    "type": "Resource"
  }
]
:::

前の例とは 2 つの重要な違いがあることがわかります。まず、`resourceChange` 構造の `replacement` プロパティの値が `True` に設定されています。次に、`detail` 構造の下に `Static` と `Dynamic` の 2 つの評価が表示されます。これらの点について詳しく説明しましょう。

置換が必要な `BucketName` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-properties) を更新したため、`replacement` の値は `True` です。CloudFormation は新しいリソース (この場合は新しいバケット) を作成し、古いリソースを削除します。特定のリソースに複数の変更を加え、それぞれの `requiresRecreation` フィールドの値が異なる場合、CloudFormation は再作成が必要になったときにリソースを置き換えます。言い換えると、多くの変更のうちの 1 つだけを置き換える必要がある場合、リソースを置き換えるために `replacement` フィールドを `True` に設定します。

`replacement` フィールドの値は、`target` 構造の `requiresRecreation` フィールドで示されます。`requiresRecreation` フィールドが `Never` の場合、`replacement` フィールドは `False` になります。`requiresRecreation` フィールドが `Always` で、`evaluation` フィールドが `Static` の場合、`replacement` は `True` になります。ただし、`RequiresRecreation` フィールドが `Always` で、`evaluation` フィールドが `Dynamic` の場合、`replacement` は `Conditionally` になります。

上の例で同じリソースに対して 2 つの異なる評価がある理由を理解するために、それぞれの意味を見てみましょう。

`Static` 評価とは、変更を評価するために必要な情報がすべて揃っているため、CloudFormation が変更セットを実行する前に値を決定できることを意味します。

CloudFormation では、変更セットを実行した後に初めて値を決定できる場合があります。CloudFormation は、これらの変更を `Dynamic` 評価としてラベル付けします。つまり、条件付きで置き換えられた更新済みリソースを参照する場合、CloudFormation は更新されたリソースへの参照が変更されるかどうかを判断できません。例えば、テンプレートに条件付きで置き換えられるリソースへの参照が含まれている場合、リソースを再作成するかどうかによって、参照の値 (リソースの物理 ID) が変わることがあります。リソースを再作成すると、新しい物理 ID が割り当てられるため、そのリソースへのすべての参照も更新されます。 上の例では、更新されたパラメータを参照していて、その結果として `Dynamic` 評価が行われています。

次に、変更に関する静的評価関連データに注目しましょう。 上の例で、静的評価では、パラメータ参照値 `ParameterReference` が変更された結果であることが示されています。変更された正確なパラメータは `causingEntity` フィールド (この場合は `BucketName`) で示されます。

### チャレンジ
お好みのテキストエディタで、`code/workspace/understanding-changesets` ディレクトリにある `changeset-challenge.yaml` という名前のテンプレートファイルを開きます。このファイルは、以前に使用した `bucket.yaml` テンプレートの修正版です。`MyS3Bucket` ではなく `NewS3Bucket` の Amazon S3 バケットリソースの論理 ID を書き留めてください。テンプレートには、`MySqsQueue` 論理 ID を持つ [Amazon Simple Queue Service](https://aws.amazon.com/jp/sqs/) (SQS) [queue](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#aws-resource-sqs-queue-properties) という新しいリソースも記述されていることに注意してください。

`changeset-challenge.yaml` ファイルを使用して `cfn-workshop-understanding-changesets` スタックの新しい変更セットを作成したらどうなると思いますか? リソースはいくつ追加されますか？ リソースは削除されますか? 変更セットの **JSON の変更** からキューの物理 ID を取得できますか?

このファイルを使用して変更セットを作成し、提案された変更を正しく判断できたかどうかを確認してください。

:::expand{header="ヒントが必要ですか？"}
テンプレート内のリソースの論理 ID を変更し、更新したテンプレートでスタックを更新すると、CloudFormation はリソースを置き換えようとします。
:::

::::expand{header= "解決策を確認しますか？"}
* CloudFormation は、新しい `MySqsQueue` キューリソースを追加することに加えて、`NewS3Bucket` 論理 ID を使用して新しいバケットを作成し、`MyS3Bucket` を削除しようとします。新しいリソースの物理 ID は作成されるまで使用できません。 **JSON の変更** は次のようになるはずです。

:::code{language=json showLineNumbers=false showCopyAction=false}
[
  {
    "resourceChange": {
      "logicalResourceId": "MyS3Bucket",
      "action": "Remove",
      "physicalResourceId": "understanding-changesets-123",
      "resourceType": "AWS::S3::Bucket",
      "replacement": null,
      "moduleInfo": null,
      "details": [],
      "changeSetId": null,
      "scope": []
    },
    "hookInvocationCount": null,
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "NewS3Bucket",
      "action": "Add",
      "physicalResourceId": null,
      "resourceType": "AWS::S3::Bucket",
      "replacement": null,
      "moduleInfo": null,
      "details": [],
      "changeSetId": null,
      "scope": []
    },
    "hookInvocationCount": null,
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "MySqsQueue",
      "action": "Add",
      "physicalResourceId": null,
      "resourceType": "AWS::SQS::Queue",
      "replacement": null,
      "moduleInfo": null,
      "details": [],
      "changeSetId": null,
      "scope": []
    },
    "hookInvocationCount": null,
    "type": "Resource"
  }
]
:::
::::

### クリーンアップ

このラボで作成したリソースをクリーンアップするには

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
ターミナルから次の AWS CLI コマンドを実行して、作成したスタックを削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-understanding-changesets
:::
::::
::::tab{id="local" label="ローカル開発"}
1. CloudFormation コンソールから、`cfn-workshop-understanding-changesets` という名前のスタックを選択します。
1. **削除** を選択し、次に **削除** を選択してスタックと、スタック用に作成した変更セットを削除します。
::::
:::::

---

### まとめ

変更セットを作成する方法、変更セットの出力を読み取る方法、リソース設定の変更に基づいて CloudFormation がどのリソースを置き換える必要があるかを判断する方法を学びました。
