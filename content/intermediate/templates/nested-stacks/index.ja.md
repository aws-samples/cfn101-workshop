---
title: "ネストされたスタック"
weight: 400
---

_ラボ実施時間 : 30分程度_

---

### 概要

CloudFormation テンプレートは、このワークショップを進めることでボリュームが多くなりました。
インフラが拡大するにつれ、それぞれのテンプレートで同じコンポーネントを宣言するパターンが出てくることがあります。

同じコンポーネントを宣言するケースにおいては、共通コンポーネントを分離して、専用のテンプレートを作成することが可能です。
具体的には、[**ネストされたスタック**](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-nested-stacks.html)を用いて、様々なテンプレートを組み合わせ、1 つの統合されたスタックを作成することができます。


例えば、Systems Manager Session Manager によるすべての EC2 インスタンスへのアクセスを有効にしたい場合があります。
同じ IAM ロール設定をコピー & ペーストする代わりに、インスタンスの IAM ロールを含む専用テンプレートを作成できます。
そして、[AWS::CloudFormation::Stack](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html)リソースを使用して、他のテンプレート内からそのテンプレートを参照することができます。


### 取り上げるトピック

このラボでは、以下を作成します。

1. **_root_ スタック** : (第 1 レベルにある親スタックでもあります)。root スタックには、他のすべてのスタックが含まれます。
1. **VPC スタック** : EC2 インスタンスを配置するシンプルな VPC テンプレートが含まれています。
1. **IAM インスタンスロールスタック** : EC2 テンプレートから切り離された IAM インスタンスロールテンプレートが含まれています。
1. **EC2 スタック** : 以前の CloudFormation テンプレートで定義した EC2 インスタンスが含まれます。

> ネストされたスタックの最上位レベルと第 1 レベルの階層

![nested-stack-hierarchy](/static/intermediate/templates/nested-stacks/nested-stack-hierarchy.ja.png)

> インフラストラクチャの概要

![ested-stack-architecture](/static/intermediate/templates/nested-stacks/ns-architecture.png)

### ラボを開始

1. `code/workspace/nested-stacks` ディレクトリに移動します。
1. 以下のトピックを読みながら、コードをコピーします。

#### 1. ネストされたスタックのリソース

テンプレート内の CloudFormation スタックを参照するには、`AWS::CloudFormation::Stack` リソースを使用します。

以下のような形です:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
Resources:
  NestedStackExample:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: 'Path/To/Template'
      Parameters:
        ExampleKey: ExampleValue
:::

`TemplateURL` プロパティは、ネストしたい CloudFormation テンプレートを参照するために使用されます。

`Parameters` プロパティを使用すると、ネストされた CloudFormation テンプレートにパラメータを渡すことができます。

#### 2. S3 バケットを準備

単一のテンプレートの場合は、ローカルマシンからデプロイできますが、ネストされたスタックでは、ネストされたテンプレートを S3 バケットに保存する必要があります。

最初のラボで、S3 バケットを作成する簡単な CloudFormation テンプレートを作成しました。作成したバケット名をメモします。

バケット名の例: `cfn-workshop-s3-s3bucket-2cozhsniu50t`

S3 バケットをお持ちでない場合は、[テンプレートとスタック](/basics/templates/template-and-stack) ラボに戻って、S3 バケットを作成します。

#### 3. ネストされた VPC スタックの作成

VPC テンプレートは既に作成されており、タイトルは `vpc.yaml` です。このテンプレートは、2 つのパブリックサブネット、インターネットゲートウェイ、ルートテーブルを含む VPC スタックを作成することができます。

##### 1. メインテンプレートで VPC パラメータを作成

`vpc.yaml` ファイルを見ると、テンプレートの **Parameters** セクションにいくつかのパラメータがあることがわかります。

これらのパラメータは、ネストされたスタックに渡せるように、メインテンプレートに追加する必要があります。

以下のコードを `main.yaml` テンプレートの **Parameters** セクションにコピーします。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
AvailabilityZones:
  Type: List<AWS::EC2::AvailabilityZone::Name>
  Description: The list of Availability Zones to use for the subnets in the VPC. Select 2 AZs.

VPCName:
  Type: String
  Description: The name of the VPC.
  Default: cfn-workshop-vpc

VPCCidr:
  Type: String
  Description: The CIDR block for the VPC.
  AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
  ConstraintDescription: CIDR block parameter must be in the form x.x.x.x/16-28
  Default: 10.0.0.0/16

PublicSubnet1Cidr:
  Type: String
  Description: The CIDR block for the public subnet located in Availability Zone 1.
  AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
  ConstraintDescription: CIDR block parameter must be in the form x.x.x.x/16-28
  Default: 10.0.0.0/24

PublicSubnet2Cidr:
  Type: String
  Description: The CIDR block for the public subnet located in Availability Zone 2.
  AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
  ConstraintDescription: CIDR block parameter must be in the form x.x.x.x/16-28
  Default: 10.0.1.0/24
:::

##### 2. メインテンプレートに VPC リソースを作成
以下のコードでは、単一のスタンドアロンテンプレートを使用する場合と同じように、リソースにパラメータ値を渡すことができます。
メインテンプレートのパラメータ名が VPC テンプレートのパラメータ名と一致することを確認してください。

このコードをメインテンプレート (`main.yaml`) の **Resources** セクションに追加します

:::code{language=yaml showLineNumbers=true showCopyAction=true}
VpcStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/vpc.yaml
    TimeoutInMinutes: 20
    Parameters:
      AvailabilityZones:
        Fn::Join:
          - ','
          - !Ref AvailabilityZones
      VPCCidr: !Ref VPCCidr
      VPCName: !Ref VPCName
      PublicSubnet1Cidr: !Ref PublicSubnet1Cidr
      PublicSubnet2Cidr: !Ref PublicSubnet2Cidr
:::

##### 3. VPC スタックを S3 にアップロード

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `code/workspace/nested-stacks` ディレクトリに移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. 以下のコマンドを実行して `vpc.yaml` を S3 バケットにコピーします。`bucket-name` を前のステップのバケット名に置き換えてください。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws s3 cp vpc.yaml s3://{bucket-name}
  :::
::::
::::tab{id="local" label="ローカル開発"}
1. [S3 コンソール](https://console.aws.amazon.com/s3/home?region=eu-west-1) に移動し、バケットを選択します。
1. **アップロード** ボタンをクリックし、 **ファイルを追加** をクリックします。
1. `vpc.yaml` ファイルを選択します。
1. **アップロード** ボタンをクリックし、ファイルをアップロードします。
::::
:::::

##### 4. ネストされた VPC スタックをデプロイ

:::alert{type="info"}
**YAML** はインデントに敏感なマークダウン言語であることに注意してください。`cfn-lint` または CloudFormation コンソールが`Template format error: [/Resources/VpcStack] resource definition is malformed` というエラーを報告した場合、 **Parameters** と **Resources** セクションが正しくフォーマットされていることを再確認してください。インストール方法や詳細なガイダンスについては、以前の [静的解析とテスト](/basics/templates/linting-and-testing)のラボを参照してください。
:::

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `code/workspace/nested-stacks` ディレクトリに移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. AWS EC2 Api を使用して VPC からアベイラビリティーゾーンのリストを取得し、出力から任意の 2 つの AZ をコピーして次のステップで使用します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws ec2 describe-availability-zones --output json --query "AvailabilityZones[*].ZoneName"
  :::
1. AWS CLI を使用してスタックを作成します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。`ParameterValue` の **bucketName** を [S3 バケットの準備](#2.-s3)セクションでメモした値に置き換えてください。`ParameterValue` の **AZ1** と **AZ2** を前のステップでコピーした値に置き換えてください。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation create-stack --stack-name cfn-workshop-nested-stacks \
  --template-body file://main.yaml \
  --parameters ParameterKey="S3BucketName",ParameterValue="bucketName" ParameterKey="AvailabilityZones",ParameterValue=AZ1\\,AZ2 \
  --capabilities CAPABILITY_NAMED_IAM
  :::
1. `create-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
  :::code{language=json showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-nested-stacks/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** コンソールを新しいタブで開き、スタックのステータスが **CREATE_COMPLETE** になっているかどうかを確認します。最新のスタックステータスを確認するには、定期的に更新を選択する必要があります。
::::
::::tab{id="local" label="ローカル開発"}
1. コンソールで CloudFormation に移動し、 **新しいリソースを使用 (標準)** をクリックします。
1. **テンプレートの準備** セクションで、 **テンプレート準備完了** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
1. `main.yaml` ファイルを選択します。
1. **スタック名** を入力します。例えば、`cfn-workshop-nested-stack` と入力します。
1. **AvaliabilityZone** パラメータには、2 つの AZ を選択します。
1. **S3BucketName** には、[S3 バケットを準備](#2.-s3) セクションに書き留めたバケット名を入力します。
1. 残りのパラメータはデフォルトのままとします。
1. **スタックオプションの設定** はデフォルトのままにして、 **次へ** をクリックします。
1. **レビュー <stack_name>** ページで一番下までスクロールし、両方の **IAM Capabilities** チェックボックスにチェックを入れます。
    ![iam-capabilities.png](/static/intermediate/templates/nested-stacks/iam-capabilities.ja.png)
1. **スタックの作成** をクリックします。CloudFormation コンソールで作成中のネストスタックの進行状況を確認できます。
1. 数分後にスタックが作成されます。`CREATE_COMPLETE` のステータスが表示されるまで、更新ボタンを数回クリックします。
::::
:::::

#### 4. ネストされた IAM スタックの作成

##### 1. IAM ロールテンプレートの準備

**IAM ロール** テンプレートが既に作成されています。タイトルは `iam.yaml` です。
このテンプレートは、[Session Manager](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager.html) が EC2 インスタンスにアクセスすることを許可する `AmazonSSMManagedInstanceCore` ポリシーを使用して IAM ロールを作成します。


1. `iam.yaml` ファイルを開きます。
1. 以下のコードをテンプレートの **Resources** セクションにコピーします。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
SSMIAMRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Statement:
        - Effect: Allow
          Principal:
            Service:
              - ec2.amazonaws.com
          Action:
            - sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

WebServerInstanceProfile:
  Type: AWS::IAM::InstanceProfile
  Properties:
    Path: /
    Roles:
      - !Ref SSMIAMRole
:::

##### 2. メインテンプレートに IAM リソースを作成
以下のコードを `main.yaml` テンプレートの **Resources** セクションにコピーします。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
IamStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/iam.yaml
    TimeoutInMinutes: 10
:::


##### 3. IAM スタックを S3 にアップロード

[VPC スタック](#3.-vpc-s3) と同様に、IAM テンプレートを S3 にアップロードします。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `code/workspace/nested-stacks` ディレクトリに移動します。
  :::code{language=shell showLineNumbers=true showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. 以下のコマンドを実行して `iam.yaml` を S3 バケットにコピーします。`bucket-name` を前のステップのバケット名に置き換えてください。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws s3 cp iam.yaml s3://{bucket-name}
  :::
::::
::::tab{id="local" label="ローカル開発"}
1. コンソールで S3 バケットに移動して選択します。
1. **アップロード** ボタン -> **ファイルを追加** をクリックします。
1. `iam.yaml` ファイルを選択します。
1. **アップロード** ボタンをクリックしてファイルをアップロードします。
::::
:::::

##### 4. ネストされた IAM スタックをデプロイ

以前に作成したネストスタックを新しいテンプレートで更新します。
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `code/workspace/nested-stacks` ディレクトリに移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. AWS EC2 Api を使用して VPC からアベイラビリティーゾーンのリストを取得し、出力から任意の 2 つの AZ をコピーして次のステップで使用します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws ec2 describe-availability-zones --output json --query "AvailabilityZones[*].ZoneName"
  :::
1. AWS CLI を使用してスタックを更新します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。`ParameterValue` の **bucketName** を [S3 バケットの準備](#2.-s3)セクションでメモした値に置き換えてください。`ParameterValue` の **AZ1** と **AZ2** を前のステップでコピーした値に置き換えてください。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-nested-stacks \
  --template-body file://main.yaml \
  --parameters ParameterKey="S3BucketName",ParameterValue="bucketName" ParameterKey="AvailabilityZones",ParameterValue=AZ1\\,AZ2 \
  --capabilities CAPABILITY_NAMED_IAM
  :::
1. `update-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-nested-stacks/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** コンソールを新しいタブで開き、スタックのステータスが **UPDATE_COMPLETE** になっているかどうかを確認します。最新のスタックステータスを確認するには、定期的に更新を選択する必要があります。
::::
::::tab{id="local" label="ローカル開発"}
1. AWS コンソールの Cloudformation サービスに移動します。
1. **root** スタック ( **ネストされた** タグが関連付けられていないスタック) を選択します。
1. 右上の **更新** をクリックします。
1. **テンプレートの準備** セクションで、 **既存のテンプレートを置き換える** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
1. **ファイルを選択** ボタンをクリックし、ワークショップディレクトリに移動します。
1. `main.yaml` テンプレートファイルを選択し、 **次へ** をクリックします。
1. ウィザードに従い、IAM Capabilities を確認し、 **送信** をクリックします。
::::
:::::

#### 5. ネストされた EC2 スタックの作成

##### 1. メインテンプレートで EC2 パラメータを作成する

VPC テンプレートと同様に、`ec2.yaml` テンプレートの **Parameters** セクションを見ると、次の 3 つのパラメータがあります。

* `SubnetId` - このプロパティは VPC スタックが作成されると VPC スタックから渡されます。
* `EnvironmentType` - このプロパティにはデフォルト値があり、頻繁に変更される可能性があるので、Parameters に追加します。
* `AmiId` - このプロパティにはデフォルト値があるため、メインテンプレートから除外してもかまいません。

`main.yaml` テンプレートの **Paramaters** セクションに以下のコードを追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
EnvironmentType:
  Description: 'Specify the Environment type of the stack.'
  Type: String
  Default: Test
  AllowedValues:
    - Dev
    - Test
    - Prod
  ConstraintDescription: 'Specify either Dev, Test or Prod.'
:::

##### 2. メインテンプレートに EC2 リソースを作成

以下のコードを `main.yaml` テンプレートの **Resources** セクションにコピーします。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
:::

##### 3. EnvironmentType を EC2 スタックに追加します

テンプレートに `EnvironmentType` パラメータを追加したので、これを `EC2Stack` リソースで参照する必要があります。

`main.yaml` テンプレートの EC2 スタック [6-7] 行目に、`Parameters` セクションと　`EnvironmentType` を追加します。
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=6-7}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
    Parameters:
      EnvironmentType: !Ref EnvironmentType
:::

#### 6. 別のネストされたスタックから変数を渡す

CloudFormation のネストスタックを更新する前に、やるべきことが他にもいくつかあります。

+ EC2 セキュリティグループを作成する VPC を指定する必要があります。VPC パラメータを指定しないと、セキュリティグループは **デフォルト VPC** に作成されます。

+ EC2 インスタンスを作成するサブネットを指定する必要があります。

##### 1. セキュリティグループリソースを準備

1. `ec2.yaml` ファイルを開き、テンプレートの **Parameters** セクションに `VpcId` と `SubnetId` の 2 つのパラメータを作成します。

  :::code{language=yaml showLineNumbers=true showCopyAction=true}
  VpcId:
    Type: AWS::EC2::VPC::Id
    Description: 'The VPC ID'

  SubnetId:
    Type: AWS::EC2::Subnet::Id
    Description: 'The Subnet ID'
  :::

1. 次に、`WebServerSecurityGroup` リソースを探します。
1. `WebServerSecurityGroup` リソース [18] 行目に `VpcId` プロパティを追加し、 `VpcId` パラメータを参照します。セキュリティグループリソースは以下のコードのようになっているはずです。

  :::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=18}
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
      VpcId: !Ref VpcId
  :::

##### 2. VPC テンプレートの準備

あるスタックから別のスタックに変数を渡すには、その変数を渡すスタックの値を含む出力を作成する必要があります。

組み込み関数 `!GetAtt` を利用すると、CloudFormation はそのスタックの値にアクセスでき、それをパラメータとして渡します。

以下のコードを `vpc.yaml` テンプレートに追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Outputs:
  VpcId:
    Value: !Ref VPC

  PublicSubnet1:
    Value: !Ref VPCPublicSubnet1

  PublicSubnet2:
    Value: !Ref VPCPublicSubnet2
:::

##### 3. VpcId と SubnetId を **EC2Stack** スタックに追加する

これで、VPC スタックから値を取得して EC2 スタックに渡すことができます。

`VpcId` と `SubnetId` パラメータを `main.yaml` テンプレートの EC2 スタックに追加します。
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=8-9}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
    Parameters:
      EnvironmentType: !Ref EnvironmentType
      VpcId: !GetAtt VpcStack.Outputs.VpcId
      SubnetId: !GetAtt VpcStack.Outputs.PublicSubnet1
:::

##### 4. IAM テンプレートの準備

`iam.yaml` を開いて、以下のコードを追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Outputs:
  WebServerInstanceProfile:
    Value: !Ref WebServerInstanceProfile
:::

##### 5. EC2 テンプレートの準備

1. `ec2.yaml` を開きます。
1. テンプレートの **Parameters** セクションに `WebServerInstanceProfile` パラメータを作成します。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
WebServerInstanceProfile:
  Type: String
  Description: 'Instance profile resource ID'
:::

##### 6. WebServerInstanceProfile を **EC2Stack** スタックに追加

`webServerInstanceProfile` パラメータを `main.yaml` テンプレートの EC2 スタック [10] 行目に追加します。
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=10}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
    Parameters:
      EnvironmentType: !Ref EnvironmentType
      VpcId: !GetAtt VpcStack.Outputs.VpcId
      SubnetId: !GetAtt VpcStack.Outputs.PublicSubnet1
      WebServerInstanceProfile: !GetAtt IamStack.Outputs.WebServerInstanceProfile
:::

##### 7. メインテンプレートの `WebsiteURL` を出力する

`WebsiteURL` を `main.yaml` テンプレートの `Outputs` セクションに追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Outputs:
  WebsiteURL:
    Value: !GetAtt EC2Stack.Outputs.WebsiteURL
:::

##### 8. EC2 スタックを S3 にアップロード
更新されたネストスタックをデプロイする前に、親テンプレート `main.yaml` が参照する S3 バケットのテンプレートを更新する必要があります。

前のステップの [VPC スタックのアップロード](#3.-vpc-s3) と同様に、`vpc.yaml`、`ec2.yaml`、 `iam.yaml` テンプレートを S3 バケットにアップロードします。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `code/workspace/nested-stacks` ディレクトリに移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. 以下のコマンドを実行して、`iam.yaml`、`vpc.yaml`、`ec2.yaml` を S3 バケットにコピーします。`bucket-name` を前のステップのバケット名に置き換えてください。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws s3 cp iam.yaml s3://{bucket-name}
aws s3 cp vpc.yaml s3://{bucket-name}
aws s3 cp ec2.yaml s3://{bucket-name}
  :::
::::
::::tab{id="local" label="ローカル開発"}
1. コンソールで S3 バケットに移動して選択します。
1. **アップロード** ボタン -> **ファイルの追加** をクリックします。
1. `vpc.yaml`、`iam.yaml`、`ec2.yaml` ファイルを選択します。
1. **アップロード** ボタンをクリックしてファイルをアップロードします。
::::
:::::

##### 9. ネストされた EC2 スタックをデプロイ

以前に作成したネストスタックを新しいテンプレートで更新します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 ターミナル** で `code/workspace/nested-stacks` ディレクトリに移動します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. AWS EC2 Api を使用して VPC からアベイラビリティーゾーンのリストを取得し、出力から任意の 2 つの AZ をコピーして次のステップで使用します。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws ec2 describe-availability-zones --output json --query "AvailabilityZones[*].ZoneName"
  :::
1. AWS CLI を使用してスタックを更新します。必須パラメータ `--stack-name` と `--template-body` はあらかじめ入力されています。`ParameterValue` の **bucketName** を [S3 バケットの準備](#2.-s3)セクションでメモした値に置き換えてください。`ParameterValue` の **AZ1** と **AZ2** を前のステップでコピーした値に置き換えてください。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-nested-stacks \
  --template-body file://main.yaml \
  --parameters ParameterKey="S3BucketName",ParameterValue="bucketName" ParameterKey="AvailabilityZones",ParameterValue=AZ1\\,AZ2 \
  --capabilities CAPABILITY_NAMED_IAM
  :::
1. `update-stack` コマンドが成功すると、CloudFormation は `StackId` を返却します。
  :::code{language=json showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-nested-stacks/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** コンソールを新しいタブで開き、スタックのステータスが **UPDATE_COMPLETE** になっているかどうかを確認します。最新のスタックステータスを確認するには、定期的に更新を選択する必要があります。
::::
::::tab{id="local" label="ローカル開発"}
1. AWS コンソールの Cloudformation サービスに移動します。
1. **root** スタック ( **ネストされた** タグが関連付けられていないスタック) を選択します。
1. 右上の **更新** をクリックします。
1. **テンプレートの準備** セクションで、 **既存のテンプレートを置き換える** を選択します。
1. **テンプレートの指定** セクションで、 **テンプレートファイルのアップロード** を選択します。
1. **ファイルを選択** ボタンをクリックし、ワークショップディレクトリに移動します。
1. `main.yaml` テンプレートファイルを選択し、 **次へ** をクリックします。
1. ウィザードに従い、IAM Capabilities を確認し、 **送信** をクリックします。
::::
:::::

#### 7.デプロイメントのテスト

##### 1. アプリケーションが正常にデプロイされたことを確認

プライベートモードで新しいブラウザウィンドウを開き、`WebsiteURL` を入力します。

`WebsiteURL` は、CloudFormation コンソールのメインスタックの **出力** タブから取得できます。

![website-url-output.png](/static/intermediate/templates/nested-stacks/website-url-output.ja.png)

ブラウザウィンドウに、以下の図のようなインスタンスメタデータが表示されます。

![ami-id](/static/intermediate/templates/nested-stacks/ami-id-1.ja.png)

##### 2. SSM セッションマネージャーを使用してインスタンスにログイン

**[セッションマネージャ](https://console.aws.amazon.com/systems-manager)** 経由でインスタンスにログインできることを確認します。インスタンスがデプロイされているのと同じリージョン、たとえば`米国東部(バージニア北部) us-east-1` を選択します。
### クリーンアップ

作成したリソースをクリーンアップするには、次の手順に従います。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** で、このラボで作成した **root** スタックを選択します。具体的には、`cfn-workshop-nested-stacks` を選択します。
1. **root** スタックは、すべての **子** スタックの削除を自動的に処理します。
1. 右上の **削除** をクリックします。
1. ポップアップウィンドウで、 **削除** をクリックします。
1. **DELETE_COMPLETE** のステータスが表示されるまで、 **更新** ボタンを数回クリックします。

---
### まとめ

ネストされたスタックを使用すると、CloudFormation テンプレートを作成できます。これにより、大きなテンプレートを、再利用可能な小さなテンプレートに分解することができます。
また、1 つのテンプレートのリソース制限を回避するのにも役立ちます。ネストされたスタックのコンポーネントは、他の CloudFormation リソースと同様にテンプレートに定義することができます。
