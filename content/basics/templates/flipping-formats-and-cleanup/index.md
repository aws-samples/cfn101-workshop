---
title: "Flipping formats and cleanup"
weight: 1000
---

_Lab Duration: ~10 minutes_

_Challenge: ~15 minutes._

---

### Overview
You can write AWS CloudFormation [templates](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-formats.html) in JSON or YAML formats: you choose either one or the other depending on your preference. For more information, see [AWS CloudFormation template formats](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-formats.html).

In this module, you will look into an example of switching from a JSON-formatted template into a YAML format: you will use the [cfn-flip](https://github.com/awslabs/aws-cfn-template-flip) tool as an option to easily perform this task. You will also use `cfn-flip` to perform opinionated cleanup actions for an example template.

### Topics Covered
By the end of this lab, you will be able to use `cfn-flip` as an option to:

* Flip from JSON to YAML formats, and vice versa.
* Perform opinionated cleanup actions on an example template.

### Start Lab
[Install](https://github.com/awslabs/aws-cfn-template-flip#installation) `cfn-flip` with `pip`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install cfn-flip
:::

Alternatively, if you are using [Homebrew](https://brew.sh/) on macOS:

:::code{language=shell showLineNumbers=false showCopyAction=true}
brew install cfn-flip
:::

When you are done with the installation, verify you can run `cfn-flip` by running the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-flip --version
:::

Let's now convert an example JSON-formatted template into YAML. Follow steps below to locate the template you will use, in this lab, for the task:
1. Change directory to the `code/workspace/flipping-formats-and-cleanup` directory.
2. Open the `example_parameter.json` CloudFormation template in your favorite text editor.
3. Read the content of the `example_parameter.json` file: this template describes an `AWS::SSM::Parameter` resource type for an [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) parameter. With this example template, you:
      - specify the value you wish to store for your Parameter Store parameter by using the [Ref](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) intrinsic function to reference the input `ParameterValue` template parameter. When you create a stack from this template, you pass in your desired value as an input to `ParameterValue`;
      - use `Ref` to reference the name you wish to assign to your Parameter Store parameter, that you specify in the `ParameterName` template parameter when you create a stack from the template;
      - add a description for your Parameter Store parameter: in this example, you choose to use the [Fn::Join](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html) intrinsic function to concatenate string fragments, one of which contains the reference to the name of your Parameter Store parameter. In the example template, string fragments are separated by a space, as indicated in the `" "` _delimiter_, that is the first [parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html#intrinsic-function-reference-join-parameters) you are passing here to the `Fn::Join` function.

::alert[You can also join strings with the `Fn::Sub` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html). Later on in this lab, you will learn how to use `cfn-flip` to convert from `Fn::Join` function declarations into `Fn::Sub`.]{type="info"}

Example template excerpts, that focus on points you just learned, are summarized next:

:::code{language=json showLineNumbers=false showCopyAction=false}
[...]
    "Parameters": {
        "ParameterName": {
            "Description": "Name you wish to specify for your SSM Parameter.",
[...]
        },
        "ParameterValue": {
            "Description": "Value you wish to specify for your SSM Parameter.",
[...]
        }
    },
    "Resources": {
        "MyParameter": {
            "Type": "AWS::SSM::Parameter",
            "Properties": {
                "Name": {
                    "Ref": "ParameterName"
                },
                "Type": "String",
                "Value": {
                    "Ref": "ParameterValue"
                },
                "Description": {
                    "Fn::Join": [
                        " ",
                        [
                            "My",
                            {
                                "Ref": "ParameterName"
                            },
                            "example parameter"
                        ]
[...]
:::

Next, use `cfn-flip` to convert your template from the JSON format into YAML. Run the following command from the directory where the `example_parameter.json` JSON-formatted template is located:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-flip example_parameter.json example_parameter.yaml
:::

::alert[The `cfn-flip` tool automatically detects the format of your input template (in your case, JSON), and will convert it into the opposite output format accordingly (in this example, into YAML). To explicitly tell `cfn-flip` to convert into YAML or into JSON (and to have `cfn-flip` assume the input template uses the opposite format), choose the `-y` (or `--yaml`) option or the `-j` (or `--json`) option, respectively. For more information, run ` cfn-flip --help` from the command line.]{type="info"}

As a result, you should now have a new template, in the same directory, called `example_parameter.yaml`. Open the template in your favorite text editor: can you recognize elements that you converted into YAML with `cfn-flip`?

Excerpts from the `example_parameter.yaml` template are shown next. You will note that the `Fn::Join` intrinsic function, which you saw in the JSON-formatted template, is now represented in its YAML short form, `!Join`; this is because `cfn-flip` [makes use of short form function declarations](https://github.com/awslabs/aws-cfn-template-flip#about) where possible:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
[...]
Parameters:
  ParameterName:
    Description: Name you wish to specify for your SSM Parameter.
[...]
  ParameterValue:
    Description: Value you wish to specify for your SSM Parameter.
[...]
Resources:
  MyParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Ref 'ParameterName'
      Type: String
      Value: !Ref 'ParameterValue'
      Description: !Join
        - ' '
        - - My
          - !Ref 'ParameterName'
          - example parameter
:::

With `cfn-flip` you can also convert from YAML to JSON. For more information, and to discover other `cfn-flip` features, run the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-flip --help
:::

::alert[When you write your templates in YAML format, you can choose to specify YAML comments in your template content by using the `#` character at the beginning of a line. When you use `cfn-flip` to convert from YAML into JSON, your YAML comments are not added to your output template in JSON format. This is because JSON does not support comments (see <https://json.org> for more information).]{type="info"}

Congratulations! You have converted your CloudFormation template from the JSON format to YAML, and learned how to discover other `cfn-flip` features!

### Challenge
The `cfn-flip` tool gives you also the ability to perform opinionated cleanup actions on your template, including converting from the [Fn::Join](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html) intrinsic function into using [Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html). In this lab section, you choose to use this functionality in the `example_parameter.yaml` template you converted earlier from the JSON format.

Your task is to perform opinionated cleanup actions on the `example_parameter.yaml` template, and store the cleaned up template output in a new file in your workspace, called `example_parameter_updated.yaml`. Please note that you want to maintain the same YAML format for the output template, instead of converting it to JSON.

Start with finding which options you need to pass to `cfn-flip` first, then run `cfn-flip` against the input template, and verify the output template uses the short form for the `Fn::Sub` intrinsic function instead of the short form for the `Fn::Join` intrinsic function.

::expand[Print the `cfn-flip` usage with: `cfn-flip --help` to find which two options you want to use for the task. Which are these two options?]{header="Need a hint?"}

:::expand{header="Want to see the solution?"}
Use the two following options: `-n -c` (or `--no-flip --clean`) for `cfn-flip` to maintain the same format (in this case, YAML), and to perform opinionated cleanup actions. Run the following command in your workspace:
::code[cfn-flip -n -c example_parameter.yaml example_parameter_updated.yaml]{language=shell showLineNumbers=false showCopyAction=true}

Open the resulting `example_parameter_updated.yaml` template with your favorite text editor: you should see that `!Sub` (short format) is now used, instead of `!Join` (short format) as shown in the following template excerpt:
::code[Description: !Sub 'My ${ParameterName} example parameter']{language=yaml showLineNumbers=false showCopyAction=true}
:::

---
### Conclusion

Great work! You have learned how to use `cfn-flip` to convert JSON-formatted CloudFormation templates into YAML (and vice versa), and to perform opinionated cleanup actions on a given template.
