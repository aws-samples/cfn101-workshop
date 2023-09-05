---
title: "テンプレートの設計"
weight: 650
---

### 概要

インフラストラクチャをコードで記述する場合、インフラストラクチャの成長に合わせて拡張できることと、時間の経過に伴う継続的な保守性を考慮する必要があります。[AWS CloudFormation ベストプラクティス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/best-practices.html) ページには、ワークフローで採用すべきベストプラクティスがまとめられています。このラボでは、コードで記述するリソースの _ライフサイクルと所有権_ の側面と _モジュール性と再利用_ のプラクティスを考慮して、テンプレートの設計に焦点を当てます。これらのプラクティスは、同じアカウントとリージョン内のスタックの値を参照して CloudFormation テンプレートに実装します。テンプレートの入力パラメータも同様です。このワークショップでは、ベストプラクティスの例を示す他のセルフペースラボもあります。例えば、[疑似パラメータ](/basics/templates/pseudo-parameters)、[リンティングとテスト](/basics/templates/linting-and-testing)、[動的参照](/intermediate/templates/dynamic-references) (AWS CloudFormation テンプレート内の機密情報の参照)、[Policy-as-Code with Guard](/intermediate/templates/policy-as-code-with-guard) (JSON および YAML 形式のデータのコードとしてのポリシー検証) です。



### 取り上げるトピック

このラボを修了すると、次のことを学ぶことができます。

* ライフサイクルと所有権の基準による設計テンプレートを含むデザインパターンを学習
* 依存関係の値をエクスポートして利用することでスタックを構成する方法を学習
* モジュール型テンプレートの再利用方法についての概念を学習



### ラボを開始

このラボでは、AWS クラウドで実行される簡単な Web アプリケーションのためのインフラストラクチャを作成します。

* 特定のリージョン (例: us-east-1) の 2 つの[アベイラビリティーゾーン](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) に 2 つのパブリックサブネットと 2 つのプライベートサブネットが存在する [Amazon Virtual Private Cloud](https://aws.amazon.com/jp/vpc/) (Amazon VPC)を作成します。

* 最低 2 つの [Amazon Elastic Compute Cloud](https://aws.amazon.com/jp/ec2/) (Amazon EC2) インスタンス、最大 4 つの [Auto Scaling グループ](https://docs.aws.amazon.com/ja_jp/autoscaling/ec2/userguide/auto-scaling-groups.html) を作成します。インスタンスを 2 つのプライベートサブネットで起動し、簡単な Web アプリケーションを実行します。
* インターネット向けエンドポイントを持つ [Application Load Balancer](https://aws.amazon.com/jp/elasticloadbalancing/application-load-balancer/) を作成します。このロードバランサーは EC2 インスタンスの前に配置されます。
* [Amazon Route 53](https://aws.amazon.com/jp/route53/) [ホストゾーン](https://docs.aws.amazon.com/ja_jp/Route53/latest/DeveloperGuide/hosted-zones-working-with.html) が 1 つあり、そこにロードバランサーを指す [エイリアス](https://docs.aws.amazon.com/ja_jp/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html) レコードを保存します。このサンプルラボの実行中にドメイン名を登録する必要はありません。[プライベートホストゾーン](https://docs.aws.amazon.com/ja_jp/Route53/latest/DeveloperGuide/hosted-zones-private.html) を作成して、ホストゾーンが関連付けられた VPC で起動した EC2 インスタンスなどのコンピュートリソースからサンプルアプリケーションに HTTP リクエストを送信できるようにします。そのためには、[AWS Cloud9](https://aws.amazon.com/jp/cloud9/) 環境 (このラボの一部を実行するために使用) を作成し、デプロイするアプリケーションに HTTP リクエストを送信します。

デプロイを始める前に、これから構築するアプリケーションについて考えてみましょう。特に、*ジョブロール*について考えてみてください。例えば、ある会社では、セキュリティ、ネットワーク、アプリケーション、データベースなどに関連する機能を所有するさまざまなチームがあります。すべての機能を 1 つのチームが所有することになったとしても、各テンプレートの各機能をその機能に特化した個人のグループが所有し、マッピングできるようにテンプレートを設計するのがベストプラクティスです。これは、トラブルシューティングや再利用が容易な小さなテンプレートを用意する場合にも役立ちます。このようなテンプレートは、必要に応じてさらに小さなテンプレートに分割できます。また、情報を保持するリソース (データベースなど) と、そのデータを消費するリソース (サーバー群など) を別々のスタックにまとめることも検討できます。これにより、関連するリソースを管理するデータベースチームなど、専任のリソース所有者をマッピングするのに役立つだけでなく、時間の経過に伴うトラブルシューティングやリソースの維持も容易になります。例えば、データベースとアプリケーションスタック全体を同じテンプレートに記述する場合、次に作成するスタックで問題が発生した場合、問題の性質によっては、最悪、スタックを削除して新しいスタックを作成する必要があります。影響範囲を絞り込むだけでなく、別のテンプレートを使用してデータベースを記述すると、後でテンプレートを再利用する可能性も高くなります。

では、これから構築するインフラストラクチャを見てみましょう。次のステップに進む前に、このインフラストラクチャをライフサイクルと所有権別に設計するための出発点について考えます。どのように検討を進めますか?

![architecting-templates-infrastructure-diagram.png](/static/intermediate/templates/architecting-templates/architecting-templates-infrastructure-diagram.png)

最初は、次に説明する手順を使用します。後続の各スタックで表現するリソースは、前のスタックで作成するリソースに依存している場合があることに注意してください。

* VPC 関連リソース用の 1 つのテンプレート
* ホストゾーン用の 1 つのテンプレート
* アプリケーションとロードバランサーのセキュリティグループ用の 1 つのテンプレート
* ロードバランサー、EC2 インスタンス、前のテンプレートで作成したホストゾーンに追加する DNS レコードを含む、アプリケーションスタック用の 1 つのテンプレート

また、別のテンプレートを使用して Cloud9 環境を記述します (上の図には示されていません)。

前述の戦略では、所有権 (VPC 関連リソースを所有するネットワークチーム、セキュリティグループのリソースを所有するセキュリティチーム、インフラストラクチャとアプリケーションのデプロイを所有するアプリケーションチーム) を考慮しただけでなく、ライフサイクルも考慮してテンプレートを設計しました。例として、アプリケーションの新しいバージョンをロールアウトする必要があり、それをカットオーバーするための新しいアプリケーションスタックを作成したい場合、アプリケーションインフラストラクチャの依存関係を記述する他のすべての既存のスタックを（必要でない限り）必ずしも再デプロイ、または、更新する必要はありません。

::alert[上のサンプルインフラストラクチャの一部としてデータベースを作成する場合、それを別のテンプレートで記述することも検討できます。また、同じテンプレート内のアプリケーションセキュリティグループから ingress/egress ルールを参照するために、アプリケーションスタックのセキュリティグループと同じテンプレートに、そのセキュリティグループを記述することも選択可能です。その場合、データベース用のセキュリティグループの情報をエクスポートし、データベースを作成するスタックで使用します。]{type="info"}



### 前提条件のインストール

まだ、以下の手順が実行できていない場合、前提条件に従い、次のものを自分のワークステーションにインストールします (Cloud9 はこのラボで後ほど使用しますが、最初にワークステーションを使用することから始めます)。

1. [Git をインストール](/prerequisites/git)。
2. [ラボリソースを取得](/prerequisites/lab-resources): ラボリポジトリのクローンを作成します。本作業を実施すると、リポジトリがワークステーションの `cfn101-workshop` ディレクトリにクローンされます。


次に、クローンを作成したリポジトリの `cfn101-workshop/code/workspace/architecting-templates` ディレクトリに移動します。まずは、`base-network.template` ファイルと `cloud9.template` ファイルを使用して、ベースインフラストラクチャと Cloud9 環境をそれぞれ作成します。



### VPC スタックの作成

さあ、始めましょう！ CloudFormation を使用してインフラストラクチャを表現するときに、このラボで使用するサンプルテンプレートが一連の依存関係とどのように結び付けられているかを見てみましょう。これらの依存関係は、あるスタックにエクスポートされ、別のスタックにインポートされます。

`base-network.template` ファイルを使用して新しいスタックを作成します。

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
2. ページ上部のリージョンセレクターから、*バージニア北部* (`us-east-1`) などのリージョンを選択します。
3. **スタックの作成**から、**新しいリソースを使用 (標準)** を選択します。
4. **テンプレートの準備**セクションで、**テンプレート準備完了**を選択します。
5. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。前述の `base-network.template` ファイルを選択し、**次へ** をクリックします。
6. スタック名を指定します。例えば、`cloudformation-workshop-dev-base-network` と入力します。デフォルトのパラメータ値のまま、**次へ** をクリックします。
7. 次のページで、**次へ**をクリックします。
8. 次のページで、**送信**をクリックします。

スタックの作成が開始されます。最後に、スタックのステータスが `CREATE_COMPLETE` になります。スタックの作成が進むにつれて、ワークステーションの任意のテキストエディタで `base-network.template` ファイルを開きます。次の点を確認してください。

* リージョン内の別々のアベイラビリティーゾーン (例えば、`us-east-1` リージョンの `us-east-1a`、`us-east-1b` アベイラビリティーゾーン) にサブネットを作成する場合は、各サブネットで `AvailabilityZone` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html) を指定します。サンプルテンプレートでは、アベイラビリティーゾーン名 (`us-east-1a` など) をハードコーディングする代わりに、`Fn::Sub` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) を使用します (テンプレートでは YAML の短縮形 `!sub`) を使用して、リージョンの名前 (例: `AWS::Region` [疑似パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-region) の `us-east-1`) を `a` または `b` のいずれかと連結します。例えば、`AvailabilityZone: !Sub '${AWS::Region}a'` と記述します。連結し、テンプレートの移植性を高めることで、このテンプレートをリージョン間で再利用しやすくできます。
* テンプレートの `Outputs` セクションで、[エクスポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) したいリソースの値を書き留めて、次に作成するスタックでそれらの値を使用できるようにします。特定の名前でエクスポートを作成すると、その名前を参照してエクスポートの値を別のスタックで使用できます。各エクスポートは、アカウントやリージョンごとに一意でなければなりません。サンプルテンプレートでは、各エクスポートの名前にはプレフィックスとしてスタック名が含まれています（前述のように、`AWS::StackName` 疑似パラメータが `Fn::Sub` と共に使用されていることに注意してください）。スタック名は特定のアカウントとリージョンでも一意でなければならないため、最初にプレフィックスとしてスタック名を選択するのが妥当な選択です。もちろん、選択するサフィックスとプレフィックスを組み合わせると、アカウントやリージョン内でも一意のエクスポート名になることを確認する必要があります。最終的には、選択したエクスポート名が一意で、使いやすく、同じ命名規則で後続のスタックで派生しやすい形になっていることが重要です。



### Cloud9 環境の作成

次に、Cloud9 環境を作成します。これを 2 つの目的で使用します。1 つは、このラボ用のインフラストラクチャのデプロイを継続すること、もう 1 つは VPC の範囲内で DNS 設定を検証することです。Cloud9 環境をデプロイする前に、環境そのものを記述するテンプレートでどのようにエクスポートを実行するかを見てみましょう。お好みのテキストエディタで `cloud9.template` ファイルを開き、`AWS::Cloud9::EnvironmentEC2` リソースタイプの `SubnetId` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-cloud9-environmentec2.html#cfn-cloud9-environmentec2-subnetid) の値を書き留めておきます。Cloud9 環境の EC2 インスタンスを使用して前述のプライベートホストゾーンの DNS レコードの名前解決をテストするには、プライベートホストゾーン自体に関連付けるのと同じ VPC に属するサブネットでインスタンスを起動します。このラボでは、先ほど作成した最初のパブリックサブネットを指定します。サブネットを指定するには、サブネット ID を含むエクスポート名を参照します。この例では、最初に、エクスポートしたスタック名 (このスタック名を `cloud9.template` に入力パラメータとして渡します)を、 VPC スタックで選択したサフィックス (`Fn::Sub: ${NetworkStackName}-PublicSubnet1Id`) に連結し、最初のパブリックサブネットのエクスポート名を作成します。エクスポートの合成名を使用して、その値を `Fn::ImportValue` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) で利用します。なお、サンプルテンプレートには、YAML の短縮形で示されています。クロススタック参照の詳細については、この [ページ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) の `Fn::ImportValue` の **Note** セクションをご参照ください。

Cloud9 の環境を作ってみましょう！ [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) を使用します。

1. 先ほど選択したリージョンと同一のリージョン (*バージニア北部* (`us-east-1`)など) であることを確認してください。
2. **スタックの作成**から、**新しいリソースを使用 (標準)** を選択します。
3. **テンプレートの準備**セクションで、**テンプレート準備完了**を選択します。
4.  **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。`cloud9.template` ファイルを選択し、**次へ**をクリックします。
5. スタック名を指定します。例えば、`cloudformation-workshop-dev-cloud9` と入力します。デフォルトのパラメータ値のまま、**次へ** をクリックします。
6. 次のページで、**次へ**をクリックします。
7. 次のページで、**送信**をクリックします。
8. スタックのステータスが `CREATE_COMPLETE` になるまで、スタックの作成ページを更新します。名前のプレフィックスが `aws-cloud9-aws-cloudformation-workshop-` となっている別のスタックも作成されることに注意してください。このスタックは、Cloud9 環境のセキュリティグループと EC2 インスタンスを作成します。
9. 準備ができたら、Cloud9 環境を開きます。[AWS Cloud9 コンソール](https://console.aws.amazon.com/cloud9/home) に移動し、`aws-cloudformation-workshop` 環境を見つけて、**Open IDE** を選択します。これで、環境が別のウィンドウで開かれるはずです。



### `cfn-lint` のインストール

ソフトウェア開発ライフサイクル (SDLC) の一環として、*フィードバックループを短縮して時間を節約* するために、コード開発中に問題の発見と修正を開始するには、早期テストが鍵となります。CloudFormation を使用する際のベストプラクティスの一環として、テンプレートが有効な JSON または YAML データ構造を使用しているだけでなく、[AWS CloudFormation リソース仕様](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) にも準拠していることを検証する必要があります 。早期にテストを実施することで、例えば、間違ったリソースプロパティ名や値を指定した場合、ワークステーションでテンプレートを作成するときに、SDLC の非常に早い段階で誤りを発見できます。

テンプレートを検証するには、[AWS CloudFormation Linter](https://github.com/aws-cloudformation/cfn-lint) を使用します。Cloud9 環境のページの下部にあるコマンドラインターミナルを利用し、次に示すように、`virtualenv` を使用して Python 用の新しい仮想環境を作成し、アクティブ化します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir ~/my-virtual-environments
virtualenv ~/my-virtual-environments/cloudformation-workshop-venv
source ~/my-virtual-environments/cloudformation-workshop-venv/bin/activate
:::

上記の最後のコマンドで、作成した仮想環境がアクティブになっているはずです。シェルプロンプトに `(cloudformation-workshop-venv)` というプレフィックスが付加されているはずです。次に、次のコマンドを実行して、現在のターミナルの仮想環境スコープに `cfn-lint` をインストールします。

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install cfn-lint
:::

::alert[Cloud9 の現在のターミナルを閉じてから新しいターミナルを再度開く場合は、`source ~/my-virtual-environments/cloudformation-workshop-venv/bin/activate` コマンドをもう一度実行して、以前に作成した仮想環境を新しいターミナルでアクティブ化してください。]{type="info"}

インフラストラクチャをデプロイし続ける中で、`cfn-lint` を使用する例を後で説明します。このワークショップでの CloudFormation テストツールの詳細については、[リンティングとテスト](/basics/templates/linting-and-testing) ラボをご参照ください。`cfn-lint` をワークステーションで任意の [サポートされているエディタ](https://github.com/aws-cloudformation/cfn-lint#editor-plugins) のプラグインとしても実行可能です。あなたのプロジェクトにて、`cfn-lint` を `pre-commit` [フック](https://github.com/aws-cloudformation/cfn-lint#pre-commit) として実行することもできます。

::alert[フェイルファスト戦略や使用している SDLC プロセスの一環として、コードで記述したインフラストラクチャが、会社が必要としている統制に準拠していることを確認するためのコンプライアンス検証チェックも含める必要があります。一例として、CloudFormation のツールや機能には [AWS CloudFormation Guard](https://docs.aws.amazon.com/ja_jp/cfn-guard/latest/ug/what-is-guard.html) と [AWS CloudFormation Hooks](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/hooks.html) がありますが、このラボでは説明しません。CloudFormation ワークショップの、[Policy-as-Code with Guard](/mediate/templates/policy-as-code-with-guard) ラボを試してみてください。]{type="info"}



### Cloud9 環境からのデプロイの継続

リソースのデプロイを続行します。今回は、[AWS Command Line Interface](https://aws.amazon.com/jp/cli/) (AWS CLI) を使用してスタックを作成します。AWS CLI は既に Cloud9 に含まれています。今後の参考として、ご自身のワークステーションにインストールする方法の詳細については、[AWS CLI 入門ガイド](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-getting-started.html) をご参照ください。

インフラストラクチャのデプロイを続けるには、まずこのラボのリポジトリを Cloud9 環境にクローンする必要があります。次に示すように、必ず `~/environment` ディレクトリ内から以下のコマンドを実行してください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd ~/environment
git clone https://github.com/aws-samples/cfn101-workshop.git
:::

次に、ディレクトリを `cfn101-workshop/code/workspace/architecting-templates/` に変更します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/architecting-templates/
:::



### cfn-lint を実行

`architecting-templates` ディレクトリのテンプレートファイルに対して `cfn-lint` を実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint *.template
:::

上記のコマンドの出力は表示されないはずです。つまり、エラーがないということを示しています。このコマンドを実行することで、テンプレートが前述のリソースタイプの仕様に準拠していることを確認できました。このラボでは、テンプレートアーキテクチャの例を示すことと、ワークスペースを準備するという2つの理由のために、VPC と Cloud9 環境のリソースをデプロイしました。ベストプラクティスの一環として、リソースをデプロイしたり、テンプレートをリポジトリに追加したりする前に `cfn-lint` を実行して、プロセスの早い段階で変更を加えます。

`cfn-lint` の機能の例を説明するために、Cloud9 の左側にある *Environment* ナビゲーションタブを使用して `aws-cloudformation-workshop -> cfn101-workshop-> code -> workspace -> architecting-templates` ディレクトリの `hosted-zone.template` ファイルを開きます。 `Name: !Ref 'HostedZoneName'` の行を、一時的に `Names: !Ref 'HostedZoneName'` に変更します (`Name` プロパティを一時的に `Names` に変更します)。次に、先ほど行ったように `cfn-lint` を実行すると、次のようなエラーが表示されるはずです。

:::code{language=shell showLineNumbers=false showCopyAction=false}
E3002 Invalid Property Resources/HostedZone/Properties/Names
:::

ここで `cfn-lint` は、指定したプロパティが、[論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) が `HostedZone` のリソースに対して有効ではないことを示しています。ご覧のとおり、早めにチェックして、リンティングの観点からテンプレートを検証する機会があります。

::alert[ホストゾーンを作成する前に、忘れずに `Names` を `Name` に戻してください。]{type="warning"}



### ホストゾーンの作成

Cloud9 で `hosted-zone.template` ファイルを開きます。次の点をご確認ください。

* このラボでは、これから作成するホストゾーンを VPC に関連付けます。VPC の ID を参照する `AWS::Route53::HostedZone` リソースタイプの設定を見ると、このサンプルテンプレートがどのように実装されているかがわかります。そのためには、まずエクスポート名を `Fn::Sub: ${NetworkStackName}-VpcId` で構成し、次に `!ImportValue` 宣言でエクスポート値を利用します。
* ホストゾーンを作成したら、ホストゾーン情報を利用するアプリケーションスタックを作成します。アプリケーションスタックには、同じスタックで作成するロードバランサーを指す DNS エイリアスレコードを記述し、このレコードの保存場所を知る必要があります。`hosted-zone.template` ファイルでは、ホストゾーンの ID と名前を `Outputs` セクションにエクスポートして、この情報を後でアプリケーションスタックで使用できるようにします。

このテンプレートで表現されているビジネスロジックを理解できたので、次はホストゾーンを作成します。 この作業の実行には、Cloud9 環境に既にインストールされている AWS CLI を使用します。まず、`hosted-zone.template` ファイルと `us-east-1` リージョンに `cloudformation-workshop-dev-hosted-zone` という名前の新しいスタックを作成します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-hosted-zone \
    --template-body file://hosted-zone.template \
    --region us-east-1
:::

このコマンドを実行することで、次の抜粋のような出力が得られます。

:::code{language=json showLineNumbers=false showCopyAction=false}
{
    "StackId": "arn:aws:cloudformation: [...]"
}
:::

次のコマンドを使用してスタックの作成が完了するのを待ちます (または、CloudFormation コンソールに移動して、スタックのステータスが `CREATE_COMPLETE` になるまで待ちます)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name cloudformation-workshop-dev-hosted-zone \
    --region us-east-1
:::

スタックの作成が完了すると、Route 53 のプライベートホストゾーンが作成されます。スタックの作成に使用したデフォルトのテンプレートパラメータを見てください。ホストゾーンの名前は `my-example-domain.com` です。[Route 53 Console](https://console.aws.amazon.com/route53/home) に移動し、**ホストゾーン**から、作成したホストゾーンを選択すると、詳細ページに `NS` と `SOA` の 2 つの DNS レコードタイプが既にあることがわかります。後で CloudFormation を使用してロードバランサー用のエイリアスレコードを作成します。そのレコードも詳細ページに表示されるはずです。



### セキュリティグループの作成

Cloud9 で `security-groups.template` ファイルを開きます。このサンプルテンプレートでは、2 つのセキュリティグループについて表現しています。1 つは作成するロードバランサー用、もう 1 つはサンプル Web アプリケーションを実行する EC2 インスタンス用です。どちらのセキュリティグループも、前に見たのと同じ方法で VPC ID を利用することに注意してください。また、セキュリティグループ ID が `Outputs` セクションでエクスポートされ、後でアプリケーションスタックから使用可能としている点にも注目します。

`cloudformation-workshop-dev-security-groups` という名前の新しいスタックでセキュリティグループを作成します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-security-groups \
    --template-body file://security-groups.template \
    --region us-east-1
:::

コマンド実行後は、作成が完了するのを待ちます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name cloudformation-workshop-dev-security-groups \
    --region us-east-1
:::



### アプリケーションスタックの作成

Cloud9 で `application.template` ファイルを開きます。このテンプレートでは、アプリケーションロードバランサーと EC2 インスタンスの Auto Scaling グループを使用して、アプリケーションをデプロイする方法を説明します。次の点に注意してください。


* このラボで簡単にテストできるように、ロードバランサーの HTTP リスナーを使用します。
* Auto Scaling グループ [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html) は `LaunchTemplate` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-launchtemplate.html) を使用して各インスタンスをブートストラップします。特に、 `LaunchTemplateData` の下にある `UserData` プロパティ内から、最初に `yum update -y aws-cfn-bootstrap` を使用して各インスタンスで [CloudFormation ヘルパースクリプト](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html) がどのようにセットアップされて、次に、`cfn-init` [ヘルパースクリプト](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-init.html) がパッケージ (`httpd` など) インストールとコンテンツの設定にどのように使用されるかがわかります: 例として、デフォルト値が `Hello world!` となっているサンプルテンプレートパラメータから参照されている `/var/www/html/index.html` Web アプリケーションファイルの値に注目してください。
* `UserData` セクションの `cfn-signal` [ヘルパースクリプト](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-signal.html) は、インスタンスの作成や更新が成功したかどうかを CloudFormation に伝えるよう設定されています。さらに、`cfn-hup` [ヘルパー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-hup.html) は、スタックの更新時に `Metadata` の変化を検出するように設定されています (この例では、検出の `interval` はデフォルト値の `15` の代わりに 2 分ごとにチェックするように設定されていることに注意してください)。必要に応じて変更を適用します。
* Auto Scaling グループは、`Timeout` を 15 分に設定した CreationPolicy [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html) を使用して、その間に少なくとも 2 つの `Count` シグナル (2 つのインスタンスのそれぞれから 1 つ) を受信して、インスタンスのブートストラップが成功しました。このような信号が 15 分以内に受信されない場合、スタックはロールバックされます。
* Auto Scaling グループは、`UpdatePolicy` [属性](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html) と `autoScalingRollingUpdate` [ポリシー](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html#cfn-attributes-updatepolicy-rollingupdate) も使用しています。 スタックを更新し、関連するリソースの更新がトリガーされると、ポリシーは `MaxBatchSize` で指定されたとおりに一度に 1 つのインスタンスを更新し、最低 2 つのインスタンスをサービス状態のままにします (`MinInstanceInService` を参照)。さらに、`PauseTime` と `WaitOnResourceSignals` を組み合わせると、追加または置換されたインスタンスから正常にシグナルを受信するまで、Auto Scaling グループが 15 分間 (`PT15M`) 待つように CloudFormation に指示します。

アプリケーションとそのインフラストラクチャを、`cloudformation-workshop-dev-application` という新しいスタックでデプロイします。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-application \
    --template-body file://application.template \
    --region us-east-1
:::

そして、作成が完了するのを待ってください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name cloudformation-workshop-dev-application \
    --region us-east-1
:::

デプロイの最後には、エイリアスの Route 53 レコードを含む、アプリケーションを作成したスタックが用意されているはずです。次に、このラボで意図したとおりにデプロイされていること検証します。



### デプロイメントの検証

次の方法で二段階認証を行います。

* ロードバランサーの URL に接続し、HTTP レスポンスで得られるコンテンツを検証することが、このラボの例の一部として実装されています。
* エイリアスレコードを使用する URL に HTTP リクエストを発行し、HTTP 応答が前のステップで取得したものと同じであることを確認します。



#### ロードバランサーの URL に接続して検証

CloudFormation コンソールから、`cloudformation-workshop-dev-application` スタックを選択し、`出力`タブを選択します。ブラウザの新しいタブで、`AppUrl` 出力値のリンクを開きます。出力 `Hello world!` が表示されています。



#### DNS レコード値の URL に接続して検証

Cloud9 で `application.template` ファイルを開き、`AWS::Route53::RecordSet` タイプのリソースを探します。このリソースは、プライベートホストゾーンに `A` 型のエイリアスレコードを作成します (`${HostedZoneStackName}-HostedZoneId` のエクスポートを用いて、`HostedZoneId` を参照します)。`Name` エイリアスレコードの値は `my-example-domain.com` という名前のエントリで、この例ではドメインの Zone Apex と同一です。

このラボでは (代わりにパブリックホストゾーンを指すドメインを登録する代わりに) プライベートホストゾーンを作成したので、VPC のコンテキスト内から上記のエイリアスレコードを解決できるはずです。つまり、VPC で EC2 インスタンスを作成した Cloud9 環境は、名前解決を正常に実行できるはずです。Cloud9 のコンソールターミナルから、以下のコマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
curl http://my-example-domain.com
:::

`Hello world!` は、先ほど見たものと同じ出力です。

おめでとうございます！ CloudFormation を使用してサンプルアプリケーションとそのインフラストラクチャのデプロイを正常に実行し、検証することができました。



### チャレンジ

この課題では、再利用とモジュール性に関連する主要な概念を思い出して適用し、それらをデプロイメントのオーケストレーションの観点から拡張します。あなたは、（Cloud9 のワークスペースにある）`application.template` ファイルを `application-blue-green.template` という名前の新しいファイルにコピーし、この新しいファイルを更新して、blue / green のデプロイパターンのコンテキストで 2 つのスタックで使用できるようにします。[Amazon Route 53 DNS ルーティングの更新](https://docs.aws.amazon.com/ja_jp/whitepapers/latest/blue-green-deployments/update-dns-routing-with-amazon-route-53.html)をご参照ください。このチャレンジの要件は次の通りでです。

* 2つのスタックを用意します。作成した既存の `cloudformation-workshop-dev-application` を更新し、`cloudformation-workshop-dev-application-v2` という名前の新しいスタックを作成して、それぞれ `Hello world!` の代わりに `Blue` と `Green` を出力として表示します。両方のスタックをそれぞれ *Blue* と *Green* と呼び、両方のスタックに新しい `application-blue-green.template` ファイルを使用します。
* 各スタックは、前に使用したものと同じ `名前` (ホストゾーン名) を持つ新しいエイリアスレコードを作成する必要があります。ただし、これらのレコードは両方とも [加重セット](https://docs.aws.amazon.com/ja_jp/Route53/latest/DeveloperGuide/resource-record-sets-values-weighted.html#rrsets-values-weighted-weight) である必要があります。これにより、Route 53 は、[特定のリソースの合計に対する重みの比率](https://docs.aws.amazon.com/ja_jp/Route53/latest/DeveloperGuide/routing-policy-weighted.html) に基づいてユーザーが発行したクエリに応答します。最初に、 *Blue* スタックに重み `255` (大きい重み) を割り当て、*Green* スタックに重み `1` (少ない重み) を割り当てます。この方法では、*Blue* は最初にトラフィックの 255 / 256、*Green* はトラフィックの 1 / 256 に割り当てられます。
* 必ず、テンプレート内の _set identifier_ を更新し、同じテンプレートを使用する 2 つのスタックで値が一意となるようにします。

このラボの例で望ましい状態を示す図を以下に示します。

![architecting-templates-blue-green-diagram.png](/static/intermediate/templates/architecting-templates/architecting-templates-blue-green-diagram.png)

`AWS::Route53::RecordSet` リソースタイプの CloudFormation ドキュメント [ページ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html) を参照して、上記の要件を満たすために追加または更新するプロパティを特定してください。

2 つのスタックを作成したら、`my-example-domain.com` エイリアスが最初はほとんどが *Blue* を指していることを `curl` で検証します。次に、両方のスタックで作成したエイリアスレコードのウェイト値を反転させて、もう一度テストすると、ほとんどのトラフィックが *Green* にルーティングされます（つまり、出力が `Green` のサンプルアプリのバージョン 2 をロードします）。



:::expand{header= "ヒントが必要ですか？"}

* サンプルの `PageTextContent` テンプレートパラメータを再利用し、新しい値を追加して、テンプレートを使用する特定のスタックでの `Blue` または `Green` の実行を実証および検証できるようにする方法をご検討ください。
* `SetIdentifier` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#cfn-route53-recordset-setidentifier) をご参照ください。*Blue* スタックを起動するか、*Green* スタックを起動するかに応じて、このプロパティに一意の値を指定します。
* `Weight` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#cfn-route53-recordset-weight) をご参照ください。
* 更新したレコードセットで `Region` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#cfn-route53-recordset-region) を指定する必要はありません。
:::



::::expand{header= "解決策を確認しますか？"}

解決策は、`code/solutions/architecting-templates` ディレクトリにある `application-blue-green.template` ファイルにあります。

代わりに、`application-blue-green.template` ファイルを参照しつつ、以下の手順に従ってあなたのワークスペースを更新してください。

* `AllowedValues` を `PageTextContent` サンプル入力パラメータ (`-Blue`、`-Green`) を、インデントに注意し、2 行に分けて追加します。
* 新しいテンプレートパラメータ `RecordSetWeight` を追加します。`Type` を `Number` に、`Default` の値を `0` に、`MinValue` を `0` に、`MaxValue` を `255` に設定します。 パラメータの目的をユーザに伝えるための `Decription` を追加します。
* セット識別子を、ホストゾーンの両方のレコードで一意となる値に更新します。次の例のように、レコードセットの `SetIdentifier` プロパティを更新します。例: `SetIdentifier: !Sub '${AppNameTagValue} application managed with the ${AWS::StackName} stack.'`
* `AWS::Route53::RecordSet` リソースタイプに `Weight` プロパティを追加して、`RecordsetWeight` テンプレートパラメータを参照します: `Weight: !Ref 'RecordSetWeight'`。
* レコードセットリソースから `Region: !Ref 'AWS::Region'` 行を削除します。
* 既存のスタック `cloudformation-workshop-dev-application` を、新しい application-blue-green.template ファイルで更新します。`Blue` を `PageTextContent` のパラメータ値として、`255` を `RecordSetWeight `に渡します。例:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
    --stack-name cloudformation-workshop-dev-application \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Blue \
        ParameterKey=RecordSetWeight,ParameterValue=255
:::

* `cloudformation-workshop-dev-application-v2` という名前の新しいスタックを作成し、そこに `Green` を `PageTextContent` のパラメータ値として、`1` を `RecordSetWeight `に渡します。例:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-application-v2 \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Green \
        ParameterKey=RecordSetWeight,ParameterValue=1
:::

* 両方の操作が完了したら、`my-example-domain.com` レコードが主に `Blue` を指していることをテストします。

:::code{language=shell showLineNumbers=false showCopyAction=true}
curl http://my-example-domain.com
:::

* 次に、両方のスタックを更新し、`RecordSetWeight` の値を入れ替えます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
    --stack-name cloudformation-workshop-dev-application \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Blue \
        ParameterKey=RecordSetWeight,ParameterValue=1

aws cloudformation update-stack \
    --stack-name cloudformation-workshop-dev-application-v2 \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Green \
        ParameterKey=RecordSetWeight,ParameterValue=255
:::

* スタックの更新が完了したら、`my-example-domain.com` レコードが主に `Green` を指していることをテストします。

:::code{language=shell showLineNumbers=false showCopyAction=true}
curl http://my-example-domain.com
:::

::::



### クリーンアップ

ワークステーションの CloudFormation コンソールに移動します。このラボで作成したスタックを次の順序で削除します。クロススタック参照を使用していくつかのスタックを参照しているため、値をエクスポートするスタックが利用側スタックで使用されている場合は削除できない点に注意してください。

1. `cloudformation-workshop-dev-application-v2` と `cloudformation-workshop-dev-application` は互いに依存していないため、それぞれが削除されるのを待たずに削除可能です。両方のスタックが削除されたら、次のステップに進みます。
2. `cloudformation-workshop-dev-security-groups` と `cloudformation-workshop-dev-hosted-zone` は、それぞれが削除されるのを待たずに削除可能です。次のステップに進みます。
3. `cloudformation-workshop-dev-cloud9` を削除します。このスタックを削除すると、開始した削除アクションによって、名前が `aws-cloud9-aws-cloudformation-workshop-` で始まるスタックも削除されます。両方のスタックが削除されたら、最後のステップに進みます。
4. `cloudformation-workshop-dev-base-network` スタックを削除します。


### まとめ

おめでとうございます！ ライフサイクルと所有権を考慮したテンプレートの設計方法と、再利用性とモジュール性を優先して多数の擬似パラメータと組み込み関数を使用する方法を学び、実践しました。また、値をエクスポートおよびインポートしてスタックを作成する方法や、Blue / Green デプロイパターンを例にしてテンプレートを再利用する方法についても学びました。
