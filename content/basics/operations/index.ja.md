---
title: "オペレーション"
weight: 20
---

![ec2-png](/static/basics/operations/ec2-1.png)

前の章では、CloudFormation の基礎とさまざまな _テンプレート_ のセクションについて学びました。

Elastic IP を使用して EC2 インスタンスを作成する単純なシナリオを体験しました。

この章では、既存のテンプレートを以下の機能で改善します。

+ Systems Manager Parameter Store を使用して、最新の Amazon Linux 2 AMI を任意のリージョンにデプロイします。
+ IAM ロールをインスタンスにアタッチし、SSM Session Manager を使用してインスタンスにログインします。
+ _UserData_ スクリプトを使用してインスタンスをブートストラップします。
+ `cfn-init` を使用して EC2 インスタンスのブートストラップを支援します。

---

### ワークショップでカバーするトピック:

::children
