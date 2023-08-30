---
title: "サンプルモジュールの利用"
weight: 330
---

#### サンプルモジュールの使用

AWS アカウントの、特定の AWS リージョンのプライベートレジストリに、新しい CloudFormation モジュールを作成して登録しました。つまり、モジュールを CloudFormation テンプレートで他の AWS リソースと同じように使用できるようになりました。

どのように利用できるのか見てみましょう。

新しい YAML ファイルを作成します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
touch use-module.yaml
:::

テキストエディターでこのファイルを開き、以下の CloudFormatoin YAML コードを貼り付けます。

<!-- vale off -->
:::code{language=yaml showLineNumbers=false showCopyAction=true}
AWSTemplateFormatVersion: 2010-09-09

Resources:

  Vpc:
    Type: CFNWORKSHOP::EC2::VPC::MODULE
    Properties:
      VpcCidr: 10.1.0.0/16
:::
<!-- vale on -->

この短いコードで終了です。モジュールの便利さについてご理解いただけると思います。

以下のコマンドを実行して、テンプレートから新しいスタックを作成しましょう。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deploy --template-file use-module.yaml --stack-name cfn-workshop-modules
:::

### さらに詳しく見る

スタックをデプロイしたので、実際に何が起こったのかを詳しく見てみましょう。CloudFormation でモジュールがどのように機能するのかをより理解しやすくなるでしょう。

AWS コンソールを開き、CloudFormation サービスに移動します。作成したスタックを見つけて、`Resources` タブを選択します。
スタックには 23 個のリソースがあることが示されていることに注目します。

![stack-resources](/static/advanced/modules/StackResources.ja.png)

このリソースの数は、スタックの処理済みのテンプレートを見れば説明できます。CloudFormation が実際にデプロイするテンプレートは、モジュールの内容に基づいていることがわかります。
CloudFormation テンプレートでモジュールが使用されると、モジュールリソースはモジュールテンプレートで定義されたリソースに置き換えられます。

![stack-template](/static/advanced/modules/StackTemplate.ja.png)

### チャレンジ

作成されたリソースを簡単に識別できるように、モジュールフラグメントで定義されているリソースに `Name` タグを追加します。ユーザーは、モジュールを使用するときに `NameTag` というモジュールの新しいプロパティの値を指定できるようにします。

:::expand{header="ヒントが必要ですか?"}
* `module.yaml` ファイルを更新して、`Name` タグをサポートするすべてのリソースに追加します。VPC にタグを追加するためのドキュメントは[こちら](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html#cfn-ec2-vpc-tags)です。テンプレート内の他のリソースタイプについては、それぞれのリソースタイプがタグをサポートしているかどうか、また、その利用方法を確認してください。詳細については [AWS リソースおよびプロパティタイプのリファレンス](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)をご参照ください。完了したら、フラグメントに指定する新しい `NameTag` 入力パラメーターで、タグをサポートする各リソースに追加した `Name` タグの値を参照します。

* 変更を送信し、新しいモジュールバージョンをデフォルトバージョンとして設定します。詳細については、CloudFormation CLI command reference の `submit` [コマンド](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-cli-submit.html) をご参照ください。

* `use-module.yaml` テンプレートを更新して、新しい `NameTag` モジュールプロパティを含めます。

* `cfn-workshop-modules` スタックの更新を実行します。
:::

:::expand{header="解決策を確認しますか?"}

`module.yaml` ファイルの内容を次のように更新します。

<!-- vale off -->
```yaml
AWSTemplateFormatVersion: 2010-09-09

Description: A full VPC Stack

Parameters:

  VpcCidr:
    Type: String

  NameTag:
    Type: String

Resources:

  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
      Tags:
        - Key: Name
          Value: !Ref NameTag

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Ref NameTag

  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref Vpc
      InternetGatewayId: !Ref InternetGateway

  EIP1:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  EIP2:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  NATGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public1Subnet
      AllocationId: !GetAtt EIP1.AllocationId
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  NATGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public2Subnet
      AllocationId: !GetAtt EIP2.AllocationId
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  Public1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [0, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  Public2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [1, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  Private1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [2, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet1

  Private2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [3, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet2

  Public1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  Public2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  Private1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet1

  Private2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet2

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
```
<!-- vale on -->

次のコマンドを実行し、この新しいバージョンをデフォルトバージョンとします。

```shell
cfn submit --set-default
```

`use-module.yaml` ファイルの内容を次のように更新します。

<!-- vale off -->
```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:

  Vpc:
    Type: CFNWORKSHOP::EC2::VPC::MODULE
    Properties:
      VpcCidr: 10.1.0.0/16
      NameTag: VPCModule
```
<!-- vale on -->

deploy コマンドを実行し、スタックを更新します。

```shell
aws cloudformation deploy --template-file use-module.yaml --stack-name cfn-workshop-modules
```
:::
