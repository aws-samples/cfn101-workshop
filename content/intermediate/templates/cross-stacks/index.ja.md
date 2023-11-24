---
title: "クロススタック参照"
weight: 500
---

_ラボ実施時間 : 25分程度_

---

### 概要
前のラボでは、`Outputs` セクションと `Fn::GetAtt` 関数を使って子スタックから親スタックへ値を渡す方法について学びました。そして、再利用可能なテンプレートを作成することができるようになりました。例えば、ネストされたスタックを利用すると、VPC と IAM ロール専用のテンプレートを用意することができます。
しかし、 **スタック** を再利用したい場合はどうでしょうか？

例えば、多数のテンプレートを使用して多数のワークロードをデプロイする計画があったとします。すべての EC2 インスタンスが Systems Manager Session Manager によるすべての EC2 インスタンスへのアクセスを有効にする必要があります。
同様に、1 つのスタックで VPC をデプロイし、それを将来、複数のスタックやワークロードで使用したい場合があります。
このような一対多の関係は、ネストされたスタックのシナリオでは実現できません。
ここでクロススタック参照の出番です。


私たちは [Export](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) を使用し、同じ AWS アカウントと同じリージョンの任意の CloudFormation スタックに [Import](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) できるグローバル変数を作成します。

### 取り上げるトピック
このラボでは、以下を作成します。

1. **VPC スタック** : 前のラボで使用したものと同じシンプルな VPC テンプレートが含まれていますが、出力に Export が追加されています。
1. **IAM インスタンスロールスタック** : 前のラボで使用したのと同じ IAM インスタンスロールが含まれていますが、出力に Export が追加されています。
1. **EC2 スタック** : 前のラボで定義した EC2 インスタンスが含まれていますが、ここでは Fn::ImportValue 関数を使用します。

> クロススタック参照の関係を示す図

![cross-stack-hierarchy.png](/static/intermediate/templates/cross-stacks/cross-stack-hierarchy.ja.png)

> 導入されるインフラストラクチャの概要

![ls-architecture.png](/static/intermediate/templates/cross-stacks/ls-architecture.png)

### ラボを開始

作業ファイルは `code/workspace/cross-stacks` にあります。このラボの残りの部分では、テンプレートにコードを追加する必要があります。なお、解決策は `code/solutions/cross-stacks` フォルダにありますので、こちらを参照することも可能です。

#### VPC スタックの作成
VPC テンプレートは既に作成されており、タイトルは `vpc.yaml` です。このテンプレートは、2 つのパブリックサブネット、1 つのインターネットゲートウェイ、および、ルートテーブルを含む VPC スタックを作成することができます。

##### 1. VPC テンプレートの準備

::alert[このラボで参照されているファイルはすべて `code/workspace/cross-stacks` 内にあります。]{type="info"}

`vpc.yaml` ファイルを見ると、テンプレートの **Outputs** セクションにいくつかの出力があることがわかります。次に、Export を追加して、他の CloudFormation スタックから使用できるようにします。

以下の [4-5、9-10、14-15] 行目をテンプレートファイルに追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=4-5,9-10,14-15}
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: cfn-workshop-VpcId

  PublicSubnet1:
    Value: !Ref VPCPublicSubnet1
    Export:
      Name: cfn-workshop-PublicSubnet1

  PublicSubnet2:
    Value: !Ref VPCPublicSubnet2
    Export:
      Name: cfn-workshop-PublicSubnet2
:::

##### 2. VPC スタックのデプロイ

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `cfn101-workshop/code/workspace/cross-stacks` ディレクトリに移動します。
1. **スタックを作成** は、次の AWS CLI コマンドを使用して行います。このテンプレートでは、 `AvailabilityZones` パラメータの値を指定する必要があります。たとえば、 `us-east-1a` と `us-east-1b` は以下で使用されます。利用しているリージョンの 2 つのアベイラビリティーゾーンを選択してください。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-cross-stacks-vpc \
--template-body file://vpc.yaml \
--parameters ParameterKey=AvailabilityZones,ParameterValue=us-east-1a\\,us-east-1b
:::
1. 次の AWS CLI コマンドを実行して、スタックの作成が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-cross-stacks-vpc
:::
::::
::::tab{id="local" label="ローカル開発"}
1. コンソールで CloudFormation に移動し、 **新しいリソースを使用 (標準)** をクリックします。
1. **テンプレートの準備** セクションで、 **テンプレート準備完了** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
1. `vpc.yaml` ファイルを選択します。
1. **スタック名** を入力します。例えば、`cfn-workshop-cross-stacks-vpc` と入力します。
1. **AvaliabilityZone** パラメータには、 **2 つの AZ** を選択します。
1. 残りのパラメータは **デフォルト** のままとします。
1. すべてデフォルトのままウィザード内を移動します。
1. レビューページで一番下までスクロールし、 **送信** をクリックします。
::::
:::::
#### IAM スタックの作成

##### 1. IAM ロールテンプレートの準備

1. `iam.yaml` ファイルを開きます。
1. 以下の [4 ～ 5] 行目をテンプレートの **Outputs** セクションにコピーします。
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=4-5}
    Outputs:
      WebServerInstanceProfile:
        Value: !Ref WebServerInstanceProfile
        Export:
          Name: cfn-workshop-WebServerInstanceProfile
:::

##### 2. IAM スタックのデプロイ
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを使用して、 **スタックを作成** してみましょう。このテンプレートでは、IAM リソースを作成するための `CAPABILITY_IAM` 機能を指定する必要があります。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-cross-stacks-iam \
--template-body file://iam.yaml \
--capabilities CAPABILITY_IAM
:::
1. 次の AWS CLI コマンドを実行して、スタックの作成が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-cross-stacks-iam
:::
::::
::::tab{id="local" label="ローカル開発"}
1. コンソールで CloudFormation に移動し、 **新しいリソースを使用 (標準)** をクリックします。
1. **テンプレートの準備** セクションで、 **テンプレート準備完了** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
1. `iam.yaml` ファイルを選択します。
1. **スタック名** を入力します。例えば、`cfn-workshop-cross-stacks-iam` と入力します。
1. **次へ** をクリックします。
1. すべてデフォルトのままウィザード内を移動します。
1. **Acknowledge IAM capabilities** をクリックし、 **送信** をクリックします。
::::
:::::

#### EC2 クロススタックの作成

##### 1. EC2 テンプレートの準備
**クロススタック** のコンセプトは、 **Paramaters** を使用する代わりに、組み込み関数を使用して、以前にエクスポートされた値をインポートすることです。
従って、`ec2.yaml` に最初に加えるべき変更は、今後使用されなくなる `SubnetId`、`VpcID`、`WebServerInstanceProfile` のパラメータを削除することです。


##### 2. Parameters セクションの更新

次の例のような形で、 **Parameters** セクションを更新します。
つまり、 **Parameters** セクションから、`VpcId`、`SubnetId`、`WebServerInstanceProfile` の項目を削除します。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Parameters:
  EnvironmentType:
    Description: 'Specify the Environment type of the stack.'
    Type: String
    Default: Test
    AllowedValues:
      - Dev
      - Test
      - Prod
    ConstraintDescription: 'Specify either Dev, Test or Prod.'

  AmiID:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Description: 'The ID of the AMI.'
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
:::

##### 3. WebServerInstance リソースの更新

次に、テンプレートの `Ref` を更新して、以前に作成した VPC と IAM スタックからエクスポートされた値をインポートする必要があります。
このインポートは [Fn::ImportValue](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) 組み込み関数を使用して実行します。

`ec2.yaml` テンプレートのリソースセクションにある WebServerInstance リソースを更新します。

:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=5-8}
WebServerInstance:
  Type: AWS::EC2::Instance
  {...}
  Properties:
    SubnetId: !ImportValue cfn-workshop-PublicSubnet1
    IamInstanceProfile: !ImportValue cfn-workshop-WebServerInstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
  {...}
:::

##### 4. セキュリティグループの更新
最後に、セキュリティグループリソースを更新します。`ec2.yaml` テンプレートの **Resources** セクション `WebServerSecurityGroup` リソース [19] 行目を更新します。

:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=19}
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Enable HTTP and HTTPS access
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
    SecurityGroupEgress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        CidrIp: 0.0.0.0/0
    VpcId: !ImportValue cfn-workshop-VpcId
:::

##### 5. EC2 スタックのデプロイ

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. 次の AWS CLI コマンドを使用して、 **スタックを作成** してみましょう。このテンプレートでは、IAM リソースを作成するための `CAPABILITY_IAM` 機能を指定する必要があります。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-cross-stacks-ec2 \
--template-body file://ec2.yaml
:::
1. 次の AWS CLI コマンドを実行して、スタックの作成が完了するまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-cross-stacks-ec2
:::
::::
::::tab{id="local" label="ローカル開発"}
1. コンソールで CloudFormation に移動し、 **新しいリソースを使用 (標準)** をクリックします。
1. **テンプレートの準備** セクションで、 **テンプレート準備完了** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
1. `ec2.yaml` ファイルを選択します。
1. **スタック名** を入力します。例えば、`cfn-workshop-cross-stacks-ec2`と入力します。
1. 残りのパラメータは **デフォルト** のままとします。
1. すべてデフォルトのままウィザード内を移動します。
1. **レビュー** ページで一番下までスクロールし、 **送信** をクリックします。
::::
:::::

#### 7. デプロイメントのテスト

##### 1.アプリケーションが正常にデプロイされたことを確認

プライベートモードで新しいブラウザウィンドウを開き、`websiteURL` を入力します (WebsiteURL は CloudFormation コンソールの EC2 スタックの **出力** タブから取得できます)。
下の図のような、いくつかのインスタンスメタデータが表示されます。

![ami-id](/static/intermediate/templates/cross-stacks/ami-id-1.ja.png)

##### 2.SSM Session Manager を使用してインスタンスにログイン

Session Manager を使用してインスタンスにログインできることを確認します。

やり方がわからない場合は、[Session Manager](/basics/operations/session-manager#challenge) ラボをご参照ください。

### クリーンアップ

::alert[スタックが出力値をインポートした後は、出力値をエクスポートしているスタックを削除したり、エクスポートされた出力値を変更したりすることはできません。エクスポートするスタックを削除したり、出力値を変更したりする前に、すべてのインポートを削除する必要があります。]{type="info"}

例えば、 **EC2 スタック** を削除する前に **VPC スタック** を削除することはできません。次のエラーメッセージが表示されます。

![delete-export-before-import.png](/static/intermediate/templates/cross-stacks/delete-export-before-import.ja.png)
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **スタックを削除** するために次の AWS CLI コマンドを実行してください
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-cross-stacks-ec2
:::
1. 次の AWS CLI コマンドを使用して、スタックが削除されるまで待ちます。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--stack-name cfn-workshop-cross-stacks-ec2
:::
1. `cfn-workshop-cross-stacks-iam` と `cfn-workshop-cross-stacks-vpc` スタックについて、上記のステップ (1-2) を繰り返します。
::::
::::tab{id="local" label="ローカル開発"}
1. [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation) で、 **EC2 スタック** を選択します (例: `cfn-workshop-cross-stacks-ec2`)。
1. 右上の **削除** をクリックします。
1. ポップアップウィンドウで、 **スタックの削除** をクリックします。
1. **DELETE_COMPLETE** のステータスが表示されるまで、 **更新** ボタンを数回クリックします。
1. 依存関係がなくなったため、 **IAM** と **VPC** スタックが削除できます。
::::
:::::

---
### まとめ
**クロススタック参照** では、複数のスタックで繰り返し使用できるリソースを作成できます。利用する全てのスタックで、 **Export** で指定した名前を知る必要があります。この機能を利用することで、役割と責任を分けることができます。例えば、ネットワークチームは、承認された VPC デザインをテンプレートとして作成して提供できます。必要に応じて、VPC スタックの Export を参照すれば良いです。同様に、セキュリティチームは IAM ロールや EC2 セキュリティグループについても同じ操作を行うことができます。
