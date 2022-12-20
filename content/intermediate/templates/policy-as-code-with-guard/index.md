---
title: "Policy-as-code with Guard"
weight: 700
---


### Overview

In a typical organization, a Security team establishes security, governance, and policy compliance requirements the organization needs. This includes requirements for Infrastructure as Code (IaC) configurations: for example, a Security team establishes a policy prescribing that [Amazon Simple Storage Service](https://aws.amazon.com/s3/) (Amazon S3) buckets must be configured with server-side encryption by default, and with versioning enabled.

As part of best practices, you choose to adopt the policy-as-code practice to programmatically detect policy compliance issues very early in the Software Development Life Cycle (SDLC), such as:

* in developers’ workstations, and
* in the Continuous Integration (CI) phase of your delivery pipelines

When you adopt the policy-as-code practice, you **speed up your SDLC feedback loop** because you have the opportunity to address policy compliance issues you detected early in the SDLC process.

In order to programmatically leverage policy-as-code, a company first needs to translate their policy requirements into rules written in a language that a policy-as-code tool understands. In this lab, you will learn how you can use a tool such as [AWS CloudFormation Guard](https://github.com/aws-cloudformation/cloudformation-guard) (Guard) for policy compliance validation against rules you write.


### Topics Covered

By the end of this lab, you will be able to:

* Understand basics of the domain-specific language (DSL) used by Guard
* Write your first Guard rule
* Use filters as the default method for selecting targets
* Rewrite your rules/rule clauses for modularity and reusability
* Write your first Guard rule test
* Adopt test-driven development (TDD) as a practice when you write Guard rules
* Reference the Guard documentation for more information and advanced use cases


### Start Lab

#### Install Guard
Choose to [install Guard](https://github.com/aws-cloudformation/cloudformation-guard#installation) in your workstation, by using a method of your choice depending on the operating system you use. If you have [Rust and Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html) installed on your machine (or if choose to install Rust and Cargo), it is easy to install Guard with:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cargo install cfn-guard
:::

Once you have set up Guard with a method you chose, verify you can successfully run it:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard help
:::

#### Write your first Guard rule

In this section, you will write example Guard rule clauses to validate that a sample CloudFormation template describes an [Amazon S3 bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html) with following properties you require:

* [server-side encryption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-bucketencryption.html) using the AES256 algorithm as an example, and
* [versioning](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-versioningconfiguration.html) enabled

Let's get started! Choose to follow steps shown next:

1. Change directory to the `code/workspace/policy-as-code-with-guard` directory.
2. Open the `example_bucket.yaml` CloudFormation template in your favorite text editor.
3. The template describes an `AWS::S3::Bucket` resource type; update the template by appending a `Properties` section with [server-side encryption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-bucketencryption.html) configuration using the AES256 algorithm, and [versioning](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-versioningconfiguration.html) enabled. Choose to copy content shown next, and paste it in the `example_bucket.yaml` file by appending it to the existing file content:

```yaml
Properties:
  BucketEncryption:
    ServerSideEncryptionConfiguration:
      - ServerSideEncryptionByDefault:
          SSEAlgorithm: AES256
  VersioningConfiguration:
    Status: Enabled
```

4. Create example Guard rule clauses to validate both properties are described as you expect. Open the `example_bucket.guard` file in the same directory mentioned earlier, and create a **type block** to validate your configuration for resource(s) of type `AWS::S3::Bucket` you describe in your template. Copy content shown next, and paste it in the `example_bucket.guard` file by appending it to the existing content:

```json
AWS::S3::Bucket {
    Properties {
        BucketEncryption.ServerSideEncryptionConfiguration[*] {
            ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256'
            <<BucketEncryption not configured with the AES256 algorithm>>
        }
        VersioningConfiguration.Status == 'Enabled'
        <<BucketEncryption not configured with versioning enabled>>
    }
}
```

::alert[When you write your Guard rules, use **filters** as the default mode for selecting resource types. As you are gradually learning about new concepts, in this section you will continue to use a type block (which is a syntactic sugar block for a filter that only matches a selection by a given type), and you will learn about filters in the next section.]{type="info"}

5. Inspect the previous set of example rule clauses. Note the following:
    * the outer, enclosing block contains a `AWS::S3::Bucket` type; rule clauses inside this block will apply to all the resources of the `AWS::S3::Bucket` type you declare in the template you are providing as input data;
    * rule clauses use the dot (`.`) character to traverse down the data hierarchy (for example, `VersioningConfiguration.Status` to refer to the `Status` property underneath `VersioningConfiguration`);
    * the wildcard (`*`) character is used to traverse down all array indexes for a given level (e.g., for `ServerSideEncryptionConfiguration[*]`);
    * rule clauses contain optional sections, delimited by `<<` and `>>` blocks, where you can choose to provide a [custom message](https://docs.aws.amazon.com/cfn-guard/latest/ug/writing-rules.html#clauses-custom-messages);
    * you expect that rule clauses as declared in the example pass validation. With Guard, you use the [Conjunctive Normal Form](https://en.wikipedia.org/wiki/Conjunctive_normal_form) (CNF) to describe logical `AND` clauses across `OR` clauses: in the example shown earlier, rule clauses are interpreted as `AND` clauses (that is, you validate server-side encryption *and* versioning configurations, and *both* must be satisfied for your data to pass validation against your rule). When you have use cases where you want to validate that e.g., *either* clause A *or* clause B are satisfied instead, you describe this behavior by appending `OR` to the line for clause A. In the next example, for your rule to pass, both `ExampleClause1` and `ExampleClause2` requirements must be satisfied, and either `ExampleClauseA` or `ExampleClauseB` must be satisfied:

:::code{language=shell showLineNumbers=false showCopyAction=false}
[...]
ExampleClause1
ExampleClause2
ExampleClauseA OR
ExampleClauseB
[...]
:::

6. Now that you have taken a closer look at example rule clauses, run the `validate` Guard subcommand by specifying your template with the `-d` (or `--data`) flag, and your rules with `-r` (or `--rules`) as shown next:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard --show-summary pass
:::

7. You should then get an output similar to the following, that indicates your template passed validation against your rule clauses:

:::code{language=shell showLineNumbers=false showCopyAction=false}
example_bucket.yaml Status = PASS
PASS rules
example_bucket.guard/default    PASS
---
Evaluation of rules example_bucket.guard against data example_bucket.yaml
--
Rule [example_bucket.guard/default] is compliant for template [example_bucket.yaml]
--
:::

::alert[The `default` suffix shown in the preceding `example_bucket.guard/default` output portion indicates that your rule clauses belong to a rule named `default`. Later on in this lab, you will write rules with a given name (**named rules**), and you will use such rules instead of the default rule. This will give you opportunities to create modular and reusable rules.]{type="info"}

Congratulations! You created your first Guard rule, and you used it to validate an example template that described an example S3 bucket configuration!


#### Filtering

In the previous example, you have used type blocks to select target resources of a given type that you describe in your input template. In this section, you will learn about **filters**, that give you flexibility in selecting targets you wish to validate against your rules. For example, if you want to validate that all [AWS::IAM::Policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html) and [AWS::IAM::ManagedPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-managedpolicy.html) resources you describe in your template contain a `PolicyDocument` property (that is a common property for both resource types), you first create a filter to query for resources of both types such as:

:::code{language=json showLineNumbers=false showCopyAction=true}
Resources.*[
    Type in [ 'IAM::Policy', 'IAM::ManagedPolicy' ]
]
:::

Let's rewrite example rule clauses you used earlier by using filters! As part of this exercise, you will also declare a `my_buckets` example variable by using `let`, and you will reference that variable in the new implementation of example rules with the `%` character as shown next:

```javascript
let my_buckets = Resources.*[ Type == 'AWS::S3::Bucket' ]


%my_buckets.Properties {
    BucketEncryption.ServerSideEncryptionConfiguration[*] {
        ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256'
        <<BucketEncryption not configured with the AES256 algorithm>>
    }
    VersioningConfiguration.Status == 'Enabled'
    <<BucketEncryption not configured with versioning enabled>>
}
```

Replace existing rule clauses in `example_bucket.guard` with the new content just shown, and run the validation again:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

Validation against your rule clauses that now use filters should pass.

::alert[Guard supports variable scopes at the *file*, *rule* and *block* level. The specific placement of a variable in a given scope determines its visibility in a file containing your Guard rules. The scope of the `my_buckets` variable shown earlier is a file-level scope: thus, `my_buckets` should be visible to rules/rule clauses you describe in the `example_bucket.guard` rules file. For more information, see [Assigning and referencing variables in AWS CloudFormation Guard rules](https://docs.aws.amazon.com/cfn-guard/latest/ug/variables.html).]{type="info"}

Congratulations! You have created a filter that matches resources of a given type in your template, and you have also reused a variable you scoped at the file level.


#### Rewrite your rule for modularity and reusability

In this section, you will decouple rule clauses into separate rules, to favor modularity and reuse. **Writing simple and modular Guard rules not only gives you reuse opportunities, but it also makes it easier for you to pinpoint which rule failed when you validated your data, and/or to troubleshoot your rules as needed.**

Recall example rule clauses shown earlier. With one clause, you validated the server-side encryption configuration you set up for your bucket, and with another clause you validated that you enabled versioning for your bucket. Let's rewrite this logic into two [named rules](https://docs.aws.amazon.com/cfn-guard/latest/ug/named-rule-block-composition.html), that are rules with a name you assign.

You will create two named rules: `rule validate_bucket_sse_example` and `validate_bucket_versioning_example`. For each rule declaration statement, you will use the `when` keyword with the intent of running the given rule against your input data only when selection targets (in this case, `AWS::S3::Bucket` resources) are present in your input data:

```javascript
let my_buckets = Resources.*[ Type == 'AWS::S3::Bucket' ]


rule validate_bucket_sse_example when %my_buckets !empty {
    %my_buckets.Properties {
        BucketEncryption.ServerSideEncryptionConfiguration[*] {
            ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256'
            <<BucketEncryption not configured with the AES256 algorithm>>
        }
    }
}


rule validate_bucket_versioning_example when %my_buckets !empty {
    %my_buckets.Properties {
        VersioningConfiguration.Status == 'Enabled'
        <<BucketEncryption not configured versioning enabled>>
    }
}
```

Copy and paste the two named rules by replacing existing rule clauses in `example_bucket.guard`. When done, run the validation again:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

You should then get an output similar to the following, where instead of `default` rule occurrences you have seen earlier, you should now see names you assigned to `rule validate_bucket_sse_example` and `validate_bucket_versioning_example` rules you decoupled:

:::code{language=shell showLineNumbers=false showCopyAction=false}
example_bucket.yaml Status = PASS
PASS rules
example_bucket.guard/validate_bucket_sse_example           PASS
example_bucket.guard/validate_bucket_versioning_example    PASS
---
Evaluation of rules example_bucket.guard against data example_bucket.yaml
--
Rule [example_bucket.guard/validate_bucket_sse_example] is compliant for template [example_bucket.yaml]
Rule [example_bucket.guard/validate_bucket_versioning_example] is compliant for template [example_bucket.yaml]
--
:::

::alert[If your input data does not contain target selections (in the previous example, if you did not describe Amazon S3 buckets in your template): if you use the `when` keyword as shown earlier (`when %my_buckets !empty`), the rule evaluation will be skipped and marked as `SKIP` in the resulting Guard output. If you, instead, omit the `when` keyword and the `%my_buckets !empty` portion as shown earlier, the rule will fail due to a retrieval error. For more information on clauses, queries, operators, see [Writing AWS CloudFormation Guard rules](https://docs.aws.amazon.com/cfn-guard/latest/ug/writing-rules.html).]{type="info"}

Congratulations! You have decoupled initial rule clauses into two separate named rules, thus favoring modularity and reusability! You also now have examples of smaller code portions to write, consume, and troubleshoot as needed.


#### Rule correlation

Depending on your use cases or business logic implementation needs, you have the option to reference a named rule from within another rule. Let's recall the previous example: append, to the `example_bucket.guard` file, the following content:

```json
rule correlation_example when %my_buckets !empty {
    validate_bucket_sse_example
    validate_bucket_versioning_example
}
```

The `correlation_example` example rule references the two other named rules you described in the same file earlier: both named rules must be satisfied for `correlation_example` to pass. Run validation again:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

You should get an output similar to the following excerpt:

:::code{language=shell showLineNumbers=false showCopyAction=false}
example_bucket.yaml Status = PASS
PASS rules
example_bucket.guard/validate_bucket_sse_example           PASS
example_bucket.guard/validate_bucket_versioning_example    PASS
example_bucket.guard/correlation_example                   PASS
[...]
:::

If the `validate_bucket_sse_example` rule and/or the `validate_bucket_versioning_example` rule fail(s), the `correlation_example` rule will also fail.

Congratulations! You have learned how to correlate and reference named rules!


#### Write your first Guard rule test

Guard gives you the ability to write tests for your rules, to validate that your rules work as you expect. This aspect also opens up the opportunity to leverage the [test-driven development](https://en.wikipedia.org/wiki/Test-driven_development) (TDD) practice in your workflow, where you start with writing tests for your rules first, and you write and run test for your rules next.

Let's get started! Open the `example_bucket_tests.yaml` file with your favorite text editor, and append the following content that contains tests for named rules you used earlier:

```yaml
- input:
    Resources:
      MyExampleBucket:
        Type: AWS::S3::Bucket
        Properties:
          BucketEncryption:
            ServerSideEncryptionConfiguration:
              - ServerSideEncryptionByDefault:
                  SSEAlgorithm: AES256
  expectations:
    rules:
      validate_bucket_sse_example: PASS

- input:
    Resources:
      MyExampleBucket:
        Type: AWS::S3::Bucket
        Properties:
          VersioningConfiguration:
            Status: Suspended
  expectations:
    rules:
      validate_bucket_versioning_example: FAIL
```

When you look at the example test content just shown, you note that tests contain two `input` sections, one for each test case in this example:
* with the first test case, you test that the server-side encryption validation logic of your `validate_bucket_sse_example` rule validation will pass when provided with expected test input, that in your example uses `AES256` for the `SSEAlgorithm` property underneath `BucketEncryption`;
* with the second test case, you expect the `validate_bucket_versioning_example` rule validation will fail when providing `Suspended` (instead of `Enabled`) for the `VersioningConfiguration` `Status`.

Let's run tests! Choose to use the `test` Guard subcommand, followed by `-t` (or `--test-data`) to specify your test file, and `-r` (or `--rules-file`) to specify the file containing your rules to put under test:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard test -t example_bucket_tests.yaml -r example_bucket.guard
:::

You should get an output similar to the one following next, depicting both example test cases and the outcome you expect:

:::code{language=shell showLineNumbers=false showCopyAction=false}
Test Case #1
  No Test expectation was set for Rule validate_bucket_versioning_example
  No Test expectation was set for Rule correlation_example
  PASS Rules:
    validate_bucket_sse_example: Expected = PASS, Evaluated = PASS

Test Case #2
  No Test expectation was set for Rule validate_bucket_sse_example
  No Test expectation was set for Rule correlation_example
  PASS Rules:
    validate_bucket_versioning_example: Expected = FAIL, Evaluated = FAIL
:::

Congratulations! You have written and ran your first tests for your Guard rules!


### Challenge

In this example, you want to configure your [Amazon S3 bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html) with all [properties](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#aws-resource-s3-bucket-properties) underneath `PublicAccessBlockConfiguration` set to `true` (Boolean).

Your tasks are:
1. Append, to the `example_bucket_tests.yaml` unit test file content, a new `input` section to validate that a new rule you will create, called `validate_bucket_public_access_block_example`, is expected to pass when you provide test input data containing all `PublicAccessBlockConfiguration` properties set to `true`.
2. Implement the `validate_bucket_public_access_block_example` rule in the `example_bucket.guard` file. Add a custom message after each clause you will write, in the rule, for each one of the `PublicAccessBlockConfiguration` properties;
3. Run Guard with the `test` subcommand to run your tests. You should see a Test Case #3 section in the unit tests output, with a line such as: `validate_bucket_public_access_block_example: Expected = PASS, Evaluated = PASS` to indicate unit tests for the new rule succeeded.
3. Update the `example_bucket.yaml` template, and add the relevant `PublicAccessBlockConfiguration` configuration.
4. Run Guard with the `validate` subcommand to validate the `example_bucket.yaml` file content against rules you wrote in the `example_bucket.guard` file. You should see a line such as `example_bucket.guard/validate_bucket_public_access_block_example    PASS` in the resulting output to indicate validation against your new rule succeeded.


:::expand{header="Need a hint?"}
* Navigate to the `PublicAccessBlockConfiguration` property documentation [page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-publicaccessblockconfiguration.html) to determine names of properties underneath it;
* follow the same rule structure for the `VersioningConfiguration.Status` clause; for rule clauses you will write for each of the `PublicAccessBlockConfiguration` [properties](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-publicaccessblockconfiguration.html), use a boolean value for `true` instead of a string.
:::


::::expand{header="Want to see the solution?"}
Note: content shown next is also available in relevant files located in the `code/solutions/policy-as-code-with-guard` directory.

* Append this content to the `example_bucket_tests.yaml` unit test file:

```yaml
- input:
    Resources:
      MyExampleBucket:
        Type: AWS::S3::Bucket
        Properties:
          PublicAccessBlockConfiguration:
            BlockPublicAcls: true
            BlockPublicPolicy: true
            IgnorePublicAcls: true
            RestrictPublicBuckets: true
  expectations:
    rules:
      validate_bucket_public_access_block_example: PASS
```


* Append this content to the `example_bucket.guard` file:

```json
rule validate_bucket_public_access_block_example when %my_buckets !empty {
    %my_buckets.Properties {
        PublicAccessBlockConfiguration.BlockPublicAcls == true
        <<BlockPublicAcls not set to true in PublicAccessBlockConfiguration>>

        PublicAccessBlockConfiguration.BlockPublicPolicy == true
        <<BlockPublicPolicy not set to true in PublicAccessBlockConfiguration>>

        PublicAccessBlockConfiguration.IgnorePublicAcls == true
        <<IgnorePublicAcls not set to true in PublicAccessBlockConfiguration>>

        PublicAccessBlockConfiguration.RestrictPublicBuckets == true
        <<RestrictPublicBuckets not set to true in PublicAccessBlockConfiguration>>
    }
}
```


* Run unit tests, and make sure they pass:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard test -t example_bucket_tests.yaml -r example_bucket.guard
:::


* Append this content to the `example_bucket.yaml` template:

```yaml
PublicAccessBlockConfiguration:
  BlockPublicAcls: true
  BlockPublicPolicy: true
  IgnorePublicAcls: true
  RestrictPublicBuckets: true
```


* Validate your template data against your rules, and make sure all rules pass the validation:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::
::::


---
### Conclusion

Great work! You have learned the basics of writing and testing Guard rules! To learn more about Guard, see the [documentation](https://docs.aws.amazon.com/cfn-guard/latest/ug/what-is-guard.html), as well as the [Guard repository](https://github.com/aws-cloudformation/cloudformation-guard) for content that include FAQs and examples.
