---
title: 前提条件
weight: 310
---

### リソースタイプ開発ツール

次のセクションに進む前に、以下の前提条件からマシンに適切なツールをインストールしてください。

* 次のリンクからご使用のオペレーティングシステムに合う説明に従って [AWS SAM CLI](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-reference.html#serverless-sam-cli) をインストールしてください。SAM CLI をインストールするときは、コントラクトテストの実行に必要な Docker をインストールするための説明に従ってください (まだ Docker をインストールしていない場合のみ)。

    - [Linux の AWS SAM CLI](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install-linux.html)
    - [Windows の AWS SAM CLI](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install-windows.html)
    - [macOS の AWS SAM CLI](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install-mac.html)

* 使用したいサポート対象言語の [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) とプラグインをインストールします。

  `pip` を使用して CloudFormation CLI と Python プラグインをインストールします。
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  pip install cloudformation-cli cloudformation-cli-java-plugin cloudformation-cli-go-plugin cloudformation-cli-python-plugin cloudformation-cli-typescript-plugin
  :::

::alert[CloudFormation CLI のバージョン 1.0 がすでにインストールされている場合は、バージョン 2.0 にアップグレードし、使用する言語プラグインもアップグレードすることをお勧めします。アップグレードには、前に示した `pip install` コマンドの `--upgrade` オプションを使用し、使用している、または、使用する予定の言語プラグインを含めることができます。詳細については、[ページ](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html#resource-type-setup) の下部にある *Upgrading to CFN-CLI 2.0* をご参照ください。]{type="info"}

* [Python での実装例](../example-in_python) ラボでは、サンプルアプリケーションのユニットテストを実行するために必要な以下のパッケージをインストールします。

  :::code{language=shell showLineNumbers=false showCopyAction=true}
  pip install pytest-cov cloudformation-cli-python-lib
  :::
