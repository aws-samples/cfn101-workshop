---
title: 'Example in Python'
date: 2021-11-16T20:55:12Z
weight: 320
---

### Overview
In this module, you will follow steps to register an existing, example private extension written in Python with the AWS CloudFormation registry in your AWS account. You will also navigate through the example source code implementation for the resource type to understand key concepts of the resource type development workflow.

### Topics Covered
By the end of this lab, you will be able to:

* understand key concepts to leverage when you develop a resource type;
* use the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) to create a new project, run contract tests, and submit the resource type to the CloudFormation registry in your AWS account;
* understand how to use the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) to manually test your resource type handlers.

### Start Lab
In this lab, you will go on a deep dive for the code of an existing, example resource type: you will explore steps and a number of considerations to make when modeling and implementing a resource type. For information on how to get started with the CloudFormation CLI to create a new project, see [Walkthrough: Develop a resource type](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-walkthrough.html).

#### Creating a new project
First, open a command line shell on your machine and navigate to `code/workspace` directory:

```shell
# create working directory
cd code/workspace
mkdir resource-types
cd resource-types

# initialize new resource types project
cfn init
```

Follow the prompts (`>>`) in the terminal as below:
```shell
Initializing new project
Do you want to develop a new resource(r) or a module(m)?.
>> r
Whats the name of your resource type?
(Organization::Service::Resource)
>> CfnWorkshop::EC2::KeyPair
Select a language for code generation:
[1] go
[2] python36
[3] python37
(enter an integer):
>> 3
Use docker for platform-independent packaging (Y/n)?
This is highly recommended unless you are experienced
with cross-platform Python packaging.
>> Y
Initialized a new project in /Users/username/aws-samples/cfn101-workshop/code/solutions/resource-types
```

Congratulations! You have created your first stub for your resource type in Python! Let's take a look at the generated stub content:

* `README.md`: main documentation file where you'd want to add information on how to use your resource type;
* `docs`: directory containing syntax information for properties of your resource type;
* `example_inputs`: directory containing files with property key/value data you will specify for use with contract tests. *As such files are also added to source code control, do not add sensitive information to such files*;
* `myorganization-myservice-myresource.json`: this file, named after your resource type name choice above, contains the schema for the resource: **this file is where you describe the model for your resource**;
* `src`: contains a directory named after your resource type name, inside of which you should find the `models.py` file, that you manage with the CloudFormation CLI when you make schema changes, and the `handlers.py` file, that is where you will start adding your code for the CRUDL implementation logic. Open the `src/handlers.py` file with a text editor of your choice, and **familiarize with the handlers' structure** described in `create_handler`, `update_handler`, `delete_handler`, `read_handler`, `list_handler` functions;
* `resource-role.yaml`: file created by the CloudFormation CLI, that describes an [AWS Identity and Access Management](https://aws.amazon.com/iam/) (IAM) role whose `PolicyDocument` contains permissions you indicate in the schema for your handlers in the `handlers` section.  CloudFormation assumes this role to manage resources on your behalf as part of CRUDL operations;
* `template.yml`: [AWS Serverless Application Model](https://aws.amazon.com/serverless/sam/) (SAM) template used as part of resource type testing.

#### Writing your schema
The first step in creating a resource type is to define a schema that describes properties for your resource, as well as permissions needed for CloudFormation to manage the resource on your behalf.

##### 1. Replace generated schema
In your working directory, you should see a `cfnworkshop-ec2-keypair.json` file. Click the arrow to expand the file and replace the current one:
{{%expand "cfnworkshop-ec2-keypair.json file" %}}
```json
{
    "typeName": "CfnWorkshop::EC2::KeyPair",
    "description": "Provides an EC2 key pair resource. A key pair is used to control login access to EC2 instances. This resource requires an existing user-supplied key pair.",
    "sourceUrl": "https://github.com/aws-samples/cfn101-workshop",
    "properties": {
        "KeyName": {
            "description": "The name for the key pair.",
            "type": "string",
            "pattern": "^[a-zA-Z0-9_-]+$",
            "minLength": 1,
            "maxLength": 255
        },
        "PublicKey": {
            "description": "The public key material.",
            "type": "string"
        },
        "Fingerprint": {
            "description": "The MD5 public key fingerprint as specified in section 4 of RFC 4716.",
            "type": "string"
        }
    },
    "required": [
        "KeyName",
        "PublicKey"
    ],
    "additionalIdentifiers": [
        [
            "/properties/Fingerprint"
        ]
    ],
    "readOnlyProperties": [
        "/properties/Fingerprint"
    ],
    "writeOnlyProperties": [
        "/properties/PublicKey"
    ],
    "createOnlyProperties": [
        "/properties/PublicKey",
        "/properties/KeyName"
    ],
    "primaryIdentifier": [
        "/properties/KeyName"
    ],
    "additionalProperties": false,
    "handlers": {
        "create": {
            "permissions": [
                "ec2:ImportKeyPair"
            ]
        },
        "read": {
            "permissions": [
                "ec2:DescribeKeyPairs"
            ]
        },
        "delete": {
            "permissions": [
                "ec2:DeleteKeyPair",
                "ec2:DescribeKeyPairs"
            ]
        },
        "list": {
            "permissions": [
                "ec2:DescribeKeyPairs"
            ]
        }
    }
}
```
{{% /expand %}}

Let's look into the individual fields of the schema:
- `typeName`: This should match the type name you defined when you ran cfn init.
- `description`: A description of the type and what it does.
- `sourceUrl`: The location of your documentation and source code, if public.
- `properties`: The types and other attributes of the properties within the type.
- `additionalProperties`: Whether non-explicit properties (properties you haven’t defined) are allowed to be passed in.
- `required`: A list of the required property names. In this case, the key name and the public key material are required and creation should be rejected if those properties are not present.
- `additionalIdentifiers`: An array of single-element arrays which each should contain the path string to the property. A path string should take the form /properties/<FirstLevelProperty>/<SecondLevelProperty>. The value of properties specified in this format will be returned when using a `!GetAtt` intrinsic function.
- `readOnlyProperties`: An array of path strings that represent properties that cannot be explicitly set, only returned after creation. This usually means that these properties are identifiers that are returned from the creation of a resource.
- `writeOnlyProperties`: An array of path strings that represent properties that cannot be returned when retrieving the current state of a resource (for example, during a drift detection operation). This usually means that these properties are secrets used for the resource. Note that these properties will still be available to the creation handler.
- `primaryIdentifier`: An single-element array containing a path string that represent the primary identifier for the resource. The value of this property will be returned when using a `!Ref` intrinsic function.
- `handlers`: A map of required AWS permissions needed for the handler functions to operate. The CloudFormation service role (or the calling user if not present) will need to have these permissions in order for the handler to execute.

The `PublicKey` is defined as `writeOnlyProperty`.  Write-only properties are often used to contain passwords, secrets, or other sensitive data.
While the public key does not contain sensitive data, the ec2 api does not return it when describing a key.
Defining this as write only means we do not have to figure out a way to store and retrieve it.
```shell
"writeOnlyProperties": [
"/properties/PublicKey"
],
```

The `KeyName` and `PublicKey` are defined as `createOnlyProperties`. This means that changing these properties will always trigger
the creation of a new resource. Since those are the only two properties that a user can set, this also means that we do
not have to write code to handle updates, as every update will trigger first a new CREATE (in the UPDATE_IN_PROGRESS phase)
and then a DELETE (in the UPDATE_COMPLETE_CLEANUP_IN_PROGRESS phase).
```shell
"createOnlyProperties": [
"/properties/PublicKey",
"/properties/KeyName"
],
```

##### 2. Regenerate the code
Since we edited our schema, we also need to regenerate code that was created for us with `cfn init`.

To regenerate the code run:
```shell
$ cfn generate
Explicitly specify value for tagging
Resource schema is valid.
Generated files for CfnWorkshop::EC2::KeyPair
```

## --> end of rewrite <--

#### Handlers

In the previous section, you have followed along an example process of how to start building your schema. In this section, you will go through steps that illustrate an example handler code implementation. Initial, key considerations to make are:

* for a given CRUDL handler (*Create*, *Read*, *Update*, *Delete*, *List*), you will need to implement a business logic as such:
    * call a given, service-specific API(s) (such as `ImportKeyPair` in the *create* handler, `DeleteKeyPair` in the *delete* handler, et cetera);
* consume data returned by a given API you call in a given handler; moreover:
    * every handler must always return a `ProgressEvent`. For more information on its structure, see [ProgressEvent object schema](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-progressevent.html);
    * if there are no errors, return a `ProgressEvent` object with `status=OperationStatus.SUCCESS` from a given handler; additionally, if the handler is not *delete* or *list*, return a `ResourceModel` object (the model for the resource) with the data you gather with your handler code (from an API call) for the resource. For the *list* handler, instead of a single model, return a list of models for each of your resources of the type you're describing;
    * if the API you call returns an error, or if there is another exception being thrown, return a `ProgressEvent` object with `status=OperationStatus.FAILED`. Considerations to make when you do so include:
        * capture the stacktrace, and the specific error message text from a given exception (`botocore.exceptions.ClientError`, other exceptions, ....). This way, you can show your stacktrace in log statements you write in your handler's code, and return the error message description with a `ProgressEvent` object, so that this information can be made available as part of CloudFormation events (e.g., in the Events pane in the CloudFormation console) to describe to the user the cause of the error;
        * depending on the error you get from the underlying API (for the import key pair example, for a given error from [Error codes for the Amazon EC2 API](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/errors-overview.html)), you want to map it to a given error from [Handler error codes](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-contract-errors.html). For example, if an EC2 API returns an `InvalidKeyPair.NotFound` client error you want to return a `HandlerErrorCode.NotFound` handler error with a `ProgressEvent`;
        * if your resource type will require time to stabilize (for example, reaching to a state where the resource is fully available), use a stabilization mechanism on *create*, *update*, and *delete* handlers: you return a `ProgressEvent` with an `OperationStatus.IN_PROGRESS` the first time a handler is called, and for subsequent calls of that handler until your desired state is reached, you drive next steps by checking on the progress status by calling the *read* handler (where, for example, you check for a specific property value to determine creation complete or in progress).

You can see examples of topics described above in the `src/awssamples_ec2_importkeypair/handlers.py` sample resource type: each handler makes calls to given EC2 API(s), for which there is a relevant set of permissions set in the schema as you have seen earlier. The example resource type leverages exception handling mechanism described above, whereas a downstream API error message is captured and returned along with a handler error code mapped to a given EC2 API. Even if, for the key pair import use case, a stabilization process is not necessarily needed, the sample resource type illustrates an example of a callback mechanism used in *create*, *update*, and *delete* handlers.


#### Running unit tests

As part of software development best practices, you want to write *unit tests* to increase your level of confidence that your code works the way you expect. As mentioned in these [notes](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python#unit-tests), the `AWSSamples::EC2::ImportKeyPair` example resource type includes unit tests in the `src/awssamples_ec2_importkeypair/tests` directory. If you look at the `test_handlers.py` file in that directory (that should be on your machine as part of the repository clone/download choice you made earlier), you will see test utility functions described at the beginning and, about at half-way through the file, unit tests that consume such utility functions to perform tests including validating return values and exceptions being thrown. Objects, that include function calls such as EC2 API calls, are replaced/patched in tests with mock objects calls by leveraging the [unittest.mock](https://docs.python.org/3/library/unittest.mock.html) mock object library.

Let's run unit tests! Make sure you are in the directory that is at the root level of the `AWSSamples::EC2::ImportKeyPair` example resource type (i.e., inside the `python` directory), and that you have followed prerequisites in the previous topic. Next, choose to run unit tests as follows:

```
pytest --cov src --cov-report term-missing
```

You should get an output indicating unit tests results, along with a total coverage percentage value. Unit tests in the example resource type leverage a `.coveragerc` file at the root of the project that contains [configuration](https://coverage.readthedocs.io/en/latest/config.html) choices that include a required test coverage value.


#### Running contract tests

In subsequent steps on this lab, you will locally test and then submit, to the CloudFormation Registry in your account, the `AWSSamples::EC2::ImportKeyPair` example resource type as a private extension.

As you build your resource type, and very early in the development process, you want to make sure to leverage the [Resource type handler contract](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-contract.html), that describes requirements for you to adhere to when you implement the business logic of your handlers. Enforcement of the handler contract is done when you submit a public resource type to the Registry, whereas in that case you are required to pass contract tests: this is important to make sure a high quality bar is maintained on behalf of external customers consuming your resource type.

{{% notice note %}}
When you submit a private resource type, unless you use an `aws`, `amzn`, `alexa`, `amazon`, `awsquickstart` namespace, contract tests do not run. As part of best practices though, you should try to adhere to contract tests specifications very early in your development process anyway.
{{% /notice %}}

Let's run contract tests for the example resource type! First, let's set up test support infrastructure as described on these [notes](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python#contract-tests) for the example resource type. Contract tests for the example resource type will create, update, and delete test-only key pair resources in your account. Key pair information, such as name and tags, will be provided in files in the `inputs` directory in the project, and the public key material will be consumed from an exported value of a CloudFormation stack you create. For more information on how to pass test data to contract tests, see [Specifying input data for use in contract tests](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test.html#resource-type-test-input-data).

{{% notice note %}}
Contract tests will make real API calls. Make sure your configuration is set up to point to your test AWS account, so to use either relevant environment credentials or relevant credentials from the Boto3 credential chain.
{{% /notice %}}

First, let's generate an SSH key pair you will use for testing. Open a new terminal console in your machine, and choose an existing or new directory outside the `AWSSamples::EC2::ImportKeyPair` project directory path. When ready, change directory in to the one you chose or created, and create the SSH key pair with the `ssh-keygen` command:

```
ssh-keygen -t rsa -C "Example key pair for testing" -f example-key-pair-for-testing
```

Follow prompts and complete the creation of the key pair. You should now have, in the directory you chose, 2 files: `example-key-pair-for-testing` and `example-key-pair-for-testing.pub`. The former is the private key; the latter the public key portion, which is the one you will use in following steps where, when needed, you will need to provide its content by opening the public key file, copying its content in the clipboard and pasting it in the command line.

Next, create a CloudFormation stack that will create, for reference, an [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) resource containing the public key material you will provide an input: contract tests will consume the `KeyPairPublicKeyForContractTests` [exported stack output value](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) of this stack. Input files in the `inputs` directory of the example resource type, in turn, contain `{{KeyPairPublicKeyForContractTests}}` references to the value exported from the stack.

When ready, switch back to the terminal where you cloned or downloaded the example resource type, and make sure you are in the `aws-cloudformation-samples/resource-types/awssamples-ec2-importkeypair/python/` directory. With the next command, you will choose to create a new stack using the `examples/example-template-contract-tests-input.yaml` example template file: the template requires you to specify the `KeyPairPublicKey` input parameter, for which you will need to specify the content as mentioned earlier. The template also requires `OrganizationName` and `OrganizationBusinessUnitName`, that are set with example default values, `ExampleOrganization` and `ExampleBusinessUnit` respectively, and that will be used if you do not choose to provide values for them. Choose to create the stack as shown next, with a placeholder for the public key file content, where you will need to copy and paste the content of the public key file (the example uses `us-east-1` for the AWS region, change this value as needed):

```
aws cloudformation create-stack \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests \
  --template-body file://examples/example-template-contract-tests-input.yaml \
  --parameters ParameterKey=KeyPairPublicKey,ParameterValue='PASTE_CONTENT_OF_example-key-pair-for-testing.pub'
```

Wait until the `example-for-key-pair-contract-tests` stack is created, by using the CloudFormation console or the [stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) wait command of the AWS CLI (the example uses `us-east-1` for the AWS region):

```
aws cloudformation wait stack-create-complete \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests
```

 Next, you will need two terminal consoles opened on your machine; for each one, make sure you are at the root level of the `AWSSamples::EC2::ImportKeyPair` example resource type project:

* on the first terminal console, make sure Docker is running on your machine, and run `sam local start-lambda`
* on the second terminal console, run contract tests: `cfn generate && cfn submit --dry-run && cfn test`

For more information on contract tests for each handler (e.g., `contract_create_create`, `contract_create_read`, et cetera), see [Contract tests](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/contract-tests.html).

At the end of this process, you should see output indicating contract tests results. Let's move onto the next step!


#### Submitting the resource type as a private extension

Let's use the CloudFormation CLI to submit the resource to the registry in your CloudFormation account (the example uses `us-east-1` for the AWS region):

```
cfn generate && cfn submit --set-default --region us-east-1
```

Wait until the registration finishes, after which you should have the `AWSSamples::EC2::ImportKeyPair` example resource type registered as a private extension in your account. To verify, choose *Activated extensions* in the CloudFormation console, and then choose *Privately registered*.

Now, let's test the example resource type with an example template, that is already available as `examples/example-template-import-keypair.yaml` in the repository you cloned or downloaded: if you open the file with a text editor of your choice, you will see how the example resource type is referenced in the `Resources` section. For `KeyPairPublicKey`, choose to specify the same public key content you used for contract tests. The template also uses default values for `KeyPairName`, `OrganizationName`, and `OrganizationBusinessUnitName`, that will be used unless you specify your own. Choose to create the stack (the example uses `us-east-1` for the AWS region):

```
aws cloudformation create-stack \
  --region us-east-1 \
  --stack-name example-key-pair-stack \
  --template-body file://examples/example-template-import-keypair.yaml \
  --parameters ParameterKey=KeyPairPublicKey,ParameterValue='PASTE_CONTENT_OF_example-key-pair-for-testing.pub'
```

Wait until the stack creation finishes, after which you should have imported successfully the example key pair using CloudFormation and the sample `AWSSamples::EC2::ImportKeyPair` resource type (the example uses `us-east-1` for the AWS region):

```
aws cloudformation wait stack-create-complete \
  --region us-east-1 \
  --stack-name example-key-pair-stack
```

### Challenge

##### Context
As part of contract testing, you also have the option of [Testing resource types manually](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing), by using the [`sam local invoke`](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-local-invoke.html) command to issue handler invocations. To manually run tests:

* in one terminal, run `sam local start-lambda` like you did earlier on this lab (from inside the `python` directory of the example resource type);
* in another terminal, invoke the handler with e.g., `sam local invoke TestEntrypoint --event sam-tests/YOUR_INPUT_FILE`, where `YOUR_INPUT_FILE` is a JSON-formatted file whose structure is documented [here](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing), and that you locally store in a `sam-tests` directory at the project's root level.

{{% notice note %}}
Files you create and edit in the `sam-tests` directory may contain credentials. The `sam-tests/` location should be added to a `.gitignore` file (like the one at the project's root level for the example resource type you used in this lab) to avoid adding it to a source code repository. Depending on your setup, you might or might not need to add credentials to the files in the `sam-tests` directory.
{{% /notice %}}

##### Challenge
Create a `sam-tests/example-read.json` file to test the *read* handler of the `AWSSamples::EC2::ImportKeyPair` example resource type. As an example input, choose the key pair you created in the `example-key-pair-stack` stack earlier. The expected output is a data structure containing properties from the model that the *read* handler for the example resource type first fetches on your behalf, and that then returns.

{{%expand "Need a hint?" %}}
* Use the [uuid](https://docs.python.org/3/library/uuid.html) module in Python to generate a `UUID4` value to pass to `clientRequestToken`;
* from the [Read handlers](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-contract.html#resource-type-test-contract-read) section in the Resource type handler contract documentation [page](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-contract.html), read content in *Input assumptions* to determine which key and value to pass, as an input, underneath the `desiredResourceState` key in the JSON structure;
* use an example value for the logical identifier of the resource, such as `my-example-resource`.
{{% /expand %}}


{{%expand "Want to see the solution?" %}}
* Create a `sam-tests/example-read.json` file, by using the structure documented [here](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing);
* from the Python command line interface, generate a `UUID4` value as in this example:

```
>>> import uuid
>>> uuid.uuid4()
UUID('OUTPUT EDITED: THIS WILL CONTAIN A UUID4 VALUE')
```

* from the `Outputs` section of the `example-key-pair-stack` CloudFormation stack you created: use the value for `KeyPairId`, and pass it to a new `KeyPairId` key that you create in the JSON file's structure underneath the `desiredResourceState` key;
* a resulting file structure should look like in the following example:

```
{
  "credentials": {
    "accessKeyId": "",
    "secretAccessKey": "",
    "sessionToken": ""
  },
  "action": "READ",
  "request": {
    "clientRequestToken": "REPLACE_WITH_YOUR_UUID4_VALUE_HERE",
    "desiredResourceState": {
      "KeyPairId": "REPLACE_WITH_THE_KEYPAIR_ID"
    },
    "logicalResourceIdentifier": "my-example-resource"
  },
    "callbackContext": {}
}
```

* run `sam local invoke TestEntrypoint --event sam-tests/example-read.json` sample test file; you should see, as an output, a `resourceModel` section with resource property values returned from the *read* handler.
{{% /expand %}}


### Clean up

Steps to clean up resources you created follow next (assuming `us-east-1` as the AWS region you chose):

```
aws cloudformation delete-stack \
  --region us-east-1 \
  --stack-name example-key-pair-stack

aws cloudformation wait stack-delete-complete \
  --region us-east-1 \
  --stack-name example-key-pair-stack

aws cloudformation delete-stack \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests

aws cloudformation wait stack-delete-complete \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests

aws cloudformation deregister-type \
  --region us-east-1 \
  --type-name AWSSamples::EC2::ImportKeyPair \
  --type RESOURCE
```



### Conclusion

Congratulations! You have walked through an example resource type implementation in Python, and learned key concepts, expectations and objectives to keep in mind when writing your resource types.
