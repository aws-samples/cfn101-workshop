---
title: "静的解析とテスト"
weight: 900
---

### 概要
ソフトウェア開発ライフサイクル (Software Development Life Cycle, SDLC) の早い段階において CloudFormation テンプレートの静的解析 (lint) とテストをしておくことはベストプラクティスです。まず、自身のワークステーションで lint とテストのアクションを実行します。次に、テンプレートの lint とテストをパイプラインの継続的インテグレーション (Continuous Integration, CI) のフェーズに組み込みます。CI フェーズをコードプロモーションの最初の導入口として使うのです。

このラボでは、自身のワークステーションから lint とテストのワークフローを実行する例にフォーカスします。[AWS CloudFormation Resource Specification](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) に対してテンプレートの検証を行う [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) のツールや、指定したリージョンにスタックを作成することでテストを行うことができる [taskcat](https://github.com/aws-ia/taskcat) に慣れることができます。

### カバーするトピック
このラボの修了でに次のことができるようになります。

* テンプレートを検証するための `cfn-lint` を使えるようになります。
* 検証エラーを見つけ修正する方法を理解できるようになります。
* `taskcat` を使って指定したリージョンにスタックを作成してテンプレートをテストできるようになります。

### 事前準備

#### lint のための事前準備
お好きな方法で `cfn-lint` を[インストールします](https://github.com/aws-cloudformation/cfn-lint#install)。例えば、次のように `pip` で `cfn-lint` をインストールできます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install cfn-lint
:::

::alert[このラボでは、`cfn-lint` をコマンドラインから実行します。他には、`cfn-lint` の IDE プラグインをこの[ページ](https://github.com/aws-cloudformation/cfn-lint#editor-plugins)のリストからインストールし、サポートされているエディタで `cfn-lint` からフィードバックを得られます。]{type="info"}

インストールが完了したら、`cfn-lint` を実行できることを確認してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint --version
:::

#### テストの前提条件

`pip` で `taskcat` を [インストール](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html)します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install taskcat
:::

::alert[この [note](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html#windows) によると、`taskcat` は Windows ではサポートされていません。Windows 10 を使用している場合は、この [ページ](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html#windows) の指示に従って、[Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) (WSL) 環境内に `taskcat` をインストールしてください。]{type="info"}

インストールが完了したら、`taskcat` を実行できることを確認します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
taskcat --version
:::

### ラボの開始

#### テンプレートの lint

このセクションでは、設定の検証を行うために、サンプルの CloudFormation テンプレートに対して `cfn-lint` を実行します。ゴールは、開発ライフサイクルの初期において、[AWS CloudFormation Resource Specification](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) に対してテンプレートの内容の検証を行い、指定した値の妥当性をチェックし、多くのベストプラクティスのチェックに対してテンプレートを検証する機会になります。

1. `code/workspace/linting-and-testing` ディレクトリに移動します。
2. `vpc-and-security-group.yaml` CloudFormation テンプレートをお好きなエディタで開きます。サンプルテンプレートには、VPC の例と、その VPC を参照する VPC セキュリティグループの例が記載されています。このラボのスコープをシンプルにし、lint のユースケースにフォーカスするため、サンプルのテンプレートは他の VPC 関連のリソース (サブネット、インターネットゲートウェイ、ルートテーブル、ルートリソースなど) の記述をしていません。
3. テンプレートに対し、`cfn-lint` を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint vpc-and-security-group.yaml
:::

出力にエラーが表示されることをご確認ください。
:::code{language=shell showLineNumbers=false showCopyAction=false}
E3004 Circular Dependencies for resource SecurityGroup. Circular dependency with [SecurityGroup]
[...]
:::

サンプルのテンプレートは循環依存 (circular dependency) のエラーを含んでいます。このようなエラーは、リソースプロパティの _値_ で、リソース自身の[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) を参照しているときに起きます。サンプルテンプレートを見てみると、`AWS::EC2::SecurityGroup` [タイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html) の `SecurityGroup` リソースで循環依存を持っていることがわかります。次のテンプレートの抜粋で示されているように、`SourceSecurityGroupId` プロパティは `SecurityGroup` リソース自身を参照しているからです。

:::code{language=yaml showLineNumbers=false showCopyAction=false}
[...]
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Example Security Group
      SecurityGroupIngress:
        - Description: Example rule to allow tcp/443 traffic from SecurityGroup
          FromPort: 443
          ToPort: 443
          IpProtocol: tcp
          SourceSecurityGroupId: !Ref SecurityGroup
[...]
:::

この循環依存を解消するためには、セキュリティグループの `SecurityGroupIngress` に関連した設定を `AWS::EC2::SecurityGroupIngress` [タイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html) の新しいリソースに移植します。テンプレートに追加するこのリソースの `SourceSecurityGroupId` プロパティ値には、`SecurityGroup` リソースを参照します。お好みのテキストエディタで `vpc-and-security-group.yaml` テンプレートを開き、`SecurityGroup` リソースの宣言ブロック全体を次の内容で置き換えてください。

```yaml
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Example Security Group
      SecurityGroupEgress:
        - Description: Example rule limiting egress traffic to 127.0.0.1/32
          CidrIp: 127.0.0.1/32
          IpProtocol: "-1"
      VpcId: !Ref Vpc

  SecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      Description: Example rule to allow tcp/443 traffic from SecurityGroup
      FromPort: 443
      ToPort: 443
      GroupId: !Ref SecurityGroup
      IpProtocol: tcp
      SourceSecurityGroupId: !Ref SecurityGroup
```

できたら、ファイルを保存してテンプレートを再び `cfn-lint` で検証し、エラーが修正されたことを確かめます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint vpc-and-security-group.yaml
:::

おめでとうございます！`cfn-lint` ツールをテンプレートに対して実行し、ツールが検出したエラーを発見し修正しました！

#### テンプレートのテスト

`taskcat` を使用して、指定する AWS リージョンでテンプレートからスタックを作成し、テンプレートをテストします。`taskcat` で使いたいテスト設定値は [config files](https://aws-ia.github.io/taskcat/docs/usage/GENERAL_USAGE/#config-files) を使って記述できます。その設定プロパティは以下の通りに指定できます。

* **[general](https://aws-ia.github.io/taskcat/docs/usage/GENERAL_USAGE/#global-config) スコープ:** すべてのプロジェクトを対象としたグローバルスコープ。このユースケースでは、ホームディレクトリに `~/.taskcat.yml` ファイルを作成します。
* **[project](https://aws-ia.github.io/taskcat/docs/usage/GENERAL_USAGE/#project-config) スコープ:** プロジェクトのルートディレクトリに `.taskcat.yml` 設定ファイルを作成します。プロジェクトレベルのスコープで [tests](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema/#tests) 設定ディレクティブを使用することもできます。

まず、`code/workspace/linting-and-testing` ディレクトリにある `.taskcat.yml` ファイルで _project_ と _tests_ のスコープを設定します。このファイルをお好みのテキストエディターで開き、以下のファイルの抜粋のように、`vpc-and-security-group.yaml` テンプレートをテストしたい AWS [regions](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema/#project_regions) の名前を指定します。

:::code{language=shell showLineNumbers=false showCopyAction=false}
[...]
  regions:
  - us-east-1
  - us-east-2
[...]
:::

完了したら、変更したファイルを保存します。

::alert[`taskcat` の [要件](https://aws-ia.github.io/taskcat/docs/INSTALLATION/#requirements) の一部として、`Dockerfile` を使用して AWS Lambda 関数を構築する場合は Docker が必要になります。この機能はこのラボでは必要ありません。この機能は、`.taskcat.yml` ファイルの `package_lambda` [設定](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema/#project_package_lambda) が `false` に設定されているため無効になっています。]{type="info"}

次に、`~/.taskcat.yml` 設定ファイルを __プロジェクトのバージョン管理パスの外にあるホームディレクトリ__ に作成します。このファイルには、すべてのプロジェクトについて構成設定を保存するので、バージョンコントロールに追加しません。なぜなら、使用する可能性がある機密値も含まれるからです。__機密値をバージョン管理に保存しないでください__。

::alert[CloudFormation テンプレートから機密値を参照する方法については、[SSM Secure String パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-secure-strings)と [Secrets Manager のシークレット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-secretsmanager)を参照してください。]{type="info"}

::alert[下位のスコープ (たとえば、`tests`) で記述した構成設定の値は、上位のスコープ (`project` や `general` など) よりも [優先](https://aws-ia.github.io/taskcat/docs/usage/GENERAL_USAGE/#precedence) になります。__逆に動作する `parameters` 設定は例外です__。つまり、`general` スコープで設定 `parameters` 設定の値が下位のスコープよりも優先されます。この後に `general` スコープの `parameters` の記述を説明します。]{type="info"}

ホームディレクトリに新しく `~/.taskcat.yml` ファイルを作成します。このファイルには、`taskcat` がテストするテンプレートをアップロードするS3バケットの名前と、`VpcIpV4Cidr` サンプルテンプレートパラメータの `172.16.0.0/16` の値の例を指定します。
::: code {language=shell showLineNumbers=False showCopyAction=True}
~/.taskcat.yml をタッチしてください
:::

作成したファイルに次のコンテンツを追加します。必ず `YOUR_ACCOUNT_ID` にはご利用の [AWS アカウント ID](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/console_account-alias.html#FindingYourAWSId) に置き換えてください。

```yaml
general:
  s3_bucket: tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID
  parameters:
    VpcIpv4Cidr: 172.16.0.0/16
```

次に、AWS CLI を使用して、ファイルに指定した名前のバケットを作成します (ここも `YOUR_ACCOUNT_ID` を自分の値に置き換えてください)。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 mb s3://tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID
:::

::alert[必要に応じて _general_、_project_、および _tests_ スコープで `s3_bucket` コンフィギュレーション設定を指定できます。`s3_bucket` プロパティを指定しない場合、テストを起動すると `taskcat` が自動的にバケットを作成します。]{type="info"}

バケットを作成したら、次のコマンドを実行してテストを開始します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
taskcat test run
:::

`taskcat` がテストの実行を終了すると、`code/workspace/linting-and-testing/taskcat_outputs/index.html` ファイルにテストが正常に終了したことを確認できるレポートが出力されます。

`code/solutions/linting-and-testing` パスには、`vpc-and-security-group.yaml`、`.taskcat.yml`、`.gitignore` というワークスペースファイル (必要に応じて更新してください) があります。

> おめでとうございます！`taskcat` を使用して CloudFormation テンプレートのテストを 1 つ (または複数) のリージョンで実行しました！

#### テンプレートテスト:ラボリソースのクリーンアップ

[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/) を使用して、このラボで作成したテスト用のリソースを削除します。まず、次の例のように、`taskcat` が S3 バケットにアップロードした *テンプレートファイルオブジェクトを削除します* (注意: `YOUR_ACCOUNT_ID` を自分の値に置き換えてください)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api delete-object --bucket tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID --key linting-and-testing-workshop/vpc-and-security-group.yaml
:::

`vpc-and-security-group.yaml` と同じディレクトリに、このラボの _Challenge_ セクションで利用する別のテンプレート (`sqs-queue.yaml`) があります。先ほど行ったテスト実行の際に、`taskcat` がこのファイルもバケットにアップロードしてくれました。次の例に示すように、バケットから削除してください (`YOUR_ACCOUNT_ID` を自分の値に置き換えてください)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api delete-object --bucket tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID --key linting-and-testing-workshop/sqs-queue.yaml
:::

次に、このラボ用に作成した**バケットを削除します**。この時点で、バケットには他のオブジェクトは含まれていないはずです。次のコマンドを実行します。必ず `YOUR_ACCOUNT_ID` を自分の値に置き換えてください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api delete-bucket --bucket tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID
:::

必要に応じて、ホームディレクトリに作成した `~/.taskcat.yml` ファイルも削除してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
rm ~/.taskcat.yml
:::

### チャレンジ

`AWS::SQS::Queue` [リソースタイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#aws-resource-sqs-queue-properties) を記述したサンプルテンプレートのエラーを発見し修正してください。

* 次のパスのテンプレートファイルを特定してください: `code/workspace/linting-and-testing/sqs-queue.yaml`
* `cfn-lint` を使ってテンプレートのエラーを発見してください。
* 問題を修正し、見つけた問題を修正したことを `cfn-lint` で確認してください。

:::expand{header="ヒントが必要ですか？"}
* `code/workspace/linting-and-testing` ディレクトリから, `cfn-lint sqs-queue.yaml` を実行し、サンプルテンプレートのエラーを見つけます。
* `cfn-lint` コマンドの出力を参照し、`DelaySeconds` プロパティに指定する値を SQS のリソースドキュメント [ページ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-delayseconds) から確認してください。
* SQS キュー[プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#aws-resource-sqs-queue-properties)で利用可能な名前を確認してください。
* SQS キューの[戻り値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#aws-resource-sqs-queue-return-values) で利用可能な _属性_ 名を確認してください。
:::

:::expand{header="解決策を確認しますか？"}
* `DelaySeconds` に `0` (デフォルト) か `900` を指定してください。
* テンプレートの SQS リソースプロパティの `Tag` を `Tags` で置き換えてください。
* キュー名を返すために、`Fn::GetAtt` で指定した属性を `Name` から `QueueName` に置き換えてください。
* `code/workspace/linting-and-testing` ディレクトリで `cfn-lint sqs-queue.yaml` を実行し、これ以上エラーが出ないことを確認してください。

完全な解答は `code/solutions/linting-and-testing/sqs-queue.yaml` のサンプルテンプレートで確認できます。
:::

---
### まとめ

すばらいい！ワークステーションから `cfn-lint` と `taskcat` をコマンドラインから使ってサンプルテンプレートの検証を行いました。また、`cfn-lint` を使ってサンプルテンプレートのエラーを見つけ、`cfn-lint` から提供されたエラー情報を使ってテンプレートの問題を解決しました。より早いフィードバックループのために、`cfn-lint` はこの[ページ](https://github.com/aws-cloudformation/cfn-lint#editor-plugins)で示されているように、たくさんのコードエディタと統合することを選択できます。
