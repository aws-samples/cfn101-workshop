---
title: "AWS アカウントの作成"
weight: 100
---

## 検証のために AWS アカウントを作成

アプリケーションをデプロイするために、AWS アカウントへのアクセスが必要です。すでにアカウントをお持ちで、さらに管理者権限を持っているユーザが利用する環境に設定されている場合は、[次のステップ](../cloud9)に移動しても大丈夫です。

:::alert{type="warning"}
既存の個人アカウントまたは会社のアカウントを利用する場合は、そのアカウントにリソースを作成する場合の影響とポリシーをご確認ください。
:::

AWS アカウントを持ちでない場合は、[こちらで無料で AWS アカウントを作成](https://portal.aws.amazon.com/billing/signup)できます。

## 管理者ユーザ

1. AWS アカウントにログインします。
1. AWS IAM コンソールに遷移して、[ユーザを追加](https://console.aws.amazon.com/iam/home?#/users$new)します。
1. ユーザ名を入力し (例えば `cfn-workshop`)、**アクセスキー - プログラムによるアクセス** と **パスワード - AWS マネジメントコンソールへのアクセス** にチェックを入れます。

    ![new-user-1-png](/static/prerequisites/account/new-user-1.ja.png)

1. **次のステップ: アクセス権限** を選択します。
1. **既存のポリシーを直接アタッチ** を選択し、**AdministratorAccess** にチェックを入れます。

    ![new-user-2-png](/static/prerequisites/account/new-user-2.ja.png)

1. **次のステップ: タグ** を選択します。
1. **次のステップ: 確認** を選択します。
1. **ユーザーの作成** を選択します。
1. 次の画面で利用する **アクセスキー ID** が表示されます。**シークレットアクセスキー** の隣の **表示** をクリックすると、その値が表示されます。

    ![new-user-3-png](/static/prerequisites/account/new-user-3.ja.png)

::alert[重要: 次のステップでアクセスキー ID とシークレットアクセスキーが必要になるので、この画面をこのまま維持するか、メモに保存してください。]{type="info"}
