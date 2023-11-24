---
title: "スタックセットによるオーケストレーション"
weight: 700
---

_ラボ実施時間 : 45分程度_

---

### 概要

[AWS CloudFormation StackSets](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html) を使用して、同じインフラストラクチャを複数の AWS [リージョン](https://aws.amazon.com/jp/about-aws/global-infrastructure/regions_az/)または複数の AWS アカウントにデプロイできます。CloudFormation StackSets を使用すると、1 回の操作で複数のアカウントや AWS リージョンにまたがるスタックを作成、更新、削除できます。管理アカウントから CloudFormation テンプレートを定義および管理し、そのテンプレートを基にして任意のターゲットアカウントまたはリージョンにスタックをプロビジョニングできます。[出力値のエクスポートとインポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html)によってスタックセットの間でパラメータを共有したり、スタックセットに依存関係を設定したりすることもできます。

StackSets を使用して複数の AWS アカウントやリージョンにデプロイすることもできますが、このラボでは、1 つのアカウントを使用して複数のリージョンにデプロイする方法を学習することに重点を置きます。最終的な状態のアーキテクチャ図を以下に示します。

![StackSetsOverview](/static/intermediate/operations/stacksets/stacksetsoverview.png)

### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* CloudFormation StackSets を活用して、1 つのアカウントでリソースをプロビジョニングし、1 回の操作で複数のリージョンにまたがってリソースをプロビジョニングします。
* スタックセットのインスタンスから出力パラメータをエクスポートし、別のスタックセットのインスタンスにインポートする方法を理解します。

### ラボを開始

#### 事前準備

AWS CloudFormation StackSets が複数の AWS アカウントにスタックをデプロイしたり、複数の AWS リージョンにスタックをデプロイしたりするには、特定の権限が必要です。StackSets の操作を実行するには管理ロールが必要で、ターゲットアカウントに実際のスタックをデプロイするには実行ロールが必要です。これらのロールには特定の命名規則が必要です。管理者ロールには**AWSCloudFormationStackSetAdministrationRole**、実行ロールには**AWSCloudFormationStackSetExecutionRole** となります。これらのロールがないと、StackSets の実行は失敗します。

::alert[クロスアカウントデプロイでは、スタックセットを作成するアカウント(管理アカウント)に**AWSCloudFormationStackSetAdministrationRole** を作成する必要があることに注意してください。**AWSCloudFormationStackSetExecutionRole** は、スタックをデプロイしたい各ターゲットアカウントで作成する必要があります。CloudFormation スタックセットの[セルフマネージド型のアクセス許可を付与する](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html) で詳細をご覧ください。アカウントが AWS Organizations を使用して管理されている場合は、[信頼できるアクセスを有効にする](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/stacksets-orgs-activate-trusted-access.html)を実行すると、CloudFormation が全てのアカウントに必要なロールのプロビジョニングを行います。]{type="info"}

このラボを開始するには、CloudFormation を使用して管理者ロールと実行者ロールを作成します。

1. 管理者ロール CloudFormation テンプレートをダウンロードします: https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml
2. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation) に移動し、**米国東部 (バージニア北部)** リージョンにいることを確認します。
3. **スタックの作成** を選択し、**新しいリソースを使用 (標準)** を選択します。
4. **テンプレートを作成** 設定は以下のように設定します。
    1. **テンプレートソース** では、**テンプレートファイルをアップロード** を選択します。
    2. **ファイルを選択**を選択し、ダウンロードした CloudFormation テンプレート (*AWSCloudFormationStackSetAdministrationRole.yml*)を指定します。**次へ** を選択します。
5. **スタック名** には、`StackSetAdministratorRole` を使用してください。**次へ** を選択します。
6. **スタックオプションの設定** では、キーとバリューのペアであるタグを設定できます。タグは、スタックとスタックによって作成されるリソースを識別するのに役立ちます。例えば、左側の列にタグキーである *Owner* を入力し、右側の列にタグ値である電子メールアドレスを入力します。ページの他の設定はデフォルト値をそのまま使用します。**次へ** を選択します。
7. **レビュー** でページの内容を確認します。ページの下部で、**AWS CloudFormation によって IAM リソースがカスタム名で作成される場合があることを承認します。** にチェックを入れます。
8. **送信** を選択します。

スタックの作成の **ステータス** が `CREATE_COMPLETE` になるまで待ってください。

StackSets の管理者ロールを作成しました。次に実行ロールを作成します。

1. 実行ロール CloudFormation テンプレートをダウンロードします: https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml
2. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)で、**スタックの作成** を選択し、**新しいリソースを使用 (標準)** を選択します。
3. **テンプレートを作成** 設定は、以下のように設定します。
    1. **テンプレートソース** では、**テンプレートファイルをアップロード** を選択します。
    2. **ファイルを選択** を選択し、ダウンロードした CloudFormation テンプレート (*AWSCloudFormationStackSetExecutionRole.yml*) を指定します。**次へ** を選択します。
4. **スタックの詳細を指定** ページで、**スタック名** には `StackSetExecutionRole` を使用してください。
5. **パラメータ** に、このラボで使用している AWS アカウントの 12 桁のアカウント ID を入力します。**次へ** を選択します。
6. **スタックオプションの設定** では、前述のようにタグを設定することができます。例えば、タグキーには *Owner* と入力し、タグ値にはメールアドレスを入力します。ページの他の設定はデフォルト値をそのまま使用します。**次へ** を選択します。
7. **レビュー** で、ページの内容を確認します。ページの下部で、**AWS CloudFormation によって IAM リソースがカスタム名で作成される場合があることを承認します。** を選択します。
8. **送信** を選択します。

スタックの作成の **ステータス** が `CREATE_COMPLETE` になるまで待ってください。

必要な権限を作成したので、ラボのパート 1 に進みます。

#### ラボパート 1

このラボのパート 1 では、サンプルの CloudFormation テンプレート `example_network.yaml` を使用して、StackSets 機能で同じアカウントの 2 つのリージョンにスタックを作成します。このラボのパート 2 では、別のサンプル CloudFormation テンプレート `example_securitygroup.yaml` を使用して、前のスタックセットで作成したネットワークごとにセキュリティグループを作成します。`example_network.yaml` で記述するリソースのアーキテクチャ図を以下に示します。

![StackSetsNetworkStack](/static/intermediate/operations/stacksets/stacksetsnetworkstack.png)

開始するには、以下の手順に従ってく進んでださい。

1. `code/workspace/stacksets` ディレクトリに移動します。
2. お好みのテキストエディターで `example_network.yaml` CloudFormation テンプレートを開きます。
3. テンプレート内のサンプルリソースの設定を確認しておいてください。この例では以下のことを意図しています。
   1. [Amazon Virtual Private Cloud](https://aws.amazon.com/jp/vpc/)、インターネットゲートウェイ、2 つのパブリックサブネット、ルートテーブル、およびインターネットへの 2 つのルートを作成します。CloudFormation StackSets で 1 回の作成オペレーションで、これらのリソースを複数のリージョンにデプロイできるようにします。
   2. VPC ID とサブネット ID を[エクスポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html)に出力します。エクスポートはリージョンによって異なります。

前述のネットワークリソースを含む `example_network.yaml` テンプレートを使用して、同じアカウントの 2 つのリージョン(`us-east-1` と `us-west-2`)　にテンプレートをデプロイします。

次のステップでは、AWS CloudFormation コンソールを使用して　`example_network.yaml` テンプレートからスタックセットを作成します。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを使用して、**Create StackSet** をしてみましょう。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-set \
--stack-set-name cfn-workshop-network \
--template-body file://example_network.yaml
:::
1. 次の AWS CLI コマンドを使用して、スタックセットにスタックインスタンスを作成します。このコマンドでは、このラボで使用するアカウントの 12 桁の AWS アカウント ID を指定する必要があります。AWS アカウント ID は、画面の右上の ユーザ/ロール ドロップダウンメニューを選択すると確認できます。リージョンには、米国東部 (バージニア北部) と米国西部 (オレゴン) の両方にデプロイすることを選択します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-instances \
--stack-set-name cfn-workshop-network \
--accounts 123456789012 \
--regions us-east-1 us-west-2
:::
1. CloudFormation は次の出力を返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"OperationId": "d7995c31-83c2-xmpl-a3d4-e9ca2811563f"
:::
1. スタックインスタンスが正常に作成されたことを確認します。ステップ 3 の出力の一部として返された `operation-id` を使用して `DescribeStackSetOperation` を実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-set-operation \
--stack-set-name cfn-workshop-network \
--operation-id operation_ID
:::
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。ページの左側にあるパネルから、**StackSets** タブを選択します。
1. `cfn-workshop-network` を選択すると、**スタックインスタンス** の下に 2 つのスタックがデプロイされているはずです。1 つは `us-east-1` にあり、もう 1 つは `us-west-2` にあります。
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. ページの左側のパネルから、**StackSets** タブを選択します。**StackSet の作成** を選択します。
1. **アクセス許可** セクションで、**IAM 管理ロール ARN** の値は空白のままにし、**IAM 実行ロール名** を**AWSCloudFormationStackSetExecutionRole** に設定します。
1. **前提条件 - テンプレートの準備** セクションから、**テンプレートの準備完了** を選択します。
1. **テンプレートを指定** セクションで、**テンプレートソース** で **テンプレートファイルのアップロード** を選択します。**ファイル名の選択** を選択し、前述の CloudFormation テンプレート `example_network.yaml` を指定して、**次へ** を選択します。
1. **StackSet の詳細を指定** ページで、名前、説明、設定パラメータを指定します。
    1. **StackSet 名** を指定します。例えば、`cfn-workshop-network` を入力します。
    1. **StackSet の説明**を入力します。例えば、`Provisions VPC, internet gateway, two public subnets, and two routes to the Internet` を入力します。
    1. **パラメータ** はデフォルト値をそのまま使用してください。**次へ** を選択します。
1. **StackSet オプションの設定** では、**実行設定** はそのままにします。**次へ** を選択します。
1. **デプロイオプションの設定** ページの **スタックセットにスタックを追加** セクションで、**新しいスタックのデプロイ** を選択します。
1. **アカウント** で、**スタックをアカウントにデプロイ** を選択します。
1. **アカウント番号** テキストボックスに、このラボで使用しているアカウントの 12 桁のアカウント ID を入力します。この値は、画面の右上にある ユーザ/ロール ドロップダウンメニューを選択すると確認できます。
![StackSetsDeploymentOptions](/static/intermediate/operations/stacksets/stacksetsdeploymentoptions.ja.png)
1. **リージョンの指定** では、**米国東部 (バージニア北部)** と **米国西部 (オレゴン)** にデプロイすることを選択します。
1. **デプロイオプション** はデフォルト値をそのまま使用し、**次へ** を選択します。
1. **レビュー** ページで、ページの内容を確認し、**送信** を選択します。
1. **CREATE** ステータスが `SUCCEEDED` になるまで StackSet 作成ページを更新します。
![StackSetCompletion](/static/intermediate/operations/stacksets/createstacksetcompletion.ja.png)
1. **スタックインスタンス** タブで、2 つのスタックがデプロイされているはずです。1 つは `us-east-1` にあり、もう 1 つは `us-west-2` にあります。
![StackInstances](/static/intermediate/operations/stacksets/stackinstances.ja.png)
::::
:::::
左のパネルで **エクスポート** を選択します。`AWS-CloudFormationWorkshop-SubnetId1`、`AWS-CloudFormationWorkshop-SubnetId2`、`AWS-CloudFormationWOrkshop-VPCID` という名前の 3 つのエクスポートが表示されるはずです。これらのエクスポートは、スタックセットをデプロイした各リージョン (`us-east-1` と `us-west-2`) で作成されます。

![StackSetExports](/static/intermediate/operations/stacksets/exports.ja.png)

おめでとうございます! 1 回のオペレーションでインフラストラクチャを複数のリージョンにデプロイできました。

#### ラボパート 2

ラボのこのパートでは、新しい CloudFormation テンプレート `example_securitygroup.yaml` を使用して、特定のリージョンで以前作成した VPC に関連付けるセキュリティグループを記述します。また、**セキュリティグループ ID** の出力をエクスポートして、このワークショップラボの *チャレンジ* の部分で後で使用できるようにします。`example_securitygroup.yaml` テンプレートで記述するセキュリティグループリソースを表現したアーキテクチャ図を以下に示します。

![StackSetsSecurityGroup](/static/intermediate/operations/stacksets/stacksetsecuritygroup.png)

それでは、始めましょう。

1. `code/workspace/stacksets` ディレクトリに移動します。
2. `example_securitygroup.yaml` テンプレートをお好みのテキストエディタで開きます。
3. テンプレート内のサンプルセキュリティグループの設定を確認してください。この例では、以下のことを意図しています。
    1. CloudFormation StackSets を使用して 1 回の作成操作で、2 つのリージョンのそれぞれで先に作成した VPC にセキュリティグループを作成します。VPC ID は `Fn::ImportValue` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) を使用して参照します。
    2. `SecurityGroupID` の出力をエクスポートします。エクスポートはリージョンによって異なります。

次のステップでは、AWS CloudFormation コンソールを使用して `example_securitygroup.yaml` テンプレートからスタックセットを作成します。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを使用して、**Create StackSet** を実行しましょう。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-set \
--stack-set-name cfn-workshop-security \
--template-body file://example_securitygroup.yaml
:::
1. 次の AWS CLI コマンドを使用して、スタックセットにスタックインスタンスを作成します。このコマンドでは、ラボで使用するアカウントの 12 桁の AWS アカウント ID を指定する必要があります。この値は、画面の右上にある ユーザー/ロール ドロップダウンメニューを選択すると確認できます。リージョンの場合には、米国東部 (バージニア北部) と米国西部 (オレゴン) の両方にデプロイすることを選択します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-instances \
--stack-set-name cfn-workshop-security \
--accounts 123456789012 \
--regions us-east-1 us-west-2
:::
1. CloudFormation は次の出力を返却します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"OperationId": "d7995c31-83c2-xmpl-a3d4-e9ca2811563f"
:::
1. スタックインスタンスが正常に作成されたことを確認します。ステップ 3 の出力の一部として返却された `operation-id` を使用して `DescribeStackSetOperation` を実行します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-set-operation \
--stack-set-name cfn-workshop-security \
--operation-id operation_ID
:::
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。左側のパネルから、**StackSets** を選択します。
2. `cfn-workshop-security` を選択すると、**スタックインスタンス** の下に 2 つのスタックがデプロイされているはずです。1 つは `us-east-1` にあり、もう 1 つは `us-west-2` にあります。
::::
::::tab{id="local" label="ローカル開発"}
1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
1. ページの左側のパネルから、**StackSets** タブを選択します。**StackSet の作成** を選択します。
1. **アクセス許可** セクションで、**IAM 管理ロール ARN** 配下には、ドロップダウンから **IAM ロール名** を選択し、隣のドロップダウンから **AWSCloudFormationStackSetAdministrationRole** を選択します。**IAM 実行ロール名** を **AWSCloudFormationStackSetExecutionRole** に設定します。
1. **前提条件 - テンプレートの準備** セクションから、**テンプレートの準備完了** を選択します。
1. **テンプレートを指定** セクションで、**テンプレートソース** で **テンプレートファイルのアップロード** を選択します。**ファイル名の選択** を選択し、前述の CloudFormation テンプレート `example_securitygroup.yaml `を指定して、**次へ** を選択します。
1. **StackSet の詳細を指定** ページで、名前、説明、設定パラメータを指定します。
   1. **StackSet 名**を指定します。例えば、`cfn-workshop-security`を選択します。
   1. **StackSet の説明**を入力します。例えば、`Provisions a security group, and associates it to the existing VPC` を入力します。
   1. **パラメータ** はデフォルト値をそのまま使用してください。**次へ** を選択します。
1. **StackSet オプションの設定** では、**実行設定** はそのままにします。**次へ** を選択します。
1. **デプロイオプションの設定** ページの **スタックセットにスタックを追加** セクションで、**新しいスタックのデプロイ** を選択します。
1. **アカウント** で、**アカウントにスタックをデプロイ** オプションを選択します。
1. **アカウント番号** テキストボックスに、このラボで使用しているアカウントの 12 桁の AWS アカウント ID を入力します。
1. **リージョンの指定** では、**米国東部 (バージニア北部)** と **米国西部 (オレゴン)** にデプロイすることを選択します。
1. **デプロイオプション** はデフォルト値をそのまま使用します。**同時アカウントの最大数** は **1** で、**障害耐性** は **0** で、**リージョンの同時実行** を **順次** であることを確認してください。**次へ** を選択します。
1. **レビュー** ページで、内容を確認し、**送信** を選択します。
1. **CREATE** ステータスが `SUCCEEDED` になるまで StackSet 作成ページを更新します。
1. **スタックインスタンス** タブで、2 つのスタックがデプロイされているはずです。1 つは `us-east-1` にあり、もう 1 つは `us-west-2` にあります。
::::
:::::

左のパネルで **エクスポート** に移動します。「AWS-CloudFormationWorkshop-SecurityGroupId」という名前の新しいエクスポートが表示されるはずです。

![StackSetsSecurityGroupExports](/static/intermediate/operations/stacksets/exportssecuritygroup.ja.png)

おめでとうございます!スタックセットインスタンスから出力値をエクスポートし、別のスタックセットインスタンスにインポートする方法を学びました。

### チャレンジ

この演習では、ラボの前半で得た知識を使用します。あなたのタスクは、既存の VPC に [Amazon Elastic Compute Cloud (Amazon EC2)](https://docs.aws.amazon.com/ja_jp/ec2/) インスタンスをプロビジョニングする新しい `cfn-workshop-ec2instance` スタックセットを作成し、先ほど作成したセキュリティグループをアタッチすることです。また、このラボのパート 1 でエクスポートした `SubnetId1` の値をインポートするように `example_ec2instance.yaml` テンプレートを更新することも課題です。スタックセットを作成する時は、StackSets オペレーションを **並行** にデプロイするようにしてください。このチャレンジで定義する EC2 インスタンスを表すアーキテクチャ図を以下に示します。

![StackSetsEc2instance](/static/intermediate/operations/stacksets/stacksetsec2instance.png)

::::expand{header="ヒントが必要ですか？"}
* `code/workspace/stacksets` ディレクトリに移動していることを確認してください。
* お好みのテキストエディターで `example_ec2instance.yaml` CloudFormation テンプレートを開きます。

:::alert{type="info"}
[Amazon Machine Image (AMI)](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/AMIs.html) リソースはリージョンごとに異なります。リージョン固有の AMI ID を使用するには、テンプレートの `Parameter` セクションにある次のコードスニペットを使用して、特定のリージョンの最新の AMI ID を取得します。また、テンプレートの **Resources** セクションで `ImageId` で `LatestAmId` を参照します。
:::
:::code{language=yaml showLineNumbers=false showCopyAction=false}
LatestAmiId:
  Description: The ID of the region-specific Amazon Machine Image to use.
  Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
  Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
:::
* テンプレートの `Resources` セクションを編集して、第 1 回でエクスポートした `SubnetId1` の値をインポートします。VPC ID をインポートしたのと同じ方法で、`example_network.yaml` から `example_securitygroup.yaml` に任意のパラメータをインポートできます。
::::

::::::expand{header="解決策を確認しますか？"}
ソリューションの全文は `code/solutions/stacksets/example_ec2instance.yaml` テンプレートにあります。

EC2 インスタンスのプロパティにこのコードを追加します: `SubnetId: !ImportValue AWS-CloudFormationWorkshop-SubnetId1`
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. ディレクトリを `cfn101-workshop/code/solutions/stacksets` に変更します。
2. 更新したテンプレートを使用し、次の AWS CLI コマンドを使用して新しい **StackSet** を作成します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-set \
--stack-set-name cfn-workshop-ec2instance \
--template-body file://example_ec2instance.yaml
:::
1. 次の AWS CLI コマンドを使用して、スタックセットにスタックインスタンスを作成します。StackSet のオペレーションを並行してデプロイするには、`--operation-preferences` の `RegionConcurrencyType` を **PARALLEL** に指定します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-instances \
--stack-set-name cfn-workshop-ec2instance \
--accounts 123456789012 \
--regions us-east-1 us-west-2 \
--operation-preferences RegionConcurrencyType=PARALLEL
:::
::::
::::tab{id="local" label="ローカル開発"}
更新したテンプレートを使用して、新しい `cfn-workshop-ec2instance` スタックセットを作成して、先に選択した 2 つのリージョンに EC2 インスタンスリソースをデプロイします。StackSets のオペレーションを並行してデプロイするには、**リージョンの同時実行** を **並行** に設定します。これにより、StackSets のオペレーションを両方のリージョンに並行してデプロイできるため、時間を節約できます。
::::
:::::
::::::

### クリーンアップ

最後に、作成したリソースを削除します。スタックセットを削除するには、まずスタックインスタンスを削除し、次に空のスタックセットを削除します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. AWS CLI からスタックセットを削除する前に、**StackSet** のスタックインスタンスを削除してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack-instances \
--stack-set-name cfn-workshop-ec2instance \
--accounts 123456789012 \
--regions us-east-1 us-west-2 \
--no-retain-stacks
:::
1. `DELETE-STACK-INSTANCE` 操作が完了するのを待ってから、次のコマンドを実行して **StackSet** を削除します
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack-set \
--stack-set-name cfn-workshop-ec2instance
:::
1. 他の 2 つのスタックセットについては、`cfn-workshop-security` と `cfn-workshop-network` の順序で、ステップ 1 〜 2 を実行します。
1. 次の AWS CLI コマンドを実行して、このラボで作成した IAM ロールを削除します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-set-name StackSetAdministratorRole
:::
1. ステップ 4 を繰り返して、実行ロールスタック `StackSetAdministratorRole` を **削除** します。
::::
::::tab{id="local" label="ローカル開発"}

**スタックセット内の AWS CloudFormation スタックを削除する方法**

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
2. 削除したいスタックから CloudFormation スタックセットを選択します。最後に作成したスタックセット、つまり `cfn-workshop-ec2instance` を選択します。
3. ページの右上のセクションから**アクション**を選択し、**StackSet からスタックを削除**を選択します。
4. **アカウント**で、**デプロイロケーション**で**アカウントにスタックをデプロイ**を選択します。
5. **アカウント番号**に、このラボで使用しているアカウントの 12 桁の AWS アカウント IDを入力します。
6. **リージョンを指定**では、**全てのリージョンを追加**を選択します。これにより、StackSet がデプロイされた AWS リージョンが自動的に選択されます。 **次へ**を選択します。
7. **レビュー**ページで、ページの内容を確認し、**送信**を選択します。
8. **ステータス**が `Pending`に変わります。
9. **ステータス**が `SUCCEEDED` になるまで更新します。
10. 他の 2 つのスタックセットについては、`cfn-workshop-security` と `cfn-workshop-network` の順番で、ステップ 2 〜 8 を実行します。

各 StackSet 内のスタックを削除したので、次は空の StackSet を削除することを選択します。

**AWS CloudFormation スタックセットを削除する方法**

1. [AWS CloudFormation StackSets コンソール](https://console.aws.amazon.com/cloudformation/home#/stacksets) に移動します。
2. 削除するスタックセットを選択します。
3. **アクション** を選択し、**StackSet の削除** を選択します。
4. 表示されるポップアップで、**削除** を選択して、このスタックセットの削除を確定します。
5. 画面を更新すると、StackSet は表示されなくなります。
6. 他の 2 つのスタックセットについては、ステップ 2 〜 5 を実行します。

**AWS CloudFormation スタックを削除する方法**

1. [AWS CloudFormation スタック コンソール](https://console.aws.amazon.com/cloudformation/home#/stacksets) に移動します。
2. スタック `StackSetAdministratorRole` を選択し、**削除** を選択します。
3. 示されるポップアップで、**削除** を選択してこのスタックの削除を確定します。
4. 画面を更新すると、スタック `StackSetAdministratorRole` は表示されなくなります。
5. このラボで作成したもう 1 つの `StackSetExecutionRole` スタックに対しても、ステップ 2 ～ 4 を実行します。
::::
:::::

### まとめ

CloudFormation StackSets を使用して 1 回のオペレーションで複数の AWS リージョンにテンプレートをデプロイする方法と、あるスタックセットのスタックインスタンスから出力パラメータをエクスポートして別のスタックセットのスタックインスタンスにインポートする方法を学びました。
