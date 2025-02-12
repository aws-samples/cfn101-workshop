---
title: "Activate a Lambda Hook"
weight: 500
---

### Introduction

To use an AWS Lambda Hook in your account, you must first activate the Hook for the account and Region where you want to use it. Activating a Hook makes it usable in stack operations in the account and Region where it's activated.

When you activate a Lambda Hook, CloudFormation creates an entry in your account's registry for the activated Hook as a private Hook. This allows you to set any configuration properties the Hook includes. Configuration properties define how the Hook is configured for a given AWS account and Region.
