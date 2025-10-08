### Feedback for the section

- First read the last few commits in the git log and see what new content is addes in this branch compared to the main branch
- then read the following and make them into a progress note with summaries for each issue, note on which issues you have resolved
- Help me update the workshop content.
- Help me address them one by one and make note of them in this md file.

#### List of suggestions

##### Section "Write Guard rules for Hook"

1. Update the "Step 5: Upload Guard Rules to S3" in write-guard-rules section to give link to Amazon S3 so people can open it directly to the console to create the bucket mannuall, note on the common best practice for creating new bucket with the default bucket public access settings.
2. Update the "Step 5: Upload Guard Rules to S3" give a suggestion for a bucket name maybe something like guard*hook_bucket* + participants' names

##### Section "Prepare to create a Guard Hook"

1. updatee the instruction to note the link to the preivous seciont if people ahve not upload the guard file the s3 bucket.

##### Section "Activate a Guard Hook"

1. update the "Configure Hook Settings" section and the other few sections to have use a few screenshots for configuring the hook, look the screenshots names with the same prefix "advanced-hook-create-a-hook-with-guard" for which screenshot for which section:
   - the screenshots are in this folder "/Users/jjlei/dev/cfn101-workshop/static/advanced/hook": advanced-hook-create-a-hook-with-guard.png and all the other screnshots are named with the same prefix "advanced-hook-create-a-hook-with-guard"
   - give guidance on how to find the Execution Role from the previous steps like giving an eaxmple of the guard hook role name
2. udpate the section of "S3 URI – Enter the S3 URI of your Guard rules file" with links to the previous section where people have created the bucket so they can find the name from the previous steps.
3. The content for the steps in this section is littile messed up, update the intrusction to use these steps the following are what is on each setting page update to be more accurate as the screnshot will be along side with the content too:
   Step 1
   Provide your Guard rules

for this thse are the settings: Provide your Guard rules Info
Evaluate and activate a Hook with custom logic using Guard rules to validate against your CloudFormation resources and stacks.

Learn about CloudFormation Guard

AWS CloudFormation Guard is an open-source general-purpose policy-as-code evaluation tool that provides developers with a simple-to-use, yet powerful and expressive domain-specific language (DSL) to define Hooks.
Simple and easy language for non-technical policy authors to pick up.
Allows policy authors to use the same DSL to validate AWS Config-based configuration items.
See community best-effort examples to start with in the Guard Hooks library
Guard Hook source
Provide an S3 destination that directs AWS to your Guard rules for your Hook. Learn more about writing Hooks in Guard.

Store your Guard rules in S3
Enter a destination where your Guard rules will be stored for your Hook to validate against your JSON- or YAML-formatted CloudFormation data.
S3 URI
s3://jj-guard-rules-bucket/hooks/s3-security-rules.guard

Object version

Select an option
View
Browse S3
Object should end in .guard, .zip, or .tar.gz. For objects in a bucket with versioning enabled, you can choose the most recent or a previous version of the object.
S3 bucket for Guard output report - optional
Provide the S3 bucket name for where your Guard output report will be stored.
Use the same bucket my Guard rules are stored in.

Choose a bucket
Guard rule input parameters - optional
Store your Guard rule input parameters in S3
Provide a parameter file in JSON or YAML that specifies any additional parameters to use along with data files to be used as a combined context.
S3 URI
Object version

Select an option
View
Browse S3
Object should end in json, yaml, .zip, or .tar.gz. For objects in a bucket with versioning enabled, you can choose the most recent or a previous version of the object.

Step 2
Hook details and settings
here. are the settings for this section: ook details and settings Info
Provide the additional details, configuration, and settings needed to activate your Hook.

Hook details and configuration
Hook name
Provide a Hook name that will be appended to ‘Private::Guard::’ or provide a full alias. Hook names must be unique within a given account and region.
A Hook name must be provided.
Must be 10-204 characters and can use either alphanumeric characters or a custom alias in [provider::service-name::hook-name] format.
Hook targets
Choose the targets for your Hook invocations. Learn more about the different Hook targets

Choose targets
Actions
Choose which deployment actions you want your Hook to be invoked on based on your targets.

Choose actions
Hook mode
A Hook mode is a value you configure to determine how the Hook will respond when a Hook fails.

Warn
Only emit a warning message when a hook fails, without stopping the provisioning operation.
Execution role
Provide a role that Hooks assumes to invoke the Lambda function used for this Hook.

New execution role
Create a role in your account.
Existing execution role
Choose an existing role in your account.
Role Name
Use only letters, numbers, or hyphens. The maximum length is 100 characters.
Cancel
Previous
Next

Step 3 - optional
Apply Hook filters
the setting on this part is:
Provide your Guard rules Info
Evaluate and activate a Hook with custom logic using Guard rules to validate against your CloudFormation resources and stacks.

Learn about CloudFormation Guard

AWS CloudFormation Guard is an open-source general-purpose policy-as-code evaluation tool that provides developers with a simple-to-use, yet powerful and expressive domain-specific language (DSL) to define Hooks.
Simple and easy language for non-technical policy authors to pick up.
Allows policy authors to use the same DSL to validate AWS Config-based configuration items.
See community best-effort examples to start with in the Guard Hooks library
Guard Hook source
Provide an S3 destination that directs AWS to your Guard rules for your Hook. Learn more about writing Hooks in Guard.

Store your Guard rules in S3
Enter a destination where your Guard rules will be stored for your Hook to validate against your JSON- or YAML-formatted CloudFormation data.
S3 URI
Object version

Select an option
View
Browse S3
Object should end in .guard, .zip, or .tar.gz. For objects in a bucket with versioning enabled, you can choose the most recent or a previous version of the object.
S3 bucket for Guard output report - optional
Provide the S3 bucket name for where your Guard output report will be stored.
Use the same bucket my Guard rules are stored in.

Choose a bucket
Guard rule input parameters - optional
Cancel
Next

Step 4
Review and activate

here are the content on this page: Review and activate Info
Step 1: Provide your Guard rules
Edit
Guard Hook source
S3 URI
s3://jj-guard-rules-bucket/hooks/s3-security-rules.guard
S3 bucket for Guard output report

- Guard rule input parameters - optional
  Step 2: Hook details and settings
  Edit
  Hook details and configuration
  Hook name
  Private::Guard::S3SecurityGuardHook
  Hook targets
  Resources
  Actions
  Create
  Hook mode
  Fail
  Execution role
  Execution role name
  GuardHookExecutionRoleStack-GuardHookExecutionRole-vAWS5Q9POcGi
  Step 3: Apply Hook filters - optional
  Edit
  Hook filters
  Target resources
  AWS::S3::Bucket
  Filtering criteria
  ALL
  Stack names
  Include: -
  Exclude: -
  Stack roles
  Include: -
  Exclude: -
  Cancel
  Previous

##### Section: Test Guard Hook

1. update the instruction to ask the participants to use the aws account credentials if they were to run the awscloudforamtion create-stack commands
2. updaet this if not correct - after running the
   aws cloudformation create-stack \
    --stack-name s3-noncompliant-stack \
    --template-body file://noncompliant-s3.yaml \
    --region us-east-1 first the user will get
   {
   "StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-noncompliant-stack/c997a360-a481-11f0-ae62-1251de0de62d"
   } and then they need to press q to exit the output view

3. updaet this if not correct - example output for the commadn aws cloudformation describe-stack-events \
   --stack-name s3-noncompliant-stack \
   --query 'StackEvents[?HookType!=`null` && contains(HookType, `S3SecurityGuardHook`)]' \
   --region us-east-1

the output is: stack",
"LogicalResourceId": "NonCompl
iantS3Bucket",
"PhysicalResourceId": "",
"ResourceType": "AWS::S3::Buck
et",
"Timestamp": "2025-10-08T20:03
:02.446000+00:00",
"ResourceStatus": "CREATE_IN_P
ROGRESS",
"HookType": "Private::Guard::S
3SecurityGuardHook",
"HookStatus": "HOOK_COMPLETE_F
AILED",
"HookStatusReason": "Hook fail
ed with message: Template failed valid
ation, the following rule(s) failed: s
3_encryption_enabled, s3_no_public_rea
d, s3_public_access_blocked, s3_versioning_enabled.",
"HookInvocationPoint": "PRE_PROVISION",
"HookInvocationId": "2a36aa47-2d4c-4ab8-a263-4162b342545c",
"HookFailureMode": "FAIL"
},
{
"StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-noncompliant-stack/c997a360-a481-11f0-ae62-1251de0de62d",
"EventId": "NonCompliantS3Bucket-9cd25ccd-8b45-4c61-890e-08c042d5be66",
"StackName": "s3-noncompliant-stack",
"LogicalResourceId": "NonCompliantS3Bucket",
"PhysicalResourceId": "",
"ResourceType": "AWS::S3::Bucket",
"Timestamp": "2025-10-08T20:03:01.818000+00:00",
"ResourceStatus": "CREATE_IN_PROGRESS",
"HookType": "Private::Guard::S3SecurityGuardHook",
"HookStatus": "HOOK_IN_PROGRES
S",
"HookStatusReason": "Invoking
hook",
"HookInvocationPoint": "PRE_PR
OVISION",
"HookInvocationId": "2a36aa47-
2d4c-4ab8-a263-4162b342545c",
"HookFailureMode": "FAIL"
}
]
press q to exsit the view

1. udpate with screenshots in the content, look at the name with prefix: "advanced-hook-create-a-hook-with-guard"

2. update if needed this is what the failed stack deployment shows for the noncompliant stack: Events (8)
   View root cause

Timestamp
Logical ID
Status
Detailed status
Status reason
Hook invocations

Timestamp
Logical ID
Status
Detailed status
Status reason
Hook invocations

2025-10-08 13:03:05 UTC-0700
s3-noncompliant-stack
ROLLBACK_COMPLETE

-
-
- 2025-10-08 13:03:05 UTC-0700
  NonCompliantS3Bucket
  DELETE_COMPLETE
-
-
- 2025-10-08 13:03:02 UTC-0700
  s3-noncompliant-stack
  ROLLBACK_IN_PROGRESS
- The following resource(s) failed to create: [NonCompliantS3Bucket]. Rollback requested by user.
- 2025-10-08 13:03:02 UTC-0700
  NonCompliantS3Bucket
  CREATE_FAILED
  Likely root cause
- The following hook(s) failed: [Private::Guard::S3SecurityGuardHook]
- 2025-10-08 13:03:02 UTC-0700
  NonCompliantS3Bucket
  CREATE_IN_PROGRESS
-
- Private::Guard::S3SecurityGuardHook
  2025-10-08 13:03:01 UTC-0700
  NonCompliantS3Bucket
  CREATE_IN_PROGRESS
-
- Private::Guard::S3SecurityGuardHook
  2025-10-08 13:03:01 UTC-0700
  NonCompliantS3Bucket
  CREATE_IN_PROGRESS
-
-
- 2025-10-08 13:02:58 UTC-0700
  s3-noncompliant-stack
  CREATE_IN_PROGRESS
- User Initiated
-

also update the screenshot for the event output: advanced-hook-create-a-hook-with-guard-failed-stack-view-events-output.png

- in the "Scenario 2: Compliant S3 Bucket" section plesae update if it need here is my test output after running:aws cloudformation create-stack \
   --stack-name s3-compliant-stack \
   --template-body file://compliant-s3.yaml \
   --region us-east-1
  : {
  "StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-compliant-stack/2aeb8df0-a498-11f0-9a7d-12b38b1ac8b9"
  }

then I prssed q to quit the output view.

this my output after running: aws cloudformation describe-stack-events \
 --stack-name s3-compliant-stack \
 --query 'StackEvents[?HookType!=`null` && contains(HookType, `S3SecurityGuardHook`)]' \
 --region us-east-1

:
[
{
"StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-compliant-stack/2aeb8df0-a498-11f0-9a7d-12b38b1ac8b9",
"EventId": "CompliantS3Bucket-224b78da-9fbc-47cf-9cb4-b9a4706c83a7",
"StackName": "s3-compliant-stack",
"LogicalResourceId": "CompliantS3Bucket",
"PhysicalResourceId": "",
"ResourceType": "AWS::S3::Bucket",
"Timestamp": "2025-10-08T22:43:14.488000+00:00",
"ResourceStatus": "CREATE_IN_PROGRESS",
"HookType": "Private::Guard::S3SecurityGuardHook",
"HookStatus": "HOOK_COMPLETE_SUCCEEDED",
"HookStatusReason": "Hook succeeded with message: Successful validation",
"HookInvocationPoint": "PRE_PROVISION",
"HookInvocationId": "01496608-f297-4dbb-8303-5fa8fc529498",
"HookFailureMode": "FAIL"
},
{
"StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-compliant-stack/2aeb8df0-a498-11f0-9a7d-12b38b1ac8b9",
"EventId": "CompliantS3Bucket-89472586-e207-418a-b514-429a3e9cc8ef",
"StackName": "s3-compliant-stack",
"LogicalResourceId": "CompliantS3Bucket",
"PhysicalResourceId": "",
"ResourceType": "AWS::S3::Bucket",
"Timestamp": "2025-10-08T22:43:14.047000+00:00",
"ResourceStatus": "CREATE_IN_PROGRESS",
"HookType": "Private::Guard::S3SecurityGuardHook",
"HookStatus": "HOOK_IN_PROGRESS",
"HookStatusReason": "Invoking hook",
"HookInvocationPoint": "PRE_PROVISION",
"HookInvocationId": "01496608-f297-4dbb-8303-5fa8fc529498",
"HookFailureMode": "FAIL"
}
]
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
(END)

update the guide if needed.

s3-compliant-stack

help me address this error: Resource handler returned message: "The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again. (Service: S3, Status Code: 409, Request ID: KG5436TPK0PYFQAZ, Extended Request ID: KtStja1AN+O2Xws4reNOEHtMLCGXh0tBCwx2d7/JK/cS25Ub+bI+iQDWV/Sw26hZjohcWlK6pn8=) (SDK Attempt Count: 1)" (RequestToken: 690975cb-5620-1e3d-28fa-b1a5f1f12a46, HandlerErrorCode: AlreadyExists)

I can actually run it after I've updated the bucker name in the compliant yaml file. and this is the output for aws cloudformation describe-stack-events \
 --stack-name s3-compliant-stack \
 --query 'StackEvents[?HookType!=`null` && contains(HookType, `S3SecurityGuardHook`)]' \
 --region us-east-1

[
{
"StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-compliant-stack/c7dd3540-a499-11f0-8e05-0affcdb6e4dd",
"EventId": "CompliantS3Bucket-c820250f-3c03-44dd-a520-d29bd75f4523",
"StackName": "s3-compliant-stack",
"LogicalResourceId": "CompliantS3Bucket",
"PhysicalResourceId": "",
"ResourceType": "AWS::S3::Bucket",
"Timestamp": "2025-10-08T22:54:47.524000+00:00",
"ResourceStatus": "CREATE_IN_PROGRESS",
"HookType": "Private::Guard::S3SecurityGuardHook",
"HookStatus": "HOOK_COMPLETE_SUCCEEDED",
"HookStatusReason": "Hook succeeded with message: Successful validation",
"HookInvocationPoint": "PRE_PROVISION",
"HookInvocationId": "3dc80239-9056-4dd4-9716-eec4d2477ca4",
"HookFailureMode": "FAIL"
},
{
"StackId": "arn:aws:cloudformation:us-east-1:832978051484:stack/s3-compliant-stack/c7dd3540-a499-11f0-8e05-0affcdb6e4dd",
"EventId": "CompliantS3Bucket-c5f4dc9e-1145-4af6-ba40-53b36bc28354",
"StackName": "s3-compliant-stack",
"LogicalResourceId": "CompliantS3Bucket",
"PhysicalResourceId": "",
"ResourceType": "AWS::S3::Bucket",
"Timestamp": "2025-10-08T22:54:47.049000+00:00",
"ResourceStatus": "CREATE_IN_PROGRESS",
"HookType": "Private::Guard::S3SecurityGuardHook",
"HookStatus": "HOOK_IN_PROGRESS",
"HookStatusReason": "Invoking hook",
"HookInvocationPoint": "PRE_PROVISION",
"HookInvocationId": "3dc80239-9056-4dd4-9716-eec4d2477ca4",
"HookFailureMode": "FAIL"
}
]
~
~
(END)

- add sreenshot too. read the screenshots names here in this folder for finding the correct one to use: /Users/jjlei/dev/cfn101-workshop/static/advanced/hook

* rememebr to replace my aws account id and other private information as place holder so nobody will use those data.
