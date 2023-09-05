---
title: "前提条件"
weight: 310
---

### モジュール開発ツール

次のセクションに進む前に、以下のツールをマシンにインストールしてください。

* [CloudFormation コマンドラインインターフェイス (CLI)](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) をインストールします。

    `pip` を使用して CloudFormation CLI をインストールします。

    :::code{language=shell showLineNumbers=false showCopyAction=true}
    pip install cloudformation-cli
    :::

::alert[CloudFormation CLI のバージョン 1.0 が既にインストールされている場合は、バージョン 2.0 にアップグレードすることをお勧めします。アップグレードには、`pip install` コマンドの `--upgrade` オプションを使用できます。詳細については、こちらの[ページ](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html#resource-type-setup) の下部に記載の *Upgrading to CFN-CLI 2.0* をご参照ください。]{type="info"}
