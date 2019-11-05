---
title: "Lab 04: Mapping & Conditionals"
date: 2019-11-01T13:36:34Z
weight: 300
---

## Introduction

This lab will cover Mapping, which allows you to lookup values from a set of predefined keys.

### Motivation
A common use for Mappings is to configure a template according to different environments, such as dev, test and production.

Rather than have 3 similar templates, one for each of dev, test and production, mapping allows you to have one template. Keys and their corresponding values are predefined in a map. These keys can be accessed in other parts of your template.

### Key Components

#### Mapping Section

The [`Mapping`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) section is a top level section of a CloudFormation template. It is used to define maps, their keys and values.



A Mapping Section can contain multiple maps. Each map contains atleast one key
A key in a map has two components, a top level key and a second level key.
Each key contains one or more Name - Value pairs. Each top level key must contain atleast one second level key.

Here is a simple Mapping section. It contains one Map, `Mapping01`. \
`Mapping01` contains three top level keys, `TopLevelKey01`, `TopLevelKey02` and `TopLevelKey03`. \
Each top level key contains one second level key, `SecondLevelKey`.
```yaml
Mappings: 
  Mapping01: 
    TopLevelKey01: 
      SecondLevelKey: Value01
    TopLevelKey02: 
      SecondLevelKey: Value02
    TopLevelKey03: 
      SecondLevelKey: Value03
```

#### Fn::FindInMap

[`Fn::FindInMap`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html) is an intrinsic function used to lookup the value of a key in a map.


## Implementing a simple map

## Challenge #1 - Simple Map


## Advanced Maps
## Challenge #2 - Advanced Maps

## Conclusion