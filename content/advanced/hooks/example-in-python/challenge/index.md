---
title: "Challenge"
weight: 490
---

Previously on this lab, you've written unit tests to validate the core logic of your hook. One of the requirements you were given was to allow for a mechanism to ignore S3 buckets whose names are specified by the hook administrator in the hook's configuration. You've used contract tests and end-to-end tests to validate aspects for this use case: in this challenge, you are tasked to write unit test code for this use case.

First, make sure you're in the `example-hook/` directory, as you'll need to run unit tests from there.

Next, open the existing `src/examplecompany_s3_versioningenabled/tests/test_handlers.py` file. Your task is to append, at the end of the file, a new unit test method you'll write, called `test_when_s3_bucket_is_ignored_then_validation_always_succeeds()`, to assert that when you specify the `my-ignored-bucket,my-other-ignored-bucket` comma-delimited list as an input to the type configuration, the hook validation succeeds regardless of the versioning configuration for the bucket. When you write the unit test method, do not specify the versioning configuration in the resource properties input.

Once you've written the new unit test method, run unit tests from the `example-hook/` directory, and make sure your new test passes as well.

:::expand{header="Need a hint?"}
- Look at the existing `test_when_s3_bucket_versioning_status_is_enabled_then_succeed()` test method; make a copy of it, and replace the method name in the method copy with `test_when_s3_bucket_is_ignored_then_validation_always_succeeds()`;
- in the test method you just copied (see the hint above), is there something you'll need to add and to remove for the `resourceProperties` input?
- Is there anything you need to add to `IgnoreS3BucketNames` further below?
- Look at the assertion for the response's message: does it need to be updated?
:::

::::expand{header="Want to see the solution?"}
Append the following content to the `src/examplecompany_s3_versioningenabled/tests/test_handlers.py` empty file you just created (add two empty lines before pasting the code below):

:::code{language=python showLineNumbers=false showCopyAction=true}
def test_when_s3_bucket_is_ignored_then_validation_always_succeeds() -> (  # noqa: D103 E501
    None
):
    MOCK_BASE_HOOK_HANDLER_REQUEST.hookContext.targetModel = {
        "resourceProperties": {
            "BucketName": "my-other-ignored-bucket",
        },
    }

    response = handlers._run_pre_create_pre_update_common_checks(
        session=None,
        request=MOCK_BASE_HOOK_HANDLER_REQUEST,
        callback_context=MOCK_CALLBACK_CONTEXT,
        type_configuration=TypeConfigurationModel(
            IgnoreS3BucketNames="my-ignored-bucket,my-other-ignored-bucket",
        ),
    )

    assert response.message == "Ignoring versioning configuration."
    assert response.status == OperationStatus.SUCCESS
    assert response.errorCode is None
    assert response.callbackContext is None
    assert response.callbackDelaySeconds == 0
:::

Next, run the unit tests from the `example-hook/` directory to verify:

:::code{language=shell showLineNumbers=false showCopyAction=true}
pytest --cov
:::

::::

Choose **Next** to continue!
