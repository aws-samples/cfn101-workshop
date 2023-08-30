---
title: "クリーンアップ"
weight: 340
---

## クリーンアップ

このモジュールで作成したリソースをクリーンアップするには、次の手順に従います。

サンプルモジュールを使用したサンプルスタックを削除します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name cfn-workshop-modules
aws cloudformation wait stack-delete-complete --stack-name cfn-workshop-modules
:::

:::alert{header="チャレンジを完了した場合にのみ必要" type="warning"}
モジュールのバージョン `00000001` を CloudFormation レジストリから登録解除します。登録したモジュールのバージョン毎に、この手順を繰り返す必要があります (登録解除できないデフォルトバージョンは例外)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type --type MODULE --type-name CFNWORKSHOP::EC2::VPC::MODULE --version-id 00000001
:::

CloudFormation レジストリからモジュールを登録解除します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type --type MODULE --type-name CFNWORKSHOP::EC2::VPC::MODULE
:::
