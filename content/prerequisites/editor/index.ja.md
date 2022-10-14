---
title: "コードエディタのインストール"
weight: 300
---

[YAML](https://yaml.org/) の編集をサポートするお好みのコードエディタや IDE を利用できますが、このワークショップでは macOS、Linux、Windows でうまく動作する [Visual Studio Code](https://code.visualstudio.com/) の利用を前提とします。

VS Code をインストールするためには、オペレーティングシステムのパッケージマネージャ（例： macOS の `brew cask install visual-studio-code`）を使うか、[VS code のサイトの指示](https://code.visualstudio.com/) に従ってインストールしてください。

## CloudFormation Linter

[AWS CloudFormation Linter](https://github.com/aws-cloudformation/cfn-lint) のインストールを推奨します。[Linter](https://ja.wikipedia.org/wiki/Lint) は CloudFormation のテンプレートをデプロイする前に、基本的なエラーを事前に警告してくれます。

もし VS Code をお使いの場合、[cfn-lint](https://marketplace.visualstudio.com/items?itemName=kddejong.vscode-cfn-lint) プラグインをインストールしてください。

:::alert{type="info"}
`cfn-lint` は VS Code の `cfn-lint` プラグインと自動的にインストールされません。別途 [インストール手順](https://github.com/aws-cloudformation/cfn-lint#install) に沿ってインストールしてください。
:::
