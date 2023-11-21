---
title: "スタックポリシーと誤操作防止のためのコントロール"
weight: 300
---

### 概要

[AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) を使用してコードでインフラストラクチャを記述する場合、意図しない操作を防ぐためのポリシーを実装できます。例えば、[スタックポリシー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)、[削除保護](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html)、[DeletionPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) 属性、[UpdateReplacePolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html) 属性により、スタックに記述したリソースの偶発的な終了、更新、削除を防ぎます。

### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* CloudFormation スタックに [スタックポリシー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) を設定して、スタックで管理しているリソースに対して実行できる更新アクションを設定する方法を学びます。
* [削除保護](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html) を有効にしてスタックの削除を防ぐ方法を学びます。
* [DeletionPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) 属性を使用して、スタックからリソースを削除するとき、またはスタックを削除するときに、スタックに記述したリソースを保持 (場合によってはバックアップ) する方法について学びます。

### ラボを開始

* `code/workspace/stack-policy-and-prevention-controls` ディレクトリに移動します。
* `stack-policy-lab.yaml` ファイルを開きます。
* このラボの手順に従って、テンプレートのコンテンツを更新します。

### **ラボパート 1 - スタックポリシーと削除保護**

[スタックポリシー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) は、スタックリソースの更新操作を定義および制御するためにスタック上にセットアップする JSON 形式のドキュメントです。[削除保護](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html) は、スタックが削除されないようにするためにスタック上で有効にするスタックオプションです。

このラボでは、まず [Amazon Simple Notification Service](https://aws.amazon.com/jp/sns/) (Amazon SNS) [トピック](https://docs.aws.amazon.com/ja_jp/sns/latest/dg/sns-create-topic.html) をスタック内に作成します。トピックの更新を拒否するスタックポリシーを設定し、スタックの削除保護を有効にします。次に、作成したスタックを更新してトピックを更新し、スタックリソースに設定したスタックポリシーをテストします。後ほど、スタックを削除して、有効にした削除保護設定をテストします。

開始するには、次の手順に沿って進んでください。

* 以下のコードをコピーして `stack-policy-lab.yaml` ファイルに追加し、ファイルを保存します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
Parameters:
  SNSTopicTagValue:
    Description: Tag value for your Amazon SNS topic
    Type: String
    Default: Topic-Tag-1
    MinLength: 1
    MaxLength: 256

Resources:
  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: Topic-1
      Tags:
        - Key: TagSNS
          Value: !Ref SNSTopicTagValue
:::


この次のステップでは、`stack-policy-lab.yaml` テンプレートファイルを使用してスタックを作成します。次の手順に沿って進んでください。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
次の手順でスタックを作成します。
1. **Cloud9 のターミナル** で `code/workspace/stack-policy-and-prevention-controls` ディレクトリに移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/stack-policy-and-prevention-controls
:::
1. スタックポリシーを記述するため新しい JSON ファイルを作成します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch policy-body.json
:::
1. Cloud9 のエディタでこのファイルを開き、次の JSON をペーストします。
:::code{language=json showLineNumbers=false showCopyAction=true}
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "Update:Modify",
      "Resource" : "LogicalResourceId/SNSTopic"
    },
    {
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*"
    }
  ]
}
:::
1. テンプレートは入力パラメータとして `SNSTopicTagValue` を必要とします。例えば `Topic-Tag-1` と入力します。
1. 次のコマンドを実行してスタックを作成しましょう。(ここでは例として `us-east-1` リージョンを利用します。必要に応じてリージョンを変更してください。):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--region us-east-1 \
--stack-name cfn-workshop-stack-policy \
--template-body file://stack-policy-lab.yaml \
--stack-policy-body file://policy-body.json \
--parameters ParameterKey=SNSTopicTagValue,ParameterValue=Topic-Tag-1 \
--enable-termination-protection
:::
1. CloudFormation は次の結果を返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId" : "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-stack-policy/330b0120-1771-11e4-af37-50ba1b98bea6"
:::
1. `cfn-workshop-stack-policy` が作成されるまで、CloudFormation コンソールで待機するか AWS CLI の [stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) コマンドを使って待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-stack-policy
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. **スタックの作成** から、 **新しいリソースを使用 (標準)** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルをアップロード** を選択します。`stack-policy-lab.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
1. スタック名を入力します。例えば、`cfn-workshop-stack-policy` と入力します。パラメータセクションで、`SnStopicTagValue` のパラメータ値を `Topic-Tag-1` とします。 **次へ** をクリックします。
1. **スタックオプションの設定** ページの **スタックポリシー** セクションで、 **スタックポリシーを入力する** を選択し、スタックポリシーに次のコードを貼り付けます。 **スタック作成オプション** で、 **削除保護** を **有効** とし、 **次へ** をクリックします。
:::code{language=json showLineNumbers=false showCopyAction=true}
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "Update:Modify",
      "Resource" : "LogicalResourceId/SNSTopic"
    },
    {
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*"
    }
  ]
}
:::
1. 次のページで、 **送信** をクリックします。
::::
:::::

::alert[スタックポリシーをスタックに適用すると、そのスタック内のすべてのリソースがデフォルトで保護されます。従って、他のすべてのリソースを更新できるようにするには、スタックポリシーに明示的な `Allow` ステートメントを指定する必要があります。]

上記で `cfn-workshop-stack-policy` スタックに設定したスタックポリシーは、[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) が `SNSTopic` であるリソースの更新を拒否します。

それでは、作成したスタックを更新して、適用したスタックポリシーをテストしてみましょう。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
次のコマンドを使って `SNSTopicTagValue` の値を `Topic-Tag-1` から `Topic-Tag-2` に更新します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-stack-policy \
--use-previous-template \
--parameters ParameterKey=SNSTopicTagValue,ParameterValue=Topic-Tag-2
:::
CloudFormation は次の結果を返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId" : "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-stack-policy/330b0120-1771-11e4-af37-50ba1b98bea6"
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. `cfn-workshop-stack-policy` という名前のスタックを選択し、 **更新** を選択します。
1. 次のページで、 **現在のテンプレートの使用** を選択します。 **次へ** をクリックします。
1. パラメーターセクションで、`SNSTopicTagValue` の値を `Topic-Tag-1` から `Topic-Tag-2` に更新します。 **次へ** をクリックします。
1. **スタックオプションの設定** ページでデフォルト値のまま、 **次へ** をクリックします。
1. 次のページで **送信** をクリックします。
::::
:::::

スタックの更新は失敗します。[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)でスタックの **イベント** ペインを見ると、[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) が `SNSTopic` であるリソースの `Action denied by stack policy` というエラーが表示されます。

それでは、`cfn-workshop-stack-policy` スタックで有効にした削除保護機能をテストしてみましょう。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. `cfn-workshop-stack-policy` という名前のスタックを選択し、 **削除** を選択します。

スタックで **削除保護** が有効になっていることを知らせるメッセージウィンドウが表示されます。スタックを削除する前に無効にする必要があります。 **キャンセル** を選択してください。

おめでとうございます！ これで、CloudFormation スタック内のリソースの更新操作を定義し、スタックが削除されないようにする方法を学習しました。


### **ラボパート 2 - DeletionPolicy**

[DeletionPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) は、スタックからリソースを削除する場合やスタック自体を削除する場合に、スタック内のリソースを保持 (場合によってはバックアップ) するように設定する CloudFormation リソース属性です。デフォルトでは、リソースに `DeletionPolicy` が設定されていない場合、またはその値が `Delete` に設定されている場合、CloudFormation はスタックの削除時にリソースを削除します。

このラボでは、まず Amazon SNS トピックリソースを含む CloudFormation スタックを作成し、`DeletionPolicy` 属性値を `Retain` に設定してリソースを保存します。次に、スタックを削除し、リソースがまだ存在するかどうかを確認します。

開始するには、次の手順に沿って進んでください。

* `code/workspace/stack-policy-and-prevention-controls` ディレクトリにいることを確認します。
* 以下のコードをコピーして `deletion-policy-lab.yaml` ファイルに追加し、ファイルを保存します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
Resources:
  SNSTopic:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: Topic-2
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
**スタックの作成** を行うためにターミナルで次のコマンドを実行します
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-stack-policy-deletion \
--template-body file://deletion-policy-lab.yaml
:::
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. **スタックの作成** から、 **新しいリソースを使用 (標準)** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルをアップロード** を選択します。`deletion-policy-lab.yaml` テンプレートをアップロードし、 **次へ** をクリックします。
1. スタック名を入力します。例えば、`deletion-policy-lab` と入力します。 **次へ** をクリックします。
1. **スタックオプションの設定ページ** でデフォルト値のまま、ページの一番下までスクロールして **次へ** をクリックします。
1. 次のページで、 **送信** をクリックします。
::::
:::::

`DeletionPolicy` 属性に `Retain` 値を使用するときは、スタックからリソースを削除するとき、またはスタックを削除するときにリソースを保持するように指定します。

スタックが作成されたら、リソースに設定した `DeletionPolicy` をテストしてみましょう。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. `cfn-workshop-deletion-policy` という名前のスタックを選択し、 **削除** を選択します。次に、 **削除** を選択して確定します。

スタックイベントペインで、論理 ID が `SNSTopic` のリソースが削除をスキップしたことがわかります。リソースが保持されていることを確認するには、以下の手順に従います。

1. [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) に移動し、 **トピック** を選択します。
1. スタックで作成したトピック `Topic-2` がまだ存在していることから、スタックの削除中に削除されなかったことが分かります。

おめでとうございます！ これで、リソースに `DeletionPolicy` リソース属性を定義して、スタックの削除時にそのリソースを保持する方法を学習しました。詳しい情報については、[`DeletionPolicy` 属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) と [`DeletionPolicy` オプション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html#aws-attribute-deletionpolicy-options)をご参照ください。

::alert[スタックの更新時に、`UpdateReplacePolicy` [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html) を使用して、スタックの更新中にリソースが置き換えられた際、特定のリソースを保持するか、バックアップするかを選択できます。]

### チャレンジ

これで、[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) に基づいてリソースの更新を拒否するスタックポリシーを作成する方法がわかりました。この演習では、特定のタイプのリソースに適用されるスタックポリシーを作成します。タスクは、`AWS::RDS::DBInstance` リソースタイプへのすべての更新アクションを拒否するスタックポリシーを作成することです。

:::expand{header= "ヒントが必要ですか？"}
- [Condition](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html#stack-policy-reference) キーを使用して `ResourceType` を定義します。
- すべての更新アクションを含めるには、 `Action` をどのように指定しますか？
- `Resource` にはどの値を指定すべきですか？
:::

::::expand{header= "解決策を確認しますか？"}
`"Effect" : "Deny"` に対して、次に示すように `Action`、`Resource`、`Condition` ブロックを含むスタックポリシーを作成します。
:::code{language=json showLineNumbers=false showCopyAction=true}
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*",
      "Condition" : {
        "StringEquals" : {
          "ResourceType" : ["AWS::RDS::DBInstance"]
        }
      }
    },
    {
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*"
    }
  ]
}
:::
::::

これで、特定のリソースタイプの更新を拒否するスタックポリシーを作成する方法がわかりました。

### クリーンアップ
次に示す手順に従って、このラボで作成したリソースをクリーンアップしてください。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. `cfn-workshop-stack-policy` という名前のスタックを選択し、 **削除** を選択します。
1. メッセージウィンドウで、 **削除保護を編集する** を選択し、 **削除保護** を **無効** とします。 **保存する** をクリックします。
1. `cfn-workshop-stack-policy` という名前のスタックを選択し、 **削除** を選択し、 **削除** を選択して確定します。
1. [Amazon SNS コンソール](https://console.aws.amazon.com/sns/) に移動し、 **トピック** を選択します。次に、トピック `Topic-2` を選択し、 **削除** を選択します。メッセージペインに `これを削除` と入力し、 **削除** を選択して確定します。

___

### まとめ
おめでとうございます！ これで、意図しない更新を防ぎ、スタックが削除されないように保護し、意図せずにスタックが削除された場合にリソースを保存する方法を学習しました。
