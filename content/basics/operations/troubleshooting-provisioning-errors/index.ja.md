---
title: "プロビジョニングエラーのトラブルシューティング"
weight: 500
---

### 概要
CloudFormation テンプレートの開発を繰り返す中で、CloudFormation [スタック](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/stacks.html) を作成することで、テンプレートに記述されているリソースのプロビジョニングを検証できます。テンプレート内のリソースの構成に誤ったプロパティ値を指定した場合、デフォルトではスタックは最後に確認された安定した状態にロールバックし、すべてのスタックのリソースはロールバックされます。

10 個のリソースを記述したテンプレートの例からスタックの作成を検証してみましょう。この例では、9 つのリソースが正常に作成されますが、10 番目のリソースの作成は失敗します。デフォルトでは、正常にプロビジョニングされた 9 つのリソースを含め、スタックはロールバックされます。

開発サイクルを早めるために、スタックの作成および更新操作、または[変更セット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)操作の際に正常にプロビジョニングされたリソースの状態を[保持](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/stack-failure-options.html)することが出来ます。この機能を使用すると、スタックのロールバックが一時停止され、正常にプロビジョニングされたリソースの状態を保持します。その状態で設定のトラブルシューティングと修正ができ、準備ができたらプロビジョニング操作を再開できます。

### カバーするトピック
このラボを修了すると、次のことができるようになります。

* 正常にデプロイされたリソースの状態を保持しながら、プロビジョニングエラーをトラブルシューティングする方法を理解する。
* [AWS リソースおよびプロパティタイプのリファレンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)に移動して、特定のリソースのリソースプロパティと戻り値を確認できます。


### Start Lab
サンプルの CloudFormation テンプレートには、誤ったリソース設定が含まれています。これを修正するには、*スタック障害オプション* の一部として *正常にプロビジョニングされたリソースを保存* を選択して、正常にプロビジョニングされるサンプルの `DeadLetterQueue` [Amazon SQS](https://aws.amazon.com/jp/sqs/) キューリソースの状態を保存されるようにします。

テンプレートに別の SQS キューが記述されており、設定エラーがあるため、スタックの作成操作は失敗します。テンプレートのエラーをトラブルシューティングして修正したら、更新されたテンプレートを使用してスタックの作成操作を再開できます。

### ラボの開始

最初は、次の手順を実施してください。
1. `code/workspace/troubleshooting-provisioning-errors` ディレクトリに移動します。
1. お気に入りのテキストエディターで `sqs-queues.yaml` CloudFormation テンプレートを開きます。
1. テンプレート内のサンプル SQS キューの設定をよく確認してください。この例では次のポイントにフォーカスして進みます。
 1. *ソース* キューと [*デッドレター* キュー](https://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) (DLQ) を作成します。正常に処理できない `SourceQueue` のメッセージが `DeadLetterQueue` に流れるようにします。テンプレートでは、`SourceQueue` の [RedrivePolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-redrivepolicy) で `DeadLetterQueue` の [Amazon リソースネーム](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference-arns.html) (ARN) を参照します。DLQ が先に作成され、*ソース* キューがその ARN を参照できるようになります。
 2. この例では、両方のキューを [First-In-First-Out](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-fifoqueue) (FIFO) キューとして記述します。*ソース* キューと *デッドレター* [キュー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-redrivepolicy)を記述する場合、両方のキューは同じタイプ (*standard* または *FIFO*) でなければなりません (後者はこのラボの例です)。サンプルテンプレートには、`FIFOQueue` プロパティ値に両方のキューに設定すべき `true` ではなく、片方を違う設定にしていることにご注目ください。さらに、FIFO キューを記述する場合、その名前には `.fifo` サフィックスを含める必要があります。`SourceQueue` の `QueueName` には `.fifo` サフィックスが含まれていますが、標準キュー (つまり、`FIFOQueue` が `false` に設定されている) として設定されるため、エラーになります。

前述のエラーを含む `sqs-queues.yaml` テンプレートを使用してスタックのロールバックの一時停止機能を利用し、エラーを修正してスタックの作成を完了させます。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動し、使用したい [AWS リージョン](https://docs.aws.amazon.com/ja_jp/awsconsolehelpdocs/latest/gsg/select-region.html) を選択します。
1. 画面の右上の **スタックの作成** プルダウンを開き、**新しいリソースを使用 (標準)** をクリックします。
1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。前述の `sqs-queues.yaml` テンプレートを選択し、**次** を選択します。
1. スタック名を指定します (例: `troubleshoot-provisioning-errors-workshop`)。同じページで、`QueueNamePrefix` パラメーターのデフォルト値をそのまま使用し、**次** を選択します。
1. **スタックの失敗オプション** で、**正常にプロビジョニングされたリソースの保持** を選択します。**次** を選択します。
1. 次ののページで、ページの下部までスクロールし、**スタックの作成** をクリックします。
1. スタックが `CREATE_FAILED` ステータスになるまで、スタック作成ページを更新します。

前述のエラーが原因で、スタックの作成が失敗しました。リストからスタックの名前を選択します (例: `troubleshoot-provisioning-errors-workshop`)。**リソース** タブで、`DeadLetterQueue` リソースが`CREATE_COMPLETE` ステータスで、`SourceQueue` リソースが `CREATE_FAILED` ステータスの状態を確認出来ます。また、失敗した理ソールの `CREATE_FAILED` メッセージをクリックすると、関連エラーを確認出来ます。

同じスページには、次の図に示すように、次に行うステップを選択できるオプションも表示されます。

![stack-rollback-paused.png](/static/basics/operations/troubleshooting-provisioning-errors/stack-rollback-paused.ja.png)

目標は、テンプレートのエラーをトラブルシューティングして修正し、プロビジョニングを再開して `SourceQueue` リソースを作成することです。このプロセスの一環として、先に正常に作成された `DeadLetterQueue` の状態を保持します。次のステップ:

1. テキストエディターで `sqs-queues.yaml` テンプレートを開き、`SourceQueue` リソースを探し、`FifoQueue: false` を `FifoQueue: true` に変更します。完了したら、変更を保存します。
1. 前の図に示した **スタックのロールバックが一時停止されました** の枠の中の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択し、更新したテンプレートを設定した上で **次** を選択します。
1. **パラメータ** ページで **次** を選択します。
1. **スタックオプションの設定** ページで、**スタックの失敗オプション** セクションを探します。スタックの作成時に選択した **正常にプロビジョニングされたリソースの保持** オプションは引き続き選択されているはずです。ページを下にスクロールして、**次へ** を選択します。
1. 次に、**送信** を選択します。

スタックが `UPDATE_COMPLETE` ステータスになるまでページを更新します。スタックの **リソース** タブでは、`SourceQueue` リソースが `CREATE_COMPLETE` ステータスになっているはずです。

::alert[変更不可能な更新タイプ (つまり、置換が必要な[プロパティの値を変更](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html)した場合) はサポートされていません。詳細については、[スタックのロールバックを一時停止する条件](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/stack-failure-options.html#stack-failure-options-conditions) をご参照ください。]{type="info"}

おめでとうございます！CloudFormation の一時停止無効化ロールバック機能を使用してプロビジョニングエラーをトラブルシューティングする方法を学びました！

::alert[このラボでは、AWS CloudFormation コンソールを使用してこの機能を学習しました。[AWS Command Line Interface](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-welcome.html) での使用方法については、ドキュメントの [正常にプロビジョニングされたリソースを保持する (AWS CLI)](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/stack-failure-options.html#stack-failure-options-cli) をご参照ください。]{type="info"}

### チャレンジ
`sqs-queues.yaml` テンプレートに 2 つの [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html) パラメータリソースを追加することとします。パラメータごとに、先に作成したキューの ARN を保存することとします。そのためには、`Fn::GetAtt` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html)を使用して、関連する SQS キューリソースの必要な[戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#aws-resource-sqs-queue-return-values)を取得します。また、各パラメーターの値が ARN であることを検証するために、`AllowedPattern` で定義されている正規表現パターンを定義します。手順は以下の通りです。

* 最初に、次の設定例を `sqs-queues.yaml` テンプレートに追加してください。

```yaml
  DeadLetterQueueParameter:
    Type: AWS::SSM::Parameter
    Properties:
      AllowedPattern: ^arn:aws([-a-z0-9-]*[a-z0-9])*:sqs:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]{1,80}(\.fifo){0,1}$
      Description: Parameter for the DeadLetterQueue ARN value
      Name: workshop-example-dead-letter-queue
      Type: String
      Value: !GetAtt DeadLetterQueue.Arn

  SourceQueueParameter:
    Type: AWS::SSM::Parameter
    Properties:
      AllowedPattern: ^arn:aws([-a-z0-9-]*[a-z0-9])*:sqs:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]{1,80}(\.fifo){0,1}$
      Description: Parameter for the SourceQueue ARN value
      Name: workshop-example-source-queue
      Type: String
      Value: !GetAtt SourceQueue.QueueName
```

* 変更をファイルに保存します。次に、AWS CloudFormation コンソールを使用して[スタックを更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html)します。その際、**テンプレートの準備** で **既存テンプレートを置き換える** を選択し、更新したテンプレートをアップロードします。**スタックオプションの設定** ページでは、**正常にプロビジョニングされたリソースの保持** オプションが引き続き選択されているはずです。
* スタックの更新操作は失敗します。スタックの **リソース** タブを見ると、2 つの新しいリソースのうちの 1 つが正常に作成され、もう 1 つは `CREATE_FAILED` ステータスになっているはずです。
* テンプレートに貼り付けたスニペットのエラーをトラブルシューティングして修正します。
* スタックの更新を再開した後に、スタックが `UPDATE_COMPLETE` ステータスになり、以前は `CREATE_FAILED` ステータスだったリソースが `CREATE_COMPLETE` ステータスになることを確認します。

:::expand{header="ヒントが必要ですか？"}
* AWS CloudFormation コンソールのスタックの「イベント」ペインでエラーを調べてください。
* この SQS リソースの[ドキュメントページ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#aws-resource-sqs-queue-return-values)を開き、SQS キューの ARN を取得するために、`Fn::GetAtt` でどの戻り値を利用すべきかを判断してください。この情報に基づいて、先ほど貼り付けたスニペット内の関連する構成が想定どおりであるかどうかを確認します。
:::

:::expand{header="解決策を確認しますか？"}
* テンプレートの中で、`SourceQueueParameter` リソースの `Value: !GetAtt 'SourceQueue.QueueName'` を `Value: !GetAtt 'SourceQueue.Arn'` に変更してください。
* 更新されたテンプレートを使用して、[スタックの更新](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html)を行ってください。
* 完全なソリューションを含むテンプレートは、`code/solutions/troubleshooting-provisioning-errors` ディレクトリにあります。
:::

### クリーンアップ
このラボで作成したリソースのクリーンアップを行うために、以下の手順を実施してください。
1. このラボで作成したスタック (例: `troubleshoot-provisioning-errors-workshop`) を選択します。
1. **[削除]** を選択してスタックを削除し、ポップアップで **[削除]** を選択して確定します。

---
### まとめ
素晴らしいです！プロビジョニングエラーのトラブルシューティング方法と、作成した SQS キューの例を使って AWS ドキュメントのリソースプロパティ参照情報を検索する方法を学びました。
