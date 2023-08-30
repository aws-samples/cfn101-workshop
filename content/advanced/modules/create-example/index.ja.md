---
title: "サンプルモジュールの作成"
weight: 320
---

### 概要

このラボでは、AWS アカウントの、特定の AWS リージョンの AWS CloudFormation レジストリに、サンプルの CloudFormation モジュールをプライベート拡張で登録する手順を実施します。

この例では、デフォルト設定の関連リソースを含む [Amazon Virtual Private Cloud](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/what-is-amazon-vpc.html) (Amazon VPC) 全体をデプロイするモジュールを作成します。この例を選定した理由は、VPC のように複雑な設定を中央集権的役割のチームがベストプラクティスな方法で定義し、他のチームが簡単に利用できるようにする方法を示すためです。

### 対象トピック

このラボを修了すると、次のことができるようになります。

* モジュールを開発する際に活用すべき重要な概念を理解します。
* [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) を使用して新しいプロジェクトを作成し、そのモジュールをプライベート拡張として、AWS アカウントの、特定の AWS リージョンの CloudFormation レジストリに送信します。
* CloudFormation テンプレートでモジュールを使用する方法を理解します。

### ラボを開始

#### サンプルモジュールに関するチュートリアル

さあ、始めましょう！新しいディレクトリを作成し、そのディレクトリ内から以下のコマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir module
cd module
cfn init
:::

いくつかの質問に対し、回答を入力します。

    Initializing new project
    Do you want to develop a new resource(r) or a module(m) or a hook(h)?.
    >> m
    What's the name of your module type?
    (<Organization>::<Service>::<Name>::MODULE)
    >> CFNWORKSHOP::EC2::VPC::MODULE
    Directory  /home/user/cfn101-workshop/module/fragments  Created
    Initialized a new project in /home/user/cfn101-workshop/module

コマンドを実行することで、ディレクトリ内に何が作成されたのかを見てみましょう。

* `fragments/`: 自動生成された `sample.json` CloudFormation テンプレートファイル。
* `.rpdk-config`: 上記の init コマンドを実行したときに指定した詳細を格納する設定ファイル。
* `rpdk.log`: cfn cli によって実行されたアクションのログファイル。

まずは、不要なものを削除しましょう。このワークショップでは YAML 形式を使用するので、`sample.json` ファイルを削除します。このファイルは必要ありません。

:::code{language=shell showLineNumbers=false showCopyAction=true}
rm fragments/sample.json
:::

CloudFormation モジュールは、このワークショップで既に作成しているものと同様に、標準の CloudFormation テンプレートを使用して作成されます。ただし、モジュールで使用できるテンプレートファイルは 1 つだけで、ネストされたスタックはサポートされていません。詳細については、[モジュール構造](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/modules-structure.html) ドキュメントの _Creating the module template fragment_ と _Considerations when authoring the template fragment_ をご参照ください。

次の図は、サンプルモジュールに含める VPC リソースを示しています。

![vpc-diagram](/static/advanced/modules/vpc.png)

`fragments` フォルダー内にモジュール用の新しい YAML ファイルを作成します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
touch fragments/module.yaml
:::

テキストエディターでこのファイルを開き、以下の CloudFormation YAML コードを貼り付けます。

<!-- vale off -->
:::code{language=yaml showLineNumbers=false showCopyAction=true}
AWSTemplateFormatVersion: 2010-09-09

Description: A full VPC Stack

Parameters:

  VpcCidr:
    Type: String

Resources:

  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref Vpc
      InternetGatewayId: !Ref InternetGateway

  EIP1:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  EIP2:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  NATGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public1Subnet
      AllocationId: !GetAtt EIP1.AllocationId

  NATGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public2Subnet
      AllocationId: !GetAtt EIP2.AllocationId

  Public1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [0, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true

  Public2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [1, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true

  Private1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [2, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false

  Private2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [3, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false

  Public1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Public2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Private1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Private2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Public1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Public1RouteTable
      SubnetId: !Ref Public1Subnet

  Public2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Public2RouteTable
      SubnetId: !Ref Public2Subnet

  Private1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Private1RouteTable
      SubnetId: !Ref Private1Subnet

  Private2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Private2RouteTable
      SubnetId: !Ref Private2Subnet

  Public1DefaultRoute:
    Type: AWS::EC2::Route
    DependsOn:
      - VPCGatewayAttachment
    Properties:
      RouteTableId: !Ref Public1RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  Public2DefaultRoute:
    Type: AWS::EC2::Route
    DependsOn:
      - VPCGatewayAttachment
    Properties:
      RouteTableId: !Ref Public2RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  Private1DefaultRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref Private1RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway1

  Private2DefaultRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref Private2RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway2
:::
<!-- vale on -->

この CloudFormation テンプレートには、CloudFormation を使用して VPC をデプロイしたことのある人ならご存知の 23 個のリソースがあります。コンポーネントが非常に多いため、デプロイするすべての VPC が標準的な方法で行われ、間違いや相違がないことを確認することが難しい場合があります。

これは CloudFormation モジュールの優れたユースケースです。リソースを 1 つのモジュールにまとめることができ、多くのチームが何度でも使用できるため、複雑さが解消され、何度も必要になった場合でもエラーや相違が生じる可能性がなくなります。

テンプレートには `VpcCidr` というパラメーターがあります。これはモジュールを使用する際に使用できるようになるため、ユーザーは標準デプロイを使用しながらも、ユースケースに合わせてカスタマイズすることができます。

`YAML` ファイルが完成したので、モジュールとして CloudFormation レジストリに送信する準備ができました。以下のコマンドを実行し、モジュールをデフォルトリージョンに登録します。リージョンを指定したい場合は、`--region` オプションをコマンドに追加します (例: `--region us-east-2`)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn submit
:::

次のような出力が表示されます。

```
Module fragment is valid.
Successfully submitted type. Waiting for registration with token '{token}' to complete.
Registration complete.
{'ProgressStatus': 'COMPLETE', 'Description': 'Deployment is currently in DEPLOY_STAGE of status COMPLETED', ...
...
```

これで [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) にアクセスすると、レジストリのページの `アクティブ化済みの拡張機能` セクションに新しいモジュールが表示されるはずです。

![activated-extensions](/static/advanced/modules/ActivatedExtensions.ja.png)
