---
title: 'Key Concepts'
date: 2021-11-16T20:44:31Z
weight: 310
---

### Getting started

Key concepts for developing a resource type include:

* [schema](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-schema.html): a document where you describe your resource specification, such as properties whose input values users can specify, or read-only properties that will only be available after resource creation (for example, a resource ID), et cetera;
* [handlers](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-develop.html#resource-type-develop-implement-handlers): when you develop a resource type, you describe its life cycle across Create, Read, Update, Delete, List (CRUDL) operations in code you will implement in a [supported language](https://github.com/aws-cloudformation/cloudformation-cli#supported-plugins). In your code, you describe the behavior you wish to have for your resource type (e.g., which AWS or third-party API to call to perform a given operation) in CRUDL handlers mentioned above (e.g., the *create* handler, the *update* handler, et cetera).
