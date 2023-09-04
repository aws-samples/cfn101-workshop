---
title: "デフォルト VPC"
weight: 400
---

デフォルト VPC では、すぐに利用開始出来ます。例えば、外部に公開するブログや簡単な Web サイトを作成できます。

ワークショップの **[初級編](../../Basics)** では、CloudFormation のテンプレートを実行するリージョンにデフォルト VPC が必須です。

意識的に削除されていない場合は、デフォルト VPC が必ず存在しています。わからない場合は、コマンドラインの手順に記載されている方法で確認してください。

デフォルト VPC を削除した場合は、以下のどちらかの手順で作り直すことができます。

### 1. Amazon VPC のコンソールでデフォルトVPCの作成

1. Amazon VPC のコンソールを [https://console.aws.amazon.com/vpc/](https://console.aws.amazon.com/vpc/) で開きます。
1. ナビゲーションペインで **お使いの VPC** を選択します。
1. **アクション** から **デフォルト VPC を作成** を選択します。
1. **デフォルト VPC を作成** で確認画面を閉じます。

### 2. コマンドラインでデフォルト VPC の作成

ひとまず、デフォルト VPC の存在を確認します。AWS CLI を使って、リージョン内の全ての VPC のリストから取得します。

1. 以下のコマンドラインをターミナルにコピーしてください。`--region` フラグで指定するリージョンをCloudFormation をデプロイする予定のリージョンに合わせてください。

   :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[].VpcId" --region ap-northeast-1
    :::

デフォルト VPC が存在している場合は、出力されるはずです。このセクションの残りを飛ばして、[次のステップ](../../Basics) に移行してください。

回答が空欄 `[]` の場合は、リージョンのデフォルト VPC がないということです。

2. 以下のコマンドをターミナルにコピーしてください。`--region` フラグで指定するリージョンをCloudFormation をデプロイする予定のリージョンに合わせてください。

   :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws ec2 create-default-vpc --region ap-northeast-1
    :::

    コマンドの結果は、以下の通りに新しく作成された VPC の情報が表示されます。

   :::code{language=json showLineNumbers=false showCopyAction=false}
    {
        "Vpc": {
            "CidrBlock": "172.31.0.0/16",
            "DhcpOptionsId": "dopt-c1422ea9",
            "State": "pending",
            "VpcId": "vpc-088b5ae6628fbf3ac",
            "OwnerId": "123456789012",
            "InstanceTenancy": "default",
            "Ipv6CidrBlockAssociationSet": [],
            "CidrBlockAssociationSet": [
                {
                    "AssociationId": "vpc-cidr-assoc-0ab2ffabcbe0548bc",
                    "CidrBlock": "172.31.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                }
            ],
            "IsDefault": true,
            "Tags": []
        }
    }
    :::

   ::alert[ワークショップの後にデフォルト VPC を削除されたい場合は、上記の **VpcId** のメモを取ると削除時に確実に正しい VPC を削除できます。]{type="info"}
