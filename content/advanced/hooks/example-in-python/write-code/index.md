---
title: "Write code"
weight: 440
---

When you used the CloudFormation CLI to generate the project for your hook, it also created some files and directories in the `src/` directory. You'll next focus on inspecting and editing the content of the `handlers.py` file in the `src/examplecompany_s3_versioningenabled/` directory, to add the business logic for the proactive control you're implementing with your hook.

::alert[When you inspect the content of the `src/examplecompany_s3_versioningenabled/` directory, you'll see a number of files that are managed by the CloudFormation CLI when you run the `cfn generate` command (that you've already used earlier): for example, the `models.py` file and files in the `target_models` directory. Do not manually change these files or content, as they'll be overwritten by the CloudFormation CLI when you'll run `cfn generate`.]{type="warning"}

Open the `handlers.py` file mentioned above: the content of this file has been automatically generated for you when you used the CloudFormation CLI to create the project for your hook. Familiarize with the structure of the file: you'll see 3 methods, `pre_create_handler()`, `pre_update_handler()`, and `pre_delete_handler()` that are decorated, respectively, with the following wrappers:

- `@hook.handler(HookInvocationPoint.CREATE_PRE_PROVISION)`
- `@hook.handler(HookInvocationPoint.UPDATE_PRE_PROVISION)`
- `@hook.handler(HookInvocationPoint.DELETE_PRE_PROVISION)`

The intent is to have each of these methods above being called for a relevant event: for example, `pre_create_handler()` to be called when the hook is invoked for a given S3 bucket on stack creation. Each of these methods will need to have the business logic -written by you, in this case- to analyze the properties for a given resource (S3 bucket, in your case), that are described by users in a CloudFormation template.

Each of the methods above must return a properly-configured `ProgressEvent` object on events such as a successful verification of resource properties (`OperationStatus.SUCCESS`: your resource is compliant), or a failure (`OperationStatus.FAILED`: your resource is not compliant), so that CloudFormation understands what to do next.

Per requirements you received, you'll only want to invoke your hook on pre-create and pre-update events. This means that:

- you can remove the pre-delete method and logic, that you won't need for your use case, and
- you can conveniently use one single, shared method for both pre-create and pre-update operations in your use case: this way, you can efficiently maintain the business logic code in one place.

How can you consume, from the business logic of a given handler method, the resource properties coming from a CloudFormation template? When you look at the input parameters for methods above, you'll see the `request` parameter: first, you get the target model of the resource (S3 bucket in your case) from `request.hookContext.targetModel`, and then you can consume `resourceProperties` from the target model.

The boilerplate code also passes in, as an input parameter, `callback_context`. Typically, you'd use this parameter if the operations you run in your handler code take more than 30 seconds, _as hooks time out after 30 seconds_. You set up the callback context to persist values you need to read the current state in a subsequent reinvocation of the current handler. To signal the intent of calling back the current handler, you set `status` to `OperationStatus.IN_PROGRESS`, `callbackContext` to the value(s) you need, and optionally `callbackDelaySeconds` in the `ProgressEvent` object that you return from the handler's code. You won't use this functionality in the hook you're building.

As you continue to look at the boilerplate code, you also note the `type_configuration` input parameter for each of the methods mentioned above: you'll use this parameter from the business logic of your code to consume the optional hook configuration value(s) (in your case, `IgnoreS3BucketNames`), that you've already modeled in the schema earlier.

Before implementing the logic you need, note that the boilerplate code also has the following example snippet:

:::code{language=python showLineNumbers=false showCopyAction=false}
        if isinstance(session, SessionProxy):
            client = session.client("s3")
:::

The example above shows you how to properly create, for a hook, an SDK client (in your example, an S3 client), by using a pre-vended session proxy. You use an SDK client from a hook's code only if you need to make AWS API calls to a given AWS service (should this be the case, you'll also want to add the necessary IAM permissions to the schema for your hook). You won't need this functionality for the hook you'll build, but it's worth mentioning this important aspect anyway, as you might need it in your hooks for use cases that require verification checks that go beyond static code analysis.

Let's implement the create and update handler logic! You'll use one shared entrypoint method, with both the pre-create and pre-update decorations. Replace the entire content of the `handlers.py` file with the following:

:::code{language=python showLineNumbers=false showCopyAction=true}
"""Example hook to validate versioning is enabled for an Amazon S3 bucket."""

import logging
from typing import (
    Any,
    List,
    Mapping,
    MutableMapping,
    Optional,
)

from cloudformation_cli_python_lib import (  # type: ignore
    HandlerErrorCode,
    Hook,
    HookInvocationPoint,
    OperationStatus,
    ProgressEvent,
    SessionProxy,
)

from .models import (
    HookHandlerRequest,
    TypeConfigurationModel,
)


# Use this logger to forward log messages to CloudWatch Logs.
LOG = logging.getLogger(__name__)
TYPE_NAME = "ExampleCompany::S3::VersioningEnabled"

hook = Hook(TYPE_NAME, TypeConfigurationModel)
test_entrypoint = hook.test_entrypoint


@hook.handler(HookInvocationPoint.CREATE_PRE_PROVISION)
@hook.handler(HookInvocationPoint.UPDATE_PRE_PROVISION)
def pre_create_pre_update_common_handler(
    session: Optional[SessionProxy],
    request: HookHandlerRequest,
    callback_context: MutableMapping[str, Any],
    type_configuration: TypeConfigurationModel,
) -> ProgressEvent:
    """Use a common method for pre-create and pre-update validations."""
    return _run_pre_create_pre_update_common_checks(
        session=session,
        request=request,
        callback_context=callback_context,
        type_configuration=type_configuration,
    )


def _run_pre_create_pre_update_common_checks(
    session: Optional[SessionProxy],
    request: HookHandlerRequest,
    callback_context: MutableMapping[str, Any],
    type_configuration: TypeConfigurationModel,
) -> ProgressEvent:
    """Run common checks for pre-create and pre-update validations."""
    try:
        progress = ProgressEvent(status=OperationStatus.IN_PROGRESS)

        # Read the target properties of the S3 bucket.
        resource_properties = None
        target_model = _get_target_model(
            request=request,
        )
        if target_model:
            resource_properties = _get_resource_properties(
                target_model=target_model,
            )

        # Return a failure immediately if there are no S3 bucket
        # properties defined in the template.
        if resource_properties is None:
            message = "The S3 bucket has no properties set."
            LOG.error(message)
            progress.status = OperationStatus.FAILED
            progress.message = message
            progress.errorCode = HandlerErrorCode.NonCompliant
            return progress

        # Consume the IgnoreS3BucketNames type configuration
        # directive, and return success if the user specifies a bucket
        # name that is ignored in the directive.
        if (
            hasattr(
                type_configuration,
                "IgnoreS3BucketNames",
            )
            and type_configuration.IgnoreS3BucketNames != ""
        ):
            bucket_name = _get_bucket_name(
                resource_properties=resource_properties,
            )
            if bucket_name:
                ignore_s3_bucket_names_list = _get_ignore_s3_bucket_names_list(
                    type_configuration
                )
                if bucket_name in ignore_s3_bucket_names_list:
                    message = "Ignoring versioning configuration."
                    LOG.info(message)
                    # Set status to success to signal that the
                    # validation is successful, and return progress.
                    progress.status = OperationStatus.SUCCESS
                    progress.message = message
                    return progress

        # If the bucket is not in the list of buckets to ignore,
        # proceed with the validation: start with checking if the
        # VersioningConfiguration property is set.
        versioning_configuration = _get_versioning_configuration(
            resource_properties=resource_properties,
        )
        if versioning_configuration is None:
            message = "The VersioningConfiguration property value is missing."
            LOG.error(message)
            progress.status = OperationStatus.FAILED
            progress.message = message
            progress.errorCode = HandlerErrorCode.NonCompliant
            return progress
        else:
            # Check if the Status property for VersioningConfiguration
            # is set to Enabled.
            versioning_configuration_status = (
                _get_versioning_configuration_status(
                    versioning_configuration=versioning_configuration,
                )
            )
            if (
                versioning_configuration_status
                and versioning_configuration_status == "Enabled"
            ):
                message = "Bucket versioning is enabled."
                LOG.info(message)
                progress.status = OperationStatus.SUCCESS
                progress.message = message
                return progress

        # Fail the validation by default if the code execution did not
        # succeed above.
        message = "Bucket versioning is not enabled."
        LOG.error(message)
        progress.status = OperationStatus.FAILED
        progress.message = message
        progress.errorCode = HandlerErrorCode.NonCompliant
        return progress
    except Exception as exception:
        LOG.error(exception)
        progress.status = OperationStatus.FAILED
        progress.message = str(exception)
        progress.errorCode = HandlerErrorCode.InternalFailure
        return progress


def _get_target_model(
    request: HookHandlerRequest,
) -> Optional[Mapping[str, Any]]:
    """Return the target model of the resource from the request."""
    return request.hookContext.targetModel


def _get_resource_properties(
    target_model: Optional[Mapping[str, Any]],
) -> Any:
    """Return the resource properties from the target model."""
    return (
        target_model.get("resourceProperties")
        if target_model and target_model.get("resourceProperties")
        else None
    )


def _get_ignore_s3_bucket_names_list(
    type_configuration: TypeConfigurationModel,
) -> List[str]:
    """Return a list of items from type_configuration.IgnoreS3BucketNames."""
    # Remove spaces on assignment for ignore_s3_bucket_names.
    ignore_s3_bucket_names = (
        type_configuration.IgnoreS3BucketNames.replace(" ", "")
        if type_configuration.IgnoreS3BucketNames
        else ""
    )

    # Remove any list item that is an empty string when creating a
    # list of bucket names to ignore from IgnoreS3BucketNames in the
    # type configuration.
    return list(
        filter(
            None,
            ignore_s3_bucket_names.split(","),
        )
    )


def _get_bucket_name(
    resource_properties: Any,
) -> Any:
    """Return the bucket name from the resource properties."""
    # Remove spaces, if any, as well.
    return (
        resource_properties.get("BucketName").replace(" ", "")
        if resource_properties and resource_properties.get("BucketName")
        else None
    )


def _get_versioning_configuration(
    resource_properties: Any,
) -> Any:
    """Return the versioning configuration from the resource properties."""
    return (
        resource_properties.get("VersioningConfiguration")
        if resource_properties
        and resource_properties.get("VersioningConfiguration")
        else None
    )


def _get_versioning_configuration_status(
    versioning_configuration: Any,
) -> Any:
    """Return the status from the versioning configuration."""
    return (
        versioning_configuration.get("Status")
        if versioning_configuration and versioning_configuration.get("Status")
        else None
    )
:::

Save the file, and take a look at the code: can you recognize some of the implementation aspects that relate to the requirements you were given, for example: the code that checks if a bucket is ignored from the validation logic, if its name is in an input list maintained by the hook's administrator?

Also, note how the outer structure of the input data is validated. When you describe an S3 bucket with a CloudFormation template, for it to pass the validation above it needs to look like the following snippet:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
AWSTemplateFormatVersion: 2010-09-09
Description: Example S3 bucket.
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      VersioningConfiguration:
        Status: Enabled
:::

As you traverse the `Properties` tree above, you write the logic to validate that `Status`, for `VersioningConfiguration`, is set to `Enabled`. What if the `Properties` node above is missing though, or what if the `VersioningConfiguration` node underneath it is missing instead? The hook's business logic above also checks for these specific cases, and returns targeted error messages to the end user for them to easily pinpoint the relevant error.

As part of the prerequisites for running this lab, you've installed tools such as [mypy](https://github.com/python/mypy), a static type checker for Python, and [flake8](https://flake8.pycqa.org/en/latest/) for linting Python code. You'll use both tools in this lab as examples to check the code for the hook you're building.

::alert[You're not required to use `mypy` and `flake8` for your hook code to work. This lab shows an example usage of such tools in the context of the sample Python code for the hook you're building; you can choose to use tools and configurations you need or prefer in your projects.]{type="info"}

First, let's configure your hook's project settings for `mypy`. Create a `mypy.ini` configuration file for your hook project as follows (make sure you are in the `example-hook/` directory):

:::code{language=shell showLineNumbers=false showCopyAction=true}
touch mypy.ini
:::

When done, add this content to the `mypy.ini` file you just created:

:::code{language=text showLineNumbers=false showCopyAction=true}
[mypy]
follow_imports = silent

strict = True
:::

Next, run `mypy` against your `handlers.py` file (make sure you are in the `example-hook/` directory):

:::code{language=shell showLineNumbers=false showCopyAction=true}
mypy src/examplecompany_s3_versioningenabled/handlers.py
:::

You should see an output indicating no errors. Next, run `flake8` against the same file:

:::code{language=shell showLineNumbers=false showCopyAction=true}
flake8 \
    --docstring-convention pep257 \
    --ignore=W503,W504 \
    --max-complexity=10 \
    --max-line-length=79 \
    src/examplecompany_s3_versioningenabled/handlers.py
:::

You should see no output messages, indicating no errors have occurred. As part of the example set of command options for `flake8` above, note the `max-complexity=10` directive, that uses the `mccabe` [plugin](https://flake8.pycqa.org/en/latest/user/options.html#cmdoption-flake8-max-complexity) for McCabe's [cyclomatic complexity](https://en.wikipedia.org/wiki/Cyclomatic_complexity) metric to check if the code, at the method level for example, exceeds an example cyclomatic complexity value of `10` when it takes a number of paths: you use this check to measure how complex the structure of your code is, and you can choose to use this indicator as an opportunity to improve the code you write so that it is easier to maintain over time. A practical example would be to break down methods into smaller, specialized functions you can easily maintain -and reuse, as needed- in your code that, overall, will be more readable.

Next, you'll write some tests for your hook's logic, so that you'll have the opportunity to run these tests locally to speed up the development loop. Choose **Next** to continue!
