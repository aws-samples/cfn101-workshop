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


#### Example resource type walkthrough

Let's dive deeper into key considerations you should make when you design the model schema of your resource type. As an example, you will use an existing, sample resource type called [AWSSamples::EC2::ImportKeyPair](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python), that illustrates an example of importing and managing an imported [Amazon EC2](https://aws.amazon.com/ec2/) key pair with CloudFormation.

Let's get started! Choose an existing or new directory on your machine, that is outside of the directory path of an existing source code repository. Change directory into the directory you chose, and choose to clone the [repository](https://github.com/aws-cloudformation/aws-cloudformation-samples) where the example resource type is located. Alternatively, you can choose to [download a ZIP archive](https://github.com/aws-cloudformation/aws-cloudformation-samples/archive/refs/heads/main.zip) instead. To clone the repository, use the following command:

```shell
$ git clone https://github.com/aws-cloudformation/aws-cloudformation-samples.git
```

The repository contains a number of other examples. Change directory into the following one that contains the example resource type, and then choose to enter the directory containing the example implementation in Python:

```shell
$ cd aws-cloudformation-samples/resource-types/awssamples-ec2-importkeypair/
$ cd python/
```

Let's take a look at a number of elements in the directory structure inside of the `python/` directory:

* `README.md`: main documentation file where you'd typically want to add information on how to use a resource type you develop;
* `docs`: directory containing auto-generated syntax information for properties of the resource type. Every time you make changes to the resource schema file, you want to refresh auto-generated code - that includes files in the `docs/` directory - with the `cfn generate` CloudFormation CLI command;
* `inputs`: directory containing files with key/value data for resource type input properties. The resource type creator specifies this input information for use with contract tests: *do not add sensitive information to those files*. For more information, see [Specifying input data for use in contract tests](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test.html#resource-type-test-input-data);
* `awssamples-ec2-importkeypair.json`: this file, named after the resource type name choice, contains the schema for the resource. When you develop a resource type, you use this file to **describe the model for the resource**;
* `src`: contains a directory named after the resource type name, inside of which you should find:
  - the `models.py` file, that is managed by the CloudFormation CLI on your behalf when you make schema changes, and
  - the `handlers.py` file, that is where the resource type developer adds code for the CRUDL implementation logic. Open the `src/handlers.py` file with a text editor of your choice, and **familiarize with the handlers' structure** described in `create_handler`, `update_handler`, `delete_handler`, `read_handler`, `list_handler` functions;
* `resource-role.yaml`: file managed by the CloudFormation CLI, that describes an [AWS Identity and Access Management](https://aws.amazon.com/iam/) (IAM) role whose `PolicyDocument` contains permissions the resource type developer indicates in the `handlers` section of the schema file.  CloudFormation assumes this role to manage resources on behalf of the user as part of CRUDL operations;
* `template.yml`: [AWS Serverless Application Model](https://aws.amazon.com/serverless/sam/) (SAM) template used as part of resource type testing.

In the next section, you will explore aspects of the thought process of *implementing a resource type by starting from the model*, and you will compare such steps with example code content you just chose to clone or download on your machine.


#### Resource modeling

The first step in creating a resource type is to define a schema that describes properties for your resource, as well as permissions needed for CloudFormation to manage the resource on your behalf.

Let's start with determining which properties are needed in the example resource type you are using for this walkthrough. Visit the API reference page relevant to the resource type you wish to create; for the `AWSSamples::EC2::ImportKeyPair` resource type example, you want to look for the [Amazon EC2 API reference](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/Welcome.html): you can find it by navigating to the [AWS documentation](https://docs.aws.amazon.com/) page, where you choose **Amazon EC2** from **Compute**, and then **API Reference** in the next page. Next, from [Actions](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html), locate operations that give you the ability to programmatically perform actions on a key pair: you note `CreateKeyPair`, `DeleteKeyPair`, `DescribeKeyPairs`, and `ImportKeyPair`. Since the first action is relevant to the creation on a key pair and not to its import, it is not needed. You will need the other 3 actions instead.

Next, let's look at the documentation for [ImportKeyPair](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ImportKeyPair.html): look into *request parameters* and *response elements* to determine which properties you want to describe in the schema. For request parameters, in this case, you want to specify:

* a `KeyName` for the key pair you're importing (see the *Required: Yes* relevant note in the documentation);
* your `PublicKeyMaterial` content (*Required: Yes*);
* a set of optional tags (`TagSpecification.N` - *Required: No)*.


Let's now look at response elements: `keyPairId` is returned when you create the resource, along with other elements that include the `keyFingerprint`. The [DeleteKeyPair](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DeleteKeyPair.html) action takes in parameters that include the `KeyName`. Let's summarize an initial analysis:

* `KeyName` and `PublicKeyMaterial` are required input parameters; tags (`TagSpecification.N`), are optional;
* `keyPairId` and `keyFingerprint` are available after the resource is created; hence, cannot be specified by the user;
* `keyPairId` is a good choice for the resource's primary identifier property.

Properties above are good candidates for use with *Create*, *update*, and *delete* handlers for CloudFormation to manage the resource on your behalf. Additional properties are needed for *read* and *list* handlers: in this example, [`DescribeKeyPairs`](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeKeyPairs.html) is a good choice. The `keySet` response element includes a number of fields you've noted earlier, including `keyType` that could also be included in the model along with properties available after resource creation.

Let's now compare findings above with the example schema for the `AWSSamples::EC2::ImportKeyPair` resource type. Open the `awssamples-ec2-importkeypair.json` file with your favorite text editor; you'll note that:

* properties for the model, along with value constraints, are described in the `properties` section;
* `KeyName`, `PublicKeyMaterial` are set as `required`
* `KeyPairId`, `KeyFingerprint`, `KeyType` (properties that are determined after resource creation) are specified as `readOnlyProperties`
* `KeyPairId` is set as a `primaryIdentifier`
* `PublicKeyMaterial` is specified with `writeOnlyProperties`. You often use `writeOnlyProperties` to describe values containing sensitive data (such as passwords): these values cannot be returned from *list* or *read* requests. In the `AWSSamples::EC2::ImportKeyPair` example, since information for the public key material is not returned by `DescribeKeyPairs` that the example uses in *list* or *read* handlers, it would not make sense to include it with a null value in *list* or *read* handlers: this is why, in the example, describing the property as `writeOnlyProperties` is deemed to be a fit;
* `KeyName`, `PublicKeyMaterial` are set as `createOnlyProperties`: as such, updating any of the two values for the imported key pair will cause the creation of a new resource with new values, and a deletion of the previous resource;
* `Tags`, that are not required, are described in the [`definitions`](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-schema.html#schema-properties-definitions) section as part of best practices for potential reuse across definitions in your schema. In the example schema, `Tags` are referenced with a `$ref` pointer in the `properties` section.

For more information on how to create a schema and on schema elements, see [Resource type schema](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-schema.html).

The `awssamples-ec2-importkeypair.json` example schema file also contains a number of [AWS Identity and Access Management](https://aws.amazon.com/iam/) (IAM) permissions that handlers will need to manage the resource type on your behalf. When you look into the `handlers` section on the example schema file, you'll find a number of self-descriptive, EC2-related permissions. For more information on permissions from which you can choose when you create your resource type, see [Actions, resources, and condition keys for AWS services](https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html): on that page, choose the AWS service you need - in this case, [Amazon EC2](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html) - and then choose [Actions defined by Amazon EC2](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html#amazonec2-actions-as-permissions).

{{% notice note %}}
When you make changes to the schema file for the resource you develop, run the `cfn generate` CloudFormation CLI command from inside the root directory of your resource type project to reflect schema changes into project files such as `docs/*`, `resource-role.yaml`, and `src/[RESOURCE_TYPE_NAME]/models.py`.
{{% /notice %}}


#### Handlers

In the previous section, you have followed along an example process of how to start building your schema. In this section, you will go through steps that illustrate an example handler code implementation. Initial, key considerations to make are:

* for a given CRUDL handler (*Create*, *Read*, *Update*, *Delete*, *List*), you will need to implement a business logic as such:
    * call a given, service-specific API(s) (such as `ImportKeyPair` in the *create* handler, `DeleteKeyPair` in the *delete* handler, et cetera);
* consume data returned by a given API you call in a given handler; moreover:
    * every handler must always return a `ProgressEvent`. For more information on its structure, see [ProgressEvent object schema](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-progressevent.html);
    * if there are no errors, return a `ProgressEvent` object with `status=OperationStatus.SUCCESS` from a given handler; additionally, if the handler is not *delete* or *list*, return a `ResourceModel` object (the model for the resource) with the data you gather with your handler code (from an API call) for the resource. For the *list* handler, instead of a single model, return a list of models for each of your resources of the type you're describing;
    * if the API you call returns an error, or if there is another exception being thrown, return a `ProgressEvent` object with `status=OperationStatus.FAILED`. Considerations to make when you do so include:
        * capture the stacktrace, and the specific error message text from a given exception (`botocore.exceptions.ClientError`, other exceptions, ...). This way, you can show your stacktrace in log statements you write in your handler's code, and return the error message description with a `ProgressEvent` object, so that this information can be made available as part of CloudFormation events (e.g., in the Events pane in the CloudFormation console) to describe to the user the cause of the error;
        * depending on the error you get from the underlying API (for the import key pair example, for a given error from [Error codes for the Amazon EC2 API](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/errors-overview.html)), you want to map it to a given error from [Handler error codes](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-test-contract-errors.html). For example, if an EC2 API returns an `InvalidKeyPair.NotFound` client error you want to return a `HandlerErrorCode.NotFound` handler error with a `ProgressEvent`;
        * if your resource type will require time to stabilize (for example, reaching to a state where the resource is fully available), use a stabilization mechanism on *create*, *update*, and *delete* handlers: you return a `ProgressEvent` with an `OperationStatus.IN_PROGRESS` the first time a handler is called, and for subsequent calls of that handler until your desired state is reached, you drive next steps by checking on the progress status by calling the *read* handler (where, for example, you check for a specific property value to determine creation complete or in progress).

You can see examples of topics described above in the `src/awssamples_ec2_importkeypair/handlers.py` sample resource type: each handler makes calls to given EC2 API(s), for which there is a relevant set of permissions set in the schema as you have seen earlier. The example resource type leverages exception handling mechanism described above, whereas a downstream API error message is captured and returned along with a handler error code mapped to a given EC2 API. Even if, for the key pair import use case, a stabilization process is not necessarily needed, the sample resource type illustrates an example of a callback mechanism used in *create*, *update*, and *delete* handlers.


#### Running unit tests

As part of software development best practices, you want to write *unit tests* to increase your level of confidence that your code works the way you expect. As mentioned in these [notes](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python#unit-tests), the `AWSSamples::EC2::ImportKeyPair` example resource type includes unit tests in the `src/awssamples_ec2_importkeypair/tests` directory. If you look at the `test_handlers.py` file in that directory (that should be on your machine as part of the repository clone/download choice you made earlier), you will see test utility functions described at the beginning and, about at half-way through the file, unit tests that consume such utility functions to perform tests including validating return values and exceptions being thrown. Objects, that include function calls such as EC2 API calls, are replaced/patched in tests with mock objects calls by leveraging the [unittest.mock](https://docs.python.org/3/library/unittest.mock.html) mock object library.

Let's run unit tests! Make sure you are in the directory that is at the root level of the `AWSSamples::EC2::ImportKeyPair` example resource type (i.e., inside the `python` directory), and that you have followed prerequisites in the previous topic. Next, choose to run unit tests as follows:

```shell
$ pytest --cov src --cov-report term-missing
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

```shell
$ ssh-keygen -t rsa -C "Example key pair for testing" -f example-key-pair-for-testing
```

Follow prompts and complete the creation of the key pair. You should now have, in the directory you chose, 2 files: `example-key-pair-for-testing` and `example-key-pair-for-testing.pub`. The former is the private key; the latter the public key portion, which is the one you will use in following steps where, when needed, you will need to provide its content by opening the public key file, copying its content in the clipboard and pasting it in the command line.

Next, create a CloudFormation stack that will create, for reference, an [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) resource containing the public key material you will provide an input: contract tests will consume the `KeyPairPublicKeyForContractTests` [exported stack output value](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) of this stack. Input files in the `inputs` directory of the example resource type, in turn, contain `{{KeyPairPublicKeyForContractTests}}` references to the value exported from the stack.

When ready, switch back to the terminal where you cloned or downloaded the example resource type, and make sure you are in the `aws-cloudformation-samples/resource-types/awssamples-ec2-importkeypair/python/` directory. With the next command, you will choose to create a new stack using the `examples/example-template-contract-tests-input.yaml` example template file: the template requires you to specify the `KeyPairPublicKey` input parameter, for which you will need to specify the content as mentioned earlier. The template also requires `OrganizationName` and `OrganizationBusinessUnitName`, that are set with example default values, `ExampleOrganization` and `ExampleBusinessUnit` respectively, and that will be used if you do not choose to provide values for them. Choose to create the stack as shown next, with a placeholder for the public key file content, where you will need to copy and paste the content of the public key file (the example uses `us-east-1` for the AWS region, change this value as needed):

```shell
$ aws cloudformation create-stack \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests \
  --template-body file://examples/example-template-contract-tests-input.yaml \
  --parameters ParameterKey=KeyPairPublicKey,ParameterValue='PASTE_CONTENT_OF_example-key-pair-for-testing.pub'
```

Wait until the `example-for-key-pair-contract-tests` stack is created, by using the CloudFormation console or the [stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) wait command of the AWS CLI (the example uses `us-east-1` for the AWS region):

```shell
$ aws cloudformation wait stack-create-complete \
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

```shell
$ cfn generate && cfn submit --set-default --region us-east-1
```

Wait until the registration finishes, after which you should have the `AWSSamples::EC2::ImportKeyPair` example resource type registered as a private extension in your account. To verify, choose *Activated extensions* in the CloudFormation console, and then choose *Privately registered*.

Now, let's test the example resource type with an example template, that is already available as `examples/example-template-import-keypair.yaml` in the repository you cloned or downloaded: if you open the file with a text editor of your choice, you will see how the example resource type is referenced in the `Resources` section. For `KeyPairPublicKey`, choose to specify the same public key content you used for contract tests. The template also uses default values for `KeyPairName`, `OrganizationName`, and `OrganizationBusinessUnitName`, that will be used unless you specify your own. Choose to create the stack (the example uses `us-east-1` for the AWS region):

```shell
$ aws cloudformation create-stack \
  --region us-east-1 \
  --stack-name example-key-pair-stack \
  --template-body file://examples/example-template-import-keypair.yaml \
  --parameters ParameterKey=KeyPairPublicKey,ParameterValue='PASTE_CONTENT_OF_example-key-pair-for-testing.pub'
```

Wait until the stack creation finishes, after which you should have imported successfully the example key pair using CloudFormation and the sample `AWSSamples::EC2::ImportKeyPair` resource type (the example uses `us-east-1` for the AWS region):

```shell
$ aws cloudformation wait stack-create-complete \
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
* use an example value for the logical identifier of the resource, such as `MyExampleResource`.
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
    "logicalResourceIdentifier": "MyExampleResource"
  },
    "callbackContext": {}
}
```

* run `sam local invoke TestEntrypoint --event sam-tests/example-read.json` sample test file; you should see, as an output, a `resourceModel` section with resource property values returned from the *read* handler.
{{% /expand %}}


### Clean up

Steps to clean up resources you created follow next (assuming `us-east-1` as the AWS region you chose):

```shell
$ aws cloudformation delete-stack \
  --region us-east-1 \
  --stack-name example-key-pair-stack

$ aws cloudformation wait stack-delete-complete \
  --region us-east-1 \
  --stack-name example-key-pair-stack

$ aws cloudformation delete-stack \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests

$ aws cloudformation wait stack-delete-complete \
  --region us-east-1 \
  --stack-name example-for-key-pair-contract-tests

$ aws cloudformation deregister-type \
  --region us-east-1 \
  --type-name AWSSamples::EC2::ImportKeyPair \
  --type RESOURCE
```



### Conclusion

Congratulations! You have walked through an example resource type implementation in Python, and learned key concepts, expectations and objectives to keep in mind when writing your resource types.
